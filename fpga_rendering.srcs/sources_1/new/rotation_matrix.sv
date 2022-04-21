`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::valf;

module rotation_matrix (
    input wire logic clk,
    input wire logic start,
    input wire valf  theta,
    output     mat4f mat_rotation,
    output     logic busy,
    output     logic done
    );

    valf sin_theta, cos_theta;

    assign mat_rotation = '{
        cos_theta,                              32'b0000000000000000_0000000000000000, -sin_theta,                             32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000,  32'b0000000000000001_0000000000000000,  32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        sin_theta,                              32'b0000000000000000_0000000000000000,  cos_theta,                             32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000,  32'b0000000000000000_0000000000000000,  32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    localparam SIN_DEPTH = 256;
    localparam SIN_WIDTH = 16;
    localparam SIN_DATAW = 2 * SIN_WIDTH;
    localparam SIN_ADDRW = $clog2(4*SIN_DEPTH);

    logic signed [31:-32] theta_sin, theta_cos;
    assign theta_sin = theta * 32'b0000000000000010_1101100000101101;
    assign theta_cos = 64'b00000000000000000000000100000000_00000000000000000000000000000000 - theta_sin;

    logic signed [SIN_ADDRW-1:0] sin_id;
    logic signed [SIN_DATAW-1:0] sin_data;

    sine_table #(
        .ROM_DEPTH(SIN_DEPTH),
        .ROM_WIDTH(SIN_WIDTH),
        .ROM_FILE("sine_table_256x16.mem"),
        .ADDRW(SIN_ADDRW)
    ) st_inst (
        .id(sin_id),
        .data(sin_data)
    );

    enum {IDLE, INIT, SIN, COS} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                busy <= 0;
                done <= 0;
                if (start) begin
                    state <= INIT;
                    busy <= 1;
                end
            end
            INIT: begin
                sin_id = theta_sin[SIN_ADDRW-1:0] + theta_sin[-1];
                state <= SIN;
            end
            SIN: begin
//                sin_theta <= {{8{sin_data[15]}}, sin_data, {8{1'b0}}};
                sin_theta <= sin_data;
                sin_id = theta_cos[SIN_ADDRW-1:0] + theta_cos[-1];
                state <= COS;
            end
            COS: begin
                cos_theta <= sin_data;
                state <= IDLE;
                done <= 1;
            end
        endcase
    end

endmodule
