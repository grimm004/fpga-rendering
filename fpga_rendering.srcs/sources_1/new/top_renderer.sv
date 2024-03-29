// 3D Graphics Rendering Pipeline by Max Grimmett
// Based on Project F: Lines and Triangles - Top Triangles (Arty Pmod VGA)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

import Utils::mat4f;
import Utils::vec3f;
import Utils::vec4f;
import Utils::valf;
import Utils::coli;
import Utils::colf;
import Utils::vec2i;

module top_renderer (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    input  wire logic [15:0] SW,    // Board switches
    input  wire logic BTNC,
    input  wire logic BTNU,
    input  wire logic BTNL,
    input  wire logic BTNR,
    input  wire logic BTND,
    output      logic [15:0] LED,   // Board LEDs
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b,  // 4-bit VGA blue
    output      logic [6:0] seg,    // Seven-seg display segments
    output      logic       dp,     // Seven-seg display decimal point
    output      logic [7:0] an      // Seven-seg display anodes
    );

    localparam FB_SCALE   = 1;
    localparam FB_WIDTH   = 640;
    localparam FB_HEIGHT  = 480;
    localparam FB_CHANW   = 4;
    localparam FB_COLW    = 3 * FB_CHANW;

    assign LED[11:0] = SW[11:0];
    assign LED[15:13] = SW[15:13];
    assign LED[12] = 0;

    logic [31:0] bin_in;

    // Frame Counter Output
    seg7bcd seg7 (
        .clk(clk_100m),
        .bin_in,
        .seg,
        .dp,
        .an
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;

    clock_gen clock_jen (
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

    // Matrices for transformation
    mat4f mat_scale = '{
        SW[2] ? 32'b0000000000000000_1000000000000000 : 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, SW[3] ? 32'b0000000000000000_1000000000000000 : 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    mat4f mat_translation = {
        32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000101_0000000000000000, 
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

    // Transform
    valf  theta;
    mat4f mat_rotation;

    logic rot_start, rot_busy;

    rotation_matrix rot_mat_inst (
        .clk(clk_100m),
        .start(rot_start),
        .theta,
        .mat_rotation,
        .busy(rot_busy),
        .done()
    );

    always @(posedge clk_100m) begin
        if (SW[1] && frame_sys && !rot_busy) begin
            theta <= theta + 32'b0000000000000001_0000000000000000;  // +1.0 degree per frame
            if (theta == 32'b0000000101101000_0000000000000000)      //  360.0
                theta <= 32'b0000000000000000_0000000000000000;      //  0.0
            rot_start <= 1;
        end else
            rot_start <= 0;
    end

    // Start matrix transformation flag
    logic mtr_start;
    // Matrix transformation busy flag
    logic mtr_busy;

    // Transformed matrix
    mat4f mat_tr;

    mat4f mat_identity = {
        32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000, 32'b0000000000000000_0000000000000000, 
        32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000001_0000000000000000
    };

    transform_matrix #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT)
    ) mt (
        .clk(clk_100m),
        .start(mtr_start),
        .mat_rotation(SW[7] ? mat_rotation : mat_identity),
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
        if (frame_sys && SW[0])
            mtr_start <= 1;
    end

    // Current world-space vertex positions
    vec3f v [0:2];
    // Current vertex colours
    colf vc [0:2];

    localparam MODEL_FACE_COUNT  = 12;
    localparam MODEL_FILE  = "cube.mem";

    logic model_reset, face_start, face_done, model_complete;

    model #(
        .FACE_COUNT(MODEL_FACE_COUNT),
        .FILE(MODEL_FILE)
    ) model_loader (
        .clk(clk_100m),
        .reset(model_reset),
        .face_start,
        .v0(v[0]),  .v1(v[1]),  .v2(v[2]),
        .c0(vc[0]), .c1(vc[1]), .c2(vc[2]),
        .face_done,
        .busy(),
        .done(),
        .complete(model_complete)
    );

    vec3f v_fixed [0:2];
    colf vc_fixed [0:2];

    // Start vertex transform flag
    logic vtr_start;
    // Vertex transform busy and done flags
    logic vtr_busy, vtr_done;

    // Current screen-space vertices
    vec4f v_tr [0:2];

    transform_vertex vt (
        .clk(clk_100m),
        .start(vtr_start),
        .matrix(mat_tr),
        .v0({SW[15] ? v[0] : v_fixed[0], 32'b0000000000000001_0000000000000000}),  // Convert vertex position from vec3f to vec4f
        .v1({SW[15] ? v[1] : v_fixed[1], 32'b0000000000000001_0000000000000000}),
        .v2({SW[15] ? v[2] : v_fixed[2], 32'b0000000000000001_0000000000000000}),
        .v0_tr(v_tr[0]),
        .v1_tr(v_tr[1]),
        .v2_tr(v_tr[2]),
        .busy(vtr_busy),
        .done(vtr_done)
    );

    logic fb_we;  // write enable
    vec2i fb_draw_pos;  // draw coordinates
    coli fb_col;  // draw colour
    logic fb_busy;  // when framebuffer is busy it cannot accept writes
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display output
    logic fb_clearing;
    vec2i fb_clear_pos;  // clear coordinates
    coli fb_clearcol;
    assign fb_clearcol = SW[11] ? 12'hFFF : 12'h000;

    framebuffer_bram #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CHANW(FB_CHANW),
        .COLW(FB_COLW),
        .SCALE(FB_SCALE)
    ) fb_inst (
        .clk_sys(clk_100m),
        .clk_pix,
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de(sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx <= FB_WIDTH),
        .frame,
        .line,
        .we(fb_we),
        .x(fb_clearing ? fb_clear_pos.x : fb_draw_pos.x),
        .y(fb_clearing ? fb_clear_pos.y : fb_draw_pos.y),
        .col(fb_clearing ? fb_clearcol : fb_col),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        /* verilator lint_on PINCONNECTEMPTY */
        .busy(fb_busy),
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw triangles in framebuffer
    localparam SHAPE_CNT=2;  // number of shapes to draw
    logic [1:0] shape_id;    // shape identifier
    logic draw_start, drawing, draw_done, cull_backface;  // drawing signals
    assign cull_backface = SW[10];

    logic [26:0] pipeline_timer = 0;
    logic [26:0] pipeline_timer_min = '1;
    logic [26:0] pipeline_timer_max = 0;
    enum {CURRENT, MIN, MAX} seg7_state;
    always_ff @(posedge clk_100m) begin
        if (state == DONE) begin
            if (pipeline_timer < pipeline_timer_min)
                pipeline_timer_min <= pipeline_timer;
            else if (pipeline_timer > pipeline_timer_max)
                pipeline_timer_max <= pipeline_timer;
            case (seg7_state)
                CURRENT: bin_in <= pipeline_timer;
                MIN: bin_in <= pipeline_timer_min;
                MAX: bin_in <= pipeline_timer_max;
            endcase
            pipeline_timer <= 0;
        end else if (state != IDLE)
            pipeline_timer <= pipeline_timer + 1;

        if (BTNC) seg7_state <= CURRENT;
        else if (BTND) seg7_state <= MIN;
        else if (BTNU) seg7_state <= MAX;
        if (BTNL) begin
            bin_in <= 0;
            pipeline_timer_min = '1;
            pipeline_timer_max = 0;
        end
    end

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
                    fb_clear_pos.x <= fb_clear_pos.x + 1;
                    if (fb_clear_pos.x == FB_WIDTH) begin
                        fb_clear_pos.x <= 0;
                        fb_clear_pos.y <= fb_clear_pos.y + 1;
                        if (fb_clear_pos.y == FB_HEIGHT) begin
                            fb_clearing <= 0;
                            fb_clear_pos.y   <= 0;
                            state       <= INIT;
                            if (SW[15])
                                face_start  <= 1;
                        end
                    end
                end
            end
            INIT: begin  // register coordinates and colour
                if (SW[15]) begin

                    face_start  <= 0;
                    if (face_done) begin
                        state <= TRANSFORM;
                        vtr_start <= 1;
                    end

                end else begin
                    state <= TRANSFORM;
                    vtr_start <= 1;

                    case (shape_id)
                        2'd0: begin
                            if (SW[8]) begin
                                v_fixed[0].x <= 32'b0000000000000000_0000000000000000 + 32'b0000000000000001_0000000000000000; v_fixed[0].y <= 32'b0000000000000000_1000000000000000; v_fixed[0].z <= 32'b0000000000000000_0000000000000000;
                                v_fixed[1].x <= 32'b1111111111111111_1000000000000000 + 32'b0000000000000001_0000000000000000; v_fixed[1].y <= 32'b1111111111111111_1000000000000000; v_fixed[1].z <= 32'b0000000000000000_0000000000000000;
                                v_fixed[2].x <= 32'b0000000000000000_1000000000000000 + 32'b0000000000000001_0000000000000000; v_fixed[2].y <= 32'b1111111111111111_1000000000000000; v_fixed[2].z <= 32'b0000000000000000_0000000000000000;
                            end else begin
                                v_fixed[0].x <= 32'b0000000000000000_0000000000000000; v_fixed[0].y <= 32'b0000000000000000_1000000000000000; v_fixed[0].z <= 32'b0000000000000000_0000000000000000;
                                v_fixed[1].x <= 32'b1111111111111111_1000000000000000; v_fixed[1].y <= 32'b1111111111111111_1000000000000000; v_fixed[1].z <= 32'b0000000000000000_0000000000000000;
                                v_fixed[2].x <= 32'b0000000000000000_1000000000000000; v_fixed[2].y <= 32'b1111111111111111_1000000000000000; v_fixed[2].z <= 32'b0000000000000000_0000000000000000;
                            end
    
                            if (SW[4])
                                if (SW[9])
                                    vc_fixed[0] <= {32'b0000000000001111_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
                                else
                                    vc_fixed[0] <= {32'b0000000000001111_0000000000000000, 32'b0000000000001111_0000000000000000, 32'b0000000000001111_0000000000000000};
                            else
                                vc_fixed[0] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
    
                            if (SW[5])
                                if (SW[9])
                                    vc_fixed[1] <= {32'b0000000000000000_0000000000000000, 32'b0000000000001111_0000000000000000, 32'b0000000000000000_0000000000000000};
                                else
                                    vc_fixed[1] <= {32'b0000000000001111_0000000000000000, 32'b0000000000001111_0000000000000000, 32'b0000000000001111_0000000000000000};
                            else
                                vc_fixed[1] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
    
                            if (SW[6])
                                if (SW[9])
                                    vc_fixed[2] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000001111_0000000000000000};
                                else
                                    vc_fixed[2] <= {32'b0000000000001111_0000000000000000, 32'b0000000000001111_0000000000000000, 32'b0000000000001111_0000000000000000};
                            else
                                vc_fixed[2] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
    
    //                        vc[0] <= SW[4] ? (SW[9] ? 12'hF00 : 12'hFFF) : 12'h000;
    //                        vc[1] <= SW[5] ? (SW[9] ? 12'h0F0 : 12'hFFF) : 12'h000;
    //                        vc[2] <= SW[6] ? (SW[9] ? 12'h00F : 12'hFFF) : 12'h000;
                        end
                        2'd1: begin
                            v_fixed[0].x <= 32'b0000000000000000_0000000000000000 - 32'b0000000000000001_0000000000000000; v_fixed[0].y <= 32'b0000000000000000_1000000000000000; v_fixed[0].z <= 32'b0000000000000000_0000000000000000;
                            v_fixed[1].x <= 32'b1111111111111111_1000000000000000 - 32'b0000000000000001_0000000000000000; v_fixed[1].y <= 32'b1111111111111111_1000000000000000; v_fixed[1].z <= 32'b0000000000000000_0000000000000000;
                            v_fixed[2].x <= 32'b0000000000000000_1000000000000000 - 32'b0000000000000001_0000000000000000; v_fixed[2].y <= 32'b1111111111111111_1000000000000000; v_fixed[2].z <= 32'b0000000000000000_0000000000000000;
    
    
                            if (SW[4])
                                vc_fixed[0] <= {32'b0000000000001111_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
                            else
                                vc_fixed[0] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
    
                            if (SW[5])
                                vc_fixed[1] <= {32'b0000000000000000_0000000000000000, 32'b0000000000001111_0000000000000000, 32'b0000000000000000_0000000000000000};
                            else
                                vc_fixed[1] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
    
                            if (SW[6])
                                vc_fixed[2] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000001111_0000000000000000};
                            else
                                vc_fixed[2] <= {32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000, 32'b0000000000000000_0000000000000000};
    
    //                        vc[0] <= SW[4] ? 12'hF00 : 12'h000;
    //                        vc[1] <= SW[5] ? 12'h0F0 : 12'h000;
    //                        vc[2] <= SW[6] ? 12'h00F : 12'h000;
                        end
                        default: begin  // should never occur
                            v_fixed[0].x <= 32'b0000000000000000_0000000000000000; v_fixed[0].y <= 32'b0000000000000000_0000000000000000; v_fixed[0].z <= 32'b0000000000000000_0000000000000000;
                            v_fixed[1].x <= 32'b0000000000000001_0000000000000000; v_fixed[1].y <= 32'b0000000000000000_0000000000000000; v_fixed[1].z <= 32'b0000000000000000_0000000000000000;
                            v_fixed[2].x <= 32'b0000000000000000_0000000000000000; v_fixed[2].y <= 32'b0000000000000001_0000000000000000; v_fixed[2].z <= 32'b0000000000000000_0000000000000000;
    
                            vc_fixed[0] <= {3{32'h000C0000}};
                            vc_fixed[1] <= {3{32'h000C0000}};
                            vc_fixed[2] <= {3{32'h000C0000}};
                        end
                    endcase

                end
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
                    if (SW[15] ? model_complete : shape_id == (SW[8] ? SHAPE_CNT-1 : 0)) begin
                        if (SW[15])
                            model_reset = 1;
                        state <= DONE;
                    end else begin
                        if (SW[15])
                            face_start = 1;
                        else
                            shape_id <= shape_id + 1;
                        state <= INIT;
                    end
                end
            end
            DONE: begin
                if (SW[15])
                    model_reset = 0;
                else
                    shape_id <= 0;
                state <= IDLE;
            end
            default: begin  // IDLE
                if (frame_sys)
                    state <= CLEAR_INIT;
            end
        endcase
    end

    draw_triangle_fill #(
        .CORDW(CORDW)
    ) draw_triangle_inst (
        .clk(clk_100m),
        .rst(1'b0),
        .start(draw_start),
        .oe(!fb_busy),
        .cull_backface,
        .v0({v_tr[0].x[15:0], v_tr[0].y[15:0], SW[15] ? {vc[0].r[3:0], vc[0].g[3:0], vc[0].b[3:0]} : {vc_fixed[0].r[3:0], vc_fixed[0].g[3:0], vc_fixed[0].b[3:0]}}),
        .v1({v_tr[1].x[15:0], v_tr[1].y[15:0], SW[15] ? {vc[1].r[3:0], vc[1].g[3:0], vc[1].b[3:0]} : {vc_fixed[1].r[3:0], vc_fixed[1].g[3:0], vc_fixed[1].b[3:0]}}),
        .v2({v_tr[2].x[15:0], v_tr[2].y[15:0], SW[15] ? {vc[2].r[3:0], vc[2].g[3:0], vc[2].b[3:0]} : {vc_fixed[2].r[3:0], vc_fixed[2].g[3:0], vc_fixed[2].b[3:0]}}),
        .draw_pos(fb_draw_pos),
        .drawing,
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        .col(fb_col),
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
