# Vivado Tcl Console: source waves_dual_fetch.tcl

catch {remove_wave [get_waves *]}

add_wave -radix bin /tb_dual/clk
add_wave -radix bin /tb_dual/Stall
add_wave -radix unsigned /tb_dual/dut/dual/PC0
add_wave -radix unsigned /tb_dual/dut/dual/PC1
add_wave -radix hex /tb_dual/dut/dual/Instr0
add_wave -radix hex /tb_dual/dut/dual/Instr1
add_wave -radix unsigned /tb_dual/dut/dual/PC0D
add_wave -radix unsigned /tb_dual/dut/dual/PC1D
add_wave -radix hex /tb_dual/dut/dual/Instr0D
add_wave -radix hex /tb_dual/dut/dual/Instr1D
add_wave -radix unsigned /tb_dual/dut/dual/PC0E
add_wave -radix unsigned /tb_dual/dut/dual/PC1E
add_wave -radix bin /tb_dual/dut/dual/ValidE

restart
run all
