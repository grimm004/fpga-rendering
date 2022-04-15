`default_nettype none
`timescale 1ns / 1ps

import Utils::valf;

module fixed_fixed2c_tb;

    valf i, o;

    fixed_fixed2c uut (.i, .o);

    initial begin
        i = 32'b0000000000000001_0000000000000000;

        #50;

        i = 32'b0000000000000000_1000000000000000;

        #50;

        i = 32'b1000000000000000_0000000000000000;

        #50;

        i = 32'b1000000000000001_0000000000000000;

        #50;

        i = 32'b1000000000000000_1000000000000000;

        #50;

        i = 32'b1000000000000001_1000000000000000;

        #50;

    end

endmodule
