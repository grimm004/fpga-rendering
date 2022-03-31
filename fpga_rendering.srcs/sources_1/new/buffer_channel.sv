`default_nettype none
`timescale 1ns / 1ps


module buffer_channel # (
            parameter BUFFER_WIDTH,
            parameter BUFFER_HEIGHT,
            parameter ADDRESS_WIDTH,
            parameter DATA_WIDTH,
            parameter INIT_FILE = ""
        ) (
        input wire clk_read,
        input wire clk_write,
        input wire re,
        input wire we,
        input [ADDRESS_WIDTH - 1:0] addr_read,
        input [ADDRESS_WIDTH - 1:0] addr_write,
        input [DATA_WIDTH - 1:0] data_write,
        output reg [DATA_WIDTH - 1:0] data_read
    );

    bram_dp # (DATA_WIDTH, BUFFER_WIDTH * BUFFER_HEIGHT, INIT_FILE) channel_memory (
        .clk_read,
        .clk_write,
        .re,
        .we,
        .addr_read,
        .addr_write,
        .data_write,
        .data_read
    );

endmodule
