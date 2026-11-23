# Vivado board files

`TUL/pynq-z2/A.0/` is a copy of `boards/TUL/pynq-z2/A.0` of
[XilinxBoardStore](https://github.com/Xilinx/XilinxBoardStore), branch `master`, commit
`c0383f674790169d711034f56fb9a70e8cdb1dc9` (copied on 2026-11-23). The files are identical to that
commit. XilinxBoardStore is under the Apache License 2.0 (Copyright 2019 Xilinx Inc).

The branches `2025.2` and `master` have the same files. The branch `2022.2` has a different
`part0_pins.xml`: it gives F16 and T16 the other way. The schematic agrees with `2022.2` on these two
pins. See `docs/vivado.md` for this and the other faults of the board file.

Earlier versions of this repository had a copy that came from TUL. Its XML files were identical to
this copy; only `pynq_z2.jpg` was a smaller picture, and it had no `xitem.json`.

To use the board files, tell Vivado where they are before you create a project:

```tcl
set_param board.repoPaths [list /path/to/this/repository/board-files]
```
