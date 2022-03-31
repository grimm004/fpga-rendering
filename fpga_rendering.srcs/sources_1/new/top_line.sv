// Project F: Framebuffers - Top David v1 (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps


module top_line (
    input  wire logic CLK100MHZ,    // 100 MHz clock
    input  wire logic CPU_RESET,    // reset button (active low)
    output      logic VGA_HS,       // horizontal sync
    output      logic VGA_VS,       // vertical sync
    output      logic [3:0] VGA_R,  // 4-bit VGA red
    output      logic [3:0] VGA_G,  // 4-bit VGA green
    output      logic [3:0] VGA_B   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;

    clock_gen clock_gen (
        .resetn(CPU_RESET),
        .clk_100mhz(CLK100MHZ),
        .clk_25mhz(clk_pix),
        .locked(clk_locked)
    );

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic frame;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst(!clk_locked),
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de(),
        .frame,
        .line()
    );

//    vga_controller vga_c (
//        .clk_pixel(clk_pix),
//        .reset(!CPU_RESET && clk_locked),
//        .pixel_x(sx),
//        .pixel_y(sy),
//        .pixel_i(),
//        .pixel_enable(),
//        .new_frame(frame),
//        .vga_hsync(hsync),
//        .vga_vsync(vsync)
//    );

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;
    localparam FB_HEIGHT = 120;
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;
    localparam FB_ADDRW  = $clog2(FB_PIXELS);
    localparam FB_DATAW  = 1;  // colour bits per pixel
    localparam FB_IMAGE  = "david_1bit.mem";
    localparam FB_COORDW = 16;

    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] r_read, g_read, b_read;

    buffer_display #(
        .BUFFER_WIDTH(FB_WIDTH),
        .BUFFER_HEIGHT(FB_HEIGHT),
        .ADDR_WIDTH(FB_ADDRW),
        .CHANNEL_WIDTH(FB_DATAW),
        .COORD_WIDTH(FB_COORDW),
        .INIT_FILE(FB_IMAGE)
    ) display_buffer (
        .clk_read(clk_pix),
        .clk_write(clk_pix),
        .re(1),
        .we(fb_we),
        .addr_read(fb_addr_read),
        .x_write(),
        .y_write(),
        .r_write(),
        .g_write(),
        .b_write(),
        .r_read,
        .g_read,
        .b_read
    );

//    always_comb fb_we = drawing;

    logic vga_hs_p1, vga_vs_p1;
    always_ff @(posedge clk_pix) begin
        vga_hs_p1 <= hsync;
        vga_vs_p1 <= vsync;
    end

    always_ff @(posedge clk_pix) begin
        VGA_HS <= vga_hs_p1;
        VGA_VS <= vga_vs_p1;
        VGA_R <= r_read;
        VGA_G <= g_read;
        VGA_B <= b_read;
    end
endmodule
