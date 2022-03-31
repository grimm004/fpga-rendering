`default_nettype none
`timescale 1ns / 1ps


module buffer_display #(
        parameter BUFFER_WIDTH = 160,
        parameter BUFFER_HEIGHT = 120,
        parameter ADDR_WIDTH = 16,
        parameter CHANNEL_WIDTH = 4,
        parameter COORD_WIDTH = 16,
        parameter INIT_FILE = ""
    ) (
        input wire clk_read,
        input wire clk_write,
        input wire re,
        input wire we,
        input wire [ADDR_WIDTH - 1:0] addr_read,
        input wire [COORD_WIDTH - 1:0] x_write, y_write,
        input wire [CHANNEL_WIDTH - 1:0] r_write, g_write, b_write,
        output     [CHANNEL_WIDTH - 1:0] r_read, g_read, b_read
    );

    wire [ADDR_WIDTH - 1:0] addr_write = y_write * BUFFER_WIDTH + x_write;

    buffer_frame # (
        BUFFER_WIDTH,
        BUFFER_HEIGHT,
        ADDR_WIDTH,
        CHANNEL_WIDTH,
        INIT_FILE
    ) fb (
        .clk_read,
        .clk_write,
        .re,
        .we,
        .addr_read, .addr_write,
        .r_write, .g_write, .b_write,
        .r_read, .g_read, .b_read
    );

endmodule
