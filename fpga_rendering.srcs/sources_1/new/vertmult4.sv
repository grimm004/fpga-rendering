`default_nettype none
`timescale 1ns / 1ps


module vertmult4 #(
        parameter NUMBER_WIDTH = 16
    ) (
        input logic signed [NUMBER_WIDTH - 1:0]
            a11, a12, a13, a14,
            a21, a22, a23, a24,
            a31, a32, a33, a34,
            a41, a42, a43, a44,
        input logic signed [NUMBER_WIDTH - 1:0]
            b1, b2, b3, b4,
        output logic signed [NUMBER_WIDTH - 1:0]
            o1, o2, o3, o4
    );

    always_comb o1 = a11 * b1 + a12 * b2 + a13 * b3 + a14 * b4;
    always_comb o2 = a21 * b1 + a22 * b2 + a23 * b3 + a24 * b4;
    always_comb o3 = a31 * b1 + a32 * b2 + a33 * b3 + a34 * b4;
    always_comb o4 = a41 * b1 + a42 * b2 + a43 * b3 + a44 * b4;

endmodule
