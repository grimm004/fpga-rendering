`timescale 1ns / 1ps


module testbench;

    reg CLK100MHZ = 0;
    wire CPU_RESET = 1;

    wire VGA_HS;
    wire VGA_VS;
    wire [3:0] VGA_R;
    wire [3:0] VGA_G;
    wire [3:0] VGA_B;

    top UUT (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESET(CPU_RESET),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
    );

    always #5 CLK100MHZ = ~CLK100MHZ;

endmodule
