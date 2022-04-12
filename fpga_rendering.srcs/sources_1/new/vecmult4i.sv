`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4i;
import Utils::vec4i;

module vecmult4i (
    input wire mat4i a,
    input wire vec4i b,
    output     vec4i o
    );

    always_comb o.x = a.v11 * b.x + a.v12 * b.y + a.v13 * b.z + a.v14 * b.w;
    always_comb o.y = a.v21 * b.x + a.v22 * b.y + a.v23 * b.z + a.v24 * b.w;
    always_comb o.z = a.v31 * b.x + a.v32 * b.y + a.v33 * b.z + a.v34 * b.w;
    always_comb o.w = a.v41 * b.x + a.v42 * b.y + a.v43 * b.z + a.v44 * b.w;

//    localparam W = 16;
//    localparam RW = 4 * 16;

//    dot4 x (a[0*RW+RW-1:0*RW], b, o.x);
//    dot4 y (a[0*RW+RW-1:0*RW], b, o.y);
//    dot4 z (a[0*RW+RW-1:0*RW], b, o.z);
//    dot4 w (a[0*RW+RW-1:0*RW], b, o.w);

endmodule
