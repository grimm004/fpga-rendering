`default_nettype none
`timescale 1ns / 1ps


module matmult4 #(
        parameter NUMBER_WIDTH = 16
    ) (
        input logic signed [NUMBER_WIDTH - 1:0]
            a11, a12, a13, a14,
            a21, a22, a23, a24,
            a31, a32, a33, a34,
            a41, a42, a43, a44,
        input logic signed [NUMBER_WIDTH - 1:0]
            b11, b12, b13, b14,
            b21, b22, b23, b24,
            b31, b32, b33, b34,
            b41, b42, b43, b44,
        output logic signed [NUMBER_WIDTH - 1:0]
            o11, o12, o13, o14,
            o21, o22, o23, o24,
            o31, o32, o33, o34,
            o41, o42, o43, o44
    );

    always_comb o11 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
    always_comb o12 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
    always_comb o13 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
    always_comb o14 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

    always_comb o21 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
    always_comb o22 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
    always_comb o23 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
    always_comb o24 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

    always_comb o31 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
    always_comb o32 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
    always_comb o33 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
    always_comb o34 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

    always_comb o41 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
    always_comb o42 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
    always_comb o43 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
    always_comb o44 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

endmodule
