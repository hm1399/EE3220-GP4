# EE3220 TBL2 Report

## 1. Project Summary

This project implements a small RISC-V mission clock system based on the provided PicoRV32 skeleton.
The system boots from instruction memory, polls a memory-mapped timer, and prints mission time through a memory-mapped UART.
The base goal is to show a correct `HH:MM:SS` clock on a UART terminal with correct second, minute, and hour rollover.

The final implementation scope in this repository is the base version required by the handout:

- UART TX peripheral
- Timer peripheral
- SoC integration
- Bare-metal firmware
- Basic directed testbench

Optional features such as UART command parsing, ANSI terminal control, countdown mode, and pause/resume were intentionally left out to keep the design reliable and focused on the required functionality.

## 2. Starting Point and Constraints

The provided skeleton already included:

- the PicoRV32 core
- instruction memory and data memory
- a top-level FPGA wrapper
- a firmware linker script and startup file
- a firmware build flow that generates `clock.mem`

The processor core itself was not modified.
All custom work was limited to the peripheral, firmware, verification, and SoC integration layers.

The implementation follows the reference MMIO map from the handout:

| Register | Address | Behavior |
|---|---|---|
| `UART_TXDATA` | `0x4000_0000` | write low 8 bits to transmit one byte |
| `UART_STATUS` | `0x4000_0004` | read bit 0 as `tx_ready` |
| `TIMER_STATUS` | `0x4000_0010` | read bit 0 as `tick_pending`, write `1` to clear |
| `TIMER_VALUE` | `0x4000_0014` | current timer count |

## 3. Hardware Design

### 3.1 UART Peripheral

The UART peripheral implements the TX path required by the base project.
It exposes a transmit data register and a status register.
The status register reports whether the transmitter is ready to accept the next byte.

The UART transmitter uses:

- 8 data bits
- no parity
- 1 stop bit
- LSB-first transmission

The baud divider is parameterized, so the same RTL can be used both for accelerated simulation and for the final hardware configuration.
The receiver input is kept in the module interface for compatibility, but RX behavior is not part of the current base implementation.

### 3.2 Timer Peripheral

The timer peripheral provides a periodic tick event to firmware.
Internally, it counts clock cycles up to a parameterized period.
When the count reaches the programmed period, the timer:

- resets the internal cycle counter
- asserts `tick_pending`

The flag remains set until firmware clears it by writing `1` to `TIMER_STATUS`.
This matches the write-one-to-clear behavior required by the handout.

The timer period is parameterized instead of hard-coded, which is important because:

- the FPGA design runs from a 62.5 MHz SoC clock in the provided top wrapper
- simulation should run with a much shorter period to keep test execution practical

### 3.3 SoC Integration

The SoC wrapper integrates four memory spaces:

- instruction memory
- data memory
- UART MMIO
- timer MMIO

Address decoding was added for the UART and timer regions.
The memory response path now combines:

- `imem_ready`
- `dmem_ready`
- `uart_ready`
- `timer_ready`
- `invalid_ready`

The UART output is connected to the SoC `uart_txd` port, which is then exported by the FPGA top-level wrapper.

## 4. Firmware Design

The firmware is intentionally simple and fully polling-based.

Its behavior is:

1. initialize mission time to `00:00:00`
2. print the initial time immediately after boot
3. poll the timer status register
4. clear the timer flag when a tick is observed
5. increment the time
6. print the updated time

The firmware prints one line per second in the format:

```text
HH:MM:SS
```

followed by carriage return and line feed.

The following rollover transitions were implemented and verified:

- `00:00:59 -> 00:01:00`
- `00:59:59 -> 01:00:00`
- `23:59:59 -> 00:00:00`

One practical firmware issue appeared during build:
the original two-digit formatting logic used division and modulo.
In the current bare-metal `-nostdlib` build flow, that introduced unresolved helper symbols such as `__udivsi3` and `__umodsi3`.
To avoid pulling in runtime helper libraries, the two-digit formatting routine was rewritten using repeated subtraction.
This keeps the firmware self-contained and compatible with the provided build setup.

## 5. Verification Strategy

### 5.1 Testbench Scope

The testbench `tb_basic.sv` was written to provide a minimal but meaningful verification flow.
It directly instantiates the SoC rather than only testing individual modules in isolation.
This allows the testbench to verify the interaction between:

- the CPU
- instruction memory
- UART MMIO
- timer MMIO
- firmware behavior

### 5.2 UART Output Checking

The testbench does not only produce waveforms.
Instead, it actively decodes the UART TX serial stream and checks each expected byte.
This is important because the project requirement is human-visible UART output, not just internal register activity.

The UART and timer parameters are shortened for simulation:

- a very small `CLK_HZ`
- a very small `UART_BAUD` ratio
- a short timer period

This makes the simulation complete quickly while preserving the control logic and protocol behavior.

### 5.3 Covered Cases

The following directed cases were checked:

1. reset output is `00:00:00`
2. next tick produces `00:00:01`
3. `00:00:59 -> 00:01:00`
4. `00:59:59 -> 01:00:00`
5. `23:59:59 -> 00:00:00`

For the rollover cases, the testbench places the firmware state near the rollover point after the CPU has entered its polling loop, then checks the next transmitted line.
This keeps the testbench fast without changing the hardware-software interface or generating special-purpose firmware images for each case.

### 5.4 Local Simulation Result

The local Icarus Verilog simulation completed successfully for all directed cases.
The executed commands were:

```bash
cd ee3220_tbl2_skeleton_rev1.0
iverilog -g2012 -o /tmp/tb_basic.vvp ../tb_basic.sv rtl/picorv32_soc_ref.sv rtl/imem.sv rtl/dmem.sv rtl/uart.sv rtl/timer.sv rtl/picorv32.v
vvp /tmp/tb_basic.vvp
```

All required directed checks passed.

## 6. Build and Bring-Up Flow

The firmware build flow is:

```text
clock.c + start.S + linker.ld -> clock.elf -> clock.bin -> clock.mem
```

The hardware flow is:

```text
RTL + clock.mem -> simulation -> synthesis -> implementation -> bitstream
```

The generated `clock.mem` file is loaded into instruction memory using `$readmemh`.
This means the firmware is baked into the FPGA design and no separate runtime firmware download is required on the board.

## 7. Hardware Demo Status

At the current repository state:

- firmware build is complete
- `clock.mem` is present
- directed RTL simulation is complete

The remaining hardware steps must still be completed manually in the lab:

- create or open the Vivado RTL project
- add the RTL, XDC, and `clock.mem`
- set `pynq_z2_tx_demo_top` as the top module
- run synthesis and implementation
- generate the bitstream
- wire CH340 to the PYNQ-Z2 board
- observe UART output on the terminal

Expected UART serial settings:

- `115200 baud`
- `8 data bits`
- `no parity`
- `1 stop bit`

Required external wiring:

- `W19 -> CH340 RXD`
- `W18 -> CH340 TXD`
- `GND -> GND`

## 8. Risks and Limitations

The main remaining risks are related to hardware bring-up rather than RTL logic:

- forgetting to add `clock.mem` into the Vivado project
- selecting the wrong top module
- incorrect CH340 wiring
- wrong serial terminal settings
- board-level timing or implementation issues that cannot be reproduced by the simplified local simulation

Another limitation is that the local simulation uses accelerated timing parameters, not the full real-time one-second delay and real hardware baud rate.
This is acceptable for functional verification, but the final lab demonstration still needs to confirm the real hardware configuration.

## 9. Conclusion

The repository now contains a complete base implementation of the EE3220 TBL2 mission clock:

- UART TX peripheral
- timer peripheral
- PicoRV32 SoC integration
- bare-metal mission clock firmware
- generated firmware memory image
- directed verification testbench

The project has passed the required functional simulation checks and is ready for the final Vivado flow and FPGA demonstration.
