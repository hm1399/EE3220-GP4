Generate an academic presentation slide (16:9, white background) titled **"Decoder Workflow — Steps 4 & 5: Correction & CRC Verification"**.

**Layout — top flow diagram, bottom code + final decision:**

**Title:** "Decoding Steps 4-5: Apply Correction, Extract Data & CRC Verify" in navy bold.

**Top section (50%) — Step 4: Error correction and data extraction flow:**

A horizontal flow diagram with 4 connected stages:

**Box 1 (light purple):** "Apply Error Pattern"
- "rx_corrected = rx ⊕ err_pat"
- Small visual: 64-bit bar with 2 red cells (error bits) being flipped to green

→ Arrow →

**Box 2 (light blue):** "Re-transform"
- "u_final = polar_transform64(rx_corrected)"
- "Force frozen bits to 0:"
- "u_final[FROZEN_POS[k]] = 0"

→ Arrow →

**Box 3 (light green):** "Extract 24-bit Data"
- A visual showing arrows from u_final's INFO_POS[0..23] to data_out[23..0]:
```
data_out[23-k] = u_final[INFO_POS[k]]
for k = 0..23
```
- Note the "23-k" reversal with a small callout: "⚠ Bit order reversal: 23-k, not k"

→ Arrow →

**Box 4 (light orange):** "Extract 16-bit CRC"
- Arrows from u_final's INFO_POS[24..39] to crc_rx[15..0]:
```
crc_rx[15-k] = u_final[INFO_POS[24+k]]
for k = 0..15
```

**Bottom section (50%) — Step 5: CRC verification and valid decision:**

**Left half — CRC check diagram:**
Two paths merging at a comparison node:
- Path 1: "data_out (24-bit)" → "crc16_ccitt24()" → "crc_calc (16-bit)" (recalculated)
- Path 2: "crc_rx (16-bit)" (extracted from u_final)
- Both arrows point to a diamond: "crc_calc == crc_rx?"
  - YES + correctable → Green output: "valid = 1, data_out = decoded data"
  - NO or !correctable → Red output: "valid = 0, data_out = 24'b0"

**Right half — Code box (dark background):**
```systemverilog
// Step 5: CRC verification
crc_calc   = crc16_ccitt24(data_comb);
valid_comb = correctable && (crc_calc == crc_rx);

// Output assignment
data_out <= valid_comb ? data_comb : 24'b0;
valid    <= valid_comb;
```

**Safety note box (red border, bottom-center):**
"Double protection: Even if syndrome matching succeeds (correctable=1), CRC must also pass. This catches rare miscorrection events where the syndrome matches a wrong error pattern."

**Style:** Flow diagram, color-coded boxes per step (purple→blue→green→orange), comparison diamond, red safety box, monospace code, navy title.
