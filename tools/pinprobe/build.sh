#!/usr/bin/env sh
# Builds the two bitstreams of pinprobe (pinprobe.sv): one with the internal pull-ups of all PL pins,
# one with the pull-downs. Read them with pinprobe.tcl.
#
#   [VIVADO=/path/to/vivado] [WORK=dir] sh build.sh
#
# Writes WORK/pullup/pinprobe.bit and WORK/pulldown/pinprobe.bit, with the reports and pinmap.csv;
# WORK is ./pinprobe in the current directory by default.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
renice -n 19 -p $$ >/dev/null 2>&1 || true
vivado="${VIVADO:-vivado}"
mkdir -p "${WORK:-pinprobe}"
work="$(cd "${WORK:-pinprobe}" && pwd)"
for pull in pullup pulldown; do
    out="$work/$pull"
    rm -rf "$out"
    python3 "$here/gen.py" "$(echo $pull | tr a-z A-Z)" "$out" >/dev/null
    # The include file is beside the source, in the build directory.
    cp "$here/pinprobe.sv" "$out/"
    (cd "$out" && "$vivado" -mode batch -nojournal -log build.log -source "$here/../../examples/pl-blinky/build.tcl" \
        -tclargs pinprobe xc7z020clg400-1 pinprobe.xdc pinprobe.sv >build.out 2>&1 </dev/null) || true
    [ -f "$out/pinprobe.bit" ] || { echo "Vivado failed; see $out/build.log" >&2; grep -E '^ERROR' "$out/build.log" | head -5 >&2; exit 1; }
    if grep -q 'Timing constraints are not met' "$out/timing.rpt"; then
        echo "timing is not met; see $out/timing.rpt" >&2; exit 3
    fi
    echo "$out/pinprobe.bit"
done
