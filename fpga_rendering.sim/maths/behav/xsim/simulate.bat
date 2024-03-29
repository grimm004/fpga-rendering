@echo off
REM ****************************************************************************
REM Vivado (TM) v2021.2 (64-bit)
REM
REM Filename    : simulate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for simulating the design by launching the simulator
REM
REM Generated by Vivado on Thu May 05 04:44:41 +0100 2022
REM SW Build 3367213 on Tue Oct 19 02:48:09 MDT 2021
REM
REM IP Build 3369179 on Thu Oct 21 08:25:16 MDT 2021
REM
REM usage: simulate.bat
REM
REM ****************************************************************************
REM simulate design
echo "xsim triangle_area_tb_behav -key {Behavioral:maths:Functional:triangle_area_tb} -tclbatch triangle_area_tb.tcl -view F:/Users/Max/Desktop/fpga_rendering/vecmult4f_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/matmult4f_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/dot4f_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/qdiv_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/fixed_fixed2c_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/fixed2c_fixed_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/interp_gradient_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/clock_counter_tb_behav.wcfg -log simulate.log"
call xsim  triangle_area_tb_behav -key {Behavioral:maths:Functional:triangle_area_tb} -tclbatch triangle_area_tb.tcl -view F:/Users/Max/Desktop/fpga_rendering/vecmult4f_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/matmult4f_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/dot4f_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/qdiv_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/fixed_fixed2c_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/fixed2c_fixed_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/interp_gradient_tb_behav.wcfg -view F:/Users/Max/Desktop/fpga_rendering/fpga_rendering.srcs/maths/imports/fpga_rendering/clock_counter_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
