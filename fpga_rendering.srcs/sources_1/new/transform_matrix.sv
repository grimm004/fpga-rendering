`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module transform_matrix (
    input  wire logic clk,
    input  wire logic start,
    input  wire mat4f mat_proj,
    input  wire mat4f mat_world,
    output      mat4f mat_tr,
    output      logic busy,
    output      logic done
    );

    localparam N = 3;

    mat4f identity = {
        32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    // Screen space transform
    mat4f mat_screen_space = '{
        32'b0000000101000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000101000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b1111111100010000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000011110000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    mat4f mats [0:N-1];
    mat4f mat_acc;

    assign mats[0] = mat_world;
    assign mats[1] = mat_proj;
    assign mats[2] = mat_screen_space;

    // mat_tr = mat_screen_space * mat_proj * mat_world * identity
    // mat_acc = identity
    // 0: mat_acc = mat_world * mat_acc = mat_world * identity
    // 1: mat_acc = mat_proj * mat_acc = mat_proj * mat_world * identity
    // 2: mat_acc = mat_screen_space * mat_acc = mat_screen_space * mat_proj * mat_world * identity

    logic [$clog2(N)-1:0] i;

    // Start matrix multiplication flag
    logic tr_start;
    // Matrix done flag
    logic tr_done;
    
    mat4f mat_product;

    matmult4f tr (
        .clk,
        .start(tr_start),
        .a(mats[i]),
        .b(mat_acc),
        .o(mat_product),
        .busy(),
        .done(tr_done)
    );

    enum {IDLE, MULTIPLYING, DONE} tr_state;
    always_ff @(posedge clk) begin
        case (tr_state)
            IDLE: begin
                done <= 0;
                busy <= 0;
                i    <= 0;
                mat_acc <= identity;

                if (start) begin
                    tr_start <= 1;
                    busy <= 1;
                    tr_state <= MULTIPLYING;
                end
            end
            MULTIPLYING: begin
                tr_start <= 0;

                if (tr_done) begin
                    mat_acc <= mat_product;

                    if (i == N - 1)
                        tr_state <= DONE;
                    else begin
                        i <= i + 1;
                        tr_start <= 1;
                        tr_state <= MULTIPLYING;
                    end
                end
            end
            DONE: begin
                mat_tr <= mat_acc;
                done <= 1;
                tr_state <= IDLE;
            end
        endcase
    end

endmodule
