Generate an academic presentation slide (16:9, white background) titled **"Decoder Workflow — Steps 1 & 2: Inverse Transform & Syndrome"**.

**Layout — two main sections, top and bottom:**

**Title:** "Decoding Steps 1-2: Inverse Polar Transform & Syndrome Extraction" in navy bold.

**Top section (55%) — Step 1: Inverse Transform with visual:**

**Left half:**
A flow diagram:
- Input box (red border): "rx (64-bit received codeword, possibly corrupted)"
- Arrow down labeled "polar_transform64(rx)" with note: "Self-inverse: F_N^(-1) = F_N over GF(2)"
- Output box (blue border): "u_hat (64-bit estimated u-vector)"

**Right half — before/after comparison:**
Two 64-cell horizontal bars stacked:
- Top bar: "Original u (at encoder)" — blue cells at info positions, gray cells at frozen positions (all 0)
- Bottom bar: "u_hat (after inverse transform)" — blue cells at info positions, but some frozen cells are RED (non-zero due to errors)
- Red arrows pointing to the non-zero frozen cells with label: "These should be 0 — non-zero = errors detected!"

**Bottom section (45%) — Step 2: Syndrome Extraction with code and visual:**

**Left half — Code box (dark background):**
```systemverilog
// Step 2: extract 24-bit syndrome
// from frozen bit positions
for (int k = 0; k < 24; k++)
    syndrome[k] = u_hat[FROZEN_POS[k]];
```

**Right half — Visual extraction diagram:**
A 64-cell bar (u_hat) with 24 frozen positions highlighted in orange.
Arrows from each of the 24 frozen cells pointing down to a compact 24-cell bar labeled "syndrome[23:0]".
- If syndrome = 24'h000000 → green badge: "No errors!"
- If syndrome ≠ 0 → red badge: "Errors detected → proceed to correction"

**Mapping table (small, bottom-right):**
| syndrome index k | Source: u_hat position | FROZEN_POS value |
|:---:|:---:|:---:|
| 0 | u_hat[0] | 0 |
| 1 | u_hat[1] | 1 |
| 2 | u_hat[15] | 15 |
| ... | ... | ... |
| 23 | u_hat[63] | 63 |

**Style:** Academic with code emphasis, red for error indicators, blue/gray for position mapping, orange for frozen positions being extracted, navy title.
