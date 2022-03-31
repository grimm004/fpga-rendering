`default_nettype none
`timescale 1ns / 1ps


module top (
    input  wire logic CLK100MHZ,    // 100 MHz clock
    input  wire logic CPU_RESET,    // reset button (active low)
    output      logic VGA_HS,       // horizontal sync
    output      logic VGA_VS,       // vertical sync
    output      logic [3:0] VGA_R,  // 4-bit VGA red
    output      logic [3:0] VGA_G,  // 4-bit VGA green
    output      logic [3:0] VGA_B   // 4-bit VGA blue
    );
    
    wire logic clk_25mhz;
    wire logic clk_locked;
    wire logic pixel_enable;

    wire logic [15:0] pixel_x;
    wire logic [15:0] pixel_y;
    wire logic [23:0] pixel_i;

    localparam SQUARE_SIZE  = 32;
    localparam SQUARE_SPEED = 5;
    
    logic square_animate;
    logic square_draw;
    logic [9:0] square_x = 0, square_y = 0;

    clock_gen clock_gen (
        .resetn(CPU_RESET),
        .clk_100mhz(CLK100MHZ),
        .clk_25mhz,
        .locked(clk_locked)
    );

    vga_controller vga_c (
        .clk_pixel(clk_25mhz),
        .reset(!CPU_RESET && clk_locked),
        .pixel_x,
        .pixel_y,
        .pixel_i,
        .pixel_enable,
        .new_frame(square_animate),
        .vga_hsync(VGA_HS),
        .vga_vsync(VGA_VS)
    );

    always_comb square_draw =
        square_x <= pixel_x && pixel_x < square_x + SQUARE_SIZE &&
        square_y <= pixel_y && pixel_y < square_y + SQUARE_SIZE;

    always_ff @(posedge clk_25mhz) begin
        if (square_animate) begin
            if (square_x + SQUARE_SIZE > 640) begin
                square_x <= 0;
                square_y <= square_y + SQUARE_SIZE > 480 ? 0 : square_y + SQUARE_SIZE;
            end
            else square_x <= square_x + SQUARE_SPEED;
        end

        VGA_R <= square_draw ? 4'hF : 4'h0;
        VGA_G <= square_draw ? 4'h8 : 4'h8;
        VGA_B <= square_draw ? 4'h0 : 4'hF;

        if (!(CPU_RESET && pixel_enable)) begin
            VGA_R <= 0;
            VGA_G <= 0;
            VGA_B <= 0;
        end
    end

endmodule





//    buffer_display db (
//        .clk_read(clk_25mhz),
//        .clk_write(clk_25mhz),
//        .re(pixel_enable),
//        .we(0),
//        .addr_read(pixel_i),
//        .x_write(pixel_x),
//        .y_write(pixel_y),
//        .r_in(4'hF),
//        .g_in(4'hF),
//        .b_in(4'hF),
//        .r_out(VGA_R),
//        .g_out(VGA_G),
//        .b_out(VGA_B)
//    );