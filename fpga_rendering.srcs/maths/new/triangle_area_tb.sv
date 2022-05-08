`default_nettype none
`timescale 1ns / 1ps

import Utils::vec2i;
import Utils::vali;

module triangle_area_tb;

    logic clk;

    vec2i v0, v1, v2;
    vali area;
    logic start, busy, done, handedness;

    triangle_area uut (
        .clk,
        .start,
        .v(v0),
        .va(v2),
        .vb(v1),
        .handedness,
        .area,
        .busy,
        .done
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        v0 = {
            16'b0000000101000000,
            16'b0000000010100000
        };

        v1 = {
            16'b0000000011110000,
            16'b0000000101000000
        };

        v2 = {
            16'b0000000110010000,
            16'b0000000101000000
        };

        start = 1'b1;

        #10

        start = 1'b0;
    end

endmodule
