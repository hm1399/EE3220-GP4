`timescale 1ns/1ps
package polar_common_pkg;

    localparam int N = 64;       // Codeword length
    localparam int K = 40;       // Information bits (24 data + 16 CRC)
    localparam int F = 24;       // Frozen bits

    // 40 information bit positions (popcount <= 3, most reliable by Bhattacharyya)
    localparam int INFO_POS [0:39] = '{
        2,  3,  4,  5,  6,  7,  8,  9, 10, 11,
       12, 13, 14, 16, 17, 18, 19, 20, 21, 22,
       24, 25, 26, 28, 32, 33, 34, 35, 36, 37,
       38, 40, 41, 42, 44, 48, 49, 50, 52, 56
    };

    // 24 frozen bit positions (set to 0 during encoding, forced to 0 during decoding)
    localparam int FROZEN_POS [0:23] = '{
        0,  1, 15, 23, 27, 29, 30, 31,
       39, 43, 45, 46, 47, 51, 53, 54,
       55, 57, 58, 59, 60, 61, 62, 63
    };

    // ----------------------------------------------------------------
    // Helper function: CRC-16-CCITT for 24-bit data
    // Polynomial: x^16 + x^12 + x^5 + 1, feedback constant 0x1021
    // Initial remainder: 0x0000, MSB first, no reflect, no xorout
    // ----------------------------------------------------------------
    function automatic logic [15:0] crc16_ccitt24(input logic [23:0] data);
        logic [15:0] crc;
        logic        fb;
        crc = 16'h0000;
        for (int i = 23; i >= 0; i--) begin
            fb  = data[i] ^ crc[15];
            crc = {crc[14:0], 1'b0};
            if (fb) crc = crc ^ 16'h1021;
        end
        return crc;
    endfunction

    // ----------------------------------------------------------------
    // Helper function: Build the 64-bit u vector from data and CRC
    // data[23-k] -> u[INFO_POS[k]]   for k = 0..23
    // crc[15-k]  -> u[INFO_POS[24+k]] for k = 0..15
    // Frozen positions remain 0
    // ----------------------------------------------------------------
    function automatic logic [63:0] build_u(input logic [23:0] data, input logic [15:0] crc);
        logic [63:0] u;
        u = 64'b0;
        for (int k = 0; k < 24; k++)
            u[INFO_POS[k]] = data[23 - k];
        for (int k = 0; k < 16; k++)
            u[INFO_POS[24 + k]] = crc[15 - k];
        return u;
    endfunction

    // ----------------------------------------------------------------
    // Helper function: Polar butterfly transform (no bit-reversal)
    // v[i+j+half] ^= v[i+j]  for each stage  (F_N generator matrix row direction)
    // This is its own inverse (F_N^{-1} = F_N over GF(2))
    // ----------------------------------------------------------------
    function automatic logic [63:0] polar_transform64(input logic [63:0] u);
        logic [63:0] v;
        int step, half;
        v = u;
        for (int s = 0; s < 6; s++) begin
            step = 1 << (s + 1);
            half = 1 << s;
            for (int i = 0; i < 64; i += step) begin
                for (int j = 0; j < half; j++) begin
                    v[i + j + half] = v[i + j] ^ v[i + j + half];
                end
            end
        end
        return v;
    endfunction

    // ----------------------------------------------------------------
    // Helper function: Verify INFO_POS and FROZEN_POS are valid
    // Returns 1 if the union covers exactly {0..63} with no overlap
    // ----------------------------------------------------------------
    function automatic bit pos_tables_ok();
        bit [63:0] seen;
        seen = 64'b0;
        for (int k = 0; k < 40; k++) begin
            if (INFO_POS[k] < 0 || INFO_POS[k] > 63) return 0;
            if (seen[INFO_POS[k]]) return 0;
            seen[INFO_POS[k]] = 1'b1;
        end
        for (int k = 0; k < 24; k++) begin
            if (FROZEN_POS[k] < 0 || FROZEN_POS[k] > 63) return 0;
            if (seen[FROZEN_POS[k]]) return 0;
            seen[FROZEN_POS[k]] = 1'b1;
        end
        return (seen == 64'hFFFFFFFFFFFFFFFF);
    endfunction

    // ----------------------------------------------------------------
    // Helper function: Compute minimum row weight among all INFO_POS
    // Row weight of position i = 2^(6 - popcount(i))
    // Should return 8 for dmin = 8
    // ----------------------------------------------------------------
    function automatic int min_info_row_weight();
        int min_w, pc, w;
        min_w = 64;
        for (int k = 0; k < 40; k++) begin
            pc = 0;
            for (int b = 0; b < 6; b++)
                if (INFO_POS[k][b]) pc++;
            w = 1 << (6 - pc);
            if (w < min_w) min_w = w;
        end
        return min_w;
    endfunction

endpackage
