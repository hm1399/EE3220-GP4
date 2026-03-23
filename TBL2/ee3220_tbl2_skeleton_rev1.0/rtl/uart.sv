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
    localparam int unsigned HALF_BAUD_DIVIDE_RAW = BAUD_DIVIDE / 2;
    localparam int unsigned HALF_BAUD_DIVIDE = (HALF_BAUD_DIVIDE_RAW == 0) ? 1 : HALF_BAUD_DIVIDE_RAW;
    localparam int unsigned BAUD_DIVIDE_W = (BAUD_DIVIDE <= 1) ? 1 : $clog2(BAUD_DIVIDE);

    typedef enum logic [1:0] {
        RX_IDLE  = 2'd0,
        RX_START = 2'd1,
        RX_DATA  = 2'd2,
        RX_STOP  = 2'd3
    } rx_state_t;

    logic                     tx_busy;
    logic                     tx_ready;
    logic [9:0]               tx_shift;
    logic [3:0]               tx_bits_remaining;
    logic [BAUD_DIVIDE_W-1:0] baud_counter;
    logic                     rx_meta;
    logic                     rx_sync;
    logic                     rx_valid;
    logic [7:0]               rx_data;
    logic [7:0]               rx_shift;
    logic [2:0]               rx_bit_index;
    logic [BAUD_DIVIDE_W-1:0] rx_baud_counter;
    rx_state_t                rx_state;

    wire txdata_hit = (bus_addr == (UART_BASE + 32'h0000_0000));
    wire status_hit = (bus_addr == (UART_BASE + 32'h0000_0004));
    wire rxdata_hit = (bus_addr == (UART_BASE + 32'h0000_0008));

    assign tx_ready = !tx_busy;
    assign tx = tx_busy ? tx_shift[0] : 1'b1;

    always_comb begin
        bus_rdata = 32'd0;
        if (status_hit) begin
            bus_rdata = {30'd0, rx_valid, tx_ready};
        end else if (rxdata_hit && rx_valid) begin
            bus_rdata = {24'd0, rx_data};
        end
    end

    assign bus_ready = bus_valid &&
                       (status_hit || rxdata_hit || (txdata_hit && (!bus_we || tx_ready)));

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_busy           <= 1'b0;
            tx_shift          <= 10'h3ff;
            tx_bits_remaining <= 4'd0;
            baud_counter      <= '0;
            rx_meta           <= 1'b1;
            rx_sync           <= 1'b1;
            rx_valid          <= 1'b0;
            rx_data           <= 8'd0;
            rx_shift          <= 8'd0;
            rx_bit_index      <= 3'd0;
            rx_baud_counter   <= '0;
            rx_state          <= RX_IDLE;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;

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

            if (bus_valid && !bus_we && rxdata_hit && rx_valid) begin
                rx_valid <= 1'b0;
            end

            case (rx_state)
                RX_IDLE: begin
                    if (!rx_sync) begin
                        rx_state        <= RX_START;
                        rx_baud_counter <= BAUD_DIVIDE_W'(HALF_BAUD_DIVIDE - 1);
                    end
                end

                RX_START: begin
                    if (rx_baud_counter == '0) begin
                        if (!rx_sync) begin
                            rx_state        <= RX_DATA;
                            rx_bit_index    <= 3'd0;
                            rx_baud_counter <= BAUD_DIVIDE_W'(BAUD_DIVIDE - 1);
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_baud_counter <= rx_baud_counter - 1'b1;
                    end
                end

                RX_DATA: begin
                    if (rx_baud_counter == '0) begin
                        rx_shift[rx_bit_index] <= rx_sync;
                        if (rx_bit_index == 3'd7) begin
                            rx_state <= RX_STOP;
                        end else begin
                            rx_bit_index <= rx_bit_index + 1'b1;
                        end
                        rx_baud_counter <= BAUD_DIVIDE_W'(BAUD_DIVIDE - 1);
                    end else begin
                        rx_baud_counter <= rx_baud_counter - 1'b1;
                    end
                end

                RX_STOP: begin
                    if (rx_baud_counter == '0) begin
                        if (rx_sync) begin
                            rx_data  <= rx_shift;
                            rx_valid <= 1'b1;
                        end
                        rx_state <= RX_IDLE;
                    end else begin
                        rx_baud_counter <= rx_baud_counter - 1'b1;
                    end
                end

                default: begin
                    rx_state <= RX_IDLE;
                end
            endcase
        end
    end

endmodule
