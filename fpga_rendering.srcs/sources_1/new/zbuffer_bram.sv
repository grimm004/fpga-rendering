// Project F Library - Draw Filled Triangle
// (C)2021 Will Green, open source hardware released under the MIT License
// Modified by Max Grimmett
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

module zbuffer_bram #(
    parameter WIDTH=640,      // Buffer width
    parameter HEIGHT=480       // Buffer height
    ) (
    input  wire logic clk,    // Input system clock
    input  wire vec2i pos,    // Pixel position
    input  wire valf  z,      // Interpolated z-position for pixel
    output      logic render  // Flag for whether to render the current pixel
    );

    

    bram_sdp #(
        .WIDTH(32),
        .DEPTH(WIDTH * HEIGHT)
    ) buffer_memory (
        .clk_write(clk),
        .clk_read(clk),
        .we(0),
        .addr_write(0),
        .addr_read(0),
        .data_in(),
        .data_out()
    );

endmodule
