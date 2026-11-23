#!/usr/bin/env python3
"""Reads the FPGA symbol pages of the TUL schematic (R12) and writes schematic-pins.csv: for each pin
of the XC7Z020 that the symbols show, its function name and the net that the schematic draws on it.

    python3 tools/schematic_pins.py references/tul/TUL_PYNQ_Schematic_R12.pdf > tools/schematic-pins.csv

It needs pdftotext of poppler. The schematic draws the net label of a pin up to 4.5 points below the pin
number, on the side away from the function name. A pin without a label is written with an empty net.
"""
import csv, html, re, subprocess, sys
sys.dont_write_bytecode = True

PAGES = (10, 11)  # "DDR and MIO Banks", "FPGA Banks, Anti Alias Filters"
PIN = re.compile(r"[A-HJ-NPRTUVWY]\d{1,2}")
FUNC = re.compile(r"IO_\S*_\d\d|PS_\S*_50\d")  # the pin function names of the symbols end with the bank
REFDES = re.compile(r"[RCLDQUJ]\d+")  # a part between the pin and its label, as R221 (0 ohm) on MIO6
WORD = re.compile(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>')


def words(pdf, page):
    out = subprocess.run(["pdftotext", "-f", str(page), "-l", str(page), "-bbox", pdf, "-"],
                         check=True, capture_output=True, text=True).stdout
    return [(float(a), float(b), float(c), float(d), html.unescape(t)) for a, b, c, d, t in WORD.findall(out)]


rows = []
for page in PAGES:
    ws = words(sys.argv[1], page)
    for x0, y0, x1, y1, t in ws:
        if not PIN.fullmatch(t):
            continue
        # The function name is on the same line, next to the pin number. If it is left of the number,
        # the net label is to the right; if it is right of the number (a mirrored symbol), to the left.
        near = [w for w in ws if FUNC.fullmatch(w[4]) and abs(w[1] - y0 - 1) < 2]
        left = [w for w in near if 0 < x0 - w[2] < 25]
        right = [w for w in near if 0 < w[0] - x1 < 25]
        if not left and not right:
            continue
        func = (max(left, key=lambda w: w[2]) if left else min(right, key=lambda w: w[0]))[4]
        def label(w):
            gap = w[0] - x1 if left else x0 - w[2]
            return (0 < gap < 160 and -0.5 < w[1] - y0 < 4.5 and not PIN.fullmatch(w[4])
                    and not FUNC.fullmatch(w[4]) and not REFDES.fullmatch(w[4]) and re.match(r"[A-Za-z]", w[4]))
        labels = [w for w in ws if label(w)]
        net = (min(labels, key=lambda w: w[0]) if left else max(labels, key=lambda w: w[2]))[4] if labels else ""
        rows.append((t, func, net, page))

w = csv.writer(sys.stdout, lineterminator="\n")
w.writerow(["pin", "schematic_function", "net", "sheet"])
for r in sorted(rows, key=lambda r: (r[3], r[0][0], int(r[0][1:]))):
    w.writerow(r)
