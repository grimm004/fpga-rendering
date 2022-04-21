`default_nettype none
`timescale 1ns / 1ps

import Utils::coli;
import Utils::valf;
import Utils::vec2i;
import Utils::vec2f;
import Utils::vert2i;
import Utils::vert2f;

module draw_triangle_fill_tb;

    logic clk;

    vert2i v0, v1, v2;
    vec2i draw_pos;
    logic draw_start, draw_busy, draw_done, drawing;
    coli draw_col;

    // sorted input vertices
    vert2i v0s, v1s, v2s;

    draw_triangle_fill #(
        .CORDW(16)
    ) uut (
        .clk(clk),
        .rst(1'b0),
        .start(draw_start),
        .oe(1'b1),
        .v0,
        .v1,
        .v2,
        .draw_pos,
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(draw_busy),
        .col(draw_col),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
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
            16'b0000000010100000,
            12'hF00
        };

        v1 = {
            16'b0000000011110000,
            16'b0000000101000000,
            12'h0F0
        };

        v2 = {
            16'b0000000110010000,
            16'b0000000101000000,
            12'h00F
        };

        draw_start = 1'b1;

        #10

        draw_start = 1'b0;
    end

endmodule
