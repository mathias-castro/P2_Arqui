module top_dual #(parameter MEMFILE = "e2_programa1.mem")
                (input  clk, reset,
                 output [31:0] WriteDataM, DataAdrM,
                 output        MemWriteM);

  wire [31:0] FetchAddrF, InstrF0, InstrF1, ReadDataM;

  riscvdual rvdual(
    .clk(clk),
    .reset(reset),
    .FetchAddrF(FetchAddrF),
    .InstrF0(InstrF0),
    .InstrF1(InstrF1),
    .MemWriteM(MemWriteM),
    .DataAdrM(DataAdrM),
    .WriteDataM(WriteDataM),
    .ReadDataM(ReadDataM)
  );

  imem_dual #(.MEMFILE(MEMFILE)) imem(
    .a(FetchAddrF),
    .rd0(InstrF0),
    .rd1(InstrF1)
  );

  dmem dmem(
    .clk(clk),
    .we(MemWriteM),
    .a(DataAdrM),
    .wd(WriteDataM),
    .rd(ReadDataM)
  );
endmodule
