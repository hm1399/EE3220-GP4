Generate an academic presentation slide (16:9, white background) titled **"Encoder Pipeline & Timing"**.

**Layout — top waveform diagram, bottom pipeline structure:**

**Title:** "Encoder Pipeline: polar64_crc16_encoder.sv" in navy bold.

**Top section (55%) — Detailed waveform/timing diagram:**

Draw a digital waveform diagram with these signals (vertically stacked, time flows left to right):

```
        | Cycle 0  | Cycle 1  | Cycle 2  | Cycle 3  | Cycle 4  |
clk     : _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
rst_n   : ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
start   : ____/‾‾‾‾\________________________________________
data_in : ====<ABCDEF>=======================================
pipe0   : ____________/‾‾‾‾\_________________________________
pipe1   : ____________________/‾‾‾‾\_________________________
done    : ____________________/‾‾‾‾\_________________________
codeword: XXXXXXXXXXXXXXXXXXXX<====VALID==================>===
```

Color-code the signals:
- start: green pulse
- pipe0: blue pulse
- pipe1/done: orange pulse
- codeword: transition from gray (invalid) to blue (valid) at cycle 2

Add annotations with arrows:
- Arrow from start to pipe0: "1 cycle delay (FF)"
- Arrow from pipe0 to pipe1: "1 cycle delay (FF)"
- Arrow at pipe1: "cw_comb captured into codeword register"
- Green checkmark at done: "done = 1 cycle pulse, exactly +2 after start"

**Bottom section (45%) — Pipeline architecture block diagram:**

A horizontal pipeline diagram with 3 stages separated by register boundaries (vertical dashed lines):

```
  [Stage 0]          │  [Stage 1]              │  [Stage 2]
                     │  (Combinational)         │
  start ──►FF──►pipe0│                          │  pipe1──►FF──►done
  data_in──►FF──►    │  crc16_ccitt24()         │
            data_reg │  build_u()               │  cw_comb──►FF──►codeword
                     │  polar_transform64()     │
                     │  ↓ all in always_comb    │
```

Register boundaries labeled as "posedge clk" with small clock icons.

**Key point box (bottom-center, light green background):**
"All encoding computation (CRC + build_u + transform) happens combinationally in Stage 1. Pipeline registers only add 2 cycles of latency for timing closure."

**Style:** Digital timing diagram style, colored signal traces, clean pipeline blocks with register boundaries, monospace labels, navy title.
