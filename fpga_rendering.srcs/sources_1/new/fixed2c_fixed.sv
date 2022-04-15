`default_nettype none
`timescale 1ns / 1ps

module fixed2c_fixed #(
    parameter N = 32
    ) (
    input wire logic signed [N-1:0] i,
    output     logic        [N-1:0] o
    );

    assign o[N-1] = i[N-1];
    assign o[N-2:0] = i[N-1] ? -i[N-2:0] : i;

endmodule
