module datapath_dual(input  clk, reset,
                     output [31:0] FetchAddrF,
                     input  [31:0] InstrF0, InstrF1,
                     output [31:0] InstrD0, InstrD1,
                     input         RegWriteD0, MemWriteD0, JumpD0, BranchD0, ALUSrcD0,
                     input  [1:0]  ResultSrcD0, ImmSrcD0,
                     input  [2:0]  ALUControlD0,
                     input         RegWriteD1, MemWriteD1, JumpD1, BranchD1, ALUSrcD1,
                     input  [1:0]  ResultSrcD1, ImmSrcD1,
                     input  [2:0]  ALUControlD1,
                     output        MemWriteM,
                     output [31:0] DataAdrM, WriteDataM,
                     input  [31:0] ReadDataM);

  localparam WIDTH = 32;

  wire StallF, StallD, Realign, FlushD, FlushE0, FlushE1, FlushM1;
  wire Issue0, Issue1;

  // ===================== Fetch =====================
  // Realign: si solo salio el slot 0, se relee desde la instruccion pendiente (PCPlus4D)
  wire [31:0] PCF, PCNextF, PCPlus4F, PCPlus8F;
  wire [31:0] PCD, PCPlus4D, PCPlus8D;
  wire [31:0] PCTargetE;
  wire        PCSrcE;

  flopenrc #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .clr(1'b0),
    .en(~StallF),
    .d(PCNextF),
    .q(PCF)
  );

  mux2 #(WIDTH) fetchmux(
    .d0(PCF),
    .d1(PCPlus4D),
    .s(Realign),
    .y(FetchAddrF)
  );

  adder pcadd4(.a(FetchAddrF), .b(32'd4), .y(PCPlus4F));
  adder pcadd8(.a(FetchAddrF), .b(32'd8), .y(PCPlus8F));

  mux2 #(WIDTH) pcmux(
    .d0(PCPlus8F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCNextF)
  );

  // ===================== Registro F -> D =====================
  flopenrc #(5*WIDTH) fdreg(
    .clk(clk),
    .reset(reset),
    .clr(FlushD),
    .en(~StallD),
    .d({InstrF0, InstrF1, FetchAddrF, PCPlus4F, PCPlus8F}),
    .q({InstrD0, InstrD1, PCD, PCPlus4D, PCPlus8D})
  );

  // ===================== Decode =====================
  wire [31:0] RD1D, RD2D, RD4D, RD5D;
  wire [31:0] ImmExtD0, ImmExtD1;
  wire [4:0]  Rs1D0, Rs2D0, RdD0, Rs1D1, Rs2D1, RdD1;
  wire [31:0] ResultW0, ResultW1;
  wire [4:0]  RdW0, RdW1;
  wire        RegWriteW0, RegWriteW1;

  assign Rs1D0 = InstrD0[19:15];
  assign Rs2D0 = InstrD0[24:20];
  assign RdD0  = InstrD0[11:7];
  assign Rs1D1 = InstrD1[19:15];
  assign Rs2D1 = InstrD1[24:20];
  assign RdD1  = InstrD1[11:7];

  regfile_dual rf(
    .clk(clk),
    .we3(RegWriteW0), .a3(RdW0), .wd3(ResultW0),
    .we6(RegWriteW1), .a6(RdW1), .wd6(ResultW1),
    .a1(Rs1D0), .a2(Rs2D0), .rd1(RD1D), .rd2(RD2D),
    .a4(Rs1D1), .a5(Rs2D1), .rd4(RD4D), .rd5(RD5D)
  );

  extend ext0(.instr(InstrD0[31:7]), .immsrc(ImmSrcD0), .immext(ImmExtD0));
  extend ext1(.instr(InstrD1[31:7]), .immsrc(ImmSrcD1), .immext(ImmExtD1));

  // ===================== Registro D -> E =====================
  wire [31:0] RD1E, RD2E, ImmExtE0, PCE0, PCPlus4E0;
  wire [4:0]  Rs1E0, Rs2E0, RdE0;
  wire        RegWriteE0, MemWriteE0, JumpE0, BranchE0, ALUSrcE0;
  wire [1:0]  ResultSrcE0;
  wire [2:0]  ALUControlE0;

  flopenrc #(5*WIDTH + 15) dereg0(
    .clk(clk),
    .reset(reset),
    .clr(FlushE0),
    .en(1'b1),
    .d({RD1D, RD2D, ImmExtD0, PCD, PCPlus4D, Rs1D0, Rs2D0, RdD0}),
    .q({RD1E, RD2E, ImmExtE0, PCE0, PCPlus4E0, Rs1E0, Rs2E0, RdE0})
  );

  flopenrc #(10) controlereg0(
    .clk(clk),
    .reset(reset),
    .clr(FlushE0),
    .en(1'b1),
    .d({RegWriteD0, ResultSrcD0, MemWriteD0, JumpD0, BranchD0, ALUControlD0, ALUSrcD0}),
    .q({RegWriteE0, ResultSrcE0, MemWriteE0, JumpE0, BranchE0, ALUControlE0, ALUSrcE0})
  );

  // la via 1 esta en PCPlus4D, asi que su PC + 4 es PCPlus8D
  wire [31:0] RD4E, RD5E, ImmExtE1, PCE1, PCPlus4E1;
  wire [4:0]  Rs1E1, Rs2E1, RdE1;
  wire        RegWriteE1, MemWriteE1, JumpE1, BranchE1, ALUSrcE1;
  wire [1:0]  ResultSrcE1;
  wire [2:0]  ALUControlE1;

  flopenrc #(5*WIDTH + 15) dereg1(
    .clk(clk),
    .reset(reset),
    .clr(FlushE1),
    .en(1'b1),
    .d({RD4D, RD5D, ImmExtD1, PCPlus4D, PCPlus8D, Rs1D1, Rs2D1, RdD1}),
    .q({RD4E, RD5E, ImmExtE1, PCE1, PCPlus4E1, Rs1E1, Rs2E1, RdE1})
  );

  flopenrc #(10) controlereg1(
    .clk(clk),
    .reset(reset),
    .clr(FlushE1),
    .en(1'b1),
    .d({RegWriteD1, ResultSrcD1, MemWriteD1, JumpD1, BranchD1, ALUControlD1, ALUSrcD1}),
    .q({RegWriteE1, ResultSrcE1, MemWriteE1, JumpE1, BranchE1, ALUControlE1, ALUSrcE1})
  );

  // ===================== Execute =====================
  wire [31:0] SrcAE0, SrcBE0, WriteDataE0, ALUResultE0;
  wire [31:0] SrcAE1, SrcBE1, WriteDataE1, ALUResultE1;
  wire        ZeroE0, ZeroE1;
  wire [2:0]  ForwardAE0, ForwardBE0, ForwardAE1, ForwardBE1;
  wire [31:0] ALUResultM0, ALUResultM1;

  // 000 RF | 001 ResultW0 | 010 ResultW1 | 011 ALUResultM0 | 100 ALUResultM1
  mux5 #(WIDTH) fwdamux0(.d0(RD1E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                         .s(ForwardAE0), .y(SrcAE0));
  mux5 #(WIDTH) fwdbmux0(.d0(RD2E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                         .s(ForwardBE0), .y(WriteDataE0));
  mux5 #(WIDTH) fwdamux1(.d0(RD4E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                         .s(ForwardAE1), .y(SrcAE1));
  mux5 #(WIDTH) fwdbmux1(.d0(RD5E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                         .s(ForwardBE1), .y(WriteDataE1));

  mux2 #(WIDTH) srcbmux0(
    .d0(WriteDataE0),
    .d1(ImmExtE0),
    .s(ALUSrcE0),
    .y(SrcBE0)
  );

  alu alu0(
    .a(SrcAE0),
    .b(SrcBE0),
    .alucontrol(ALUControlE0),
    .result(ALUResultE0),
    .zero(ZeroE0)
  );

  mux2 #(WIDTH) srcbmux1(
    .d0(WriteDataE1),
    .d1(ImmExtE1),
    .s(ALUSrcE1),
    .y(SrcBE1)
  );

  alu alu1(
    .a(SrcAE1),
    .b(SrcBE1),
    .alucontrol(ALUControlE1),
    .result(ALUResultE1),
    .zero(ZeroE1)
  );

  // Recurso unico de branch: si salta la via 0, tiene prioridad
  wire TakenE0, TakenE1, BranchLaneE;
  wire [31:0] BranchPCE, BranchImmE;

  assign TakenE0     = (BranchE0 & ZeroE0) | JumpE0;
  assign TakenE1     = (BranchE1 & ZeroE1) | JumpE1;
  assign PCSrcE      = TakenE0 | TakenE1;
  assign BranchLaneE = ~TakenE0;

  mux2 #(WIDTH) branchpcmux(
    .d0(PCE0),
    .d1(PCE1),
    .s(BranchLaneE),
    .y(BranchPCE)
  );

  mux2 #(WIDTH) branchimmmux(
    .d0(ImmExtE0),
    .d1(ImmExtE1),
    .s(BranchLaneE),
    .y(BranchImmE)
  );

  adder pcaddbranch(
    .a(BranchPCE),
    .b(BranchImmE),
    .y(PCTargetE)
  );

  // ===================== Registro E -> M =====================
  wire [31:0] WriteDataM0, WriteDataM1, PCPlus4M0, PCPlus4M1;
  wire [4:0]  RdM0, RdM1;
  wire        RegWriteM0, RegWriteM1, MemWriteM0, MemWriteM1;
  wire [1:0]  ResultSrcM0, ResultSrcM1;

  flopr #(3*WIDTH + 5) emreg0(
    .clk(clk),
    .reset(reset),
    .d({ALUResultE0, WriteDataE0, PCPlus4E0, RdE0}),
    .q({ALUResultM0, WriteDataM0, PCPlus4M0, RdM0})
  );

  flopr #(4) controlmreg0(
    .clk(clk),
    .reset(reset),
    .d({RegWriteE0, ResultSrcE0, MemWriteE0}),
    .q({RegWriteM0, ResultSrcM0, MemWriteM0})
  );

  // FlushM1: la via 1 se anula si la via 0 del mismo par salto
  flopenrc #(3*WIDTH + 5) emreg1(
    .clk(clk),
    .reset(reset),
    .clr(FlushM1),
    .en(1'b1),
    .d({ALUResultE1, WriteDataE1, PCPlus4E1, RdE1}),
    .q({ALUResultM1, WriteDataM1, PCPlus4M1, RdM1})
  );

  flopenrc #(4) controlmreg1(
    .clk(clk),
    .reset(reset),
    .clr(FlushM1),
    .en(1'b1),
    .d({RegWriteE1, ResultSrcE1, MemWriteE1}),
    .q({RegWriteM1, ResultSrcM1, MemWriteM1})
  );

  // ===================== Memory: un solo puerto =====================
  // el puerto lo usa la via que tiene el lw o el sw
  wire MemLaneM;
  assign MemLaneM  = MemWriteM1 | (ResultSrcM1 == 2'b01);
  assign MemWriteM = MemWriteM0 | MemWriteM1;

  mux2 #(WIDTH) dataadrmux(
    .d0(ALUResultM0),
    .d1(ALUResultM1),
    .s(MemLaneM),
    .y(DataAdrM)
  );

  mux2 #(WIDTH) writedatamux(
    .d0(WriteDataM0),
    .d1(WriteDataM1),
    .s(MemLaneM),
    .y(WriteDataM)
  );

  // ===================== Registro M -> W =====================
  wire [31:0] ALUResultW0, ReadDataW0, PCPlus4W0;
  wire [31:0] ALUResultW1, ReadDataW1, PCPlus4W1;
  wire [1:0]  ResultSrcW0, ResultSrcW1;

  flopr #(3*WIDTH + 5) mwreg0(
    .clk(clk),
    .reset(reset),
    .d({ALUResultM0, ReadDataM, PCPlus4M0, RdM0}),
    .q({ALUResultW0, ReadDataW0, PCPlus4W0, RdW0})
  );

  flopr #(3) controlwreg0(
    .clk(clk),
    .reset(reset),
    .d({RegWriteM0, ResultSrcM0}),
    .q({RegWriteW0, ResultSrcW0})
  );

  flopr #(3*WIDTH + 5) mwreg1(
    .clk(clk),
    .reset(reset),
    .d({ALUResultM1, ReadDataM, PCPlus4M1, RdM1}),
    .q({ALUResultW1, ReadDataW1, PCPlus4W1, RdW1})
  );

  flopr #(3) controlwreg1(
    .clk(clk),
    .reset(reset),
    .d({RegWriteM1, ResultSrcM1}),
    .q({RegWriteW1, ResultSrcW1})
  );

  // ===================== Writeback =====================
  mux3 #(WIDTH) resultmux0(
    .d0(ALUResultW0),
    .d1(ReadDataW0),
    .d2(PCPlus4W0),
    .s(ResultSrcW0),
    .y(ResultW0)
  );

  mux3 #(WIDTH) resultmux1(
    .d0(ALUResultW1),
    .d1(ReadDataW1),
    .d2(PCPlus4W1),
    .s(ResultSrcW1),
    .y(ResultW1)
  );

  // ===================== Issue Unit y Hazard Unit =====================
  wire LoadUse0, LoadUse1, RAWpar, MemConflict, BranchConflict;

  issueunit iu(
    .opD0(InstrD0[6:0]), .opD1(InstrD1[6:0]),
    .RdD0(RdD0), .Rs1D1(Rs1D1), .Rs2D1(Rs2D1),
    .RegWriteD0(RegWriteD0),
    .MemWriteD0(MemWriteD0), .MemWriteD1(MemWriteD1),
    .ResultSrcD0(ResultSrcD0), .ResultSrcD1(ResultSrcD1),
    .BranchD0(BranchD0), .JumpD0(JumpD0), .BranchD1(BranchD1), .JumpD1(JumpD1),
    .LoadUse0(LoadUse0), .LoadUse1(LoadUse1),
    .RAWpar(RAWpar), .MemConflict(MemConflict), .BranchConflict(BranchConflict),
    .Issue0(Issue0), .Issue1(Issue1)
  );

  hazardunit_dual hu(
    .Rs1E0(Rs1E0), .Rs2E0(Rs2E0), .Rs1E1(Rs1E1), .Rs2E1(Rs2E1),
    .RdM0(RdM0), .RdM1(RdM1), .RdW0(RdW0), .RdW1(RdW1),
    .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
    .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1),
    .ForwardAE0(ForwardAE0), .ForwardBE0(ForwardBE0),
    .ForwardAE1(ForwardAE1), .ForwardBE1(ForwardBE1),
    .opD0(InstrD0[6:0]), .opD1(InstrD1[6:0]),
    .Rs1D0(Rs1D0), .Rs2D0(Rs2D0), .Rs1D1(Rs1D1), .Rs2D1(Rs2D1),
    .RdE0(RdE0), .RdE1(RdE1),
    .RegWriteE0(RegWriteE0), .RegWriteE1(RegWriteE1),
    .ResultSrcE0b0(ResultSrcE0[0]), .ResultSrcE1b0(ResultSrcE1[0]),
    .LoadUse0(LoadUse0), .LoadUse1(LoadUse1),
    .Issue0(Issue0), .Issue1(Issue1),
    .PCSrcE(PCSrcE), .TakenE0(TakenE0),
    .StallF(StallF), .StallD(StallD), .Realign(Realign),
    .FlushD(FlushD), .FlushE0(FlushE0), .FlushE1(FlushE1), .FlushM1(FlushM1)
  );

  // ===================== Solo para waveforms (no afectan al procesador) =====================
  wire [31:0] InstrE0, InstrE1, InstrM0, InstrM1, InstrW0, InstrW1;

  flopenrc #(WIDTH) instrereg0(.clk(clk), .reset(reset), .clr(FlushE0), .en(1'b1),
                               .d(InstrD0), .q(InstrE0));
  flopenrc #(WIDTH) instrereg1(.clk(clk), .reset(reset), .clr(FlushE1), .en(1'b1),
                               .d(InstrD1), .q(InstrE1));
  flopr    #(WIDTH) instrmreg0(.clk(clk), .reset(reset), .d(InstrE0), .q(InstrM0));
  flopenrc #(WIDTH) instrmreg1(.clk(clk), .reset(reset), .clr(FlushM1), .en(1'b1),
                               .d(InstrE1), .q(InstrM1));
  flopr    #(WIDTH) instrwreg0(.clk(clk), .reset(reset), .d(InstrM0), .q(InstrW0));
  flopr    #(WIDTH) instrwreg1(.clk(clk), .reset(reset), .d(InstrM1), .q(InstrW1));
endmodule
