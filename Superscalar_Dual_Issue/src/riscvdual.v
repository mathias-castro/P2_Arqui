module riscvdual(input  clk, reset,
                 output [31:0] FetchAddrF,
                 input  [31:0] InstrF0, InstrF1,
                 output        MemWriteM,
                 output [31:0] DataAdrM, WriteDataM,
                 input  [31:0] ReadDataM);

  wire [31:0] InstrD0, InstrD1;

  wire       RegWriteD0, MemWriteD0, JumpD0, BranchD0, ALUSrcD0;
  wire [1:0] ResultSrcD0, ImmSrcD0;
  wire [2:0] ALUControlD0;

  wire       RegWriteD1, MemWriteD1, JumpD1, BranchD1, ALUSrcD1;
  wire [1:0] ResultSrcD1, ImmSrcD1;
  wire [2:0] ALUControlD1;

  controller c0(
    .op(InstrD0[6:0]),
    .funct3(InstrD0[14:12]),
    .funct7b5(InstrD0[30]),
    .ResultSrc(ResultSrcD0),
    .MemWrite(MemWriteD0),
    .ALUSrc(ALUSrcD0),
    .RegWrite(RegWriteD0),
    .Jump(JumpD0),
    .ImmSrc(ImmSrcD0),
    .ALUControl(ALUControlD0),
    .Branch(BranchD0)
  );

  controller c1(
    .op(InstrD1[6:0]),
    .funct3(InstrD1[14:12]),
    .funct7b5(InstrD1[30]),
    .ResultSrc(ResultSrcD1),
    .MemWrite(MemWriteD1),
    .ALUSrc(ALUSrcD1),
    .RegWrite(RegWriteD1),
    .Jump(JumpD1),
    .ImmSrc(ImmSrcD1),
    .ALUControl(ALUControlD1),
    .Branch(BranchD1)
  );

  datapath_dual dp(
    .clk(clk),
    .reset(reset),
    .FetchAddrF(FetchAddrF),
    .InstrF0(InstrF0),
    .InstrF1(InstrF1),
    .InstrD0(InstrD0),
    .InstrD1(InstrD1),
    .RegWriteD0(RegWriteD0), .MemWriteD0(MemWriteD0), .JumpD0(JumpD0),
    .BranchD0(BranchD0), .ALUSrcD0(ALUSrcD0), .ResultSrcD0(ResultSrcD0),
    .ImmSrcD0(ImmSrcD0), .ALUControlD0(ALUControlD0),
    .RegWriteD1(RegWriteD1), .MemWriteD1(MemWriteD1), .JumpD1(JumpD1),
    .BranchD1(BranchD1), .ALUSrcD1(ALUSrcD1), .ResultSrcD1(ResultSrcD1),
    .ImmSrcD1(ImmSrcD1), .ALUControlD1(ALUControlD1),
    .MemWriteM(MemWriteM),
    .DataAdrM(DataAdrM),
    .WriteDataM(WriteDataM),
    .ReadDataM(ReadDataM)
  );
endmodule
