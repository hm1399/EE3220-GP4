module polar64_crc16_decoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [63:0] rx,
    output logic        done,
    output logic [23:0] data_out,
    output logic        valid
);

    import polar_common_pkg::*;

    // ----------------------------------------------------------------
    // Column syndrome lookup table
    // COL_SYN[j] = frozen-bit projection of polar_transform64(unit_j)
    // All 64 values are distinct => unique decoding for weight <= 3
    // ----------------------------------------------------------------
    localparam logic [23:0] COL_SYN [0:63] = '{
        24'hFFFFFF,  // bit 0
        24'hAB77BE,  // bit 1
        24'hCDBBDC,  // bit 2
        24'h89339C,  // bit 3
        24'hF1DDEC,  // bit 4
        24'hA155AC,  // bit 5
        24'hC199CC,  // bit 6
        24'h81118C,  // bit 7
        24'hFE1EF4,  // bit 8
        24'hAA16B4,  // bit 9
        24'hCC1AD4,  // bit 10
        24'h881294,  // bit 11
        24'hF01CE4,  // bit 12
        24'hA014A4,  // bit 13
        24'hC018C4,  // bit 14
        24'h801084,  // bit 15
        24'hFFE0F8,  // bit 16
        24'hAB60B8,  // bit 17
        24'hCDA0D8,  // bit 18
        24'h892098,  // bit 19
        24'hF1C0E8,  // bit 20
        24'hA140A8,  // bit 21
        24'hC180C8,  // bit 22
        24'h810088,  // bit 23
        24'hFE00F0,  // bit 24
        24'hAA00B0,  // bit 25
        24'hCC00D0,  // bit 26
        24'h880090,  // bit 27
        24'hF000E0,  // bit 28
        24'hA000A0,  // bit 29
        24'hC000C0,  // bit 30
        24'h800080,  // bit 31
        24'hFFFF00,  // bit 32
        24'hAB7700,  // bit 33
        24'hCDBB00,  // bit 34
        24'h893300,  // bit 35
        24'hF1DD00,  // bit 36
        24'hA15500,  // bit 37
        24'hC19900,  // bit 38
        24'h811100,  // bit 39
        24'hFE1E00,  // bit 40
        24'hAA1600,  // bit 41
        24'hCC1A00,  // bit 42
        24'h881200,  // bit 43
        24'hF01C00,  // bit 44
        24'hA01400,  // bit 45
        24'hC01800,  // bit 46
        24'h801000,  // bit 47
        24'hFFE000,  // bit 48
        24'hAB6000,  // bit 49
        24'hCDA000,  // bit 50
        24'h892000,  // bit 51
        24'hF1C000,  // bit 52
        24'hA14000,  // bit 53
        24'hC18000,  // bit 54
        24'h810000,  // bit 55
        24'hFE0000,  // bit 56
        24'hAA0000,  // bit 57
        24'hCC0000,  // bit 58
        24'h880000,  // bit 59
        24'hF00000,  // bit 60
        24'hA00000,  // bit 61
        24'hC00000,  // bit 62
        24'h800000   // bit 63
    };

    // ----------------------------------------------------------------
    // Pipeline registers
    // ----------------------------------------------------------------
    logic        pipe0, pipe1;
    logic [63:0] rx_reg;

    // ----------------------------------------------------------------
    // Combinational decode outputs
    // ----------------------------------------------------------------
    logic [23:0] data_comb;
    logic        valid_comb;

    // ----------------------------------------------------------------
    // Combinational decode logic (no latches: all signals default at top)
    // ----------------------------------------------------------------
    always_comb begin : decode_logic
        // ---------- default assignments (prevents latches) ----------
        logic [63:0] u_hat;
        logic [23:0] syndrome;
        logic [63:0] err_pat;
        logic        correctable;
        logic [63:0] u_final;
        logic [15:0] crc_rx;
        logic [15:0] crc_calc;

        u_hat       = 64'b0;
        syndrome    = 24'b0;
        err_pat     = 64'b0;
        correctable = 1'b0;
        u_final     = 64'b0;
        crc_rx      = 16'b0;
        crc_calc    = 16'b0;
        data_comb   = 24'b0;
        valid_comb  = 1'b0;

        // Step 1: inverse Polar transform (self-inverse)
        u_hat = polar_transform64(rx_reg);

        // Step 2: extract 24-bit syndrome from frozen bit positions
        for (int k = 0; k < 24; k++)
            syndrome[k] = u_hat[FROZEN_POS[k]];

        // Step 3: bounded-distance decoding (t=3)
        //   Search for smallest error pattern whose column syndromes XOR to syndrome
        if (syndrome == 24'h0) begin
            err_pat     = 64'b0;
            correctable = 1'b1;
        end else begin
            // Weight-1 search
            for (int j = 0; j < 64; j++) begin
                if (!correctable && (COL_SYN[j] == syndrome)) begin
                    err_pat     = 64'b1 << j;
                    correctable = 1'b1;
                end
            end

            // Weight-2 search
            if (!correctable) begin
                for (int j = 0; j < 64; j++) begin
                    for (int k = j + 1; k < 64; k++) begin
                        if (!correctable &&
                            ((COL_SYN[j] ^ COL_SYN[k]) == syndrome)) begin
                            err_pat     = (64'b1 << j) | (64'b1 << k);
                            correctable = 1'b1;
                        end
                    end
                end
            end

            // Weight-3 search
            if (!correctable) begin
                for (int j = 0; j < 64; j++) begin
                    for (int k = j + 1; k < 64; k++) begin
                        for (int l = k + 1; l < 64; l++) begin
                            if (!correctable &&
                                ((COL_SYN[j] ^ COL_SYN[k] ^ COL_SYN[l]) == syndrome)) begin
                                err_pat     = (64'b1 << j) | (64'b1 << k) | (64'b1 << l);
                                correctable = 1'b1;
                            end
                        end
                    end
                end
            end
        end

        // Step 4: apply correction and re-transform
        u_final = polar_transform64(rx_reg ^ err_pat);
        // Force frozen bits to 0
        for (int k = 0; k < 24; k++)
            u_final[FROZEN_POS[k]] = 1'b0;

        // Step 5: extract data[23-k] and CRC[15-k]
        for (int k = 0; k < 24; k++)
            data_comb[23 - k] = u_final[INFO_POS[k]];
        for (int k = 0; k < 16; k++)
            crc_rx[15 - k] = u_final[INFO_POS[24 + k]];

        // Step 6: CRC verification
        crc_calc   = crc16_ccitt24(data_comb);
        valid_comb = correctable && (crc_calc == crc_rx);
    end

    // ----------------------------------------------------------------
    // Sequential pipeline: 3 stages => done at start+2
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe0    <= 1'b0;
            pipe1    <= 1'b0;
            done     <= 1'b0;
            rx_reg   <= 64'b0;
            data_out <= 24'b0;
            valid    <= 1'b0;
        end else begin
            pipe0 <= start;
            pipe1 <= pipe0;
            done  <= pipe1;

            if (start) begin
                rx_reg   <= rx;
                valid    <= 1'b0;
                data_out <= 24'b0;
            end

            if (pipe1) begin
                data_out <= valid_comb ? data_comb : 24'b0;
                valid    <= valid_comb;
            end
        end
    end

endmodule
