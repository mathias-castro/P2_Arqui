// Procesador RISC-V pipelined de cinco etapas (Single-Issue)
module riscv(input         clk, reset,
             output [31:0] PCF,
             input  [31:0] InstrF,
             output        MemWriteM,
             output [31:0] ALUResultM, WriteDataM,
             input  [31:0] ReadDataM);

  wire [31:0] InstrD;
  wire        RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
  wire [1:0]  ResultSrcD, ImmSrcD;
  wire [2:0]  ALUControlD;

  controller c(.op(InstrD[6:0]), .funct3(InstrD[14:12]), .funct7b5(InstrD[30]),
               .ResultSrc(ResultSrcD), .MemWrite(MemWriteD), .ALUSrc(ALUSrcD),
               .RegWrite(RegWriteD), .Jump(JumpD), .ImmSrc(ImmSrcD),
               .ALUControl(ALUControlD), .Branch(BranchD));

  datapath dp(.clk(clk), .reset(reset),
              .PCF(PCF), .InstrF(InstrF),
              .InstrD(InstrD),
              .RegWriteD(RegWriteD), .MemWriteD(MemWriteD), .JumpD(JumpD),
              .BranchD(BranchD), .ALUSrcD(ALUSrcD),
              .ResultSrcD(ResultSrcD), .ImmSrcD(ImmSrcD), .ALUControlD(ALUControlD),
              .MemWriteM(MemWriteM), .ALUResultM(ALUResultM), .WriteDataM(WriteDataM),
              .ReadDataM(ReadDataM));
endmodule
