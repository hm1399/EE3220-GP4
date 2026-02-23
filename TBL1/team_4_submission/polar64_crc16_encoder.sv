`timescale 1ns/1ps
module polar64_crc16_encoder (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [23:0] data_in,
    output logic        done,
    output logic [63:0] codeword
);

    import polar_common_pkg::*;

    // Pipeline control: 2 intermediate stages + registered done
    // P0: start sampled, data_in captured
    // P1: pipe0=1 (intermediate, done=0)
    // P2: pipe1=1 (intermediate, done=0, codeword registered)
    // P3: done=1 (output valid)
    logic        pipe0, pipe1;
    logic [23:0] data_reg;

    // Combinational encoding from registered data
    logic [15:0] crc_comb;
    logic [63:0] u_comb, cw_comb;

    always_comb begin
        crc_comb = crc16_ccitt24(data_reg);
        u_comb   = build_u(data_reg, crc_comb);
        cw_comb  = polar_transform64(u_comb);
    end

    // Sequential pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe0    <= 1'b0;
            pipe1    <= 1'b0;
            done     <= 1'b0;
            codeword <= 64'b0;
            data_reg <= 24'b0;
        end else begin
            pipe0 <= start;
            pipe1 <= pipe0;
            done  <= pipe1;

            if (start)
                data_reg <= data_in;

            if (pipe1)
                codeword <= cw_comb;
        end
    end

endmodule
