`default_nettype none
`timescale 1ns / 1ps

import Utils::vec4f;
import Utils::valf;

module dot4f(
    input wire logic clk,
    input wire logic ce,
    input wire vec4f a,
    input wire vec4f b,
    output     valf  o
    );

    valf veca [0:3];
    valf vecb [0:3];

    wire logic signed [31:-32] vals [-1:3];

    assign {veca[0], veca[1], veca[2], veca[3]} = a;
    assign {vecb[0], vecb[1], vecb[2], vecb[3]} = b;
    assign o = vals[3][15:-16];

    logic subtract = 1'b0;
    logic sclr = 1'b0;

    assign vals[-1] = 64'b0;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            multadd ma (
                .CLK(clk),
                .A(veca[i]),
                .B(vecb[i]),
                .C(vals[i - 1]),
                .SUBTRACT(subtract),
                .CE(ce),
                .SCLR(sclr),
                .PCOUT(),
                .P(vals[i])
            );
        end
    endgenerate

endmodule
