#!/usr/bin/env python3
"""Maps the output of sample.tcl to the pins: prints pin,value for each input cell of an I/O pin.

    python3 bsdl_inputs.py /path/to/xc7z020_clg400.bsd BITS

The BSDL file is in the Vivado installation: data/parts/xilinx/zynq/public/bsdl/xc7z020_clg400.bsd.
Its I/O ports are named IO_<package pin>.
"""
import re, sys
sys.dont_write_bytecode = True
bsdl, bits = sys.argv[1], sys.argv[2]
for line in open(bsdl):
    m = re.search(r'"\s*(\d+)\s+\(BC_\d+,\s*IO_(\w+),\s*input,', line)
    if m:
        print(f"{m.group(2)},{bits[int(m.group(1))]}")
