`default_nettype none
`timescale 1ns / 1ps

import Utils::vec4f;
import Utils::valf;

module dot4f_tb();

    logic clk, start;
    logic busy, done, ce;

    vec4f vec0;
    vec4f vec1;
    valf  o;

    dot4f uut (
        .clk,
        .ce,
        .a(vec0),
        .b(vec1),
        .o
    );

    clock_counter #(.COUNT(17)) clk_cnt (
        .clk,
        .start,
        .busy,
        .done,
        .ce
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

//    initial begin
//        #100 $finish;
//    end

    initial begin
        vec0 = {
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000
        };

        vec1 = {
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000
        };

        start = 1'b1;

        #10

        start = 1'b0;

        #250

        vec0 = {
            32'b0000000000000011_0000000000000000,
            32'b0000000000000010_0000000000000000,
            32'b0000000000000010_0000000000000000,
            32'b1111111111111110_0000000000000000
        };

        vec1 = {
            32'b0000000000000000_1000000000000000,
            32'b0000000000000000_1000000000000000,
            32'b0000000000000000_1000000000000000,
            32'b0000000000000000_1000000000000000
        };

        start = 1'b1;

        #10

        start = 1'b0;
    end

endmodule
