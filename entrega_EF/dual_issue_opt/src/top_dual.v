module top_dual #(parameter MEMFILE = "riscvtest.mem")
               (input         clk, reset,
                output [31:0] WriteDataM, DataAdrM,
                output        MemWriteM);

  wire [31:0] PCF, InstrF0, InstrF1, ReadDataM;

  // instantiate processor and memories
  riscvdual rvdual(.clk(clk), .reset(reset),
                   .PCF(PCF), .InstrF0(InstrF0), .InstrF1(InstrF1),
                   .MemWriteM(MemWriteM), .DataAdrM(DataAdrM), .WriteDataM(WriteDataM),
                   .ReadDataM(ReadDataM));

  imem_dual #(.MEMFILE(MEMFILE)) imem(.a(PCF), .rd0(InstrF0), .rd1(InstrF1));

  dmem dmem(.clk(clk), .we(MemWriteM), .a(DataAdrM), .wd(WriteDataM), .rd(ReadDataM));
endmodule
