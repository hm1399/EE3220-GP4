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
    // Column syndrome lookup table (24-bit syndrome for each of 64 bit positions)
    // COL_SYN[j] = syndrome contribution of a single-bit error at position j
    // Computed as: frozen-bit projection of polar_transform64(unit_j)
    // All 64 syndromes are distinct => unique decoding for weight <= 1
    // For weight 2/3: XOR combinations are checked combinationally
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
    // Pipeline control (same 3-stage structure as encoder)
    // P0: start sampled, rx captured
    // P1: pipe0=1, combinational decode running
    // P2: pipe1=1, results registered, done=1
    // ----------------------------------------------------------------
    logic        pipe0, pipe1;
    logic [63:0] rx_reg;

    // ----------------------------------------------------------------
    // Combinational decode
    // ----------------------------------------------------------------
    logic [63:0] u_hat_comb;
    logic [23:0] syndrome_comb;
    logic [63:0] err_pat_comb;
    logic        correctable_comb;
    logic [63:0] u_corrected_comb;
    logic [23:0] data_comb;
    logic [15:0] crc_rx_comb;
    logic [15:0] crc_calc_comb;
    logic        valid_comb;

    // Bounded-distance decoder: find error pattern of weight <= 3
    // matching the syndrome, using column syndrome lookup
    logic [23:0]  syn_rem1, syn_rem2;
    logic [63:0]  ep1, ep2, ep3;
    logic         found1, found2, found3;

    always_comb begin : decode_logic
        // Step 1: inverse Polar transform (same as forward, self-inverse)
        u_hat_comb = polar_transform64(rx_reg);

        // Step 2: extract syndrome from frozen bit positions
        syndrome_comb = 24'h000000;
        for (int k = 0; k < 24; k++)
            syndrome_comb[k] = u_hat_comb[FROZEN_POS[k]];

        // Step 3: bounded-distance decoding via column syndrome search
        ep1    = 64'b0;
        ep2    = 64'b0;
        ep3    = 64'b0;
        found1 = 1'b0;
        found2 = 1'b0;
        found3 = 1'b0;

        // Weight-1 search
        for (int j = 0; j < 64; j++) begin
            if (!found1 && (COL_SYN[j] == syndrome_comb)) begin
                ep1    = 64'b1 << j;
                found1 = 1'b1;
            end
        end

        // Weight-2 search (only if weight-1 not found)
        if (!found1) begin
            for (int j = 0; j < 64; j++) begin
                syn_rem1 = syndrome_comb ^ COL_SYN[j];
                for (int k = j + 1; k < 64; k++) begin
                    if (!found2 && (COL_SYN[k] == syn_rem1)) begin
                        ep2    = (64'b1 << j) | (64'b1 << k);
                        found2 = 1'b1;
                    end
                end
            end
        end

        // Weight-3 search (only if weight-1 and weight-2 not found)
        if (!found1 && !found2) begin
            for (int j = 0; j < 64; j++) begin
                for (int k = j + 1; k < 64; k++) begin
                    syn_rem2 = syndrome_comb ^ COL_SYN[j] ^ COL_SYN[k];
                    for (int l = k + 1; l < 64; l++) begin
                        if (!found3 && (COL_SYN[l] == syn_rem2)) begin
                            ep3    = (64'b1 << j) | (64'b1 << k) | (64'b1 << l);
                            found3 = 1'b1;
                        end
                    end
                end
            end
        end

        // Select error pattern
        if (syndrome_comb == 24'h000000) begin
            err_pat_comb   = 64'b0;
            correctable_comb = 1'b1;
        end else if (found1) begin
            err_pat_comb   = ep1;
            correctable_comb = 1'b1;
        end else if (found2) begin
            err_pat_comb   = ep2;
            correctable_comb = 1'b1;
        end else if (found3) begin
            err_pat_comb   = ep3;
            correctable_comb = 1'b1;
        end else begin
            err_pat_comb   = 64'b0;
            correctable_comb = 1'b0;
        end

        // Step 4: correct and re-transform
        u_corrected_comb = polar_transform64(rx_reg ^ err_pat_comb);
        // Force frozen bits to 0
        for (int k = 0; k < 24; k++)
            u_corrected_comb[FROZEN_POS[k]] = 1'b0;

        // Step 5: extract data and CRC (note 23-k and 15-k mapping)
        data_comb = 24'h000000;
        for (int k = 0; k < 24; k++)
            data_comb[23 - k] = u_corrected_comb[INFO_POS[k]];
        crc_rx_comb = 16'h0000;
        for (int k = 0; k < 16; k++)
            crc_rx_comb[15 - k] = u_corrected_comb[INFO_POS[24 + k]];

        // Step 6: CRC verification
        crc_calc_comb = crc16_ccitt24(data_comb);
        valid_comb = correctable_comb && (crc_calc_comb == crc_rx_comb);
    end

    // ----------------------------------------------------------------
    // Sequential pipeline: capture rx on start, register outputs on pipe1
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

            if (start)
                rx_reg <= rx;

            if (pipe1) begin
                data_out <= valid_comb ? data_comb : 24'b0;
                valid    <= valid_comb;
            end

            // Clear valid/data when new decode starts (safety)
            if (start) begin
                valid    <= 1'b0;
                data_out <= 24'b0;
            end
        end
    end

endmodule
