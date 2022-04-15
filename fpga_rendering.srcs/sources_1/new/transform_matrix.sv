`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module transform_matrix (
    input  wire logic clk,
    input  wire logic start,
    input  wire mat4f mat_rotation,
    input  wire mat4f mat_scale,
    input  wire mat4f mat_translation,
    input  wire mat4f mat_proj,
    output      mat4f mat_tr,
    output      logic busy,
    output      logic done
    );

    localparam N = 5;

    mat4f mat_identity = {
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

    assign mats[0] = mat_rotation;
    assign mats[1] = mat_scale;
    assign mats[2] = mat_translation;
    assign mats[3] = mat_proj;
    assign mats[4] = mat_screen_space;

    // mat_tr = mat_screen_space * mat_proj * mat_translation * mat_scale * mat_rotation * mat_identity

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
                mat_acc <= mat_identity;

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
