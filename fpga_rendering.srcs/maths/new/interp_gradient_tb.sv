`default_nettype none
`timescale 1ns / 1ps

import Utils::vec3f;
import Utils::valf;

module interp_gradient_tb;

    logic clk, start;
    logic busy, done;

    vec3f v0, v1, v2;
    valf dz_dx, dz_dy;

    interp_gradient uut (
        .clk,
        .start,
        .v0,
        .v1,
        .v2,
        .dz_dx,
        .dz_dy,
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
            32'b0000000101000000_0000000000000000,
            32'b0000000010100000_0000000000000000,
            32'b0000000000001111_0000000000000000
        };

        v1 = {
            32'b0000000011110000_0000000000000000,
            32'b0000000101000000_0000000000000000,
            32'b0000000000000000_0000000000000000
        };

        v2 = {
            32'b0000000110010000_0000000000000000,
            32'b0000000101000000_0000000000000000,
            32'b0000000000000000_0000000000000000
        };

        start = 1'b1;

        #10

        start = 1'b0;
    end

endmodule