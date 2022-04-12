`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;
import Utils::valf;

module vecmult4f (
    input wire clk,
    input wire start,
    input wire mat4f a,
    input wire vec4f b,
    output     vec4f o,
    output     logic busy,
    output     logic done
    );

    logic ce, oe;

    valf mata [0:3][0:3];
    valf vecb [0:3];
    valf veco [0:3];

    assign {
        mata[0][0], mata[0][1], mata[0][2], mata[0][3],
        mata[1][0], mata[1][1], mata[1][2], mata[1][3],
        mata[2][0], mata[2][1], mata[2][2], mata[2][3],
        mata[3][0], mata[3][1], mata[3][2], mata[3][3]
    } = a;

    assign {vecb[0], vecb[1], vecb[2], vecb[3]} = b;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            dot4f dot (
                .clk,
                .ce,
                .a({mata[i][0], mata[i][1], mata[i][2], mata[i][3]}),
                .b,
                .o(veco[i])
            );
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (oe)
            o <= {veco[0], veco[1], veco[2], veco[3]};
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
