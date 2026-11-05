# Vivado Tcl Console: source waves_programa1.tcl

add_wave -radix bin /tb_programa1/clk
add_wave -radix bin /tb_programa1/reset
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/PCF
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/InstrF
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/InstrD
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/InstrE
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/InstrM
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/InstrW
add_wave -radix unsigned /tb_programa1/dut/rvsingle/dp/RdW
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/ResultW
add_wave -radix bin /tb_programa1/dut/rvsingle/dp/RegWriteW
add_wave -radix bin /tb_programa1/dut/rvsingle/dp/ForwardAE
add_wave -radix bin /tb_programa1/dut/rvsingle/dp/ForwardBE
add_wave -radix bin /tb_programa1/dut/rvsingle/dp/StallF
add_wave -radix bin /tb_programa1/dut/rvsingle/dp/MemWriteM
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/ALUResultM
add_wave -radix hex /tb_programa1/dut/rvsingle/dp/WriteDataM

restart
run all
