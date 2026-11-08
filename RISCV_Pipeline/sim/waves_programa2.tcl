# Vivado Tcl Console: source waves_programa2.tcl

catch {remove_wave [get_waves *]}

add_wave -radix bin /tb_programa2/clk
add_wave -radix bin /tb_programa2/reset
add_wave_divider "Instruccion por etapa"
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/PCF
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrF
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrD
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrM
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/InstrW
add_wave_divider "Hazard Unit: entradas"
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/Rs1D
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/Rs2D
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/Rs1E
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/Rs2E
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/RdE
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/RdM
add_wave -radix unsigned /tb_programa2/dut/rvsingle/dp/hu/RdW
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/RegWriteM
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/RegWriteW
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/ResultSrcE0
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/PCSrcE
add_wave_divider "Hazard Unit: salidas"
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/ForwardAE
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/ForwardBE
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/lwStall
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/StallF
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/StallD
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/FlushD
add_wave -radix bin /tb_programa2/dut/rvsingle/dp/hu/FlushE
add_wave_divider "Datos"
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/SrcAE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/WriteDataE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/ALUResultE
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/ALUResultM
add_wave -radix hex /tb_programa2/dut/rvsingle/dp/ResultW

restart
run all
