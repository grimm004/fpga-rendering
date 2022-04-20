`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::valf;

module rotation_matrix_tb;

    logic clk;

    valf  theta;
    mat4f mat_rotation;

    logic rot_start;
    logic rot_busy, rot_done;

    rotation_matrix uut (
        .clk,
        .start(rot_start),
        .theta,
        .mat_rotation,
        .busy(rot_busy),
        .done(rot_done)
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        theta = 32'b0000000000000000_0000000000000000;  // 0

        rot_start = 1'b1;

        #10;

        rot_start = 1'b0;

        #100;

        theta = 32'b0000000001011010_0000000000000000;  // 90

        rot_start = 1'b1;

        #10;

        rot_start = 1'b0;

        #100;

        theta = 32'b0000000100111011_0000000000000000;  // 315

        rot_start = 1'b1;

        #10;

        rot_start = 1'b0;

        #100;

        theta = 32'b0000000010110100_0000000000000000;  // 180

        rot_start = 1'b1;

        #10;

        rot_start = 1'b0;
    end

endmodule
