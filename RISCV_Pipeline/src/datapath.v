module datapath(input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  ALUSrc,
                input  RegWrite,
                input  [1:0]  ImmSrc, 
                input  [2:0]  ALUControl,
                output [31:0] InstrD,
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResultM, WriteDataM,
                output MemWriteM,
                input  [31:0] ReadData,
                input MemWrite,
                input Jump,
                input Branch);
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExt; 
    wire [31:0] RD1D, RD2D, SrcAE, SrcBE, ALUResultE, WriteDataE;
  wire        ZeroE, PCSrcE;
  wire [31:0] ResultW;

  // Señales de la etapa Decode
  wire [31:0] PCD, PCPlus4D;
  wire StallF, StallD;
  wire FlushD;

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
  wire FlushE;

  // Registro de pipeline D->E
  flopenrc #(WIDTH) rd1ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(RD1D),
    .q(RD1E)
  );

  flopenrc #(WIDTH) rd2ereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(RD2D),
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
    wire [31:0] PCPlus4M;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [4:0]  RdM, RdW;
    wire        RegWriteM, RegWriteW;
    wire [1:0]  ResultSrcM, ResultSrcW;

    // Execute -> Memory
    flopr #(WIDTH) alumreg(
      .clk(clk),
      .reset(reset),
      .d(ALUResultE),
      .q(ALUResultM)
    );

    flopr #(WIDTH) writedatamreg(
      .clk(clk),
      .reset(reset),
      .d(WriteDataE),
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




  // Senales para visualizar cada instruccion en las waveforms
  wire [31:0] PCF    = PC;
  wire [31:0] InstrF = Instr;
  wire [31:0] InstrE, InstrM, InstrW;

  flopenrc #(WIDTH) instrereg(
    .clk(clk),
    .reset(reset),
    .clr(FlushE),
    .en(1'b1),
    .d(InstrD),
    .q(InstrE)
  );

  flopr #(WIDTH) instrmreg(
    .clk(clk),
    .reset(reset),
    .d(InstrE),
    .q(InstrM)
  );

  flopr #(WIDTH) instrwreg(
    .clk(clk),
    .reset(reset),
    .d(InstrM),
    .q(InstrW)
  );

  // next PC logic
  flopenrc #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .clr(1'b0),
    .en(~StallF),
    .d(PCNext),
    .q(PC)
  );

  adder       pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  assign PCSrcE = (BranchE & ZeroE) | JumpE;

  adder       pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTarget)
  ); 

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrcE),
    .y(PCNext)
  ); 
 
  // register file logic
  regfile     rf(
    .clk(clk), 
    .we3(RegWriteW),
    .a1(InstrD[19:15]),
    .a2(InstrD[24:20]),
    .a3(RdW),
    .wd3(ResultW),
    .rd1(RD1D),
    .rd2(RD2D)
  ); 

  extend      ext(
    .instr(InstrD[31:7]),
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // Forwarding
  wire [1:0] ForwardAE, ForwardBE;

  hazardunit hu(
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdM(RdM),
    .RdW(RdW),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
    .Rs1D(InstrD[19:15]),
    .Rs2D(InstrD[24:20]),
    .RdE(RdE),
    .ResultSrcE0(ResultSrcE[0]),
    .StallF(StallF),
    .StallD(StallD),
    .PCSrcE(PCSrcE),
    .FlushD(FlushD),
    .FlushE(FlushE)
  );

  mux3 #(WIDTH)  fwdamux(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardAE),
    .y(SrcAE)
  );

  mux3 #(WIDTH)  fwdbmux(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardBE),
    .y(WriteDataE)
  );

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(WriteDataE),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(SrcBE)
  ); 

  alu         alu(
    .a(SrcAE),
    .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE),
    .zero(ZeroE)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  ); 
endmodule