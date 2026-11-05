# Vivado Tcl Console: source waves_programa3.tcl

add_wave -radix bin /tb_programa3/clk
add_wave -radix bin /tb_programa3/reset
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/PCF
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/InstrF
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/InstrD
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/InstrE
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/InstrM
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/InstrW
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/hu/lwStall
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/StallF
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/StallD
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/FlushE
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/RegWriteE
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/MemWriteE
add_wave -radix unsigned /tb_programa3/dut/rvsingle/dp/RdE
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/ForwardAE
add_wave -radix bin /tb_programa3/dut/rvsingle/dp/ForwardBE
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/SrcAE
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/WriteDataE
add_wave -radix hex /tb_programa3/dut/rvsingle/dp/ResultW

restart
run all
