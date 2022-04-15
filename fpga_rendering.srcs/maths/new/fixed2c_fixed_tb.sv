`default_nettype none
`timescale 1ns / 1ps

import Utils::valf;

module fixed2c_fixed_tb;

    valf i, o;

    fixed2c_fixed uut (.i, .o);

    initial begin
        i = 32'b0000000000000001_0000000000000000;

        #50;

        i = 32'b0000000000000000_1000000000000000;

        #50;

        i = 32'b1111111111111111_0000000000000000;

        #50;

        i = 32'b1111111111111110_0000000000000000;

        #50;

        i = 32'b1111111111111111_1000000000000000;

        #50;

    end

endmodule
