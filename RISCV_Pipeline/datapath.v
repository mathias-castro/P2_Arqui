module datapath(input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  PCSrc, ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc, 
                input  [2:0]  ALUControl,
                output Zero,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData,
                input MemWrite,
                input Jump,
                input Branch);
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExt; 
  wire [31:0] SrcA, SrcB; 
  wire [31:0] Result; 

  // Señales de la etapa Decode
  wire [31:0] InstrD, PCD, PCPlus4D;
  wire        StallD = 1'b0;   // luego vendra de la Hazard Unit
  wire        FlushD = 1'b0;   // luego vendra de la Hazard Unit

  // Registro de pipeline F->D
  flopenrc #(WIDTH) instrdreg(
    .clk(clk),
    .reset(reset),
    .clr(FlushD),
    .en(~StallD),
    .d(Instr),
    .q(InstrD)
  );

  flopenrc #(WIDTH) pcdreg(
    .clk(clk),
    .reset(reset),
    .clr(FlushD),
    .en(~StallD),
    .d(PC),
    .q(PCD)
  );

  flopenrc #(WIDTH) pcplus4dreg(
    .clk(clk),
    .reset(reset),
    .clr(FlushD),
    .en(~StallD),
    .d(PCPlus4),
    .q(PCPlus4D)
  );


    // Señales de la etapa Execute
  wire [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
  wire [4:0]  Rs1E, Rs2E, RdE;
  wire        FlushE = 1'b0;   // luego vendra de la Hazard Unit

  // Registro de pipeline D->E
  flopenrc #(WIDTH) rd1ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(SrcA),
    .q(RD1E)
  );

  flopenrc #(WIDTH) rd2ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(WriteData),
    .q(RD2E)
  );

  flopenrc #(WIDTH) pcereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(PCD),
    .q(PCE)
  );

  flopenrc #(WIDTH) immextereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(ImmExt),
    .q(ImmExtE)
  );

  flopenrc #(WIDTH) pcplus4ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(PCPlus4D),
    .q(PCPlus4E)
  );

  flopenrc #(5) rs1ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(InstrD[19:15]),
    .q(Rs1E)
  );

  flopenrc #(5) rs2ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(InstrD[24:20]),
    .q(Rs2E)
  );

  flopenrc #(5) rdereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(InstrD[11:7]),
    .q(RdE)
  );



  // Registro de pipeline D->E: senales de control
  wire       RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  wire [1:0] ResultSrcE;
  wire [2:0] ALUControlE;

  flopenrc #(10) controlereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d({RegWrite, ResultSrc, MemWrite, Jump, Branch, ALUControl, ALUSrc}),
    .q({RegWriteE,ResultSrcE,MemWriteE,JumpE,BranchE,ALUControlE,ALUSrcE})
  );

    // Señales de las etapas Memory y Writeback
    wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [4:0]  RdM, RdW;
    wire        RegWriteM, MemWriteM, RegWriteW;
    wire [1:0]  ResultSrcM, ResultSrcW;

    // Execute -> Memory
    flopr #(WIDTH) alumreg(
      .clk(clk),
      .reset(reset),
      .d(ALUResult),
      .q(ALUResultM)
    );

    flopr #(WIDTH) writedatamreg(
      .clk(clk),
      .reset(reset),
      .d(RD2E),
      .q(WriteDataM)
    );

    flopr #(WIDTH) pcplus4mreg(
      .clk(clk),
      .reset(reset),
      .d(PCPlus4E),
      .q(PCPlus4M)
    );

    flopr #(5) rdmreg(
      .clk(clk),
      .reset(reset),
      .d(RdE),
      .q(RdM)
    );

    flopr #(4) controlmreg(
      .clk(clk),
      .reset(reset),
      .d({RegWriteE,ResultSrcE,MemWriteE}),
      .q({RegWriteM,ResultSrcM,MemWriteM})
    );

    // Memory -> Writeback

    flopr #(WIDTH) aluwreg(
      .clk(clk),
      .reset(reset),
      .d(ALUResultM),
      .q(ALUResultW)
    );

    flopr #(WIDTH) readdatawreg(
      .clk(clk),
      .reset(reset),
      .d(ReadData),
      .q(ReadDataW)
    );

    flopr #(WIDTH) pcplus4wreg(
      .clk(clk),
      .reset(reset),
      .d(PCPlus4M),
      .q(PCPlus4W)
    );

    flopr #(5) rdwreg(
      .clk(clk),
      .reset(reset),
      .d(RdM),
      .q(RdW)
    );

    flopr #(3) controlwreg(
      .clk(clk),
      .reset(reset),
      .d({RegWriteM, ResultSrcM}),
      .q({RegWriteW, ResultSrcW})
    );




  // next PC logic
  flopenrc #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .clr(1'b0),
    .en(1'b1),
    .d(PCNext),
    .q(PC)
  );

  adder       pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  adder       pcaddbranch(
    .a(PC), 
    .b(ImmExt), 
    .y(PCTarget)
  ); 

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrc), 
    .y(PCNext)
  ); 
 
  // register file logic
  regfile     rf(
    .clk(clk), 
    .we3(RegWrite), 
    .a1(Instr[19:15]), 
    .a2(Instr[24:20]), 
    .a3(Instr[11:7]), 
    .wd3(Result), 
    .rd1(SrcA), 
    .rd2(WriteData)
  ); 

  extend      ext(
    .instr(Instr[31:7]), 
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(WriteData), 
    .d1(ImmExt), 
    .s(ALUSrc), 
    .y(SrcB)
  ); 

  alu         alu(
    .a(SrcA), 
    .b(SrcB), 
    .alucontrol(ALUControl), 
    .result(ALUResult), 
    .zero(Zero)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResult), 
    .d1(ReadData), 
    .d2(PCPlus4), 
    .s(ResultSrc), 
    .y(Result)
  ); 
endmodule