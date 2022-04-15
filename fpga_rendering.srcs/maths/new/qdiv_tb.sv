`default_nettype none
`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:48:08 12/29/2013
// Design Name:   qdiv
// Module Name:   G:/Tran3005/TestDiv.v
// Project Name:  Trancendental
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: qdiv
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module qdiv_tb;

	// Inputs
	reg [31:0] dividend;
	reg [31:0] divisor;
	reg start;
	reg clk;

	// Outputs
	wire [31:0] quotient_out;
	wire complete;
	wire overflow;

	// Instantiate the Unit Under Test (UUT)
	qdiv uut (
		.clk,
		.start,
		.dividend,
		.divisor,
		.quotient_out,
		.complete,
		.overflow
	);

	reg [10:0]	count;

	initial begin
		// Initialize Inputs
		dividend = 32'b1111111111111111_0000000000000000;
		divisor =  32'b0000000000000001_0000000000000000;
		start = 0;
		clk = 0;

		count <= 0;

		// Wait 100 ns for global reset to finish
		#100;

		// Add stimulus here
		forever #2 clk = ~clk;
	end

		always @(posedge clk) begin
			if (count == 48) begin
				count <= 0;
				start <= 1'b1;
				end
			else begin				
				count <= count + 1;
				start <= 1'b0;
				end
			end

		always @(count) begin
			if (count == 48) begin
				if (divisor > 32'h1FFFFFFF) begin
					divisor <= 32'b0000000000000001_0000000000000000;
					dividend = (dividend << 1) + 3;
					end
				else
					divisor = divisor + 32'b0000000000000001_0000000000000000;
				end
			end

	always @(posedge complete)
		$display ("%b,%b,%b, %b", dividend, divisor, quotient_out, overflow);		//	Monitor the stuff we care about

endmodule
