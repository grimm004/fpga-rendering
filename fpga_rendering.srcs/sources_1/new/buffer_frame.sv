`default_nettype none
`timescale 1ns / 1ps


module buffer_frame # (
            parameter BUFFER_WIDTH,
            parameter BUFFER_HEIGHT,
            parameter ADDRESS_WIDTH,
            parameter CHANNEL_WIDTH,
            parameter INIT_FILE = ""
        ) (
        input wire clk_read, clk_write,
        input wire re, we,
        input wire [ADDRESS_WIDTH - 1:0] addr_read,
        input wire [ADDRESS_WIDTH - 1:0] addr_write,
        input wire [CHANNEL_WIDTH - 1:0] r_write, g_write, b_write,
        output     [CHANNEL_WIDTH - 1:0] r_read, g_read, b_read
    );

    buffer_channel # (
        BUFFER_WIDTH,
        BUFFER_HEIGHT,
        ADDRESS_WIDTH,
        CHANNEL_WIDTH,
        INIT_FILE
    ) channel_r (
        .clk_read,
        .clk_write,
        .re,
        .we,
        .addr_read,
        .addr_write,
        .data_write(r_write),
        .data_read(r_read)
    );

    buffer_channel # (
        BUFFER_WIDTH,
        BUFFER_HEIGHT,
        ADDRESS_WIDTH,
        CHANNEL_WIDTH,
        INIT_FILE
    ) channel_g (
        .clk_read,
        .clk_write,
        .re,
        .we,
        .addr_read,
        .addr_write,
        .data_write(g_write),
        .data_read(g_read)
    );

    buffer_channel # (
        BUFFER_WIDTH,
        BUFFER_HEIGHT,
        ADDRESS_WIDTH,
        CHANNEL_WIDTH,
        INIT_FILE
    ) channel_b (
        .clk_read,
        .clk_write,
        .re,
        .we,
        .addr_read,
        .addr_write,
        .data_write(b_write),
        .data_read(b_read)
    );

endmodule
