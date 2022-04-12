`default_nettype none
`timescale 1ns / 1ps

import Utils::vec4i;

module dot4(
    input wire vec4i a,
    input wire vec4i b,
    output logic [15:0] o
    );

    always_comb o = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;

endmodule
