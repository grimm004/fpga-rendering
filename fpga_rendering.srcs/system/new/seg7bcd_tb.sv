`timescale 1ns / 1ps

module seg7bcd_tb;

    logic clk;
    logic [6:0] seg;    // Seven-seg display segments
    logic       dp;     // Seven-seg display decimal point
    logic [7:0] an;     // Seven-seg display anodes

    logic [31:0] bin_in;

    seg7bcd seg7 (
        .clk,
        .bin_in,
        .seg,
        .dp,
        .an
    );

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        bin_in = 123;
    end

endmodule
