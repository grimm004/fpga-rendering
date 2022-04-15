// Project F: Lines and Triangles - Top Triangles (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec4f;

module top_renderer (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    input  wire logic [15:0] SW,
    output      logic [15:0] LED,
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    assign LED[0] = SW[0];
    assign LED[3:2] = SW[3:2];

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;

    clock_gen clock_gen (
        .reset(!btn_rst),
        .clk_100mhz(clk_100m),
        .clk_25mhz(clk_pix),
        .locked(clk_locked)
    );

    // display sync signals and coordinates
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix(!clk_locked),
        .sx,
        .sy,
        .hsync,
        .vsync,
        /* verilator lint_off PINCONNECTEMPTY */
        .de(),
        /* verilator lint_off PINCONNECTEMPTY */
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m),
                 .rst_i(1'b0), .rst_o(1'b0), .i(frame), .o(frame_sys));

    logic busy;

    mat4f mat_scale = '{
        SW[2] ? 32'b0000000000000010_0000000000000000 : 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, SW[3] ? 32'b0000000000000010_0000000000000000 : 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    mat4f mat_translation = {
        32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000011_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    mat4f mat_rotation_3deg_y = {
        32'b0000000000000000_1111111110100110, 32'b0000000000000000_0000000000000000, 32'b1111111111111111_1111001010011010, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000110101100101, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_1111111110100110, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    mat4f mat_perspective_proj = {
        32'b0000000000000000_1100000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0001000010000100, 32'b1111111111111101_1110111101111011, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000
    };

//    mat4f mat_mat = {
//        32'b0000000011110000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000101000000_0000000000000000, 32'b0000001111000000_0000000000000000, 
//        32'b0000000000000000_0000000000000000, 32'b1111111100010000_0000000000000000, 32'b0000000011110000_0000000000000000, 32'b0000001011010000_0000000000000000, 
//        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0001000010000100, 32'b0000000000000001_0010000100001000, 
//        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000011_0000000000000000
//    };

    // Transform
    mat4f mat_rotation;
    mat4f mat_product;

    mat4f mat_identity = '{
        32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    logic rot_start;
    logic rot_done;

    matmult4f mm (
        .clk(clk_100m),
        .start(rot_start),
        .a(mat_rotation_3deg_y),
        .b(mat_rotation),
        .o(mat_product),
        .busy(),
        .done(rot_done)
    );

    localparam ROTATE_FRAMES = 120;
    logic [$clog2(ROTATE_FRAMES)-1:0] frame_counter;

    enum {ROT_IDLE, ROT_PROCESSING, ROT_DONE} rot_state;
    always_ff @(posedge clk_100m) begin
        case (rot_state)
            ROT_IDLE: begin
                if (frame && SW[1]) begin
                    frame_counter <= frame_counter + 1;
                    if (frame_counter == ROTATE_FRAMES) begin
                        LED[1] <= ~LED[1];
                        frame_counter <= 0;
                        mat_rotation <= mat_identity;
                    end
                    rot_start <= 1;
                    rot_state <= ROT_PROCESSING;
                end
            end
            ROT_PROCESSING: begin
                rot_start <= 0;

                if (rot_done)
                    rot_state <= ROT_DONE;
            end
            ROT_DONE: begin
                mat_rotation <= mat_product;
                rot_state <= ROT_IDLE;
            end
        endcase
    end

    // Start matrix transformation flag
    logic mtr_start;
    // Matrix transformation busy flag
    logic mtr_busy;

    // Transformed matrix
    mat4f mat_tr;

    transform_matrix mt (
        .clk(clk_100m),
        .start(mtr_start),
        .mat_rotation,
        .mat_scale,
        .mat_translation,
        .mat_proj(mat_perspective_proj),
        .mat_tr,
        .busy(mtr_busy),
        .done()
    );

    always_ff @(posedge clk_100m) begin
        if (mtr_start)
            mtr_start <= 0;
        if (frame && SW[0])
            mtr_start <= 1;
    end

    // Start vertex transform flag
    logic vtr_start;
    // Vertex transform busy and done flags
    logic vtr_busy, vtr_done;

    // Current world-space vertices
    vec4f v [0:2];
    // Current screen-space vertices
    vec4f v_tr [0:2];

    transform_vertex vt (
        .clk(clk_100m),
        .start(vtr_start),
        .matrix(mat_tr),
        .v0(v[0]),
        .v1(v[1]),
        .v2(v[2]),
        .v0_tr(v_tr[0]),
        .v1_tr(v_tr[1]),
        .v2_tr(v_tr[2]),
        .busy(vtr_busy),
        .done(vtr_done)
    );

    // Set z and w components for world-space vertices to 0 and 1
    initial begin
        v[0].z <= 32'b0000000000000000_0000000000000000;
        v[0].w <= 32'b0000000000000001_0000000000000000;
        v[1].z <= 32'b0000000000000000_0000000000000000;
        v[1].w <= 32'b0000000000000001_0000000000000000;
        v[2].z <= 32'b0000000000000000_0000000000000000;
        v[2].w <= 32'b0000000000000001_0000000000000000;
    end

    // framebuffer (FB)
    localparam FB_WIDTH   = 640;
    localparam FB_HEIGHT  = 480;
    localparam FB_CIDXW   = 12;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 1;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "colour.mem";
    localparam FB_CLEARCOL = 12'h000;

    logic fb_we;  // write enable
    logic signed [CORDW-1:0] fbx, fby;  // draw coordinates
    logic [FB_CIDXW-1:0] fb_cidx;  // draw colour index
    logic fb_busy;  // when framebuffer is busy it cannot accept writes
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display output
    logic fb_clearing;
    logic signed [CORDW-1:0] fb_clearx, fb_cleary;  // clear coordinates

    framebuffer_bram #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_100m),
        .clk_pix,
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de(sy >= 0 && sy < 480 && sx >= 0 && sx <= 640),  // 16:9 letterbox
        .frame,
        .line,
        .we(fb_we),
        .x(fb_clearing ? fb_clearx : fbx),
        .y(fb_clearing ? fb_cleary : fby),
        .cidx(fb_clearing ? FB_CLEARCOL : fb_cidx),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .busy(fb_busy),
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw triangles in framebuffer
    localparam SHAPE_CNT=1;  // number of shapes to draw
    logic [1:0] shape_id;    // shape identifier
    logic [FB_CIDXW-1:0] vc [0:2]; // Vertex colours
    logic draw_start, drawing, draw_done;  // drawing signals

    // draw state machine
    enum {IDLE, CLEAR_INIT, CLEAR, INIT, TRANSFORM, DRAW, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            CLEAR_INIT: begin // Clear screen
                fb_clearing <= 1;
                state <= CLEAR;
            end
            CLEAR: begin // Clear screen
                if (!fb_busy) begin
                    fb_clearx <= fb_clearx + 1;
                    if (fb_clearx == FB_WIDTH) begin
                        fb_clearx <= 0;
                        fb_cleary <= fb_cleary + 1;
                        if (fb_cleary == FB_HEIGHT) begin
                            fb_clearing <= 0;
                            fb_cleary   <= 0;
                            state       <= INIT;
                        end
                    end
                end
            end
            INIT: begin  // register coordinates and colour
                vtr_start <= 1;
                state <= TRANSFORM;

                case (shape_id)
                    2'd0: begin
                        v[0].x <= 32'b0000000000000000_0000000000000000; v[0].y <= 32'b0000000000000000_1000000000000000;
                        v[1].x <= 32'b1111111111111111_1000000000000000; v[1].y <= 32'b1111111111111111_1000000000000000;
                        v[2].x <= 32'b0000000000000000_1000000000000000; v[2].y <= 32'b1111111111111111_1000000000000000;

                        vc[0] <= 12'hFFF;
                        vc[1] <= 12'hFFF;
                        vc[2] <= 12'hFFF;
                    end
                    default: begin  // should never occur
                        v[0].x <= 32'b0000000000000000_0000000000000000; v[0].y <= 32'b0000000000000000_0000000000000000;
                        v[1].x <= 32'b0000000000000001_0000000000000000; v[1].y <= 32'b0000000000000000_0000000000000000;
                        v[2].x <= 32'b0000000000000000_0000000000000000; v[2].y <= 32'b0000000000000001_0000000000000000;

                        vc[0] <= 12'hCCC;
                        vc[1] <= 12'hCCC;
                        vc[2] <= 12'hCCC;
                    end
                endcase
            end
            TRANSFORM: begin
                vtr_start <= 0;

                if (vtr_done) begin
                    draw_start <= 1;
                    state <= DRAW;
                end
            end
            DRAW: begin
                draw_start <= 0;
                if (draw_done) begin
                    if (shape_id == SHAPE_CNT-1) begin
                        state <= DONE;
                    end else begin
                        shape_id <= shape_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: begin
                shape_id <= 0;
                state <= IDLE;
            end
            default: if (frame_sys) state <= CLEAR_INIT;  // IDLE
        endcase
    end

    draw_triangle_fill #(
        .CORDW(CORDW),
        .CHANW(FB_CHANW)
    ) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!busy),
        .v0({v_tr[0].x[15:0], v_tr[0].y[15:0], vc[0]}),
        .v1({v_tr[1].x[15:0], v_tr[1].y[15:0], vc[1]}),
        .v2({v_tr[2].x[15:0], v_tr[2].y[15:0], vc[2]}),
        .x(fbx),
        .y(fby),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        .col(fb_cidx),
        /* verilator lint_on PINCONNECTEMPTY */
        .done(draw_done)
    );

    // write to framebuffer when drawing
    always_comb fb_we = drawing || fb_clearing;

    // Either frame buffer, matrix transform, or vertex transform is busy
    always_comb busy = fb_busy || mtr_busy || vtr_busy;

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_p1;
        vga_vsync <= vsync_p1;
        vga_r <= fb_red;
        vga_g <= fb_green;
        vga_b <= fb_blue;
    end
endmodule
