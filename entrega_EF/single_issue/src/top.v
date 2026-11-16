module top #(parameter MEMFILE = "riscvtest.mem")
          (input         clk, reset,
           output [31:0] WriteDataM, DataAdrM,
           output        MemWriteM);

  wire [31:0] PCF, InstrF, ReadDataM;

  // instantiate processor and memories
  riscv rv(.clk(clk), .reset(reset),
           .PCF(PCF), .InstrF(InstrF),
           .MemWriteM(MemWriteM), .ALUResultM(DataAdrM), .WriteDataM(WriteDataM),
           .ReadDataM(ReadDataM));

  imem #(.MEMFILE(MEMFILE)) imem(.a(PCF), .rd(InstrF));

  dmem dmem(.clk(clk), .we(MemWriteM), .a(DataAdrM), .wd(WriteDataM), .rd(ReadDataM));
endmodule
