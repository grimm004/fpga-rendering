`default_nettype none
`timescale 1ns / 1ps

import Utils::vec4f;
import Utils::valf;

module dot4f(
    input wire logic clk,
    input wire logic start,
    input wire vec4f a,
    input wire vec4f b,
    output     valf  o,
    output     logic busy,
    output     logic done
    );

    valf veca [0:3];
    valf vecb [0:3];
    logic signed [31:-32] acc;

    assign {veca[0], veca[1], veca[2], veca[3]} = a;
    assign {vecb[0], vecb[1], vecb[2], vecb[3]} = b;

    logic subtract = 1'b0;
    logic sclr = 1'b0;

    logic [1:0] i;
    logic ma_start;
    logic ma_done;
    logic ce;
    logic [31:-32] ma_p;

    multadd ma (
        .CLK(clk),
        .A(veca[i]),
        .B(vecb[i]),
        .C(acc),
        .SUBTRACT(subtract),
        .CE(ce),
        .SCLR(sclr),
        .PCOUT(),
        .P(ma_p)
    );

    clock_counter #(.COUNT(17)) clk_cnt (
        .clk,
        .start(ma_start),
        .busy(),
        .done(ma_done),
        .ce,
        .oe()
    );

    enum {IDLE, PROCESSING, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 0;
                busy <= 0;
                i    <= 0;
                acc  <= 0;
                
                if (start) begin
                    ma_start <= 1;
                    busy <= 1;
                    state <= PROCESSING;
                end
            end
            PROCESSING: begin
                ma_start <= 0;

                if (ma_done) begin
                    acc <= ma_p;

                    if (i == 2'd3) begin
                        state <= DONE;
                    end else begin
                        i <= i + 1;
                        ma_start <= 1;
                        state <= PROCESSING;
                    end
                end
            end
            DONE: begin
                o <= acc[15:-16];
                state <= IDLE;
                done <= 1;
            end
        endcase
    end

endmodule
