# assumed to run from /<project directory>/sim
vlib work

vcom -reportprogress 300 -work work ../vhdl/light52_pkg.vhdl
vcom -reportprogress 300 -work work ../vhdl/light52_ucode_pkg.vhdl
vcom -reportprogress 300 -work work ../vhdl/light52_muldiv.vhdl

vcom -reportprogress 300 -work work ../vhdl/tb/txt_util.vhdl
vcom -reportprogress 300 -work work ../vhdl/tb/light52_tb_pkg.vhdl
vcom -reportprogress 300 -work work ../vhdl/tb/light52_muldiv_tb.vhdl

vsim -t ps work.light52_muldiv_tb(testbench)
do ./light52_muldiv_tb_wave.do
set PrefMain(font) {Courier 9 roman normal}
