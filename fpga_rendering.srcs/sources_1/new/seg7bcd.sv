`default_nettype none
`timescale 1ns / 1ps


module seg7bcd #(
    parameter INPUT_WIDTH=32
    ) (
    input  wire logic                   clk,
    input  wire logic [INPUT_WIDTH-1:0] bin_in,
    output      logic [6:0]             seg,
    output      logic                   dp,
    output      logic [7:0]             an
    );

    logic [31:0] bcd;
    logic dd_start, dd_done;

    doubledabble #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .DECIMAL_DIGITS(8)
    ) dd_inst (
        .clk,
        .start(dd_start),
        .bin_in(bin_in),
        .bcd_out(bcd),
        .done(dd_done)
    );

    seg7decimal seg7 (
        .clk,
        .x(bcd),
        .seg,
        .dp,
        .an
    );

    parameter REFRESH_COUNT = 400000;

    logic [$clog2(REFRESH_COUNT)-1:0] counter = 0;
    logic start;

    always @(posedge clk) begin
        if (counter == REFRESH_COUNT - 1) begin
            counter <= 0;
            start <= 1;
        end else begin
            counter <= counter + 1;
            start <= 0;
        end
    end

    enum {IDLE, DD} state;
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                if (start) begin
                    state <= DD;
                    dd_start <= 1;
                end
            end
            DD: begin
                dd_start <= 0;
                if (dd_done)
                    state <= IDLE;
            end
        endcase
    end

endmodule
