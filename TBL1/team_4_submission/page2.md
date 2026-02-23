Generate an academic presentation slide (16:9, white background) titled **"File Structure & Shared Package"**.

**Layout — two columns:**

**Title:** "Code Structure: polar_common_pkg.sv" in navy bold.

**Left column (40%) — File dependency diagram:**
A tree/dependency graph showing file relationships:
```
polar_common_pkg.sv  (shared package)
    ├── imported by → polar64_crc16_encoder.sv
    ├── imported by → polar64_crc16_decoder.sv
    └── imported by → tb_basic.sv
```
Draw this as a directed graph with the package node at the top (blue box) and three module nodes below (green/orange/gray boxes) with arrows pointing from the package to each module. Label the arrows "import".

**Right column (60%) — Package contents summary as a structured card layout:**

**Card 1 (light blue background, titled "Parameters"):**
```
N = 64    // Codeword length
K = 40    // Info bits (24 data + 16 CRC)
F = 24    // Frozen bits
```

**Card 2 (light green background, titled "Bit Position Tables"):**
- A visual 64-cell horizontal bar (8x8 grid or single row):
  - 40 cells colored BLUE labeled "INFO_POS" (positions: 2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,19,20,21,22,24,25,26,28,32,33,34,35,36,37,38,40,41,42,44,48,49,50,52,56)
  - 24 cells colored GRAY labeled "FROZEN_POS" (positions: 0,1,15,23,27,29,30,31,39,43,45,46,47,51,53,54,55,57,58,59,60,61,62,63)
- Caption: "Blue = Information bits | Gray = Frozen bits (always 0)"
- Small note: "Selection criteria: popcount(i) ≤ 3, ranked by Bhattacharyya parameter"

**Card 3 (light yellow background, titled "Shared Functions"):**
A table:
| Function | Input → Output | Purpose |
|----------|---------------|---------|
| crc16_ccitt24() | 24-bit data → 16-bit CRC | CRC-16-CCITT checksum |
| build_u() | 24-bit data + 16-bit CRC → 64-bit u | Map bits to info positions |
| polar_transform64() | 64-bit u → 64-bit v | Butterfly transform (self-inverse) |

**Style:** Clean academic, card-based layout, monospace for code, colored boxes for each card, navy title.
