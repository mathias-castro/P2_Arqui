# Vivado Tcl Console: source waves_e2_programa4.tcl

catch {remove_wave [get_waves *]}

add_wave -radix bin /tb_e2_programa4/clk
add_wave -radix bin /tb_e2_programa4/reset
add_wave_divider "Fetch y pares por etapa"
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/PCF
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/FetchAddrF
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/PCD
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrF0
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrF1
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrD0
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrD1
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrE0
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrE1
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrM0
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrM1
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrW0
add_wave -radix hex /tb_e2_programa4/dut/rvdual/dp/InstrW1
add_wave_divider "Issue Unit"
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/RAWpar
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/MemConflict
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/BranchConflict
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/LoadUse0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/LoadUse1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/Issue0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/iu/Issue1
add_wave_divider "Hazard Unit: entradas"
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/Rs1E0
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/Rs2E0
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/Rs1E1
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/Rs2E1
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/RdM0
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/RdM1
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/RdW0
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/hu/RdW1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/RegWriteM0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/RegWriteM1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/RegWriteW0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/RegWriteW1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/PCSrcE
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/TakenE0
add_wave_divider "Hazard Unit: salidas"
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/ForwardAE0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/ForwardBE0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/ForwardAE1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/ForwardBE1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/StallF
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/StallD
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/Realign
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/FlushD
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/FlushE0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/FlushE1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/hu/FlushM1
add_wave_divider "Execute y branch compartido"
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/SrcAE0
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/SrcBE0
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/ALUResultE0
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/SrcAE1
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/SrcBE1
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/ALUResultE1
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/BranchLaneE
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/PCTargetE
add_wave_divider "Memoria: un puerto"
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/MemLaneM
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/MemWriteM
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/DataAdrM
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/WriteDataM
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/ReadDataM
add_wave_divider "Writeback: dos escrituras"
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/RegWriteW0
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/RdW0
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/ResultW0
add_wave -radix bin /tb_e2_programa4/dut/rvdual/dp/RegWriteW1
add_wave -radix unsigned /tb_e2_programa4/dut/rvdual/dp/RdW1
add_wave -radix dec /tb_e2_programa4/dut/rvdual/dp/ResultW1

restart
run all
