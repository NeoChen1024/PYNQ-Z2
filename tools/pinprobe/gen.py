#!/usr/bin/env python3
"""Makes the pin list of pinprobe from pynq_z2_master.xdc: every PL port except sysclk.

    python3 gen.py PULLUP|PULLDOWN OUTDIR

Writes OUTDIR/pinprobe.xdc (each port as p[i], LVCMOS33, with the given internal pull),
OUTDIR/pinprobe_idx.svh (the indexes of the pins that the design can drive) and
OUTDIR/pinmap.csv (index, pin, port of the master XDC), which pinprobe.tcl reads.
"""
import os, re, sys
sys.dont_write_bytecode = True

pull, out = sys.argv[1], sys.argv[2]
assert pull in ("PULLUP", "PULLDOWN"), pull
here = os.path.dirname(os.path.abspath(__file__))
xdc = os.path.join(here, "..", "..", "pynq_z2_master.xdc")
pat = re.compile(r"PACKAGE_PIN\s+(\w+).*get_ports\s*\{\s*([^\s}]+)\s*\}")
# PmodA and the Raspberry Pi header share pins: one entry for each package pin, with all its ports.
pins, where = [], {}
for line in open(xdc, encoding="utf-8"):
    m = pat.search(line)
    if m and m.group(2) != "sysclk":
        pin, port = m.group(1), m.group(2)
        if pin in where:
            pins[where[pin]] = (pin, pins[where[pin]][1] + "/" + port)
        else:
            where[pin] = len(pins)
            pins.append((pin, port))
# V5 is a PL pin with no net on the schematic (docs/audio.md); read it too.
pins.append(("V5", "no_net"))
# The pins that pinprobe may drive; all others stay inputs.
special = {"au_scl_r": "I_SCL", "au_sda_r": "I_SDA", "au_mclk_r": "I_MCLK",
           "adr1": "I_ADR1", "hdmi_rx_hpd": "I_HPD"}
idx = {}
os.makedirs(out, exist_ok=True)
with open(os.path.join(out, "pinprobe.xdc"), "w") as x, open(os.path.join(out, "pinmap.csv"), "w") as c:
    x.write("set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports sysclk]\n")
    x.write("create_clock -period 8.000 [get_ports sysclk]\n")
    c.write("index,pin,port\n")
    for i, (pin, port) in enumerate(pins):
        x.write(f"set_property -dict {{ PACKAGE_PIN {pin} IOSTANDARD LVCMOS33 PULLTYPE {pull} }} [get_ports {{p[{i}]}}]\n")
        c.write(f"{i},{pin},{port}\n")
        for name in port.split("/"):
            if name in special:
                idx[special[name]] = i
    x.write("create_clock -period 100.000 -name tck [get_pins bscan/TCK]\n")
    x.write("set_clock_groups -asynchronous -group [get_clocks sysclk] -group [get_clocks tck]\n")
missing = set(special.values()) - set(idx)
assert not missing, missing
with open(os.path.join(out, "pinprobe_idx.svh"), "w") as h:
    h.write(f"localparam int N = {len(pins)};\n")
    h.write(f"localparam bit PULL_UP = {1 if pull == 'PULLUP' else 0};\n")
    for k, v in sorted(idx.items()):
        h.write(f"localparam int {k} = {v};\n")
print(f"{len(pins)} pins, {pull}")
