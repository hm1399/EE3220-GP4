# EE3220 TBL2 Mission Clock

## Overview

This repository contains a PicoRV32-based mission clock for the EE3220 TBL2 project.
The system prints mission time in `HH:MM:SS` format through a memory-mapped UART and updates once per second based on a memory-mapped timer.

The current repository state includes:

- UART TX peripheral
- Timer peripheral
- SoC integration for PicoRV32 + IMEM + DMEM + MMIO devices
- Bare-metal firmware
- `clock.mem` firmware image for IMEM initialization
- Directed SystemVerilog testbench

## Repository Layout

- `ee3220_tbl2_skeleton_rev1.0/rtl/`
  - `picorv32.v`
  - `picorv32_soc_ref.sv`
  - `uart.sv`
  - `timer.sv`
  - `imem.sv`
  - `dmem.sv`
  - `pynq_z2_tx_demo_top.sv`
- `ee3220_tbl2_skeleton_rev1.0/firmware/`
  - `clock.c`
  - `start.S`
  - `linker.ld`
  - `Makefile`
- `ee3220_tbl2_skeleton_rev1.0/clock.mem`
- `ee3220_tbl2_skeleton_rev1.0/constraints/pynq_z2_tx_demo.xdc`
- `tb_basic.sv`
- `report.md`
- `report.docx`

## MMIO Map

The implementation follows the handout reference MMIO interface.

| Module | Address | Description |
|---|---|---|
| `UART_BASE` | `0x4000_0000` | UART base address |
| `UART_TXDATA` | `0x4000_0000 + 0x00` | Write low 8 bits to start transmission |
| `UART_STATUS` | `0x4000_0000 + 0x04` | Read bit 0 as `tx_ready` |
| `TIMER_BASE` | `0x4000_0010` | Timer base address |
| `TIMER_STATUS` | `0x4000_0010 + 0x00` | Read bit 0 as `tick_pending`, write `1` to clear |
| `TIMER_VALUE` | `0x4000_0010 + 0x04` | Current timer counter value |

## Firmware Behavior

- The firmware starts from `00:00:00`
- It prints the initial time once after reset
- It polls `TIMER_STATUS[0]`
- It clears the timer event using write-one-to-clear
- It updates and prints one new line per second

Required rollover behavior implemented:

- `00:00:59 -> 00:01:00`
- `00:59:59 -> 01:00:00`
- `23:59:59 -> 00:00:00`

## Firmware Build

Generate `clock.mem` from the firmware directory:

```bash
cd ee3220_tbl2_skeleton_rev1.0/firmware
make clean
make
```

Expected outputs:

- `build/clock.elf`
- `build/clock.bin`
- `build/clock.lst`
- `build/clock.map`
- `../clock.mem`

Notes:

- A working RISC-V cross toolchain is required
- The current firmware avoids integer division helpers so it can link cleanly in this bare-metal flow

## Simulation

The directed testbench is `tb_basic.sv`.
It accelerates the timer and UART parameters for simulation and checks UART output content directly.

Run the local Icarus Verilog simulation with:

```bash
cd ee3220_tbl2_skeleton_rev1.0
iverilog -g2012 -o /tmp/tb_basic.vvp ../tb_basic.sv rtl/picorv32_soc_ref.sv rtl/imem.sv rtl/dmem.sv rtl/uart.sv rtl/timer.sv rtl/picorv32.v
vvp /tmp/tb_basic.vvp
```

Directed cases covered:

- Reset -> first output `00:00:00`
- Next tick -> `00:00:01`
- `00:00:59 -> 00:01:00`
- `00:59:59 -> 01:00:00`
- `23:59:59 -> 00:00:00`

## Vivado Bring-Up

Use a normal RTL project in Vivado.
Do not use Create Block Design for this repository state.

Recommended flow:

1. Create an RTL project
2. Add all files in `ee3220_tbl2_skeleton_rev1.0/rtl/`
3. Add `ee3220_tbl2_skeleton_rev1.0/constraints/pynq_z2_tx_demo.xdc`
4. Add `ee3220_tbl2_skeleton_rev1.0/clock.mem`
5. Set top module to `pynq_z2_tx_demo_top`
6. Run synthesis, implementation, and bitstream generation

## UART Wiring for Hardware Demo

For the external CH340 connection:

- `W19 -> CH340 RXD`
- `W18 -> CH340 TXD`
- `GND -> GND`

Serial terminal configuration:

- `115200 baud`
- `8 data bits`
- `no parity`
- `1 stop bit`

Important:

- Use 3.3 V TTL UART
- Do not connect CH340 power pins to UART signal pins
- Power off the board before rewiring

## Verification Status

Completed:

- Firmware image generation
- Local directed simulation for reset and rollover behavior

Pending manual lab work:

- Vivado synthesis and implementation on the course PC
- FPGA programming
- CH340 wiring
- Serial terminal observation on the real board

## Notes for Submission

The final submission should include at least:

- `uart.sv`
- `timer.sv`
- `tb_basic.sv`
- `firmware/clock.c`
- `firmware/linker.ld`
- `firmware/Makefile`
- `clock.mem`
- `README.md`
- `report.pdf`
- `ai_log.txt`
