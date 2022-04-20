`default_nettype none
`timescale 1ns / 1ps

// one_over_dx = 1 / (((verts[1].x - verts[2].x) * (verts[0].y - verts[2].y)) - ((verts[0].x - verts[2].x) * (verts[1].y - verts[2].y))) = 1 / ((x_1_2 * y_0_2) - (x_0_2 * y_1_2))
// dz_x        =     (((verts[1].z - verts[2].z) * (verts[0].y - verts[2].y)) - ((verts[0].z - verts[2].z) * (verts[1].y - verts[2].y))) =     ((z_1_2 * y_0_2) - (z_0_2 * y_1_2))
// dz_y        =     (((verts[1].z - verts[2].z) * (verts[0].x - verts[2].x)) - ((verts[0].z - verts[2].z) * (verts[1].x - verts[2].x))) =     ((z_1_2 * x_0_2) - (z_0_2 * x_1_2))
// one_over_dy =    -one_over_dx
// dz_dx       =     dz_x * one_over_dx
// dz_dy       =     dz_y * one_over_dy

import Utils::vec3f;
import Utils::valf;

module interp_gradient (
    input  wire logic clk,
    input  wire logic start,
    input  wire vec3f v0,  // Min vertex
    input  wire vec3f v1,  // Mid vertex
    input  wire vec3f v2,  // Max vertex
    output      valf dz_dx, dz_dy,
    output      logic busy,
    output      logic done
    );

    valf zero = 32'b0000000000000000_0000000000000000;

    vec3f verts [0:2];
    valf dz_dx_r, dz_dy_r;

    assign verts[0] = v0;
    assign verts[1] = v1;
    assign verts[2] = v2;

    valf z_1_2, z_0_2, y_0_2, y_1_2, x_0_2, x_1_2;

    assign z_1_2 = verts[1].z - verts[2].z;
    assign z_0_2 = verts[0].z - verts[2].z;

    assign y_0_2 = verts[0].y - verts[2].y;
    assign y_1_2 = verts[1].y - verts[2].y;

    assign x_0_2 = verts[0].x - verts[2].x;
    assign x_1_2 = verts[1].x - verts[2].x;

    valf dz_x;
    valf dz_y;
    valf dx;
    valf dy;

    assign dy = -dx;

    logic div_start, div_done;
    valf div_a;
    valf div_b;
    valf div_out;

    // div_out = div_a / div_b
    qdiv div_x (
        .clk,
        .start(div_start),
        .dividend(div_a),
        .divisor(div_b),
        .quotient_out(div_out),
        .done(div_done),
        .complete(),
        .overflow()
    );

    logic ma_subtract = 1'b0;
    logic ma_sclr = 1'b0;

    logic ma_start, ma_done, ma_ce;
    valf ma_a, ma_b;
    logic signed [31:-32] ma_c, ma_p;

    // ma_p = ma_c + ma_a * ma_b
    multadd ma (
        .CLK(clk),
        .C(ma_c),
        .A(ma_a),
        .B(ma_b),
        .SUBTRACT(ma_subtract),
        .CE(ma_ce),
        .SCLR(ma_sclr),
        .PCOUT(),
        .P(ma_p)
    );

    clock_counter #(.COUNT(8)) clk_cnt (
        .clk,
        .start(ma_start),
        .busy(),
        .done(ma_done),
        .ce(ma_ce),
        .oe()
    );

    enum {
        IDLE,

        CALC_DX_0_INIT,
        CALC_DX_0_CALC,
        CALC_DX_1_INIT,
        CALC_DX_1_CALC,

        CALC_DZ_X_0_INIT,
        CALC_DZ_X_0_CALC,
        CALC_DZ_X_1_INIT,
        CALC_DZ_X_1_CALC,

        CALC_DZ_Y_0_INIT,
        CALC_DZ_Y_0_CALC,
        CALC_DZ_Y_1_INIT,
        CALC_DZ_Y_1_CALC,

        CALC_DZ_DX_INIT,
        CALC_DZ_DX_CALC,

        CALC_DZ_DY_INIT,
        CALC_DZ_DY_CALC,

        DONE
    } state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                busy <= 0;
                done <= 0;

                if (start) begin
                    state <= CALC_DX_0_INIT;
                    busy <= 1;
                end
            end


            // Calculate ma_p = (verts[0].x - verts[2].x) * (verts[1].y - verts[2].y) + 0 = x_0_2 * y_1_2 + 0
            CALC_DX_0_INIT: begin
                ma_a <= x_0_2;
                ma_b <= y_1_2;
                ma_c <= zero;
                ma_start <= 1;

                state <= CALC_DX_0_CALC;
            end
            CALC_DX_0_CALC: begin
                ma_start <= 0;

                if (ma_done) begin
                    state <= CALC_DX_1_INIT;
                end
            end

            // Calculate dx = ma_p = (verts[1].x - verts[2].x) * (verts[0].y - verts[2].y) + -ma_p = x_1_2 * y_0_2 + -ma_p
            CALC_DX_1_INIT: begin
                ma_a <= x_1_2;
                ma_b <= y_0_2;
                ma_c <= -ma_p;
                ma_start <= 1;

                state <= CALC_DX_1_CALC;
            end
            CALC_DX_1_CALC: begin
                ma_start <= 0;

                if (ma_done) begin
                    state <= CALC_DZ_X_0_INIT;
                    dx <= ma_p[15:-16];
                end
            end


            // Calculate ma_p = (verts[0].z - verts[2].z) * (verts[1].y - verts[2].y) + 0 = z_0_2 * y_1_2 + 0
            CALC_DZ_X_0_INIT: begin
                ma_a <= z_0_2;
                ma_b <= y_1_2;
                ma_c <= zero;
                ma_start <= 1;

                state <= CALC_DZ_X_0_CALC;
            end
            CALC_DZ_X_0_CALC: begin
                ma_start <= 0;

                if (ma_done) begin
                    state <= CALC_DZ_X_1_INIT;
                end
            end

            // Calculate dz_x = ma_p = (verts[1].z - verts[2].z) * (verts[0].y - verts[2].y) + -ma_p = z_1_2 * y_0_2 + -ma_p
            CALC_DZ_X_1_INIT: begin
                ma_a <= z_1_2;
                ma_b <= y_0_2;
                ma_c <= -ma_p;
                ma_start <= 1;

                state <= CALC_DZ_X_1_CALC;
            end
            CALC_DZ_X_1_CALC: begin
                ma_start <= 0;

                if (ma_done) begin
                    state <= CALC_DZ_Y_0_INIT;
                    dz_x <= ma_p[15:-16];
                end
            end


            // Calculate ma_p = (verts[0].z - verts[2].z) * (verts[1].x - verts[2].x) + 1 = z_0_2 * x_1_2 + 0
            CALC_DZ_Y_0_INIT: begin
                ma_a <= z_0_2;
                ma_b <= x_1_2;
                ma_c <= zero;
                ma_start <= 1;

                state <= CALC_DZ_Y_0_CALC;
            end
            CALC_DZ_Y_0_CALC: begin
                ma_start <= 0;

                if (ma_done) begin
                    state <= CALC_DZ_Y_1_INIT;
                end
            end

            // Calculate dz_y = ma_p = (verts[1].z - verts[2].z) * (verts[0].x - verts[2].x) + -ma_p = z_1_2 * x_0_2 + -ma_p
            CALC_DZ_Y_1_INIT: begin
                ma_a <= z_1_2;
                ma_b <= x_0_2;
                ma_c <= -ma_p;
                ma_start <= 1;

                state <= CALC_DZ_Y_1_CALC;
            end
            CALC_DZ_Y_1_CALC: begin
                ma_start <= 0;

                if (ma_done) begin
                    state <= CALC_DZ_DX_INIT;
                    dz_y <= ma_p[15:-16];
                end
            end


            // Calculate dz_dx = div_out = dz_x / dx
            CALC_DZ_DX_INIT: begin
                div_a <= dz_x;
                div_b <= dx;
                div_start <= 1;

                state <= CALC_DZ_DX_CALC;
            end
            CALC_DZ_DX_CALC: begin
                div_start <= 0;

                if (div_done) begin
                    state <= CALC_DZ_DY_INIT;
                    dz_dx_r <= div_out;
                end
            end


            // Calculate dz_dy = div_out = dz_y / dy
            CALC_DZ_DY_INIT: begin
                div_a <= dz_y;
                div_b <= dy;
                div_start <= 1;

                state <= CALC_DZ_DY_CALC;
            end
            CALC_DZ_DY_CALC: begin
                div_start <= 0;

                if (div_done) begin
                    state <= DONE;
                    dz_dy_r <= div_out;
                end
            end


            DONE: begin
                dz_dx <= dz_dx_r;
                dz_dy <= dz_dy_r;

                done <= 1;
                state <= IDLE;
            end
        endcase
    end

endmodule
