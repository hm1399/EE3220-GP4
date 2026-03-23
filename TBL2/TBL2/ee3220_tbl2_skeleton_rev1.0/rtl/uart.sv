`timescale 1ns / 1ps

module uart #(
    parameter int unsigned CLK_HZ = 125_000_000,
    parameter int unsigned BAUD   = 115_200
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        bus_valid,
    input  logic        bus_we,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready,
    input  logic        rx,
    output logic        tx
);

    localparam logic [31:0] UART_BASE = 32'h4000_0000;
    localparam int unsigned BAUD_DIVIDE_RAW = (CLK_HZ + (BAUD / 2)) / BAUD;
    localparam int unsigned BAUD_DIVIDE = (BAUD_DIVIDE_RAW == 0) ? 1 : BAUD_DIVIDE_RAW;
    localparam int unsigned BAUD_DIVIDE_W = (BAUD_DIVIDE <= 1) ? 1 : $clog2(BAUD_DIVIDE);

    logic                    tx_busy;
    logic                    tx_ready;
    logic [9:0]              tx_shift;
    logic [3:0]              tx_bits_remaining;
    logic [BAUD_DIVIDE_W-1:0] baud_counter;

    wire txdata_hit = (bus_addr == (UART_BASE + 32'h0000_0000));
    wire status_hit = (bus_addr == (UART_BASE + 32'h0000_0004));

    assign tx_ready = !tx_busy;

    // The base path only needs UART TX. RX is reserved for future extensions.
    assign tx = tx_busy ? tx_shift[0] : 1'b1;

    always_comb begin
        bus_rdata = 32'd0;
        if (status_hit) begin
            bus_rdata = {31'd0, tx_ready};
        end
    end

    // TXDATA writes stall while the transmitter is busy so software can use
    // UART_STATUS[0] as a true "can accept next byte" indicator.
    assign bus_ready = bus_valid &&
                       (status_hit || (txdata_hit && (!bus_we || tx_ready)));

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_busy           <= 1'b0;
            tx_shift          <= 10'h3ff;
            tx_bits_remaining <= 4'd0;
            baud_counter      <= '0;
        end else begin
            if (tx_busy) begin
                if (baud_counter == '0) begin
                    if (tx_bits_remaining == 4'd1) begin
                        tx_busy           <= 1'b0;
                        tx_shift          <= 10'h3ff;
                        tx_bits_remaining <= 4'd0;
                        baud_counter      <= '0;
                    end else begin
                        tx_shift          <= {1'b1, tx_shift[9:1]};
                        tx_bits_remaining <= tx_bits_remaining - 1'b1;
                        baud_counter      <= BAUD_DIVIDE_W'(BAUD_DIVIDE - 1);
                    end
                end else begin
                    baud_counter <= baud_counter - 1'b1;
                end
            end else if (bus_valid && bus_we && txdata_hit) begin
                tx_busy           <= 1'b1;
                tx_shift          <= {1'b1, bus_wdata[7:0], 1'b0};
                tx_bits_remaining <= 4'd10;
                baud_counter      <= BAUD_DIVIDE_W'(BAUD_DIVIDE - 1);
            end
        end
    end

endmodule
