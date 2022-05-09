`default_nettype none
`timescale 1ns / 1ps

import Utils::vec2i;
import Utils::vali;

module triangle_area (
    input  wire logic  clk,           // Clock
    input  wire logic  start,         // Start triangle area calculation
    input  wire vec2i  v, va, vb,    // Triangle vertices
    output      logic  handedness,    // Triangle handedness
    output      vali   area,          // Triangle area
    output      logic  busy,          // Busy calculating
    output      logic  done           // Calculation complete
    );

    vali x1, y1, x2, y2;
    vali double_area;

    assign handedness = double_area >= 0;

    enum {IDLE, SUB, MUL, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                busy <= 0;
                done <= 0;

                if (start) begin
                    state <= SUB;
                    busy <= 1;
                end
            end
            SUB: begin
                x1 <= va.x - v.x;
                y1 <= va.y - v.y;

                x2 <= vb.x - v.x;
                y2 <= vb.y - v.y;

                state <= MUL;
            end
            MUL: begin
                double_area = (x1 * y2) - (x2 * y1);
                state <= DONE;
            end
            DONE: begin
                area <= double_area >> 1;
                done <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
