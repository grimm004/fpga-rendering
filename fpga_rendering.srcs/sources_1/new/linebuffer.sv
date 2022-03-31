`default_nettype none
`timescale 1ns / 1ps


module linebuffer #(
    parameter DATA_WIDTH=8,    // data width of each channel
    parameter LINE_LENGTH=640,    // length of line
    parameter SCALE=1     // scaling factor (>=1)
    ) (
    input  wire logic clk_write,    // input clock
    input  wire logic clk_read,   // output clock
    input  wire logic rst_write,    // reset (clk_write)
    input  wire logic rst_read,   // reset (clk_read)
    output      logic data_req,  // request input data (clk_write)
    input  wire logic en_in,     // enable input (clk_write)
    input  wire logic en_out,    // enable output (clk_read)
    input  wire logic frame,     // start a new frame (clk_read)
    input  wire logic line,      // start a new line (clk_read)
    input  wire logic [DATA_WIDTH-1:0] r_write,  g_write,  b_write,  // data in (clk_write)
    output      logic [DATA_WIDTH-1:0] r_read, g_read, b_read // data out (clk_read)
    );

    // output data to display
    logic [$clog2(LINE_LENGTH)-1:0] addr_out;        // output address (pixel counter)
    logic [$clog2(SCALE)-1:0] cnt_v, cnt_h;  // scale counters
    logic set_end;   // line set end
    logic get_data;  // fresh data needed
    always_ff @(posedge clk_read) begin
        if (frame) begin  // reset addr and counters at frame start
            addr_out <= 0;
            cnt_h <= 0;
            cnt_v <= 0;
            set_end <= 1;  // ensure first line of frame triggers data_req
        end else if (en_out && !set_end) begin
            if (cnt_h == SCALE-1) begin
                cnt_h <= 0;
                if (addr_out == LINE_LENGTH-1) begin  // end of line
                    addr_out <= 0;
                    if (cnt_v == SCALE-1) begin  // end of line set
                        cnt_v <= 0;
                        set_end <= 1;
                    end else cnt_v <= cnt_v + 1;
                end else addr_out <= addr_out + 1;
            end else cnt_h <= cnt_h + 1;
        end else if (get_data) set_end <= 0;
        if (rst_read) begin
            addr_out <= 0;
            cnt_h <= 0;
            cnt_v <= 0;
            set_end <= 0;
        end
    end

    // request new data on at end of line set (needs to be in clk_write domain)
    always_comb get_data = (line && set_end);
    xd xd_req (.clk_i(clk_read), .clk_o(clk_write),
               .rst_i(rst_read), .rst_o(rst_write), .i(get_data), .o(data_req));

    // read data in
    logic [$clog2(LINE_LENGTH)-1:0] addr_in;
    always_ff @(posedge clk_write) begin
        if (en_in) addr_in <= (addr_in == LINE_LENGTH-1) ? 0 : addr_in + 1;
        if (data_req) addr_in <= 0;  // reset addr_in when we request new data
        if (rst_write) addr_in <= 0;
    end

    // red channel
    bram_dp #(.DATA_WIDTH(DATA_WIDTH), .DATA_LENGTH(LINE_LENGTH)) ch0 (
        .clk_write(clk_write),
        .clk_read(clk_read),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_write(r_write),
        .data_read(r_read)
    );

    // green channel
    bram_dp #(.DATA_WIDTH(DATA_WIDTH), .DATA_LENGTH(LINE_LENGTH)) ch1 (
        .clk_write(clk_write),
        .clk_read(clk_read),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_write(g_write),
        .data_read(g_read)
    );

    // blue channel
    bram_dp #(.DATA_WIDTH(DATA_WIDTH), .DATA_LENGTH(LINE_LENGTH)) ch2 (
        .clk_write(clk_write),
        .clk_read(clk_read),
        .we(en_in),
        .addr_write(addr_in),
        .addr_read(addr_out),
        .data_write(b_write),
        .data_read(b_read)
    );
endmodule
