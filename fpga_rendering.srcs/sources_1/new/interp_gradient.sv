`default_nettype none
`timescale 1ns / 1ps

import Utils::vert2i;
import Utils::valf;

module interp_gradient (
    input  wire logic clk,
    input  wire logic start,
    input  wire vert2i v0,
    input  wire vert2i v1,
    input  wire vert2i v2,
    output      valf dc_dx, dc_dy,
    output      logic busy,
    output      logic done
    );

    valf dc_x;
    valf dc_y;
    valf dx;
    valf dy;
    valf dc_dx_r;
    valf dc_dy_r;

    always_comb dc_x = (v1.c - v2.c) * (v0.y - v2.y) - (v0.c - v2.c) * (v1.y - v2.y);
    always_comb dc_y = (v1.c - v2.c) * (v0.x - v2.x) - (v0.c - v2.c) * (v1.x - v2.x);
    always_comb dx   = (v1.x - v2.x) * (v0.y - v2.y) - (v0.x - v2.x) * (v1.y - v2.y);
    always_comb dy   = -dx;

    logic div_start;
    logic [1:0] div_done;

    qdiv div_x (
        .clk,
        .start(div_start),
        .dividend(dc_x), 
        .divisor(dx),
        .quotient_out(dc_dx_r),
        .done(div_done[0]),
        .complete(),
        .overflow()
    );

    qdiv div_y (
        .clk,
        .start(div_start),
        .dividend(dc_y),
        .divisor(dy),
        .quotient_out(dc_dy_r),
        .done(div_done[1]),
        .complete(),
        .overflow()
    );

    enum {IDLE, CALCULATING, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                busy <= 0;
                done <= 0;

                if (start) begin
                    div_start <= 1;
                    state <= CALCULATING;
                    busy <= 1;
                end
            end
            CALCULATING: begin
                div_start <= 0;

                if (div_done == '1)
                    state <= DONE;
            end
            DONE: begin
                dc_dx <= dc_dx_r;
                dc_dy <= dc_dy_r;

                done <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
