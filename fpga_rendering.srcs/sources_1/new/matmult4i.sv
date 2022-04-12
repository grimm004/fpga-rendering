`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4i;

module matmult4i (
    input wire mat4i a,
    input wire mat4i b,
    output     mat4i o
    );

    always_comb o.v11 = a.v11 * b.v11 + a.v12 * b.v21 + a.v13 * b.v31 + a.v14 * b.v41;
    always_comb o.v12 = a.v11 * b.v12 + a.v12 * b.v22 + a.v13 * b.v32 + a.v14 * b.v42;
    always_comb o.v13 = a.v11 * b.v13 + a.v12 * b.v23 + a.v13 * b.v33 + a.v14 * b.v43;
    always_comb o.v14 = a.v11 * b.v14 + a.v12 * b.v24 + a.v13 * b.v34 + a.v14 * b.v44;

    always_comb o.v21 = a.v21 * b.v11 + a.v22 * b.v21 + a.v23 * b.v31 + a.v24 * b.v41;
    always_comb o.v22 = a.v21 * b.v12 + a.v22 * b.v22 + a.v23 * b.v32 + a.v24 * b.v42;
    always_comb o.v23 = a.v21 * b.v13 + a.v22 * b.v23 + a.v23 * b.v33 + a.v24 * b.v43;
    always_comb o.v24 = a.v21 * b.v14 + a.v22 * b.v24 + a.v23 * b.v34 + a.v24 * b.v44;

    always_comb o.v31 = a.v31 * b.v11 + a.v32 * b.v21 + a.v33 * b.v31 + a.v34 * b.v41;
    always_comb o.v32 = a.v31 * b.v12 + a.v32 * b.v22 + a.v33 * b.v32 + a.v34 * b.v42;
    always_comb o.v33 = a.v31 * b.v13 + a.v32 * b.v23 + a.v33 * b.v33 + a.v34 * b.v43;
    always_comb o.v34 = a.v31 * b.v14 + a.v32 * b.v24 + a.v33 * b.v34 + a.v34 * b.v44;

    always_comb o.v41 = a.v41 * b.v11 + a.v42 * b.v21 + a.v43 * b.v31 + a.v44 * b.v41;
    always_comb o.v42 = a.v41 * b.v12 + a.v42 * b.v22 + a.v43 * b.v32 + a.v44 * b.v42;
    always_comb o.v43 = a.v41 * b.v13 + a.v42 * b.v23 + a.v43 * b.v33 + a.v44 * b.v43;
    always_comb o.v44 = a.v41 * b.v14 + a.v42 * b.v24 + a.v43 * b.v34 + a.v44 * b.v44;

//    localparam W = 16;
//    localparam RW = 4 * 16;

//    dot4 v11 (a[0*RW+RW-1:0*RW], {b.v11, b.v21, b.v31, b.v41}, o.v11);
//    dot4 v12 (a[0*RW+RW-1:0*RW], {b.v12, b.v22, b.v32, b.v42}, o.v12);
//    dot4 v13 (a[0*RW+RW-1:0*RW], {b.v13, b.v23, b.v33, b.v43}, o.v13);
//    dot4 v14 (a[0*RW+RW-1:0*RW], {b.v14, b.v24, b.v34, b.v44}, o.v14);

//    dot4 v21 (a[1*RW+RW-1:1*RW], {b.v11, b.v21, b.v31, b.v41}, o.v21);
//    dot4 v22 (a[1*RW+RW-1:1*RW], {b.v12, b.v22, b.v32, b.v42}, o.v22);
//    dot4 v23 (a[1*RW+RW-1:1*RW], {b.v13, b.v23, b.v33, b.v43}, o.v23);
//    dot4 v24 (a[1*RW+RW-1:1*RW], {b.v14, b.v24, b.v34, b.v44}, o.v24);

//    dot4 v31 (a[2*RW+RW-1:2*RW], {b.v11, b.v21, b.v31, b.v41}, o.v31);
//    dot4 v32 (a[2*RW+RW-1:2*RW], {b.v12, b.v22, b.v32, b.v42}, o.v32);
//    dot4 v33 (a[2*RW+RW-1:2*RW], {b.v13, b.v23, b.v33, b.v43}, o.v33);
//    dot4 v34 (a[2*RW+RW-1:2*RW], {b.v14, b.v24, b.v34, b.v44}, o.v34);

//    dot4 v41 (a[3*RW+RW-1:3*RW], {b.v11, b.v21, b.v31, b.v41}, o.v41);
//    dot4 v42 (a[3*RW+RW-1:3*RW], {b.v12, b.v22, b.v32, b.v42}, o.v42);
//    dot4 v43 (a[3*RW+RW-1:3*RW], {b.v13, b.v23, b.v33, b.v43}, o.v43);
//    dot4 v44 (a[3*RW+RW-1:3*RW], {b.v14, b.v24, b.v34, b.v44}, o.v44);

endmodule
