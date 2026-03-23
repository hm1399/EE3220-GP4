`timescale 1ns / 1ps

module timer #(
    parameter int unsigned DEFAULT_PERIOD_CYCLES = 125_000_000
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        bus_valid,
    input  logic        bus_we,
    input  logic [31:0] bus_addr,
    input  logic [31:0] bus_wdata,
    output logic [31:0] bus_rdata,
    output logic        bus_ready
);

    localparam logic [31:0] TIMER_BASE = 32'h4000_0010;
    localparam int unsigned PERIOD_CYCLES = (DEFAULT_PERIOD_CYCLES == 0) ? 1 : DEFAULT_PERIOD_CYCLES;

    logic [31:0] cycle_counter;
    logic        tick_pending;

    wire status_hit = (bus_addr == (TIMER_BASE + 32'h0000_0000));
    wire value_hit  = (bus_addr == (TIMER_BASE + 32'h0000_0004));
    wire timer_hit  = status_hit || value_hit;
    wire clear_tick = bus_valid && bus_we && status_hit && bus_wdata[0];

    assign bus_ready = bus_valid && timer_hit;

    always_comb begin
        bus_rdata = 32'd0;
        if (status_hit) begin
            bus_rdata = {31'd0, tick_pending};
        end else if (value_hit) begin
            bus_rdata = cycle_counter;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            cycle_counter <= 32'd0;
            tick_pending  <= 1'b0;
        end else begin
            if (cycle_counter == (PERIOD_CYCLES - 1)) begin
                cycle_counter <= 32'd0;
                tick_pending  <= 1'b1;
            end else begin
                cycle_counter <= cycle_counter + 1'b1;
                if (clear_tick)
                    tick_pending <= 1'b0;
            end
        end
    end

endmodule
