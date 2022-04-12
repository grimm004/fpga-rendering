// Project F: Lines and Triangles - Top Triangles (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4i;
import Utils::mat4f;
import Utils::vec4i;
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

    assign LED[3:0] = SW[3:0];

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

    // framebuffer (FB)
    localparam FB_WIDTH   = 640;
    localparam FB_HEIGHT  = 480;
    localparam HALFWIDTH  = FB_WIDTH / 2;
    localparam HALFHEIGHT = FB_HEIGHT / 2;
    localparam FB_CIDXW   = 12;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 1;
    localparam FB_IMAGE   = "";
    localparam FB_PALETTE = "colour.mem";
    localparam FB_CLEARCOL = 12'h000;

//    mat4f identity = '{
//        SW[1] ? 32'b0000000000000000_1000000000000000 : 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
//        32'b0000000000000000_0000000000000000, SW[2] ? 32'b0000000000000000_1000000000000000 : 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
//        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
//        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
//    };

    // Screen space transform
    mat4f ssm = '{
        32'b0000000101000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000101000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b1111111100010000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000011110000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    vec4f vsst0, vsst1, vsst2;

    // Transform busy
    logic sst0busy, sst1busy, sst2busy;
    logic sst_busy = sst0busy || sst1busy || sst2busy;
    // Transform done
    logic sst0done, sst1done, sst2done;
    logic sst0done_r, sst1done_r, sst2done_r;
    // Start transform
    logic sst_start;

    vec4f v0, v1, v2;

    initial begin
        v0.z <= 32'b0000000000000001_0000000000000000;
        v0.w <= 32'b0000000000000001_0000000000000000;
        v1.z <= 32'b0000000000000001_0000000000000000;
        v1.w <= 32'b0000000000000001_0000000000000000;
        v2.z <= 32'b0000000000000001_0000000000000000;
        v2.w <= 32'b0000000000000001_0000000000000000;
    end

    vecmult4f sst0 (
        .clk(clk_100m),
        .start(sst_start),
        .a(ssm),
        .b(v0),
        .o(vsst0),
        .busy(sst0busy),
        .done(sst0done)
    );

    vecmult4f sst1 (
        .clk(clk_100m),
        .start(sst_start),
        .a(ssm),
        .b(v1),
        .o(vsst1),
        .busy(sst1busy),
        .done(sst1done)
    );

    vecmult4f sst2 (
        .clk(clk_100m),
        .start(sst_start),
        .a(ssm),
        .b(v2),
        .o(vsst2),
        .busy(sst2busy),
        .done(sst2done)
    );

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
//    vec2f vx0, vy0, vx1, vy1, vx2, vy2;  // shape coords
    logic [FB_CIDXW-1:0] vc0, vc1, vc2;
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
                sst_start <= 1;
                sst0done_r <= 0;
                sst1done_r <= 0;
                sst2done_r <= 0;
                state <= TRANSFORM;
                case (shape_id)
                    2'd0: begin
                        if (SW[2]) begin
                            v0.x <= 32'b0000000000000000_0000000000000000; v0.y <= 32'b0000000000000000_1000000000000000;
                            v1.x <= 32'b1111111111111111_1000000000000000; v1.y <= 32'b1111111111111111_1000000000000000;
                            v2.x <= 32'b0000000000000000_1000000000000000; v2.y <= 32'b1111111111111111_1000000000000000;
                        end else begin
                            v0.x <= 32'b0000000000111100_0000000000000000; v0.y <= 32'b0000000000010100_0000000000000000;
                            v1.x <= 32'b0000000100011000_0000000000000000; v1.y <= 32'b0000000001010000_0000000000000000;
                            v2.x <= 32'b0000000010100000_0000000000000000; v2.y <= 32'b0000000010100100_0000000000000000;
                        end

                        vc0 <= 12'hFFF;
                        vc1 <= 12'hFFF;
                        vc2 <= 12'hFFF;
                    end
//                    2'd0: begin
//                        vx0 <=  60; vy0 <=  20; vc0 <= 12'hFA0;
//                        vx1 <= 280; vy1 <=  80; vc1 <= 12'h000;
//                        vx2 <= 160; vy2 <= 164; vc2 <= 12'hFFF;
//                    end
//                    2'd1: begin
//                        vx0 <=  70; vy0 <= 160; vc0 <= 12'h3BF;
//                        vx1 <= 220; vy1 <=  90; vc1 <= 12'hF00;
//                        vx2 <= 170; vy2 <=  10; vc2 <= 12'h3BF;
//                    end
//                    2'd2: begin
//                        vx0 <=  22; vy0 <=  35; vc0 <= 12'h825;
//                        vx1 <=  62; vy1 <= 150; vc1 <= 12'h825;
//                        vx2 <=  98; vy2 <=  96; vc2 <= 12'h825;
//                    end
//                    2'd3: begin
//                        vx0 <=    0; vy0 <=   0; vc0 <= 12'hF00;
//                        vx1 <=    0; vy1 <= 100; vc1 <= 12'h0F0;
//                        vx2 <=  100; vy2 <=   0; vc2 <= 12'h00F;
//                    end
                    default: begin  // should never occur
                        v0.x <= 32'b0000000000000000_0000000000000000; v0.y <= 32'b0000000000000000_0000000000000000;
                        v1.x <= 32'b0000000000000001_0000000000000000; v1.y <= 32'b0000000000000000_0000000000000000;
                        v2.x <= 32'b0000000000000000_0000000000000000; v2.y <= 32'b0000000000000001_0000000000000000;

                        vc0 <= 12'hCCC;
                        vc1 <= 12'hCCC;
                        vc2 <= 12'hCCC;
                    end
                endcase
            end
            TRANSFORM: begin
                sst_start <= 0;
                
                if (sst0done)
                    sst0done_r <= 1;
                if (sst1done)
                    sst1done_r <= 1;
                if (sst2done)
                    sst2done_r <= 1;
                    
                if (sst0done_r & sst1done_r & sst2done_r) begin
                    sst0done_r <= 0;
                    sst1done_r <= 0;
                    sst2done_r <= 0;
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

    // control drawing speed with output enable
    localparam FRAME_WAIT = 300;  // wait this many frames to start drawing
    logic [$clog2(FRAME_WAIT)-1:0] cnt_frame_wait;
    logic draw_req;  // draw requested
    always_ff @(posedge clk_100m) begin
        if (!fb_busy) draw_req <= 0;  // disable after FB available, so 1 pix per frame
        if (frame_sys) begin  // once per frame
            if (cnt_frame_wait != FRAME_WAIT-1) begin
                cnt_frame_wait <= cnt_frame_wait + 1;
            end else draw_req <= 1;  // request drawing
        end
    end

    draw_triangle_fill #(
        .CORDW(CORDW),
        .CHANW(FB_CHANW)
    ) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe((SW[0] || draw_req) && !fb_busy && !sst_busy),  // draw if requested when framebuffer is available
        .v0({vsst0.x[15:0], vsst0.y[15:0], vc0}),
        .v1({vsst1.x[15:0], vsst1.y[15:0], vc1}),
        .v2({vsst2.x[15:0], vsst2.y[15:0], vc2}),
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
