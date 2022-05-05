`timescale 1ns / 1ps


module vga_controller #(
    PREC_COUNTER = 16,
    PREC_PIXEL = 16,
    PREC_PIXEL_INDEX = 24,
    PIXEL_WIDTH = 640,
    PIXEL_HEIGHT = 480,
    PIXEL_START_H = 144,
    PIXEL_START_V = 35,
    PIXEL_END_H = 785,
    PIXEL_END_V = 515,
    VGA_END_H = 800,
    VGA_END_V = 525
    ) (
    input   wire    logic clk_pixel,
    input   wire    logic reset,
    output          logic [PREC_PIXEL - 1:0] pixel_x = 0,
    output          logic [PREC_PIXEL - 1:0] pixel_y = 0,
    output          logic [PREC_PIXEL_INDEX - 1:0] pixel_i = 0,
    output          logic pixel_enable,
    output          logic new_frame,
    output          logic vga_hsync,
    output          logic vga_vsync
    );

    logic [PREC_COUNTER - 1:0] counter_h = 0, counter_v = 0;
    logic x_enable, y_enable;

    always_ff @(posedge clk_pixel) begin
        if (counter_h < VGA_END_H - 1) begin
            counter_h <= counter_h + 1;

            if (pixel_enable) begin
                pixel_x <= pixel_x + 1;
                pixel_i <= pixel_i + 1;
            end
        end
        else begin
            counter_h <= 0;
            pixel_x <= 0;

            if (counter_v < VGA_END_V - 1) begin
                counter_v <= counter_v + 1;

                if (y_enable) begin
                    pixel_i <= pixel_i - 1;
                    pixel_y <= pixel_y + 1;
                end
            end
            else begin
                counter_v <= 0;
                pixel_y <= 0;
                pixel_i <= 0;
            end
        end

        if (reset) begin
            counter_h <= 0;
            counter_v <= 0;
            pixel_x <= 0;
            pixel_y <= 0;
            pixel_i <= 0;
        end
    end

    always_comb begin
        vga_hsync = counter_h >= 96; // Low for 96 pixels
        vga_vsync = counter_v >= 2;  // Low for 2 lines

        x_enable = PIXEL_START_H <= counter_h && counter_h < PIXEL_END_H;
        y_enable = PIXEL_START_V <= counter_v && counter_v < PIXEL_END_V;

        pixel_enable = reset && x_enable && y_enable; // Current pixel is in active region

        new_frame = reset && counter_h == 0 && counter_v == 0;
    end

endmodule
