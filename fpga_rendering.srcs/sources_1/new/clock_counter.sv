`default_nettype none
`timescale 1ns / 1ps

module clock_counter #(
    parameter COUNT = 17
    ) (
    input wire logic clk,
    input wire logic start,
    output     logic busy,
    output     logic done,
    output     logic ce,
    output     logic oe
    );

    localparam COUNTER_WIDTH = $clog2(COUNT) + 1;

    logic [COUNTER_WIDTH-1:0] clk_counter;
    enum {IDLE, CALCULATING} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                clk_counter <= 0;
                ce   <= 0;
                busy <= 0;
                done <= 0;
                oe   <= 0;

                if (start) begin
                    ce    <= 1;
                    state <= CALCULATING;
                    busy  <= 1;
                end
            end
            CALCULATING: begin
                if (clk_counter == COUNT) begin
                    done  <= 1;
                    state <= IDLE;
                    oe    <= 1;
                end else
                    clk_counter <= clk_counter + 1;
            end
        endcase
    end

endmodule
