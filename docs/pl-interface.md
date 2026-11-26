# PS/PL interface

This document defines the fixed interface between Linux on the PS and a PL design. A PL design in
another repository uses it without changes to the device tree. The device tree, the kernel
configuration, U-Boot and the card image of `linux/` provide it.

| Item | Value | Section |
|---|---|---|
| Register window | `M_AXI_GP0`, 0x4000_0000, 1 MiB; the UIO device named `pl` | [Register window](#register-window-on-m_axi_gp0) |
| Interrupt | `IRQF2P[0]`: GIC ID 61 (SPI 29), level high; the same UIO device | [Interrupt](#interrupt) |
| Memory for the PL | 0x1F00_0000, 16 MiB, `no-map`; `/dev/mem` with `O_SYNC` | [Reserved region](#reserved-region) |
| PL clock | `FCLK_CLK0`, 100 MHz, on while Linux runs | [PL clock](#pl-clock) |
| HP ports | 64-bit; DDR 0x0008_0000 to 0x1FFF_FFFF; not coherent | [HP ports](#hp-ports) |
| PL load | JTAG, or `/pl.bit` on the FAT partition (U-Boot) | [Loading the PL](#loading-the-pl) |
| More nodes | Device tree overlays through `fdtoverlays` of `extlinux.conf` | [Overlays](#device-tree-overlays) |

## Version

The git tag `pl-interface-v1` marks the first commit that provides this interface. A change to a
value of the table above gets a new tag, and this section names it.

The interface needs the boot files of `linux/` from that commit or later: `BOOT.BIN`, `u-boot.img`,
`zImage`, `zynq-pynq-z2.dtb` and `extlinux.conf` of `mkdisk.sh`.

## Rules for a PL design

1. The design instantiates the PS7 cell. `IRQF2P[19:16]` stay 0 (vivado.md).
2. A clock runs on `MAXIGP0ACLK` and on the `SAXIHPnACLK` of each HP port that the design uses.
   `FCLK_CLK0` is the clock of this interface.
3. The design answers each request in the register window. The window is 1 MiB; the design can
   repeat its registers in it.
4. An HP master of the design accesses only the reserved region. It starts a transfer only on a
   command of the PS.
5. The interrupt of the design is `IRQF2P[0]`, active high. The line stays high until software
   removes the cause.
6. The HP ports use 64-bit data. A design with 32-bit data sets the AFI registers itself (see
   [HP ports](#hp-ports)).

## Register window on M_AXI_GP0

The device tree has the node `pl-uio@40000000` (label `pl_uio`) **[measured]**:

- `compatible = "generic-uio"`, `reg = <0x40000000 0x00100000>`, `linux,uio-name = "pl"`.
- `uio_pdrv_genirq` handles it. The driver has no compatible string of its own; it uses the module
  parameter `of_id` (Linux 6.18.64, `drivers/uio/uio_pdrv_genirq.c`).
- `extlinux.conf` of `mkdisk.sh` gives `uio_pdrv_genirq.of_id=generic-uio` on the command line.
- `CONFIG_UIO` and `CONFIG_UIO_PDRV_GENIRQ` are built in. As modules, they would need `modprobe`
  with the option, and no modalias would load them.

On 2026-11-26, Linux showed `/dev/uio0` with the name `pl` and map 0 at 0x40000000, size 0x100000
**[measured]**. A program finds the device by its name in `/sys/class/uio/uio*/name`.

A program maps the registers with `mmap` on the UIO device, offset 0. The UIO core maps them as
strongly-ordered memory (`pgprot_noncached`, Linux 6.18.64, `drivers/uio/uio.c`). Each access then
reaches the PL in program order.

`M_AXI_GP0` is an AXI3 port with 32-bit data and 12-bit IDs (the ports of the PS7 cell). UG585,
Table 4-1 (page 112), gives it 0x4000_0000 to 0x7FFF_FFFF. The interface uses the first 1 MiB of it.

A read in the window needs a design that answers it. Without one, the access possibly never ends
and stops the PS. This was not tested (unknowns.md). Read the registers only when the design is in
the PL. The UIO driver itself does not access the window.

## Interrupt

`IRQF2P[0]` of the PS7 cell is GIC ID 61, shared peripheral interrupt (SPI) 29. UG585, Table 7-3
(page 218), gives `IRQF2P[7:0]` the IDs 61 to 68 and `IRQF2P[15:8]` the IDs 84 to 91. The device
tree gives `interrupts = <0 29 4>`: SPI 29, level high. The interface uses only `IRQF2P[0]`.

The UIO device delivers it:

1. The program writes the 32-bit value 1 to the UIO device. This enables the interrupt.
2. The program waits with `read` or `poll`. `read` gives the count of interrupts.
3. At each interrupt, the driver disables it (`disable_irq_nosync`, `uio_pdrv_genirq.c`).
4. The program removes the cause in the design. Then it writes 1 again.

On 2026-11-26 **[measured]**:

- The test design gave one interrupt for each transfer and for its software interrupt. After the
  cause was removed, no further interrupt came in 100 ms. `/proc/interrupts` counted them on ID 61.
- With the PL empty after a reboot, the program enabled the interrupt and waited 3 s. No interrupt
  came, and the count stayed 0.

## Reserved region

The device tree reserves the top 16 MiB of the DDR for the PL:

```
reserved-memory {
	pl_buffer: pl-buffer@1f000000 {
		reg = <0x1f000000 0x01000000>;
		no-map;
	};
};
```

`no-map` keeps the region out of the kernel. The kernel neither allocates it nor maps it. The
results of 2026-11-26 **[measured]**:

- The kernel printed `OF: reserved mem: 0x1f000000..0x1fffffff (16384 KiB) nomap non-reusable`.
- `/proc/iomem` showed `System RAM` from 0x00000000 to 0x1effffff.
- `MemTotal` was 472912 kB. Before the change, it was 489308 kB.

### U-Boot

U-Boot v2026.10 does not use the region **[measured]**. On 2026-11-26, `bdinfo` showed `relocaddr`
0x1EEF0000. Its memory list showed 0x1f000000 to 0x1fffffff with the flag `no-map`. U-Boot loaded
the device tree for Linux to 0x1CAB9000.

The cause is `board_get_usable_ram_top` of U-Boot (`board/xilinx/common/board.c`). It reads the
reserved regions of the device tree of U-Boot and puts U-Boot below them. The device tree of U-Boot
is the same `zynq-pynq-z2.dts`.

At boot, the content of the region is not defined. Thus a design starts its transfers only on a
command of the PS (rule 4).

### Mapping and cache behaviour

A program maps the region through `/dev/mem`, opened with `O_SYNC`. The mapping is then Normal
memory that is not cacheable. Without `O_SYNC`, the mapping is cacheable. This comes from the source
of Linux 6.18.64:

- `drivers/of/of_reserved_mem.c` marks a `no-map` region with `memblock_mark_nomap`. The region stays
  in `memblock.memory`.
- Thus `pfn_valid` (`arch/arm/mm/init.c`) is true for its pages.
- `/dev/mem` asks `phys_mem_access_prot` (`arch/arm/mm/mmu.c`, with
  `CONFIG_ARM_DMA_MEM_BUFFERABLE=y`). For a valid page, it returns write-combine with `O_SYNC`. It
  returns the cacheable default without `O_SYNC`.
- `CONFIG_STRICT_DEVMEM` is not set in the kernel of `linux/`. Root can map the region.

The test confirmed this **[measured]**. On 2026-11-26, `pltest` read 64 KiB through a mapping
without `O_SYNC`. Then the PL wrote a new pattern there. The CPU then read old data in 7656 of 8192
words (first run) and 7692 of 8192 words (second run). With `O_SYNC`, no word was old.

The HP ports are not coherent with the caches of the CPUs (UG585, page 62). The ACP port is
coherent, but it is not part of this interface.

A write through the `O_SYNC` mapping can wait in a write buffer. The program executes `dsb` before
the register write that starts the PL. `pltest` does this before each transfer. With it, 300000
short transfers in each direction showed no difference **[measured]** (see below). Whether a
transfer fails without the `dsb` was not tested.

The region is not a map of the UIO device. UIO maps memory as strongly-ordered, which is slow for a
buffer, and an unaligned access, as in `memcpy`, then causes a fault.

## PL clock

`FCLK_CLK0` runs at 100 MHz while Linux runs. `FCLK_CLK1` to `FCLK_CLK3` are not part of this
interface.

| Stage | What it does with the FCLKs | Evidence |
|---|---|---|
| Board preset | `PCW_FPGA0_PERIPHERAL_FREQMHZ` 100, `PCW_EN_CLK0_PORT` 1; `PCW_EN_CLK1_PORT` to `3` are 0 | `board-files/.../preset.xml` |
| U-Boot SPL (`ps7_init`) | Writes `FPGA0_CLK_CTRL` (0xF8000170) = 0x00200500: IO PLL (1000 MHz) / 5 / 2. It does not write `FPGA1` to `FPGA3` | `ps7_init_gpl.c` of `ps7/build.sh` |
| U-Boot | Does not change them | |
| Linux | Keeps `FCLK_CLK0` on, because the device tree has `fclk-enable = <0x1>` in `&clkc` | `drivers/clk/zynq/clkc.c` |

On 2026-11-26 **[measured]**:

- `FPGA0_CLK_CTRL` read 0x00200500. `FPGA1_CLK_CTRL` to `FPGA3_CLK_CTRL` read their reset value
  0x00101800 (IO PLL / 24, 41.67 MHz).
- `clk_summary` of debugfs showed `fclk0` at 100000000 Hz, enabled. `fclk1` to `fclk3` were off.
- The test design counted `FCLK_CLK0` and `SYSCLK` for 1 s. The ratio was 0.80000, thus 100 MHz if
  `SYSCLK` is 125 MHz. Both clocks come from OSC3 (clocks.md), so this checks the dividers only.
- Against `CLOCK_MONOTONIC` of Linux, the count gave 100.004 MHz and 100.005 MHz (two runs).

### Why fclk-enable is necessary

`zynq-7000.dtsi` has `fclk-enable = <0>`. The clock driver registers a gate for each FCLK. At the end
of the boot, the clock framework turns off the gates that no driver uses. For an FCLK, the gate is
bit 0 of the register at offset 8 from `FPGAn_CLK_CTRL`, and 1 means off (`clkc.c`).

UG585 calls this register `FPGA0_THR_CNT` (0xF8000178), the count of the clock throttle (page 1584).
It does not say that bit 0 stops the clock. But it does **[measured]**. On 2026-11-26, a write of 1
to 0xF8000178 for about 2 s stopped `FCLK_CLK0`. The test design counted 4.5 million `FCLK_CLK0`
cycles in that time, against 258 million `SYSCLK` cycles. In the next 2 s, without the write, it
counted 205.5 million. A write of 0 started the clock again.

Before `fclk-enable` was in the device tree, Linux stopped `FCLK_CLK0` **[measured]**. On
2026-11-26, that kernel showed `fclk0` off, and bit 0 of 0xF8000178, 0xF8000188, 0xF8000198 and
0xF80001A8 was 1.

### PL reset

`FCLKRESETN[0]` of the PS7 cell follows bit 0 of `FPGA_RST_CTRL` (0xF8000240): 1 holds the reset.
`ps7_post_config` of the SPL writes 0 to the register, and U-Boot `fpga load` does too after the
load. The table of [Loading the PL](#loading-the-pl) gives the measured values.

## HP ports

The PS has four HP ports, `S_AXI_HP0` to `S_AXI_HP3`. The interface does not reserve one; the test
design uses `S_AXI_HP0`. The board preset enables no HP port. A design connects the port of the PS7
cell, and the port works without a change to `ps7_init` **[measured]** (the test design).

- **Data width.** The PS7 cell has 64-bit HP data ports. The AFI of each port can convert from 32
  bits: bit 0 (`32BitEn`) of `AFI_RDCHAN_CTRL` (0xF8008000 + 0x1000 × n) and of `AFI_WRCHAN_CTRL`
  (offset 0x14). UG585 describes them on pages 760 and 764. On 2026-11-26, both read 0 for HP0
  **[measured]**: 64-bit. `ps7_init` of the board preset does not write them. A design with 32-bit
  data must set the bits before it transfers. That was not tested.
- **Addresses.** UG585, Table 4-1 (page 112), gives the HP ports the DDR from 0x0008_0000 to
  0x3FFF_FFFF. Below 0x0004_0000, an HP port reaches the OCM if the OCM is mapped low. From
  0x0004_0000 to 0x0007_FFFF, it reaches nothing. The board has 512 MiB, 0x0000_0000 to 0x1FFF_FFFF. What an HP access above 0x1FFF_FFFF does is not
  known (unknowns.md). The reserved region is in the range.
- **Coherency.** An HP port goes to the DDR controller, not through the SCU. It is not coherent
  with the caches of the CPUs (UG585, page 62).
- **Throughput of the test design.** The test design has one 128-byte burst at a time, at 100 MHz.
  It wrote 16 MiB at 369.9 MiB/s and read 16 MiB at 341.4 MiB/s **[measured]**. These figures show
  the test design. They are not the limit of the port.

## Loading the PL

Linux 6.18.64 has no interface that lets user space load the PL. The kernel of `linux/` has the
FPGA manager driver (`zynq-fpga`) and the `fpga-region` of `zynq-7000.dtsi`. But `fpga-mgr.c` has
no writable sysfs file, and mainline Linux applies no overlay from user space. The Xilinx kernel
has such interfaces; this record uses no patch for them.

The PL is loaded in one of two ways:

- **JTAG:** `sh jtag/load.sh design.bit`, while Linux runs. It also clears the reset vector catch
  (jtag-uart.md).
- **U-Boot:** copy the bitstream to the FAT partition of the card as `/pl.bit`. The `preboot` of
  U-Boot then loads it with `fpga loadb` before it starts Linux. Without the file, U-Boot loads
  nothing. An `uboot.env` with a `preboot` variable replaces this default.

At the U-Boot prompt, `fpga loadb` loads a `.bit` file by hand:

```
load mmc 0:1 ${kernel_addr_r} /design.bit
fpga loadb 0 ${kernel_addr_r} ${filesize}
```

`fpga load` loads a `.bin` file without the header. `fpga loadb` checks the part name in the header
of the `.bit` file.

A reboot of Linux clears the PL **[measured]**. On 2026-11-26, after `reboot`, the LEDs of the test
design did not change in six JTAG samples over 10 s. With the design loaded, they changed. ps.md
gives the same for the reset button SRST1 **[manual]**. Thus each boot needs a new load.

### Level shifters and PL reset

| Moment | `LVL_SHFTR_EN` (0xF8000900) | `FPGA_RST_CTRL` (0xF8000240) | Evidence |
|---|---|---|---|
| After the SPL, PL empty (U-Boot prompt; Linux) | 0xF | 0x0 | **[measured]** |
| During `fpga load` of U-Boot | 0xA | 0xF | U-Boot `arch/arm/mach-zynq/slcr.c`; not measured |
| After `fpga loadb` of U-Boot (U-Boot prompt; Linux) | 0xF | 0x0 | **[measured]** |
| After a JTAG load while Linux runs | 0xF | 0x0 | **[measured]**: no change |

The measurements are of 2026-11-26. U-Boot `md.l` read the registers at the prompt; `devmem2` read
them in Linux. `ps7_post_config` of the SPL enables all level shifters (0xF), also with an empty
PL. UG585, section 2.4 (page 46), gives a sequence that enables the PL-to-PS shifters after
configuration. A JTAG load with the shifters at 0xF worked on this board.

## Device tree overlays

A project adds nodes to the device tree with an overlay. U-Boot applies it before it starts Linux:

1. Write the overlay. It can refer to the labels of `zynq-pynq-z2.dts`, for example `pl_uio`,
   `pl_buffer` or `amba`.
2. Compile it: `dtc -@ -I dts -O dtb -o project.dtbo project.dtso`.
3. Copy `project.dtbo` to the FAT partition.
4. Add `fdtoverlays /project.dtbo` to the label in `extlinux/extlinux.conf`, after the `fdt` line.

```
/dts-v1/;
/plugin/;

&pl_uio {
	linux,uio-name = "project";
};

&{/} {
	project-node {
		compatible = "vendor,device";
	};
};
```

These parts make it work:

- U-Boot has `CONFIG_OF_LIBFDT_OVERLAY=y`. `xilinx_zynq_virt_defconfig` sets it, and `build-uboot.sh`
  checks it.
- `build-kernel.sh` compiles the dtb with `-@`, so the dtb keeps its labels in `__symbols__`.
- The default environment of U-Boot has no `fdtoverlay_addr_r`. Without it, U-Boot printed
  `Invalid fdtoverlay_addr_r for loading overlays` and ignored the line. The `preboot` of
  `build-uboot.sh` sets it to 0x1e00000 if it is not set.

On 2026-11-26, an overlay with `&pl_uio` and `&{/}` appeared in `/proc/device-tree` **[measured]**.
An overlay that changes `linux,uio-name` changes the name that programs look for.

## Test design and program

`examples/pl-interface/` is the test design of this interface. It is also an example for a project.

| File | Contents |
|---|---|
| `pl_interface.sv` | The PS7 cell with a register block on `M_AXI_GP0`, a 64-bit master on `S_AXI_HP0`, and `IRQF2P[0]` |
| `pl_interface.xdc` | `SYSCLK`, the four LEDs, the clock of `FCLK_CLK0` |
| `build.sh`, `build.tcl` | The build with Vivado, without a project |
| `pltest.c` | The test program for Linux |

The registers repeat in each 128 bytes of the window:

| Offset | Name | Function |
|---|---|---|
| 0x00 | `ID` | 0x504C4931 ("PLI1") |
| 0x04 | `SCRATCH` | Read and write |
| 0x08 | `CTRL` | Bit 0 `START` (write 1), bit 1 `READ`, bit 2 `SWIRQ` |
| 0x0C | `STATUS` | Bit 0 `BUSY`, bit 1 `DONE`, bit 2 `RESP_ERR`, bit 3 the interrupt line. Write 1 to clear bits 1 and 2 |
| 0x10 | `ADDR` | Start address of the transfer, in steps of 128 bytes |
| 0x14 | `LEN` | Length in bytes, in steps of 128 bytes |
| 0x18 | `SEED` | 64-bit word i of the pattern is `{SEED ^ i, i}` |
| 0x1C | `ERRORS` | After a read: the words that differ from the pattern |
| 0x20 | `CYCLES` | `FCLK_CLK0` cycles of the last transfer |
| 0x24 | `FCLKCNT` | Counter on `FCLK_CLK0` |
| 0x28 | `SYSCNT` | Counter on `SYSCLK`, through Gray code |

`IRQF2P[0]` is high while `DONE` or `SWIRQ` is 1. LD0 shows bit 26 of the `FCLK_CLK0` counter and
LD1 bit 26 of the `SYSCLK` counter. A JTAG sample of the pins (`tools/bscan/`) then shows if the
clocks run, also when the GP0 bus cannot be used.

Build and run:

```sh
sh $P/examples/pl-interface/build.sh                   # ./pynq-pl-interface/build/pl_interface.bit
sh $P/jtag/load.sh pynq-pl-interface/build/pl_interface.bit
# on the board, as root:
cc -O2 -Wall -o pltest pltest.c && ./pltest -n 10000
```

`pltest` checks DONE of the devcfg and the FCLK0 gate before it reads a register. It writes only
the reserved region and the registers.

### Results

The build of 2026-11-26 used Vivado 2025.2.1 for `xc7z020clg400-1`. Setup slack was +2.432 ns and
hold slack +0.119 ns. The design used 448 LUTs, 527 flip-flops and no block RAM.

On 2026-11-26, `pltest` ran on the board with the kernel and U-Boot of `linux/` **[measured]**. It
ran once after a JTAG load (`-n 10000`), and once after the U-Boot load of `/pl.bit` (`-n 10000`,
then `-n 300000`). All runs passed:

| Check | Result |
|---|---|
| `ID`, and 37 values in `SCRATCH` | Correct |
| `FCLK_CLK0` | 0.80000 × `SYSCLK`; 100.004 to 100.005 MHz against `CLOCK_MONOTONIC` |
| Interrupt from `SWIRQ` | One interrupt; none after the clear |
| PL writes 16 MiB, CPU compares | No difference, no error response; 369.9 MiB/s |
| CPU writes 16 MiB, PL compares | `ERRORS` 0; 341.4 MiB/s |
| One word changed by the CPU | `ERRORS` 1 |
| Short transfers: 128 B to 4 KiB, random offsets, each way | 0 differences in 10000, 10000 and 300000 transfers |
| Mapping without `O_SYNC` | Old data in 7656 and 7692 of 8192 words (expected) |

These results are for one board and one card at room temperature. They are not a guarantee.
