# Vivado Tcl Console: source waves_programa4.tcl

add_wave -radix bin /tb_programa4/clk
add_wave -radix bin /tb_programa4/reset
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/PCF
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/InstrF
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/InstrD
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/InstrE
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/InstrM
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/InstrW
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/BranchE
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/JumpE
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/ZeroE
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/PCSrcE
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/PCTarget
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/FlushD
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/FlushE
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/MemWriteM
add_wave -radix bin /tb_programa4/dut/rvsingle/dp/RegWriteW
add_wave -radix unsigned /tb_programa4/dut/rvsingle/dp/RdW
add_wave -radix hex /tb_programa4/dut/rvsingle/dp/ResultW

restart
run all
