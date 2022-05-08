// Project F Library - Draw Line
// (C)2021 Will Green, open source hardware released under the MIT License
// Modified by Max Grimmett
// Learn more at https://projectf.io

// Based on algorithm from The Beauty of Bresenham's Algorithm by Alois Zingl
// http://members.chello.at/~easyfilter/bresenham.html

`default_nettype none
`timescale 1ns / 1ps

import Utils::colf;
import Utils::gradients;
import Utils::interpolants;

module draw_line #(parameter CORDW=16) (  // signed coordinate width
    input  wire logic clk,             // clock
    input  wire logic rst,             // reset
    input  wire logic start,           // start line drawing
    input  wire logic oe,              // output enable
    input  wire gradients grads,       // Interpolant gradients
    input  wire interpolants interp0, interp1,    // Interpolant values
    input  wire logic signed [CORDW-1:0] x0, y0,  // point 0
    input  wire logic signed [CORDW-1:0] x1, y1,  // point 1
    output      logic signed [CORDW-1:0] x,  y,   // drawing position
    output      interpolants interp, // Interpolant values
    output      logic drawing,         // actively drawing
    output      logic busy,            // drawing request in progress
    output      logic done             // drawing is complete (high for one tick)
    );

    interpolants interp_sorted;
//    gradients grads_sorted;

    // line properties
    logic swap;   // swap points to ensure y1 >= y0
    logic right;  // drawing direction
    logic signed [CORDW-1:0] xa, ya;  // start point
    logic signed [CORDW-1:0] xb, yb;  // end point
    logic signed [CORDW-1:0] x_end, y_end;  // register end point
    always_comb begin
        swap = (y0 > y1);  // swap points if y0 is below y1
        xa = swap ? x1 : x0;
        xb = swap ? x0 : x1;
        ya = swap ? y1 : y0;
        yb = swap ? y0 : y1;
        interp_sorted = swap ? interp1 : interp0;
    end

    // error values
    logic signed [CORDW:0] err;  // a bit wider as signed
    logic signed [CORDW:0] dx, dy;
    logic movx, movy;  // horizontal/vertical move required
    always_comb begin
        movx = (2*err >= dy);
        movy = (2*err <= dx);
    end

    // draw state machine
    enum {IDLE, INIT_0, INIT_1, DRAW} state;
    always_comb drawing = (state == DRAW && oe);

    always_ff @(posedge clk) begin
        case (state)
            DRAW: begin
                if (oe) begin
                    if (x == x_end && y == y_end) begin
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        if (movx) begin
                            x <= right ? x + 1 : x - 1;
                            err <= err + dy;

                            // Step interpolants in x
                            interp.col.r <= right ? interp.col.r + grads.col_x.r : interp.col.r - grads.col_x.r;
                            interp.col.g <= right ? interp.col.g + grads.col_x.g : interp.col.g - grads.col_x.g;
                            interp.col.b <= right ? interp.col.b + grads.col_x.b : interp.col.b - grads.col_x.b;
//                            interp.col.r <= interp.col.r + grads_sorted.col_x.r;
//                            interp.col.g <= interp.col.g + grads_sorted.col_x.g;
//                            interp.col.b <= interp.col.b + grads_sorted.col_x.b;
                        end
                        if (movy) begin
                            y <= y + 1;  // always down
                            err <= err + dx;

                            // Step interpolants in y
                            interp.col.r <= interp.col.r + grads.col_y.r;
                            interp.col.g <= interp.col.g + grads.col_y.g;
                            interp.col.b <= interp.col.b + grads.col_y.b;
//                            interp.col.r <= interp.col.r + grads_sorted.col_y.r;
//                            interp.col.g <= interp.col.g + grads_sorted.col_y.g;
//                            interp.col.b <= interp.col.b + grads_sorted.col_y.b;
                        end
                        if (movx && movy) begin
                            x <= right ? x + 1 : x - 1;
                            y <= y + 1;
                            err <= err + dy + dx;

                            // Step interpolants in x and y
                            interp.col.r <= interp.col.r + grads.col_y.r + (right ? grads.col_x.r : -grads.col_x.r);
                            interp.col.g <= interp.col.g + grads.col_y.g + (right ? grads.col_x.g : -grads.col_x.g);
                            interp.col.b <= interp.col.b + grads.col_y.b + (right ? grads.col_x.b : -grads.col_x.b);
//                            interp.col.r <= interp.col.r + grads_sorted.col_y.r + grads_sorted.col_x.r;
//                            interp.col.g <= interp.col.g + grads_sorted.col_y.g + grads_sorted.col_x.g;
//                            interp.col.b <= interp.col.b + grads_sorted.col_y.b + grads_sorted.col_x.b;
                        end
                    end
                end
            end
            INIT_0: begin
                state <= INIT_1;
                dx <= right ? xb - xa : xa - xb;  // dx = abs(xb - xa)
                dy <= ya - yb;  // dy = -abs(yb - ya)

//                grads_sorted <= grads;

//                grads_sorted.col_x.r <= right ? grads.col_x.r : -grads.col_x.r;
//                grads_sorted.col_x.g <= right ? grads.col_x.g : -grads.col_x.g;
//                grads_sorted.col_x.b <= right ? grads.col_x.b : -grads.col_x.b;

//                grads_sorted.col_y.r <= grads.col_y.r;
//                grads_sorted.col_y.g <= grads.col_y.g;
//                grads_sorted.col_y.b <= grads.col_y.b;
            end
            INIT_1: begin
                state <= DRAW;
                err <= dx + dy;
                x <= xa;
                y <= ya;
                x_end <= xb;
                y_end <= yb;
                interp <= interp_sorted;
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= INIT_0;
                    right <= (xa < xb);  // draw right to left?
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
endmodule
