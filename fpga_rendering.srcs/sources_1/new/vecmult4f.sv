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

    logic dot_start;
    logic [0:3] dot_done;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            dot4f dot (
                .clk,
                .start(dot_start),
                .a({mata[i][0], mata[i][1], mata[i][2], mata[i][3]}),
                .b,
                .o(veco[i]),
                .busy(),
                .done(dot_done[i])
            );
        end
    endgenerate

    enum {IDLE, COMPUTING, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                busy <= 0;
                done <= 0;

                if (start) begin
                    busy <= 1;
                    dot_start <= 1;
                    state <= COMPUTING;
                end
            end
            COMPUTING: begin
                dot_start <= 0;

                if (dot_done == '1)
                    state <= DONE;
            end
            DONE: begin
                o <= {veco[0], veco[1], veco[2], veco[3]};
                done <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
