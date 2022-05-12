`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec3f;
import Utils::vec4f;
import Utils::valf;
import Utils::coli;
import Utils::colf;
import Utils::vec2i;

module top_7seg (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    input  wire logic [15:0] SW,    // Board switches
    output      logic [15:0] LED,   // Board LEDs
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b,  // 4-bit VGA blue
    output      logic [6:0] seg,    // Seven-seg display segments
    output      logic       dp,     // Seven-seg display decimal point
    output      logic [7:0] an      // Seven-seg display anodes
    );

    logic [31:0] bin_in;
    assign bin_in[15:0] = SW;
    assign bin_in[31:16] = 0;
    assign LED = SW;

    seg7bcd seg7 (
        .clk(clk_100m),
        .bin_in,
        .seg,
        .dp,
        .an
    );

//    parameter CLKS_PER_SECOND = 100000000;
//    logic [$clog2(CLKS_PER_SECOND) - 1:0] clock_counter;

//    always_ff @(posedge clk_100m) begin
//        if (clock_counter == CLKS_PER_SECOND - 1) begin
//            bin_in <= bin_in + 1;
//            clock_counter <= 0;
//        end else
//            clock_counter <= clock_counter + 1;
//    end

endmodule