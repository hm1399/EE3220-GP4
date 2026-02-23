Generate an academic presentation slide (16:9, white background) titled **"Encoder Workflow — Step 2 & 3: Build u-vector & Polar Transform"**.

**Layout — top-to-bottom flow with three visual stages:**

**Title:** "Encoding Steps 2-3: Build u-vector & Polar Transform" in navy bold.

**Stage 1 (top, 30% height) — "Build u-vector" with visual mapping:**

Show three input sources merging into one 64-bit vector:
- Left box: "24-bit data" (green) with bits labeled [23..0]
- Middle box: "16-bit CRC" (orange) with bits labeled [15..0]
- Right label: "Frozen = 0" (gray)

All three merge via arrows into a single 64-cell horizontal bar representing the u-vector:
- Blue cells at INFO_POS[0..23] ← data bits (with mapping arrows: "data[23-k] → u[INFO_POS[k]]")
- Orange cells at INFO_POS[24..39] ← CRC bits (with mapping arrows: "crc[15-k] → u[INFO_POS[24+k]]")
- Gray cells at FROZEN_POS[0..23] ← all zeros

Code annotation next to the visual:
```
u = 64'b0;
for (k=0; k<24; k++) u[INFO_POS[k]]    = data[23-k];
for (k=0; k<16; k++) u[INFO_POS[24+k]]  = crc[15-k];
// Frozen positions remain 0
```

**Stage 2 (middle, 35% height) — "Polar Butterfly Transform":**

A compact butterfly network diagram for N=8 (as illustration) showing:
- 8 input nodes (u[0]..u[7]) on the left
- 3 stages of XOR butterfly operations
- 8 output nodes (codeword[0]..codeword[7]) on the right
- XOR operations shown as "⊕" circles
- Caption: "Illustrated for N=8; actual N=64 uses 6 stages"

Formula box beside the diagram:
```
for s = 0..5:
    step = 2^(s+1), half = 2^s
    v[i+j+half] ^= v[i+j]
```
Note: "Self-inverse: same transform is used for decoding"

**Stage 3 (bottom, 20% height) — Encoder combinational logic summary:**

A single-line flow:
```
data_reg → [crc16_ccitt24] → crc_comb → [build_u] → u_comb → [polar_transform64] → cw_comb → codeword
  24-bit        16-bit                      64-bit                    64-bit            64-bit
```
All computed in `always_comb` — pure combinational, registered at pipeline boundaries.

**Style:** Flow diagram style, green for data, orange for CRC, gray for frozen, blue butterfly lines, monospace for code, navy title.
