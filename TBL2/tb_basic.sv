`timescale 1ns / 1ps

module tb_basic;

    localparam int unsigned CLK_HZ            = 20;
    localparam int unsigned UART_BAUD         = 5;
    localparam int unsigned TIMER_TICK_CYCLES = 1000;
    localparam int unsigned BAUD_DIVIDE       = (CLK_HZ + (UART_BAUD / 2)) / UART_BAUD;
    localparam time         CLK_PERIOD        = 10ns;
    localparam integer LINE_ID_000000 = 0;
    localparam integer LINE_ID_000001 = 1;
    localparam integer LINE_ID_000100 = 2;
    localparam integer LINE_ID_010000 = 3;
    localparam integer LINE_ID_000055 = 4;
    localparam integer LINE_ID_005955 = 5;
    localparam integer LINE_ID_235955 = 6;

    logic clk      = 1'b0;
    logic resetn   = 1'b0;
    logic [2:0] buttons  = 3'b000;
    logic uart_rxd = 1'b1;
    logic uart_txd;

    picorv32_soc_ref #(
        .CLK_HZ            (CLK_HZ),
        .UART_BAUD         (UART_BAUD),
        .TIMER_TICK_CYCLES (TIMER_TICK_CYCLES)
    ) dut (
        .clk      (clk),
        .resetn   (resetn),
        .buttons  (buttons),
        .uart_rxd (uart_rxd),
        .uart_txd (uart_txd)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    function automatic [7:0] get_line_char;
        input integer line_id;
        input integer index;
        begin
            case (line_id)
                LINE_ID_000000: begin
                    case (index)
                        0, 1, 3, 4, 6, 7: get_line_char = 8'h30;
                        2, 5:             get_line_char = 8'h3a;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                LINE_ID_000001: begin
                    case (index)
                        0, 1, 3, 4, 6:    get_line_char = 8'h30;
                        2, 5:             get_line_char = 8'h3a;
                        7:                get_line_char = 8'h31;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                LINE_ID_000100: begin
                    case (index)
                        0, 1, 3, 6, 7:    get_line_char = 8'h30;
                        2, 5:             get_line_char = 8'h3a;
                        4:                get_line_char = 8'h31;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                LINE_ID_010000: begin
                    case (index)
                        0, 3, 4, 6, 7:    get_line_char = 8'h30;
                        1:                get_line_char = 8'h31;
                        2, 5:             get_line_char = 8'h3a;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                LINE_ID_000055: begin
                    case (index)
                        0, 1, 3, 4:       get_line_char = 8'h30;
                        2, 5:             get_line_char = 8'h3a;
                        6, 7:             get_line_char = 8'h35;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                LINE_ID_005955: begin
                    case (index)
                        0, 1, 6:          get_line_char = 8'h30;
                        2, 5:             get_line_char = 8'h3a;
                        3, 4, 7:          get_line_char = 8'h35;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                LINE_ID_235955: begin
                    case (index)
                        0:                get_line_char = 8'h32;
                        1, 3, 4, 6:       get_line_char = 8'h33;
                        2, 5:             get_line_char = 8'h3a;
                        7:                get_line_char = 8'h35;
                        8:                get_line_char = 8'h0d;
                        9:                get_line_char = 8'h0a;
                        default:          get_line_char = 8'hxx;
                    endcase
                end
                default: get_line_char = 8'hxx;
            endcase
        end
    endfunction

    task automatic fail;
        input [8*64-1:0] message;
        begin
            $display("FAIL: %0s (time=%0t)", message, $time);
            $fatal(1);
        end
    endtask

    task automatic wait_clocks;
        input integer count;
        begin
            repeat (count) @(posedge clk);
        end
    endtask

    task automatic apply_reset;
        begin
            resetn   = 1'b0;
            buttons  = 3'b000;
            uart_rxd = 1'b1;
            wait_clocks(8);
            resetn = 1'b1;
        end
    endtask

    task automatic wait_for_uart_start;
        input integer case_id;
        integer cycles_waited;
        begin
            cycles_waited = 0;
            while (uart_txd !== 1'b0) begin
                @(posedge clk);
                cycles_waited += 1;
                if (cycles_waited > (TIMER_TICK_CYCLES * 4)) begin
                    $display("FAIL: case %0d timed out waiting for UART start bit (time=%0t)", case_id, $time);
                    $fatal(1);
                end
            end
        end
    endtask

    task automatic uart_recv_byte;
        output [7:0] data;
        input integer case_id;
        integer i;
        begin
            data = 8'h00;
            wait_for_uart_start(case_id);

            wait_clocks(BAUD_DIVIDE / 2);
            if (uart_txd !== 1'b0) begin
                $display("FAIL: case %0d invalid start bit sample (time=%0t)", case_id, $time);
                $fatal(1);
            end

            for (i = 0; i < 8; i += 1) begin
                wait_clocks(BAUD_DIVIDE);
                data[i] = uart_txd;
            end

            wait_clocks(BAUD_DIVIDE);
            if (uart_txd !== 1'b1) begin
                $display("FAIL: case %0d invalid stop bit sample (time=%0t)", case_id, $time);
                $fatal(1);
            end
        end
    endtask

    task automatic expect_line;
        input integer case_id;
        input integer line_id;
        integer i;
        reg [7:0] got;
        reg [7:0] want;
        begin
            for (i = 0; i < 10; i += 1) begin
                uart_recv_byte(got, case_id);
                want = get_line_char(line_id, i);
                if (got !== want) begin
                    $display(
                        "FAIL: case %0d char %0d mismatch, expected 0x%02x got 0x%02x (time=%0t)",
                        case_id, i, want, got, $time
                    );
                    $fatal(1);
                end
            end

            $display("PASS: case %0d line matched", case_id);
        end
    endtask

    task automatic wait_for_poll_loop;
        int unsigned cycles_waited;
        begin
            cycles_waited = 0;
            while (!(dut.u_cpu.reg_pc == 32'h0000_0138 ||
                     dut.u_cpu.reg_pc == 32'h0000_013c ||
                     dut.u_cpu.reg_pc == 32'h0000_0140)) begin
                @(posedge clk);
                cycles_waited += 1;
                if (cycles_waited > TIMER_TICK_CYCLES) begin
                    fail("CPU did not reach timer polling loop before next tick");
                end
            end
        end
    endtask

    task automatic seed_time_registers;
        input [31:0] hours;
        input [31:0] minutes;
        input [31:0] seconds;
        begin
            @(negedge clk);
            dut.u_cpu.cpuregs[18] = hours;
            dut.u_cpu.cpuregs[9]  = minutes;
            dut.u_cpu.cpuregs[8]  = seconds;
        end
    endtask

    task automatic pulse_button;
        input integer button_index;
        begin
            @(negedge clk);
            buttons[button_index] = 1'b1;
            wait_clocks(6);
            @(negedge clk);
            buttons[button_index] = 1'b0;
        end
    endtask

    task automatic run_case;
        input integer case_id;
        input        seed_before_tick;
        input [31:0] hours;
        input [31:0] minutes;
        input [31:0] seconds;
        input integer expected_line_id;
        begin
            apply_reset();
            expect_line((case_id * 10) + 1, LINE_ID_000000);

            if (seed_before_tick) begin
                wait_for_poll_loop();
                seed_time_registers(hours, minutes, seconds);
            end

            expect_line((case_id * 10) + 2, expected_line_id);
        end
    endtask

    task automatic run_button_case;
        input integer case_id;
        input integer button_index;
        input integer expected_line_id;
        begin
            apply_reset();
            expect_line((case_id * 10) + 1, LINE_ID_000000);
            wait_for_poll_loop();
            pulse_button(button_index);
            expect_line((case_id * 10) + 2, expected_line_id);
        end
    endtask

    initial begin
        if (BAUD_DIVIDE < 2) begin
            fail("BAUD_DIVIDE must be at least 2 for the UART sampler");
        end

        run_case(1, 1'b0, 32'd0, 32'd0, 32'd0, LINE_ID_000001);
        run_case(2, 1'b1, 32'd0, 32'd0, 32'd59, LINE_ID_000100);
        run_case(3, 1'b1, 32'd0, 32'd59, 32'd59, LINE_ID_010000);
        run_case(4, 1'b1, 32'd23, 32'd59, 32'd59, LINE_ID_000000);
        run_button_case(5, 0, LINE_ID_000055);
        run_button_case(6, 1, LINE_ID_005955);
        run_button_case(7, 2, LINE_ID_235955);

        $display("PASS: all todo6 directed cases");
        $finish;
    end

endmodule
