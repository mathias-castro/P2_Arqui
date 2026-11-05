# Vivado Tcl Console: source waves_dual_regfile.tcl

catch {remove_wave [get_waves *]}

add_wave -radix bin /tb_dual_regfile/clk
add_wave -radix bin /tb_dual_regfile/we0
add_wave -radix bin /tb_dual_regfile/we1
add_wave -radix unsigned /tb_dual_regfile/wa0
add_wave -radix unsigned /tb_dual_regfile/wa1
add_wave -radix unsigned /tb_dual_regfile/wd0
add_wave -radix unsigned /tb_dual_regfile/wd1
add_wave -radix unsigned /tb_dual_regfile/ra10
add_wave -radix unsigned /tb_dual_regfile/ra20
add_wave -radix unsigned /tb_dual_regfile/ra11
add_wave -radix unsigned /tb_dual_regfile/ra21
add_wave -radix unsigned /tb_dual_regfile/rd10
add_wave -radix unsigned /tb_dual_regfile/rd20
add_wave -radix unsigned /tb_dual_regfile/rd11
add_wave -radix unsigned /tb_dual_regfile/rd21

restart
run all
