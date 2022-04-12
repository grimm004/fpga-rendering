`default_nettype none
`timescale 1ns / 1ps

import Utils::vert;
import Utils::vert2i;

module interp_gradient #(
    parameter CORDW=16
    ) (
    input wire logic clk,
    vert2i v0,
    vert2i v1,
    vert2i v2,
    output logic signed [CORDW-1:0] dc_dx, dc_dy
//    output logic busy
    );
    
//    logic ready_x, ready_y;
    
//    assign busy = ~ready;

    logic signed [CORDW-1:0] dc_x;
    logic signed [CORDW-1:0] dc_y;
    logic signed [CORDW-1:0] dx;
    logic signed [CORDW-1:0] dy;

    always_comb dc_x = (v1.c - v2.c) * (v0.y - v2.y) - (v0.c - v2.c) * (v1.y - v2.y);
    always_comb dc_y = (v1.c - v2.c) * (v0.x - v2.x) - (v0.c - v2.c) * (v1.x - v2.x);
    always_comb dx =   (v1.x - v2.x) * (v0.y - v2.y) - (v0.x - v2.x) * (v1.y - v2.y);
    always_comb dy = -dx;
    
    div div_x (
        .aclk(clk), // input clk
//        .rfd(ready_x), // ouput rfd
        .s_axis_dividend_tdata(dc_x), // input dividend
        .s_axis_divisor_tdata(dx), // input divisor
        .m_axis_dout_tdata(dc_dx) // ouput quotient
    );
    
    div div_y (
        .aclk(clk), // input clk
//        .rfd(ready_y), // ouput rfd
        .s_axis_dividend_tdata(dc_y), // input dividend
        .s_axis_divisor_tdata(dy), // input divisor
        .m_axis_dout_tdata(dc_dy) // ouput quotient
    );
endmodule
