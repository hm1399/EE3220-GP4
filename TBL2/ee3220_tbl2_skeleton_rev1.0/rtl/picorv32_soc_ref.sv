`timescale 1ns / 1ps

module picorv32_soc_ref #(
    parameter int unsigned CLK_HZ            = 125_000_000,
    parameter int unsigned UART_BAUD         = 115_200,
    parameter int unsigned TIMER_TICK_CYCLES = 125_000_000,
    parameter              IMEM_HEX          = "clock.mem",
    parameter logic [31:0] DMEM_BASE_ADDR    = 32'h0001_0000,
    parameter int unsigned DMEM_BYTES        = 8192,
    parameter int unsigned IMEM_WORDS        = 4096
) (
    input  logic        clk,
    input  logic        resetn,
    input  logic [2:0]  buttons,
    input  logic        uart_rxd,
    output logic        uart_txd
);

    localparam logic [31:0] STACKADDR  = DMEM_BASE_ADDR + DMEM_BYTES;
    localparam logic [31:0] IMEM_BYTES = IMEM_WORDS * 4;

    logic        trap;
    logic        mem_valid;
    logic        mem_instr;
    logic        mem_ready;
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [3:0]  mem_wstrb;
    logic [31:0] mem_rdata;

    logic [31:0] imem_rdata;
    logic [31:0] dmem_rdata;
    logic [31:0] uart_rdata;
    logic [31:0] timer_rdata;
    logic [31:0] button_rdata;
    logic        imem_ready;
    logic        dmem_ready;
    logic        uart_ready;
    logic        timer_ready;
    logic        button_ready;
    logic        invalid_ready;

    logic        mem_we;
    logic        imem_hit;
    logic        dmem_hit;
    logic        uart_hit;
    logic        timer_hit;
    logic        button_hit;

    logic [2:0]  buttons_meta;
    logic [2:0]  buttons_sync;

    localparam logic [31:0] UART_BASE    = 32'h4000_0000;
    localparam logic [31:0] UART_TXDATA  = UART_BASE + 32'h0000_0000;
    localparam logic [31:0] UART_STATUS  = UART_BASE + 32'h0000_0004;
    localparam logic [31:0] UART_RXDATA  = UART_BASE + 32'h0000_0008;
    localparam logic [31:0] TIMER_BASE   = 32'h4000_0010;
    localparam logic [31:0] TIMER_STATUS = TIMER_BASE + 32'h0000_0000;
    localparam logic [31:0] TIMER_VALUE  = TIMER_BASE + 32'h0000_0004;
    localparam logic [31:0] BUTTON_BASE   = 32'h4000_0020;
    localparam logic [31:0] BUTTON_STATUS = BUTTON_BASE + 32'h0000_0000;

    assign mem_we   = |mem_wstrb;
    assign imem_hit = (mem_addr < IMEM_BYTES) && !mem_we;
    assign dmem_hit = (mem_addr >= DMEM_BASE_ADDR) && (mem_addr < (DMEM_BASE_ADDR + DMEM_BYTES));
    assign uart_hit = (mem_addr == UART_TXDATA) || (mem_addr == UART_STATUS) || (mem_addr == UART_RXDATA);
    assign timer_hit = (mem_addr == TIMER_STATUS) || (mem_addr == TIMER_VALUE);
    assign button_hit = (mem_addr == BUTTON_STATUS);

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            buttons_meta <= 3'b000;
            buttons_sync <= 3'b000;
        end else begin
            buttons_meta <= buttons;
            buttons_sync <= buttons_meta;
        end
    end

    assign button_rdata = {29'd0, buttons_sync};
    assign button_ready = mem_valid && button_hit;

    picorv32 #(
        .ENABLE_COUNTERS    (1'b0),
        .ENABLE_COUNTERS64  (1'b0),
        .ENABLE_IRQ         (1'b0),
        .ENABLE_IRQ_TIMER   (1'b0),
        .ENABLE_MUL         (1'b0),
        .ENABLE_FAST_MUL    (1'b0),
        .ENABLE_DIV         (1'b0),
        .COMPRESSED_ISA     (1'b0),
        .REGS_INIT_ZERO     (1'b1),
        .PROGADDR_RESET     (32'h0000_0000),
        .PROGADDR_IRQ       (32'h0000_0010),
        .STACKADDR          (STACKADDR)
    ) u_cpu (
        .clk          (clk),
        .resetn       (resetn),
        .trap         (trap),
        .mem_valid    (mem_valid),
        .mem_instr    (mem_instr),
        .mem_ready    (mem_ready),
        .mem_addr     (mem_addr),
        .mem_wdata    (mem_wdata),
        .mem_wstrb    (mem_wstrb),
        .mem_rdata    (mem_rdata),
        .mem_la_read  (),
        .mem_la_write (),
        .mem_la_addr  (),
        .mem_la_wdata (),
        .mem_la_wstrb (),
        .pcpi_valid   (),
        .pcpi_insn    (),
        .pcpi_rs1     (),
        .pcpi_rs2     (),
        .pcpi_wr      (1'b0),
        .pcpi_rd      (32'd0),
        .pcpi_wait    (1'b0),
        .pcpi_ready   (1'b0),
        .irq          (32'd0),
        .eoi          ()
    );

    imem #(
        .WORDS   (IMEM_WORDS),
        .MEMFILE (IMEM_HEX)
    ) u_imem (
        .addr  (mem_addr),
        .rdata (imem_rdata)
    );

    dmem #(
        .BASE_ADDR (DMEM_BASE_ADDR),
        .BYTES     (DMEM_BYTES)
    ) u_dmem (
        .clk   (clk),
        .valid (mem_valid),
        .we    (mem_we),
        .be    (mem_wstrb),
        .addr  (mem_addr),
        .wdata (mem_wdata),
        .rdata (dmem_rdata),
        .ready (dmem_ready)
    );

    uart #(
        .CLK_HZ (CLK_HZ),
        .BAUD   (UART_BAUD)
    ) u_uart (
        .clk          (clk),
        .rst          (!resetn),
        .bus_valid    (mem_valid),
        .bus_we       (mem_we),
        .bus_addr     (mem_addr),
        .bus_wdata    (mem_wdata),
        .bus_rdata    (uart_rdata),
        .bus_ready    (uart_ready),
        .rx           (uart_rxd),
        .tx           (uart_txd)
    );

    timer #(
        .DEFAULT_PERIOD_CYCLES (TIMER_TICK_CYCLES)
    ) u_timer (
        .clk              (clk),
        .rst              (!resetn),
        .bus_valid        (mem_valid),
        .bus_we           (mem_we),
        .bus_addr         (mem_addr),
        .bus_wdata        (mem_wdata),
        .bus_rdata        (timer_rdata),
        .bus_ready        (timer_ready)
    );

    // invalid_ready is based on address hits instead of ready signals so an
    // MMIO access can stall correctly when the targeted peripheral is busy.
    assign imem_ready    = mem_valid && imem_hit;
    assign invalid_ready = mem_valid && !(imem_hit || dmem_hit || uart_hit || timer_hit || button_hit);

    assign mem_ready = imem_ready | dmem_ready | uart_ready | timer_ready | button_ready | invalid_ready;
    assign mem_rdata = imem_ready  ? imem_rdata :
                       dmem_ready  ? dmem_rdata :
                       uart_ready  ? uart_rdata :
                       timer_ready ? timer_rdata :
                       button_ready ? button_rdata :
                       32'd0;



endmodule
