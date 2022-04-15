`default_nettype none
`timescale 1ns / 1ps

import Utils::vec4f;
import Utils::valf;

module perspective_divide(
    input  wire logic clk,
    input  wire logic start,
    input  wire vec4f v_ss,
    output      vec4f v_pd,
    output      logic busy,
    output      logic done
    );

    valf vert_ss [0:2];
    valf vert_pd [0:2];

    assign vert_ss[0] = v_ss.x;
    assign vert_ss[1] = v_ss.y;
    assign vert_ss[2] = v_ss.z;

    // Division start and done flags
    logic div_start, div_done;
    // Output reciprocal from division
    valf div_reciporcal;

    qdiv persp_div (
        .clk,
        .start(div_start),
        .dividend(32'b0000000000000001_0000000000000000),
        .divisor(v_ss.w),
        .quotient_out(div_reciporcal),
        .done(div_done),
        .complete(),
        .overflow()
    );

    // Multiplication clock enable, start, and done flags
    logic ce, mul_start, mul_done;
    logic [2:0] i;
    valf val_pd;

    mult mul (
        .CLK(clk),
        .CE(ce),
        .A(vert_ss[i]),
        .B(div_reciporcal),
        .P(val_pd)
    );

    clock_counter #(.COUNT(7)) clk_cnt (
        .clk,
        .start(mul_start),
        .busy(),
        .done(mul_done),
        .ce,
        .oe()
    );

    enum {IDLE, DIV, MULT, DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 0;
                busy <= 0;
                i    <= 0;

                if (start) begin
                    state <= DIV;
                    busy <= 1;
                    div_start <= 1;
                end
            end
            DIV: begin
                div_start <= 0;

                if (div_done) begin
                    state <= MULT;
                    mul_start <= 1;
                end
            end
            MULT: begin
                mul_start <= 0;

                if (mul_done) begin
                    vert_pd[i] <= val_pd;

                    if (i == 2'd3)
                        state <= DONE;
                    else begin
                        i <= i + 1;
                        mul_start <= 1;
                        state <= MULT;
                    end
                end
            end
            DONE: begin
                v_pd.x = vert_pd[0];
                v_pd.y = vert_pd[1];
                v_pd.z = vert_pd[2];
                v_pd.w = v_ss.w; // v_pd.w = vert_pd[3];

                done  <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
