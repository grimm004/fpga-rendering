`default_nettype none
`timescale 1ns / 1ps

import Utils::vec2i;
import Utils::vali;

module triangle_area (
    input  wire logic  clk,           // Clock
    input  wire logic  start,         // Start triangle area calculation
    input  wire vec2i  v0, v1, v2,    // Triangle vertices
    output      logic  handedness,    // Triangle handedness
    output      vali   area,          // Triangle area
    output      logic  done           // Calculation complete
    );

    enum {IDLE, PROCESSING, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
            end
            PROCESSING: begin
                
            end
            DONE: begin
            end
        endcase
    end

endmodule
