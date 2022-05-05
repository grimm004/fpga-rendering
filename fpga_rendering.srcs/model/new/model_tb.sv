`default_nettype none
`timescale 1ns / 1ps

import Utils::vec2f;

module model_tb;

    logic clk;

    vec2f v0, v1, v2;
    vec2f c0, c1, c2;
    logic reset = 0, face_start, face_done, busy, done;

    model uut (
        .clk,
        .reset,
        .face_start,
        .v0, .v1, .v2,
        .c0, .c1, .c2,
        .face_done,
        .busy,
        .done
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;

        #30
    
        face_start = 1'b1;

        #10

        face_start = 1'b0;
    end

endmodule
