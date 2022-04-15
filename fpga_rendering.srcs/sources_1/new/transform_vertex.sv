`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module transform_vertex (
    input  wire logic clk,
    input  wire logic start,
    input  wire mat4f matrix,
    input  wire vec4f v0,    v1,    v2,
    output      vec4f v0_tr, v1_tr, v2_tr,
    output      logic busy,
    output      logic done
    );

    localparam V_COUNT = 3;

    vec4f verts    [0:V_COUNT-1];
    vec4f verts_ss [0:V_COUNT-1];
    vec4f verts_pd [0:V_COUNT-1];

    assign verts[0] = v0;
    assign verts[1] = v1;
    assign verts[2] = v2;

    // Vertex transform and perspective divide start flags
    logic tr_start, persp_div_start;

    // Vertex transform done flags
    logic tr_done [0:V_COUNT-1];
    logic persp_div_done [0:V_COUNT-1];

    genvar i;
    generate
        for (i = 0; i < V_COUNT; i = i + 1) begin
            vecmult4f tr (
                .clk,
                .start(tr_start),
                .a(matrix),
                .b(verts[i]),
                .o(verts_ss[i]),
                .busy(),
                .done(tr_done[i])
            );

            perspective_divide persp_div (
                .clk,
                .start(persp_div_start),
                .v_ss(verts_ss[i]),
                .v_pd(verts_pd[i]),
                .busy(),
                .done(persp_div_done[i])
            );
        end
    endgenerate

    // Vertex transform done registers
    logic [0:V_COUNT-1] tr_done_r;
    // Perspective divide done registers
    logic [0:V_COUNT-1] persp_div_done_r;

    enum {IDLE, TRANSFORM, PERSP_DIV, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 0;
                busy <= 0;

                if (start) begin
                    state <= TRANSFORM;
                    busy <= 1;
                    tr_start <= 1;
                end
            end
            TRANSFORM: begin
                tr_start <= 0;

                for (int j = 0; j < V_COUNT; j++) begin
                    if (tr_done[j])
                        tr_done_r[j] <= 1;
                end

                if (tr_done_r == '1) begin
                    state <= PERSP_DIV;
                    persp_div_start <= 1;
                end
            end
            PERSP_DIV: begin
                persp_div_start <= 0;

                for (int j = 0; j < V_COUNT; j++) begin
                    if (persp_div_done[j])
                        persp_div_done_r[j] <= 1;
                end

                if (persp_div_done_r == '1)
                    state <= DONE;
            end
            DONE: begin
                tr_done_r        <= '0;
                persp_div_done_r <= '0;

                v0_tr = verts_pd[0];
                v1_tr = verts_pd[1];
                v2_tr = verts_pd[2];

                done  <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
