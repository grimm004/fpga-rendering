`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::valf;

module matmult4f (
    input wire clk,
    input wire start,
    input wire mat4f a,
    input wire mat4f b,
    output     mat4f o,
    output     logic busy,
    output     logic done
    );

    logic ce, oe;

    valf mata [0:3][0:3];
    valf matb [0:3][0:3];
    valf mato [0:3][0:3];

    assign {
        mata[0][0], mata[0][1], mata[0][2], mata[0][3],
        mata[1][0], mata[1][1], mata[1][2], mata[1][3],
        mata[2][0], mata[2][1], mata[2][2], mata[2][3],
        mata[3][0], mata[3][1], mata[3][2], mata[3][3]
    } = a;

    assign {
        matb[0][0], matb[0][1], matb[0][2], matb[0][3],
        matb[1][0], matb[1][1], matb[1][2], matb[1][3],
        matb[2][0], matb[2][1], matb[2][2], matb[2][3],
        matb[3][0], matb[3][1], matb[3][2], matb[3][3]
    } = b;

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                dot4f dot (
                    .clk,
                    .ce,
                    .a({mata[i][0], mata[i][1], mata[i][2], mata[i][3]}),
                    .b({matb[0][j], matb[1][j], matb[2][j], matb[3][j]}),
                    .o(mato[i][j])
                );
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (oe)
            o <= {
                mato[0][0], mato[0][1], mato[0][2], mato[0][3],
                mato[1][0], mato[1][1], mato[1][2], mato[1][3],
                mato[2][0], mato[2][1], mato[2][2], mato[2][3],
                mato[3][0], mato[3][1], mato[3][2], mato[3][3]
            };
    end

    clock_counter #(.COUNT(17)) clk_cnt (
        .clk,
        .start,
        .busy,
        .done,
        .ce,
        .oe
    );

endmodule
