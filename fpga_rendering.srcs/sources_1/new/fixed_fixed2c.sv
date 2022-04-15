`default_nettype none
`timescale 1ns / 1ps

module fixed_fixed2c #(
    parameter N = 32
    ) (
    input wire logic        [N-1:0] i,
    output     logic signed [N-1:0] o
    );

    assign o = i[N-1] ? -i[N-2:0] : i;

endmodule
