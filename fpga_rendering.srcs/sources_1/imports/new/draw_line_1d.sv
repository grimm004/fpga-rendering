// Project F Library - Draw 1D Line (assumes x1 >= x0)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

import Utils::valf;
import Utils::gradients;
import Utils::interpolants;

module draw_line_1d #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start line drawing
    input  wire logic oe,              // output enable
//    input  wire gradients grads,       // Interpolant gradients
    input  wire interpolants interp0, interp1, // Interpolant values
    input  wire logic signed [CORDW-1:0] x0,   // point 0
    input  wire logic signed [CORDW-1:0] x1,   // point 1
    output      logic signed [CORDW-1:0] x,    // drawing position
    output      interpolants interp,   // Interpolant values
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    valf lerp_amt, lerp_step;
    logic div_start, div_done;

    qdiv interp_div (
        .clk,
        .start(div_start),
        .dividend(32'b0000000000000001_0000000000000000),
        .divisor({x1 - x0, {16{1'b0}}}),
        .quotient_out(lerp_step),
        .done(div_done),
        .complete(),
        .overflow()
    );

    logic ce, ma_start, ma_done;
    logic signed [31:-32] c_r, c_g, c_b;
    logic signed [31:-32] p_r, p_g, p_b;

    assign c_r = {{16{1'b0}}, interp0.col.r[15:-16], {16{1'b0}}};
    assign c_g = {{16{1'b0}}, interp0.col.g[15:-16], {16{1'b0}}};
    assign c_b = {{16{1'b0}}, interp0.col.b[15:-16], {16{1'b0}}};

    logic subtract = 1'b0;
    logic sclr = 1'b0;

    multadd mar (
        .CLK(clk),
        .A(lerp_amt),
        .B(interp1.col.r - interp0.col.r),
        .C(c_r),
        .SUBTRACT(subtract),
        .CE(ce),
        .SCLR(sclr),
        .PCOUT(),
        .P(p_r)
    );

    multadd mag (
        .CLK(clk),
        .A(lerp_amt),
        .B(interp1.col.g - interp0.col.g),
        .C(c_g),
        .SUBTRACT(subtract),
        .CE(ce),
        .SCLR(sclr),
        .PCOUT(),
        .P(p_g)
    );

    multadd mab (
        .CLK(clk),
        .A(lerp_amt),
        .B(interp1.col.b - interp0.col.b),
        .C(c_b),
        .SUBTRACT(subtract),
        .CE(ce),
        .SCLR(sclr),
        .PCOUT(),
        .P(p_b)
    );

    clock_counter #(.COUNT(17)) clk_cnt (
        .clk,
        .start(ma_start),
        .busy(),
        .done(ma_done),
        .ce,
        .oe()
    );

    // draw state machine
    enum {IDLE, DIV, MUL, DRAW} state;
    always_ff @(posedge clk) begin
        case (state)
            DIV: begin
                div_start <= 0;
                if (div_done) begin
                    state <= MUL;
                    ma_start <= 1;
                end
            end
            MUL: begin
                ma_start <= 0;
                if (ma_done)
                    state <= DRAW;
            end
            DRAW: begin
                if (oe) begin
                    if (x == x1) begin
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        x <= x + 1;
                        interp.col.r[15:-16] <= p_r[15:-16];
                        interp.col.g[15:-16] <= p_g[15:-16];
                        interp.col.b[15:-16] <= p_b[15:-16];
                        ma_start <= 1;
                        lerp_amt <= lerp_amt + lerp_step;
                        state <= MUL;
                    end
                end
            end
            default: begin  // IDLE
                done <= 0;
                lerp_amt <= 0;
                if (start) begin
                    state <= DIV;
                    div_start <= 1;
                    x <= x0;
                    interp <= interp0;
                    busy <= 1;
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
        end
    end

    always_comb drawing = (state == DRAW && oe);
endmodule
