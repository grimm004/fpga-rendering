// seg7decimal
// https://github.com/Digilent/Nexys-4-Abacus/blob/master/src/hdl/Seg_7_Display.v
// 06/12/2014

`default_nettype none
`timescale 1ns / 1ps

module seg7decimal (
    input  wire logic        clk,
    input  wire logic [31:0] x,
    output      logic [6:0]  seg,
    output      logic        dp,
    output      logic [7:0]  an
    );

    logic [2:0]  s;	 
    logic [3:0]  digit;
    logic [7:0]  aen;
    logic [19:0] clkdiv;

    assign dp  = 1;
    assign s   = clkdiv[19:17];
    assign aen = 8'b11111111; // all turned off initially

    // quad 4to1 MUX.
    always @(posedge clk)// or posedge clr)
        case(s)
            0: digit = x[3:0];    // s is 00 -->0 ;  digit gets assigned 4 bit value assigned to x[3:0]
            1: digit = x[7:4];    // s is 01 -->1 ;  digit gets assigned 4 bit value assigned to x[7:4]
            2: digit = x[11:8];   // s is 10 -->2 ;  digit gets assigned 4 bit value assigned to x[11:8]
            3: digit = x[15:12];  // s is 11 -->3 ;  digit gets assigned 4 bit value assigned to x[15:12]
            4: digit = x[19:16];
            5: digit = x[23:20];
            6: digit = x[27:24];
            7: digit = x[31:28];
            default: digit = x[3:0];
        endcase

    //decoder or truth-table for 7seg display values
    always @(*)
        case(digit)
            //////////<---MSB-LSB<---
            ////////////gfedcba////////////////////////////////////////////               a
            0: seg = 7'b1000000;   ////0000												 ___
            1: seg = 7'b1111001;   ////0001											 f /    /b
            2: seg = 7'b0100100;   ////0010												 g
            //                                                                           ___
            3: seg = 7'b0110000;   ////0011										 	 e /    /c
            4: seg = 7'b0011001;   ////0100												___
            5: seg = 7'b0010010;   ////0101                                               d  
            6: seg = 7'b0000010;   ////0110
            7: seg = 7'b1111000;   ////0111
            8: seg = 7'b0000000;   ////1000
            9: seg = 7'b0010000;   ////1001
            'hA: seg = 7'b0111111; // dash-(g)
            'hB: seg = 7'b1111111; // all turned off
            'hC: seg = 7'b1110111;
            default: seg = 7'b0000000; // U
        endcase

    always @(*)begin
        an=8'b11111111;
        if(aen[s] == 1)
            an[s] = 0;
    end

    //clkdiv
    always @(posedge clk) begin
        clkdiv <= clkdiv+1;
    end

endmodule
