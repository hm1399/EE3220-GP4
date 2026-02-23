Generate an academic presentation slide (16:9, white background) titled **"Decoder Pipeline & Timing"**.

**Layout — waveform on top, pipeline structure on bottom:**

**Title:** "Decoder Pipeline: polar64_crc16_decoder.sv" in navy bold.

**Top section (50%) — Waveform timing diagram:**

```
        | Cycle 0  | Cycle 1  | Cycle 2  | Cycle 3  |
clk     : _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
start   : ____/‾‾‾‾\____________________________
rx      : ====<64-bit received word>==============
pipe0   : ____________/‾‾‾‾\_____________________
pipe1   : ____________________/‾‾‾‾\_____________
done    : ____________________/‾‾‾‾\_____________
data_out: XXXXXXXXXXXXXXXXXXXX<==VALID==>=========
valid   : ____________________/‾‾‾‾\_____________
```

Annotations:
- Arrow from start: "rx captured into rx_reg"
- Arrow at pipe1: "decode_logic results (data_comb, valid_comb) captured"
- Green checkmark: "done within 12 cycles (actually at +2)"
- Note: "Same 3-stage pipeline structure as encoder"

**Bottom section (50%) — Pipeline architecture & decode logic breakdown:**

A horizontal pipeline with combinational logic in the middle:

```
[Stage 0]              │ [Combinational Decode Logic]              │ [Stage 2]
                       │ (all in always_comb)                      │
start──►FF──►pipe0     │                                           │ pipe1──►FF──►done
rx ────►FF──►rx_reg    │  1. polar_transform64(rx_reg) → u_hat    │
                       │  2. Extract syndrome from frozen pos      │ data_comb──►FF──►data_out
                       │  3. Weight-1/2/3 syndrome search          │ valid_comb──►FF──►valid
                       │  4. Apply correction, re-transform        │
                       │  5. Extract data & CRC, verify            │
                       │                                           │
```

Register boundaries marked with dashed vertical lines and clock symbols.

**Comparison table (bottom, small):**
| Property | Encoder | Decoder |
|:---:|:---:|:---:|
| Pipeline stages | 3 (start→pipe0→pipe1→done) | 3 (start→pipe0→pipe1→done) |
| Done latency | Exactly 2 cycles | Exactly 2 cycles (≤12 allowed) |
| Comb logic | CRC + build_u + transform | Transform + syndrome search + CRC verify |
| Comb complexity | O(N) | O(N^3) — weight-3 search |

**Style:** Digital waveform style, pipeline block diagram with register boundaries, comparison table, monospace labels, navy title.
