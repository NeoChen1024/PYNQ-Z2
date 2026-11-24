#!/usr/bin/env python3
"""Makes pins.csv, package-pins.csv and pynq_z2_master.xdc from four sources of pin data, and reports
where they differ:

- tools/schematic-pins.csv: the nets of the TUL schematic R12 (made by tools/schematic_pins.py)
- tools/package-dump.csv: the package data of Vivado for xc7z020clg400 (made by tools/package-dump.tcl)
- references/tul/pynq-z2_v1.0.xdc: the master XDC of TUL
- board-files/TUL/pynq-z2/A.0/part0_pins.xml: the Vivado board file

    python3 tools/tables.py .     # writes ./pins.csv, ./package-pins.csv and ./pynq_z2_master.xdc

The schematic is the reference. The port names come from the TUL XDC, with the corrections in RENAME
and the pins in ADD. A finding about a pin goes into NOTES or CHECKED, and then the tables are made
again. The script prints each difference between the three sources that NOTES does not explain.
"""
import csv, os, re, sys
sys.dont_write_bytecode = True

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
out = sys.argv[1] if len(sys.argv) > 1 else "."

schematic = {r["pin"]: r for r in csv.DictReader(open(os.path.join(ROOT, "tools/schematic-pins.csv")))}
package = {r["pin"]: r for r in csv.DictReader(open(os.path.join(ROOT, "tools/package-dump.csv")))}

# Bank voltages: schematic sheet 12 (FPGA Power).
VCCO = {"0": "3.3", "13": "3.3", "34": "3.3", "35": "3.3", "500": "3.3", "501": "1.8", "502": "1.5"}

# The TUL XDC: section titles in order, and the ports of each pin.
sections, tul = [], {}
for line in open(os.path.join(ROOT, "references/tul/pynq-z2_v1.0.xdc")):
    # A section title is a short line without a full stop or a colon; the notes of the XDC have them.
    m = re.match(r"##\s?([A-Z][^.:]*?)\s*$", line)
    if m and not m[1].startswith("This file"):
        sections.append(m[1])
        continue
    m = re.search(r"PACKAGE_PIN\s+(\w+)\s+IOSTANDARD\s+(\w+)\s*\}\s*\[get_ports\s*\{\s*(\S+)\s*\}\];\s*#(\S+)", line)
    if m:
        tul.setdefault(m[1], []).append({"port": m[3], "iostandard": m[2], "func": m[4], "section": sections[-1]})

# The board file: the pin names of each pin.
board_file = {}
for line in open(os.path.join(ROOT, "board-files/TUL/pynq-z2/A.0/part0_pins.xml")):
    m = re.search(r'name\s*="([^"]+)"\s+iostandard="(\w+)"\s+loc="(\w+)"', line)
    if m:
        board_file.setdefault(m[3], []).append(f"{m[1]} ({m[2]})")

# Sheet 11 gives K17 and K18 both the name IO_L12P_T1_MRCC_35. The package data gives K18 the N side.
FUNC_FIX = {"K18": "IO_L12N_T1_MRCC_35"}
# Sheet 10 draws the net of H6 away from the pin, and tools/schematic_pins.py does not find it.
NET_FIX = {"H6": "DDR3_VREF"}
# Comments of the TUL XDC with a wrong function name. The pins agree with the schematic, and the package
# data gives the name of the schematic. The script checks that the package data still says so.
TUL_COMMENT_WRONG = {("D18", "ar_an0_n"), ("E18", "ar_an1_p"), ("J14", "ar_an2_n"), ("J16", "ar_an3_n"),
                     ("H20", "ar_an4_n"), ("G20", "ar_an5_n"), ("U18", "rpio_06_r"), ("U19", "rpio_07_r"),
                     ("F19", "rpio_08_r"), ("W6", "rpio_23_r")}

# Corrections to the TUL XDC.
RENAME = {
    # "a" and the bus a[0..5] cannot both be ports of one design. The pin is on the AREF position of J3.
    ("Y13", "a"): "ar_aref",
    # The silkscreen SDA pin of J3 is P16, and SCL is P15 (measured 2026-11-24, docs/headers.md). The
    # schematic nets and the TUL XDC have the two names the other way round.
    ("P16", "ar_scl"): "ar_sda",
    ("P15", "ar_sda"): "ar_scl",
}
ADD = {
    # Schematic sheet 4: RP_IO04 goes through R87 to RPIO_27_R, GPIO27 on pin 13 of the Raspberry Pi
    # header. The TUL XDC and the board file do not have the pin.
    "V7": {"port": "rpio_27_r", "iostandard": "LVCMOS33", "section": "Raspberry Digital I/O"},
}
NOTES = {
    "V7": "RPi GPIO27 (header pin 13): not in the TUL XDC or the board file",
    "Y13": "on the AREF position of the Arduino header J3. The TUL XDC calls the port a, which collides with the bus a[0..5]",
    "P15": "SCL of the Arduino header (J3.10, silkscreen SCL), measured. The schematic net and the TUL XDC call it AR_SDA",
    "P16": "SDA of the Arduino header (J3.9, silkscreen SDA), measured. The schematic net and the TUL XDC call it AR_SCL",
    "U13": "also PUDC_B. No external pull (measured): only 200 ohm to Arduino AR2. UG470 says PUDC_B must not float; AR2 decides the pull-ups before configuration",
    "J15": "U14 and its pull-up R209 are not fitted (measured): the pin is not connected",
    "R19": "inverted: low while a sink asserts HPD (Q8)",
    "T19": "drives HPD through the buffer Q7, which runs on HDMI_RX_5V0",
    "H17": "through the Schottky diode D1, cathode on the PL side: a read needs a pull-down",
    "G15": "through the Schottky diode D2, cathode on the PL side: a read needs a pull-down",
    "K18": "sheet 11 names this pin IO_L12P_T1_MRCC_35, the same as K17; the package data gives IO_L12N_T1_MRCC_35",
    "F16": "AR_SS. The board file in XilinxBoardStore 2025.2 and master calls this pin arduino_a0_a13_tri_i_10, its 2022.2 branch spi_ss_i. The schematic agrees with 2022.2",
    "T16": "AR_IO10. The board file in XilinxBoardStore 2025.2 and master calls this pin spi_ss_i, its 2022.2 branch arduino_a0_a13_tri_i_10. The schematic agrees with 2022.2",
    "H16": "125 MHz from CLK125 of the Ethernet PHY U5; it stops while MIO9 (PHYRSTB) holds the PHY in reset (docs/clocks.md)",
    "E7": "50 MHz from OSC3, a DSC1121CE5-50.0000, which also clocks the Ethernet PHY",
    "B13": "DDC SCL of the HDMI output; I2C0 in the TUL PS7 preset, GPIO in preset.xml",
    "B9": "DDC SDA of the HDMI output; I2C0 in the TUL PS7 preset, GPIO in preset.xml",
    "D9": "AR_RST; the button SRST1 also pulls it low through Q9",
    "C7": "PG_ALL, the PGOOD output of the TPS65400",
    "B10": "the button SRST1",
    "H6": "on DDR3_VREF, as P6",
    "V5": "VREF of bank 13; no net on sheet 11 and no connection (measured), but the revision history of the schematic names it AU_RESET",
}
for p in ("B8", "D6", "B7", "A6", "A5", "D8", "D5"):
    NOTES[p] = "boot strap, MIO2 to MIO8 (docs/boot.md)"
for p in ("Y18", "Y19", "Y16", "Y17", "U18", "U19", "W18", "W19"):
    NOTES[p] = "shared by PmodA and the Raspberry Pi header"
# Pins that ran on the board, with the design and the date (see docs/).
CHECKED = {}
for p in ("H16", "M20", "M19", "D19", "D20", "L20", "L19", "R14", "P14", "N16", "M14", "N15", "G17", "L15", "M15"):
    CHECKED[p] = "pl-blinky 2026-11-24"
# The GND tap of tools/pinprobe: a wire from GND on each header pin, with the pin that went low.
for p, where in (("P16", "J3 SDA"), ("P15", "J3 SCL"), ("Y18", "RPi 7"), ("V6", "RPi 8"), ("Y6", "RPi 10"),
                 ("Y7", "RPi 18"), ("F20", "RPi 22"), ("U19", "RPi 26"), ("Y19", "RPi 29"), ("U18", "RPi 31")):
    CHECKED[p] = f"pinprobe GND tap on {where}, 2026-11-24"
for p in ("U9", "T9", "M18"):
    CHECKED[p] = "pinprobe I2C scan of the codec, 2026-11-24"
CHECKED["T19"] = "pinprobe HPD to an HDMI source, 2026-11-24"
for p in ("J15", "V5", "U5", "U13"):
    CHECKED[p] = "pinprobe census, 2026-11-24"
# The other pins of tools/pinprobe/census-2026-11-24.csv agree with the schematic but were not used.

rows, differences = [], []
for pin, s in schematic.items():
    func = FUNC_FIX.get(pin, s["schematic_function"])
    pkg = package.get(pin)
    if pkg is None:
        differences.append(f"{pin}: on the schematic, not in the package")
        continue
    if pkg["pin_func"] != func:
        differences.append(f"{pin}: the package data gives the function {pkg['pin_func']}, the schematic {func}")
    bank = pkg["bank"]
    ports = []
    for t in tul.get(pin, []):
        if (t["func"] != pkg["pin_func"]) != ((pin, t["port"]) in TUL_COMMENT_WRONG):
            differences.append(f"{pin}: the TUL XDC gives the function {t['func']}, the package {pkg['pin_func']}")
        ports.append(dict(t, port=RENAME.get((pin, t["port"]), t["port"])))
    if pin in ADD:
        ports.append(dict(ADD[pin], func=func))
    if s["sheet"] == "11" and s["net"] and not ports:
        differences.append(f"{pin}: net {s['net']} on the schematic, no port in the TUL XDC")
    if pin in board_file and not ports and pin not in NOTES:
        differences.append(f"{pin}: in the board file, not in the TUL XDC")
    rows.append({
        "pin": pin, "bank": bank, "vcco": VCCO.get(bank, ""), "pin_func": func, "net": NET_FIX.get(pin, s["net"]),
        "port": " ".join(p["port"] for p in ports),
        "iostandard": " ".join(sorted({p["iostandard"] for p in ports})),
        "tul_xdc_port": " ".join(t["port"] for t in tul.get(pin, [])),
        "board_file_pin": " ".join(board_file.get(pin, [])),
        "schematic_sheet": s["sheet"], "checked": CHECKED.get(pin, ""), "note": NOTES.get(pin, ""),
        "_ports": ports,
    })
# Every user I/O of the PL is on the schematic, with a net or without (V5).
for pin, r in package.items():
    if r["pin_func"].startswith("IO_") and pin not in schematic:
        differences.append(f"{pin}: a PL I/O of the package, not on the schematic")
for pin in sorted(set(tul) - set(schematic)):
    differences.append(f"{pin}: in the TUL XDC, not on the schematic")
for pin in sorted(set(board_file) - set(schematic)):
    differences.append(f"{pin}: in the board file, not on the schematic")


def key(r):
    p = r["pin"]
    i = len(p.rstrip("0123456789"))
    return (p[:i], int(p[i:]))


rows.sort(key=key)
fields = [f for f in rows[0] if not f.startswith("_")]
with open(os.path.join(out, "pins.csv"), "w", newline="") as f:
    w = csv.DictWriter(f, fields, extrasaction="ignore", lineterminator="\n")
    w.writeheader()
    w.writerows(rows)

# All the pins of the package, with the net of the schematic where it has one.
nets = {r["pin"]: r["net"] for r in rows}
with open(os.path.join(out, "package-pins.csv"), "w", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(["pin", "bank", "pin_func", "min_delay_ps", "max_delay_ps", "net"])
    for pin in sorted(package, key=lambda p: key({"pin": p})):
        r = package[pin]
        w.writerow([pin, r["bank"], r["pin_func"], r["min_delay_ps"], r["max_delay_ps"], nets.get(pin, "")])

# The master XDC: every port is a comment, in the sections of the TUL XDC.
by_section = {}
for r in rows:
    for p in r["_ports"]:
        by_section.setdefault(p["section"], []).append((r, p))
with open(os.path.join(out, "pynq_z2_master.xdc"), "w") as f:
    f.write("""## Master XDC for the TUL PYNQ-Z2 (XC7Z020-1CLG400C). Made by tools/tables.py: do not edit by hand.
##
## Remove the comment mark from the ports that the design uses, and rename them to the top-level
## ports. The port names are those of the TUL XDC, with the corrections in tools/tables.py.
## The pins and nets come from the TUL schematic R12, and each pin function was checked against the
## package data of Vivado. pins.csv has the same data, pin by pin.
## The PS pins (MIO, DDR) are not here: the PS7 configuration sets them (docs/ps.md).

## Bank 0 is at 3.3 V (schematic sheet 12).
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
""")
    for sec in sections + [s for s in by_section if s not in sections]:
        if sec not in by_section:
            continue
        f.write(f"\n## {sec}\n")
        for r, p in sorted(by_section[sec], key=lambda rp: (re.sub(r"\d+", lambda m: m[0].zfill(3), rp[1]["port"]))):
            note = f"  {r['note']}" if r["note"] and p["port"] not in ("",) else ""
            f.write(f"#set_property -dict {{ PACKAGE_PIN {r['pin']:<4} IOSTANDARD {p['iostandard']} }} "
                    f"[get_ports {{ {p['port']} }}]; # {r['net']} {r['pin_func']}{';' + note if note else ''}\n")
            if r["pin"] == "H16":
                f.write("#create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];\n")

for d in differences:
    print(d)
