`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module transform_vertex (
    input  wire logic clk,
    input  wire logic start,
    input  wire mat4f matrix,
    input  wire vec4f v0, v1, v2,
    output      vec4f v0_ss, v1_ss, v2_ss,
    output      logic busy,
    output      logic done
    );

    localparam V_COUNT = 3;

    vec4f verts    [0:V_COUNT-1];
    vec4f verts_ss [0:V_COUNT-1];

    assign verts[0] = v0;
    assign verts[1] = v1;
    assign verts[2] = v2;

    // Vertex transform done flags
    logic tr_done [0:V_COUNT-1];

    genvar i;
    generate
        for (i = 0; i < V_COUNT; i = i + 1) begin
            vecmult4f tr0 (
                .clk,
                .start,
                .a(matrix),
                .b(verts[i]),
                .o(verts_ss[i]),
                .busy(),
                .done(tr_done[i])
            );
        end
    endgenerate

    // Vertex transform done registers
    logic [0:V_COUNT-1] tr_done_r;

    enum {IDLE, PROCESSING, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 0;
                busy <= 0;
                if (start) begin
                    state <= PROCESSING;
                    busy <= 1;
                end
            end
            PROCESSING: begin
                for (int j = 0; j < V_COUNT; j++) begin
                    if (tr_done[j])
                        tr_done_r[j] <= 1;
                end

                if (tr_done_r == '1) begin
                    state <= DONE;
                end
            end
            DONE: begin
                tr_done_r <= '0;

                v0_ss = verts_ss[0];
                v1_ss = verts_ss[1];
                v2_ss = verts_ss[2];

                done <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
