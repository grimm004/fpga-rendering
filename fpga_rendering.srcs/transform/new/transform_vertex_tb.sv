`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module transform_vertex_tb;

    logic clk;

    mat4f tr_matrix;

    // Start vertex transform flag
    logic vtr_start;
    // Vertex transform busy and done flags
    logic vtr_busy, vtr_done;

    // Current world-space vertices
    vec4f v [0:2];
    // Current screen-space vertices
    vec4f v_tr [0:2];

    transform_vertex vt (
        .clk,
        .start(vtr_start),
        .matrix(tr_matrix),
        .v0(v[0]),
        .v1(v[1]),
        .v2(v[2]),
        .v0_tr(v_tr[0]),
        .v1_tr(v_tr[1]),
        .v2_tr(v_tr[2]),
        .busy(vtr_busy),
        .done(vtr_done)
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        tr_matrix = {
            32'b0000000011110000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000101000000_0000000000000000, 32'b0000001111000000_0000000000000000, 
            32'b0000000000000000_0000000000000000, 32'b1111111100010000_0000000000000000, 32'b0000000011110000_0000000000000000, 32'b0000001011010000_0000000000000000, 
            32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0001000010000100, 32'b0000000000000001_0010000100001000, 
            32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000011_0000000000000000
        };

        v[0].x = 32'b0000000000000000_0000000000000000;
        v[0].y = 32'b0000000000000001_0000000000000000;
        v[0].z = 32'b0000000000000000_0000000000000000;
        v[0].w = 32'b0000000000000001_0000000000000000;

        v[1].x = 32'b1111111111111111_0000000000000000;
        v[1].y = 32'b1111111111111111_0000000000000000;
        v[1].z = 32'b0000000000000000_0000000000000000;
        v[1].w = 32'b0000000000000001_0000000000000000;

        v[2].x = 32'b0000000000000001_0000000000000000;
        v[2].y = 32'b1111111111111111_0000000000000000;
        v[2].z = 32'b0000000000000000_0000000000000000;
        v[2].w = 32'b0000000000000001_0000000000000000;

        vtr_start = 1'b1;

        #10

        vtr_start = 1'b0;
    end

endmodule