# PYNQ-Z2 board notes — Agent guide

This repository is a record of the TUL PYNQ-Z2 board (Xilinx XC7Z020). The deliverable is the
record: a different project must be able to use the board from it. The designs and the scripts
exist to use the board, to measure it and to verify the record.

The repository is public. The board, the cards and the LAN that it connects to belong to the owner.

## Sources of truth

- [README.md](README.md) gives the overview: the evidence marks, a summary of each part of the
  board with a link, the file list and the quick start.
- `docs/` owns the description of the board, one file for each part. `docs/unknowns.md` lists
  what is not known.
- `references/` holds the third-party documents that the record cites. `references/README.md`
  gives the title, the revision, the source and the SHA-256 of each file. Do not change these files.
- `board-files/` holds the Vivado board files of the board. `board-files/README.md` names the
  commit of XilinxBoardStore that they come from.
- `pins.csv`, `package-pins.csv` and `pynq_z2_master.xdc` are generated. `tools/tables.py` makes
  them from `tools/schematic-pins.csv`, `tools/package-dump.csv`, `references/tul/pynq-z2_v1.0.xdc`
  and the board file `part0_pins.xml`. Do not edit the outputs by hand. A finding about a pin goes into `NOTES`,
  `CHECKED`, `RENAME` or `ADD` of `tools/tables.py`; then make the tables again.
- `tools/schematic-pins.csv` is made by `tools/schematic_pins.py` from the schematic PDF.
- [LICENSE](LICENSE) owns the licensing terms of the files that the owner wrote. The README says
  which files are third-party and under which terms.
- The start of each script owns its usage and options.

Keep this guide about workflow. If a fact about the board changes, change the file of `docs/`
that owns it, and the summary in the README if it changes. Link to the documents from here; do not
copy pins, figures or limits into this guide.

## Evidence marks

- Each statement about the board has a source: `[measured]`, `[schematic]`, `[manual]` or
  `[package]`. The README defines them. If there is no source, the text says that the fact is not
  known.
- A `[schematic]` statement gives the sheet of the schematic.
- Write `[measured]` only for something that ran on this board or that an instrument showed. A
  statement that seems reasonable keeps its document source, or goes into `docs/unknowns.md`.
- A person can also be the source: a marking that was read, a jumper position that was seen. Say
  so ("seen", "the marking").
- If two sources disagree (the schematic, the manual, the TUL XDC, the board file), say so and say
  which one the record follows. If a measurement contradicts a source, keep a short note of what
  was wrong. Do not delete it silently.
- A change that answers or raises a question updates `docs/unknowns.md` in the same edit.
- The documents, the script comments and `pins.csv` refer to the documents by their file names.
  After you rename, remove or split a document, check each reference to it.

## Documents

- A document describes the present state: what the board is, what the designs do, and the results
  that support them. It is not a log of the work.
- A document does not say what the owner's unit holds now (the contents of the QSPI flash or of a
  card). It describes the board model and the designs.
- Remove the steps of past work, the old states and the old figures when they no longer apply. Git
  keeps them. Keep a short note only where an earlier statement was wrong (see above).
- A table of builds or measurements keeps the present build, and the other rows only if a statement
  of the document uses them.

## Numbers and claims

- A measured figure says how it was measured: the command or the design, the date and the count.
- Never write a plausible value. Do not carry a figure from an earlier build as if it were current.
  LUT counts, flip-flop counts and slack come from the reports of the build that the text names.
- A result for one chip, one card or one temperature says so. It is not a guarantee.
- A statement about a part (a PHY, a codec, a regulator, a memory) says where it comes from: the
  schematic, the datasheet that was read, the marking, or a measurement. Name the document.
- An estimate of a tool (for example `report_power`) is called an estimate.
- The chip is marked -1. Build as -1 unless a measurement in the record supports another grade.

## Board safety

- Write the QSPI flash only when the owner explicitly asks for that write. A JTAG load of the PL
  or of a program into the PS does not need it: it is gone at power-off.
- Write an SD card only with the owner's permission for that card.
- Never program the eFuses or the BBRAM key of the XC7Z020. No tool in this repository does it.
- A design drives a header pin only if the document of that header permits it. PmodA shares its
  pins with the Raspberry Pi header (`docs/headers.md`).
- A design that sends to the LAN (Ethernet, a Linux system with a network) runs only when the owner
  permits it in that session. Its IP address is a build option or a setting outside the repository.
- A new command that sends to a network or writes to a medium is explicit, and its document gives
  its limits.
- A test that overwrites data first stores the original data in a file. It deletes the file only
  after it has restored and verified the data. A step that injects a fault goes last.

## Publication and privacy

- Do not put these into a file of the repository: a host name, a user name, a home directory path,
  an IP address or a MAC address of the LAN. Write a path as `/path/to/...`.
- Filter a result file before you store it: remove the lines with the addresses of the host and of
  the board.
- A Vivado report has a `Host` line. Remove the host name before the report goes into the
  repository.
- A MAC address in a script or a device tree is locally administered and is not a real address.

## Third-party material

- `references/` keeps the documents of TUL, AMD and others because their links stopped working
  (the owner's decision). Add a document there only with its title, revision, source and SHA-256
  in `references/README.md`. Never change a file there; a new revision is a new file.
- In `docs/`, state facts in your own words and cite the document and the page or the sheet. A
  short quotation with its source is the limit.
- `board-files/` is a copy of XilinxBoardStore (Apache License 2.0). Keep it identical to the commit
  that `board-files/README.md` names. If it is wrong, record the fault in the documents and in
  `tools/tables.py`; do not edit the copy.
- Do not commit the output of Vivado IP generation, of PS7 export or of other Xilinx tools, other
  than the reports and bitstreams of the designs of this repository.
- Refer to a third-party project (U-Boot, Linux, Alpine Linux) by its URL and its version or
  commit. Keep its source outside the repository. A patch to it is a file in this repository.

## Designs and scripts

- A build writes its products outside the repository: to the current directory, or to `WORK`. Do
  not leave build output or `__pycache__` in the repository. The Python scripts set
  `sys.dont_write_bytecode`.
- Each PL design instantiates a PS7 cell, even if it does not use the PS. A bitstream without one
  stops Linux when it is loaded over JTAG (docs/vivado.md).
- Vivado writes a bitstream when timing fails. A build script checks the slack and stops if it is
  negative.
- The Python scripts use the standard library and pyserial. `tools/schematic_pins.py` also needs
  `pdftotext` of poppler. A new dependency needs a reason.
- The Linux work uses U-Boot SPL and U-Boot, a mainline kernel and Alpine Linux (armv7) on F2FS
  (`linux/README.md`). U-Boot never keeps its environment in the QSPI flash. Files that are copied to
  the root file system get explicit modes and owners (`install -m`, `--owner=0 --group=0`): the
  host umask must not reach the card.
- Run a job that uses much CPU time at the lowest priority (`nice -n 19`). The build scripts do this
  themselves.
- Do not add automated tests unless asked. Validate a change on the board or in simulation, and
  report what was checked.
- Comments explain intent, invariants and causes. They do not repeat the statement below them.

## Language and style

Project files are in English: documents, comments and script output. Keep signal names, part
markings and quoted text as they are. Communication with the user need not be English.

Write documents in simple technical English. The model is ASD-STE100 (Simplified Technical
English), applied at about 80%: its writing rules apply, but its dictionary of approved words does
not.

- One sentence has one statement or one instruction. A sentence that describes has a maximum of 25
  words. A sentence that gives a step has a maximum of 20 words.
- Use the active voice. Name the subject: the board, the design, the PS, the PL, the host or the
  card.
- Use the present tense for what is true of the board. Use the past tense for a measurement or an
  event, and give its date.
- One word has one meaning, and one meaning has one word. Do not use a different word for the same
  thing.
- Put the condition first: "If ..., the design ...". Use a list for two or more conditions or
  steps.
- Do not put more than three nouns together.
- One paragraph has one topic and a maximum of six sentences.
- Do not use metaphors, idioms or Latin abbreviations.
- Technical names stay as they are: signal names, pin names, register values and command names. A
  table cell can contain a phrase that is not a full sentence.
