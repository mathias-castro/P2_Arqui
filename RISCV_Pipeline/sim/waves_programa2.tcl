# Vivado Tcl Console: source waves_programa2.tcl

add_wave -radix bin /tb_programa2/clk
add_wave -radix bin /tb_programa2/reset
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/PCF
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrF
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrD
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrM
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrW
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/Rs1E
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/Rs2E
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/RdM
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/RdW
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/RegWriteM
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/RegWriteW
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/ForwardAE
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/ForwardBE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/ALUResultM
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/ResultW
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/SrcAE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/WriteDataE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/ALUResultE

restart
run all
