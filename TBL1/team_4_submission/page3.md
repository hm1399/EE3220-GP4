Generate an academic presentation slide (16:9, white background) titled **"Encoder Workflow — Step 1: CRC-16 Computation"**.

**Layout — left code, right diagram:**

**Title:** "Encoding Step 1: CRC-16-CCITT Computation" in navy bold.

**Left column (50%) — Code visualization:**
A dark-background code box (syntax-highlighted SystemVerilog) showing the core CRC function:
```systemverilog
function automatic logic [15:0]
    crc16_ccitt24(input logic [23:0] data);
  logic [15:0] crc;
  logic        fb;
  crc = 16'h0000;           // init = 0
  for (int i = 23; i >= 0; i--) begin
    fb  = data[i] ^ crc[15]; // feedback
    crc = {crc[14:0], 1'b0}; // shift left
    if (fb) crc = crc ^ 16'h1021; // XOR poly
  end
  return crc;
endfunction
```
Highlight the key line `crc = crc ^ 16'h1021` with a colored annotation arrow pointing to it, labeled "Polynomial: x^16 + x^12 + x^5 + 1".

**Right column (50%) — CRC computation flow diagram:**
A vertical step-by-step diagram showing the LFSR (Linear Feedback Shift Register) process for one iteration:

Draw a 16-bit shift register as 16 connected boxes labeled [15] [14] ... [1] [0].
- An XOR gate at the input (left side) combining data[i] and crc[15] → feedback bit
- Arrow showing the shift-left operation
- XOR taps at bit positions 0, 5, 12 (corresponding to polynomial x^16+x^12+x^5+1)
- Feedback bit feeds back into XOR taps when fb=1

**Below the diagram, a concrete example box (light blue background):**
```
Input:  data_in = 24'hABCDEF
Output: CRC-16  = crc16_ccitt24(24'hABCDEF)
Process: MSB-first, 24 iterations, no reflect, no xorout
```

**Key specs box (small, bottom-right):**
- Polynomial: G(x) = x^16 + x^12 + x^5 + 1
- Init: 0x0000
- Processing: MSB first (bit 23 → bit 0)
- XOR constant: 0x1021

**Style:** Academic with code emphasis, dark code box with syntax coloring, blue LFSR diagram, light blue example box.
