`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module vecmult4f_tb();

    logic clk, start;
    logic busy, done;

    mat4f matrix;
    vec4f vector;
    vec4f o;

    vecmult4f uut (
        .clk,
        .start,
        .a(matrix),
        .b(vector),
        .o,
        .busy,
        .done
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
//        matrix = {
//            32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
//            32'b0000000000000000_0000000000000000, 32'b1111111111111111_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
//            32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
//            32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
//        };

        matrix = {
            32'b0000000101000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000101000000_0000000000000000, 
            32'b0000000000000000_0000000000000000, 32'b1111111100010000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000011110000_0000000000000000, 
            32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
            32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
        };

        vector = {
            32'b0000000000000000_0000000000000000,
            32'b0000000000000000_1000000000000000,
            32'b0000000000000001_0000000000000000,
            32'b0000000000000001_0000000000000000
        };

        start = 1'b1;
        
        #10
        
        start = 1'b0;
    end

endmodule