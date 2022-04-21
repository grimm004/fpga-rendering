// Project F Library - Draw Filled Triangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

import Utils::coli;
import Utils::colf;
import Utils::valf;
import Utils::vec2i;
import Utils::vec2f;
import Utils::vert2i;
import Utils::vert2f;

module draw_triangle_fill #(
    parameter CORDW=16  // signed coordinate width
    ) (
    input  wire logic  clk,            // clock
    input  wire logic  rst,            // reset
    input  wire logic  start,          // start triangle drawing
    input  wire logic  oe,             // output enable
    input  wire vert2i v0, v1, v2,     // Triangle vertices
    output      vec2i  draw_pos,       // drawing position
    output      coli   col,            // Drawing colour
    output      logic  drawing,        // actively drawing
    output      logic  busy,           // drawing request in progress
    output      logic  done            // drawing is complete (high for one tick)
    );

    colf cur_col, prev_col;

//    assign col = {cur_col.r[3:0], cur_col.g[3:0], cur_col.b[3:0]};

    // sorted input vertices
    vert2i v0s, v1s, v2s;

    vert2f v0sf, v1sf, v2sf;

    assign v0sf = {{v0s.x, 16'b0}, {v0s.y, 16'b0}, {{12'b0, v0s.col.r, 16'b0}, {12'b0, v0s.col.g, 16'b0}, {12'b0, v0s.col.b, 16'b0}}};
    assign v1sf = {{v1s.x, 16'b0}, {v1s.y, 16'b0}, {{12'b0, v1s.col.r, 16'b0}, {12'b0, v1s.col.g, 16'b0}, {12'b0, v1s.col.b, 16'b0}}};
    assign v2sf = {{v2s.x, 16'b0}, {v2s.y, 16'b0}, {{12'b0, v2s.col.r, 16'b0}, {12'b0, v2s.col.g, 16'b0}, {12'b0, v2s.col.b, 16'b0}}};

    logic signed [15:0] dx, dy;

    assign dx = xa - prev_xa;
    assign dy = yb - prev_y;

//    assign cur_col = v0sf.col;

    logic ig_start;
    logic [0:2] ig_busy;
    vec2f dr_d, dg_d, db_d;

    interp_gradient ig_r (
        .clk,
        .start(ig_start),
        .v0({v0sf.x, v0sf.y, v0sf.col.r}),
        .v1({v1sf.x, v1sf.y, v1sf.col.r}),
        .v2({v2sf.x, v2sf.y, v2sf.col.r}),
        .dz_dx(dr_d.x),
        .dz_dy(dr_d.y),
        .busy(ig_busy[0]),
        .done()
    );

    interp_gradient ig_g (
        .clk,
        .start(ig_start),
        .v0({v0sf.x, v0sf.y, v0sf.col.g}),
        .v1({v1sf.x, v1sf.y, v1sf.col.g}),
        .v2({v2sf.x, v2sf.y, v2sf.col.g}),
        .dz_dx(dg_d.x),
        .dz_dy(dg_d.y),
        .busy(ig_busy[1]),
        .done()
    );

    interp_gradient ig_b (
        .clk,
        .start(ig_start),
        .v0({v0sf.x, v0sf.y, v0sf.col.b}),
        .v1({v1sf.x, v1sf.y, v1sf.col.b}),
        .v2({v2sf.x, v2sf.y, v2sf.col.b}),
        .dz_dx(db_d.x),
        .dz_dy(db_d.y),
        .busy(ig_busy[2]),
        .done()
    );

    // line coordinates
    vert2i v0a, v1a;
    logic signed [CORDW-1:0] xa, ya;
    vert2i v0b, v1b;
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
    enum {
        IDLE,
        SORT_0, SORT_1, SORT_2,
        INIT_A,
        INIT_B0, INIT_B1,
        START_A, START_B, START_H,
        EDGE,
        H_LINE,
        DONE
    } state;
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

                // Whilst we run INIT_A and INIT_B0, calculate the gradients
                ig_start <= 1;
            end
            // Now v0s.y <= v1s.y <= v2s.y
            INIT_A: begin
                state <= INIT_B0;
                v0a <= v0s;
                v1a <= v2s;
                prev_xa <= v0s.x;
                prev_xb <= v0s.x;
            end
            INIT_B0: begin
                b_edge <= 0;
                v0b <= v0s;
                v1b <= v1s;
                prev_y <= v0s.y;

                // Init current and previous colour to first vertex
                cur_col  <= v0sf.col;
                prev_col <= v0sf.col;

                // Move to START_A when gradients are calculated
                ig_start <= 0;
                if (!ig_busy)
                    state <= START_A;
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
                    // ya == yb == prev_y
                    state <= START_H;
                    x0h <= (prev_xa > prev_xb) ? prev_xb : prev_xa;  // always draw...
                    x1h <= (prev_xa > prev_xb) ? prev_xa : prev_xb;  // left to right
                    cur_col <= prev_col;
                end
            end
            START_H: state <= H_LINE;
            H_LINE: begin
                cur_col.r <= cur_col.r - dr_d.x;
                cur_col.g <= cur_col.g - dg_d.x;
                cur_col.b <= cur_col.b - db_d.x;
 
                if (!busy_h) begin
                    prev_y <= yb;  // safe to update previous values once h-line done
                    prev_xa <= xa;
                    prev_xb <= xb;

                    prev_col.r <= prev_col.r + dy * dr_d.y + dx * dr_d.x;
                    prev_col.g <= prev_col.g + dy * dg_d.y + dx * dg_d.x;
                    prev_col.b <= prev_col.b + dy * db_d.y + dx * db_d.x;

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
        draw_pos.x <= xh;
        draw_pos.y <= prev_y;
        col <= {cur_col.r[3:0], cur_col.g[3:0], cur_col.b[3:0]};
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
endmodule
