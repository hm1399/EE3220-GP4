# EE3220 TBL1 — Team 4 Submission

Polar Code (N=64, K=40) + CRC-16-CCITT error correction system for Space-Z Mars rover communications.

## File Structure

```
team_4_submission/
├── polar_common_pkg.sv       # Shared package: INFO_POS, FROZEN_POS, helper functions
├── polar64_crc16_encoder.sv  # Encoder module (done @+2 cycles)
├── polar64_crc16_decoder.sv  # Decoder module (done @+2 cycles, t=3 BDD)
├── run_sim.sh                # Vivado xsim simulation script (Linux/macOS)
└── run_sim.bat               # Vivado xsim simulation script (Windows)
tb_basic.sv                   # Public smoke testbench (provided, not modified)
```

## Parameters

| Parameter | Value |
|-----------|-------|
| Codeword length N | 64 |
| Information bits K | 40 (24 data + 16 CRC) |
| Frozen bits | 24 |
| Code rate R | 40/64 = 0.625 |
| Min Hamming distance dmin | 8 |
| Error correction capability t | 3 bits |
| CRC polynomial | CRC-16-CCITT (0x1021) |

## Compilation and Simulation (Vivado xsim)

Run from the `TBL1/` directory:

**Linux / macOS:**
```bash
bash team_4_submission/run_sim.sh
```

**Windows:**
```bat
team_4_submission\run_sim.bat
```

**Manual steps:**
```bash
xvlog -sv \
  team_4_submission/polar_common_pkg.sv \
  team_4_submission/polar64_crc16_encoder.sv \
  team_4_submission/polar64_crc16_decoder.sv \
  tb_basic.sv

xelab tb_basic -debug typical -s sim_snapshot

xsim sim_snapshot -runall
```

## Module Interfaces

### polar64_crc16_encoder
```systemverilog
module polar64_crc16_encoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,      // 1-cycle pulse
    input  logic [23:0] data_in,
    output logic        done,       // 1-cycle pulse, asserts exactly +2 cycles after start
    output logic [63:0] codeword
);
```

### polar64_crc16_decoder
```systemverilog
module polar64_crc16_decoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,      // 1-cycle pulse
    input  logic [63:0] rx,
    output logic        done,       // 1-cycle pulse, asserts +2 cycles after start
    output logic [23:0] data_out,
    output logic        valid       // 1 iff correctable (<=3 bit errors) AND CRC passes
);
```

## Design Notes

- **Encoder pipeline**: `start` → `data_reg` latched → combinational CRC + build_u + polar_transform64 → `codeword` registered on `pipe1` → `done` on next cycle. Total: done @+2.
- **Decoder pipeline**: `start` → `rx_reg` latched → combinational BDD decode (weight-1/2/3 search using COL_SYN table) → outputs registered on `pipe1` → `done` on next cycle. Total: done @+2.
- **Polar transform**: `v[i+j+half] ^= v[i+j]` (F_N generator matrix direction, self-inverse over GF(2), ensures dmin=8).
- **Safety principle**: When in doubt, `valid=0`. Incorrect `valid=1` is penalized more heavily than `valid=0`.

## Smoke Test Results (Python simulation)

```
[TB] pos_tables_ok=1, min_info_row_weight=8 (target >= 8)
[SMOKE][PASS] +10 : Encoder: matches reference on 24'hABCDEF and done @ +2
[SMOKE][PASS] +10 : Decoder: Case A/B/C on ABCDEF (plus 1 fail-safe spot check)
[SMOKE][PASS] +10 : Interface timing: ENC done @+2, DEC done <=12, pulses are 1-cycle
[SUMMARY] SMOKE score = 30 / 30
[tb_basic] PASS (Python simulation)
```
