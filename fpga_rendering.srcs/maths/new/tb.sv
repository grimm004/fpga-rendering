`default_nettype none
`timescale 1ns / 1ps


module tb();

//    logic clk;
//    logic signed [31:-32] acc;
//    logic signed [15:-16] x [0:3];
//    logic signed [15:-16] y [0:3];
//    logic signed [15:-16] z;
//    logic [1:0] i;

////    assign z = temp[15:-16];

//    initial begin
//        clk = 0;
//        forever begin
//            #5 clk = ~clk;
//        end
//    end

////    initial begin
////        x = 32'b0000000000000000_1000000000000000;
////        y = 32'b1111111111111111_0000000000000000;
////        acc = x * y;
////    end

//    enum {FIRST, SECOND, LAST} state;
//    always_ff @(posedge clk) begin
//        case (state)
//            FIRST: begin
//                x[0] = 32'b0000000000000000_1000000000000000;
//                y[0] = 32'b1111111111111111_0000000000000000;
//                x[1] = 32'b0000000000000001_0000000000000000;
//                y[1] = 32'b1111111111111110_1000000000000000;
//                x[2] = 32'b1111111111111110_0000000000000000;
//                y[2] = 32'b0000000000000001_0000000000000000;
//                x[3] = 32'b0000000000000000_0000000000000000;
//                y[3] = 32'b0000000000000000_0000000000000000;
//                i <= 0;
//                acc <= 0;
//                state <= SECOND;
//            end
//            SECOND: begin
//                acc <= acc + (x[i] * y[i]);
                
//                if (i == 2'd3)
//                    state <= LAST;
//                else
//                    i <= i + 1;
//            end
//            LAST: begin
//                z <= acc[15:-16];
//                state <= FIRST;
//            end
//        endcase
//    end

endmodule
