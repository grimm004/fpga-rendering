`default_nettype none
`timescale 1ns / 1ps


module bram_dp # (
        parameter DATA_WIDTH = 4,
        parameter DATA_LENGTH = 8192,
        parameter INIT_FILE = ""
    ) (
        input wire clk_read,
        input wire clk_write,
        input wire re,
        input wire we,
        input [$clog2(DATA_LENGTH) - 1:0] addr_read, addr_write,
        input [DATA_WIDTH - 1:0] data_write,
        output reg [DATA_WIDTH - 1:0] data_read
    );

    reg [DATA_WIDTH - 1:0] memory [DATA_LENGTH];

    always_ff @(posedge clk_read) begin
        if (re)
            data_read <= memory[addr_read];
    end

    always_ff @(posedge clk_write) begin
        if (we)
            memory[addr_write] <= data_write;
    end

    initial if (INIT_FILE)
        $readmemh(INIT_FILE, memory);
endmodule
