// Project F Library - Draw Filled Triangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

import Utils::coli;
import Utils::vert;

module draw_triangle_fill #(
    parameter CORDW=16,
    parameter CHANW=4
    ) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start triangle drawing
    input  wire logic oe,              // output enable
    vert v0,
    vert v1,
    vert v2,
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      wire coli col,  // Drawing colour
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    // Take colour of first vertex
    assign col = v0s.col;

//    logic signed [CORDW-1:0] dc_dx_r, dc_dy_r;
//    logic signed [CORDW-1:0] dc_dx_g, dc_dy_g;
//    logic signed [CORDW-1:0] dc_dx_b, dc_dy_b;

    // sorted input vertices
    vert v0s, v1s, v2s;

    // line coordinates
    vert v0a, v1a;
    logic signed [CORDW-1:0] xa, ya;
    vert v0b, v1b;
    logic signed [CORDW-1:0] xb, yb;
    logic signed [CORDW-1:0] x0h, x1h, xh;

    // previous y-value for edges
    logic signed [CORDW-1:0] prev_y;

    // previous x-values for horizontal line
    logic signed [CORDW-1:0] prev_xa;
    logic signed [CORDW-1:0] prev_xb;

    // line control signals
    logic oe_a, oe_b, oe_h;
    logic drawing_h;
    logic busy_a, busy_b, busy_h;
    logic b_edge;  // which B edge are we drawing?

    // pipeline completion signals to match coordinates
    logic busy_p1, done_p1;

    // draw state machine
    enum {IDLE, SORT_0, SORT_1, SORT_2, INIT_A, INIT_B0, INIT_B1,
            START_A, START_B, START_H, EDGE, H_LINE, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            SORT_0: begin
                state <= SORT_1;
                if (v0.y > v2.y) begin
                    v0s <= v2;
                    v2s <= v0;
                end else begin
                    v0s <= v0;
                    v2s <= v2;
                end
            end
            SORT_1: begin
                state <= SORT_2;
                if (v0s.y > v1.y) begin
                    v0s <= v1;
                    v1s <= v0s;
                end else begin
                    v1s <= v1;
                end
            end
            SORT_2: begin
                state <= INIT_A;
                if (v1s.y > v2s.y) begin
                    v1s <= v2s;
                    v2s <= v1s;
                end
            end
            INIT_A: begin
                state <= INIT_B0;
                v0a <= v0s;
                v1a <= v2s;
                prev_xa <= v0s.x;
                prev_xb <= v0s.x;
            end
            INIT_B0: begin
                state <= START_A;
                b_edge <= 0;
                v0b <= v0s;
                v1b <= v1s;
                prev_y <= v0s.y;
            end
            INIT_B1: begin
                state <= START_B;  // we don't need to start A again
                b_edge <= 1;
                v0b <= v1s;
                v1b <= v2s;
                prev_y <= v1s.y;
            end
            START_A: state <= START_B;
            START_B: state <= EDGE;
            EDGE: begin
                if ((ya != prev_y || !busy_a) && (yb != prev_y || !busy_b)) begin
                    state <= START_H;
                    x0h <= (prev_xa > prev_xb) ? prev_xb : prev_xa;  // always draw...
                    x1h <= (prev_xa > prev_xb) ? prev_xa : prev_xb;  // left to right
                end
            end
            START_H: state <= H_LINE;
            H_LINE: begin
                if (!busy_h) begin
                    prev_y <= yb;  // safe to update previous values once h-line done
                    prev_xa <= xa;
                    prev_xb <= xb;
                    if (!busy_b) begin
                        state <= (busy_a && b_edge == 0) ? INIT_B1 : DONE;
                    end else state <= EDGE;
                end
            end
            DONE: begin
                state <= IDLE;
                done_p1 <= 1;
                busy_p1 <= 0;
            end
            default: begin  // IDLE
                if (start) begin
                    state <= SORT_0;
                    busy_p1 <= 1;
                end
                done_p1 <= 0;
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy_p1 <= 0;
            done_p1 <= 0;
            b_edge <= 0;
        end
    end

    always_comb begin
        oe_a = (state == EDGE && ya == prev_y);
        oe_b = (state == EDGE && yb == prev_y);
        oe_h = oe;
    end

    // register output
    always_ff @(posedge clk) begin
        x <= xh;
        y <= prev_y;
        drawing <= drawing_h;
        busy <= busy_p1;
        done <= done_p1;
    end

    draw_line #(.CORDW(CORDW)) draw_edge_a (
        .clk,
        .rst,
        .start(state == START_A),
        .oe(oe_a),
        .x0(v0a.x),
        .y0(v0a.y),
        .x1(v1a.x),
        .y1(v1a.y),
        .x(xa),
        .y(ya),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
        .busy(busy_a),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    draw_line #(.CORDW(CORDW)) draw_edge_b (
        .clk,
        .rst,
        .start(state == START_B),
        .oe(oe_b),
        .x0(v0b.x),
        .y0(v0b.y),
        .x1(v1b.x),
        .y1(v1b.y),
        .x(xb),
        .y(yb),
        /* verilator lint_off PINCONNECTEMPTY */
        .drawing(),
        .busy(busy_b),
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    draw_line_1d #(.CORDW(CORDW)) draw_h_line (
        .clk,
        .rst,
        .start(state == START_H),
        .oe(oe_h),
        .x0(x0h),
        .x1(x1h),
        .x(xh),
        .drawing(drawing_h),
        .busy(busy_h),
        /* verilator lint_off PINCONNECTEMPTY */
        .done()
        /* verilator lint_on PINCONNECTEMPTY */
    );

//    interp_gradient #(.CORDW(CORDW)) grad_r (
//        .clk,
//        .v0({v0s.x, v0s.y, v0s.col.r}),
//        .v1({v1s.x, v1s.y, v1s.col.r}),
//        .v2({v2s.x, v2s.y, v2s.col.r}),
//        .dc_dx(dc_dx_r),
//        .dc_dy(dc_dy_r)
//    );

//    interp_gradient #(.CORDW(CORDW)) grad_g (
//        .clk,
//        .v0({v0s.x, v0s.y, v0s.col.g}),
//        .v1({v1s.x, v1s.y, v1s.col.g}),
//        .v2({v2s.x, v2s.y, v2s.col.g}),
//        .dc_dx(dc_dx_g),
//        .dc_dy(dc_dy_g)
//    );

//    interp_gradient #(.CORDW(CORDW)) grad_b (
//        .clk,
//        .v0({v0s.x, v0s.y, v0s.col.b}),
//        .v1({v1s.x, v1s.y, v1s.col.b}),
//        .v2({v2s.x, v2s.y, v2s.col.b}),
//        .dc_dx(dc_dx_b),
//        .dc_dy(dc_dy_b)
//    );
endmodule
