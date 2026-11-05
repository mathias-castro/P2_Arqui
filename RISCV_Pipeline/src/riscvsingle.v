module riscvsingle(input  clk, reset,
                   output [31:0] PC,
                   input  [31:0] Instr,
                   output MemWrite,
                   output [31:0] DataAdr, 
                   output [31:0] WriteData,
                   input  [31:0] ReadData);
  
  wire [31:0] InstrD;
  wire MemWriteD; 
  
  wire       ALUSrc, RegWrite, Jump; 
  wire [1:0] ResultSrc, ImmSrc; 
  wire [2:0] ALUControl; 
  wire Branch;


  controller c(
    .op(InstrD[6:0]), 
    .funct3(InstrD[14:12]), 
    .funct7b5(InstrD[30]), 
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWriteD), 
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl),
    .Branch(Branch)
  ); 
  
  datapath dp(
    .clk(clk), 
    .reset(reset), 
    .ResultSrc(ResultSrc), 
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl),
    .InstrD(InstrD), 
    .PC(PC), 
    .Instr(Instr),
    .ALUResultM(DataAdr), 
    .WriteDataM(WriteData), 
    .ReadData(ReadData),
    .MemWrite(MemWriteD),
    .MemWriteM(MemWrite),
    .Jump(Jump),
    .Branch(Branch)
  ); 
endmodule