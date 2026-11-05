# Vivado Tcl Console: source waves_dual_control.tcl

catch {remove_wave [get_waves *]}

add_wave -radix bin /tb_dual/clk
add_wave -radix unsigned /tb_dual/dut/dual/PC0D
add_wave -radix hex /tb_dual/dut/dual/Instr0D
add_wave -radix hex /tb_dual/dut/dual/Instr1D
add_wave -radix bin /tb_dual/dut/dual/ALUControl0D
add_wave -radix bin /tb_dual/dut/dual/ALUControl1D
add_wave -radix dec /tb_dual/dut/dual/ImmExt0D
add_wave -radix dec /tb_dual/dut/dual/ImmExt1D
add_wave -radix bin /tb_dual/dut/dual/MemWrite1D
add_wave -radix bin /tb_dual/dut/dual/Branch0D
add_wave -radix bin /tb_dual/dut/dual/Jump1D
add_wave -radix unsigned /tb_dual/dut/dual/PC0E
add_wave -radix dec /tb_dual/dut/dual/ALUResult0E
add_wave -radix dec /tb_dual/dut/dual/ALUResult1E
add_wave -radix dec /tb_dual/dut/dual/WriteData1E
add_wave -radix bin /tb_dual/dut/dual/Jump1E
add_wave -radix bin /tb_dual/dut/dual/ValidE

restart
run all
