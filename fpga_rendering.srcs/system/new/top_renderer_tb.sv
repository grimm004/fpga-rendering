`default_nettype none
`timescale 1ns / 1ps

module top_renderer_tb;

    logic clk;

    logic btn_rst = 1;
    logic [15:0] SW, LED;
    logic vga_hsync, vga_vsync;
    logic [3:0] vga_r, vga_g, vga_b;
    logic [6:0] seg;
    logic dp;
    logic [7:0] an;

    top_renderer uut (
        .clk_100m(clk),
        .btn_rst,
        .SW,
        .LED,
        .vga_hsync,
        .vga_vsync,
        .vga_r,
        .vga_g,
        .vga_b,
        .seg,
        .dp,
        .an
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        SW = {16{1'b1}};
    end

endmodule
