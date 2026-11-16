// Datapath del pipeline de cinco etapas. Las senales terminan en F, D, E, M o W
// segun la etapa en la que estan.
module datapath(input         clk, reset,
                // memoria de instrucciones
                output [31:0] PCF,
                input  [31:0] InstrF,
                // control unit (las senales salen en Decode)
                output [31:0] InstrD,
                input         RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD,
                input  [1:0]  ResultSrcD, ImmSrcD,
                input  [2:0]  ALUControlD,
                // memoria de datos
                output        MemWriteM,
                output [31:0] ALUResultM, WriteDataM,
                input  [31:0] ReadDataM);

  // Fetch
  wire [31:0] PCNextF, PCPlus4F;
  // Decode
  wire [31:0] PCD, PCPlus4D, RD1D, RD2D, ImmExtD;
  wire [4:0]  Rs1D, Rs2D, RdD;
  // Execute
  wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  wire [1:0]  ResultSrcE;
  wire [2:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [4:0]  Rs1E, Rs2E, RdE;
  wire [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE, PCTargetE;
  wire        ZeroE, PCSrcE;
  // Memory
  wire        RegWriteM;
  wire [1:0]  ResultSrcM;
  wire [31:0] PCPlus4M;
  wire [4:0]  RdM;
  // Writeback
  wire        RegWriteW;
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
  wire [4:0]  RdW;
  // Hazard Unit
  wire [1:0]  ForwardAE, ForwardBE;
  wire        StallF, StallD, FlushD, FlushE;

  // ---------------- Fetch ----------------
  mux2 #(32) pcmux(.d0(PCPlus4F), .d1(PCTargetE), .s(PCSrcE), .y(PCNextF));

  flopenrc #(32) pcreg(.clk(clk), .reset(reset), .clr(1'b0), .en(~StallF),
                       .d(PCNextF), .q(PCF));

  adder pcadd4(.a(PCF), .b(32'd4), .y(PCPlus4F));

  // registro F/D
  flopenrc #(96) fdreg(.clk(clk), .reset(reset), .clr(FlushD), .en(~StallD),
                       .d({InstrF, PCF, PCPlus4F}),
                       .q({InstrD, PCD, PCPlus4D}));

  // ---------------- Decode ----------------
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD  = InstrD[11:7];

  regfile rf(.clk(clk), .we3(RegWriteW),
             .a1(Rs1D), .a2(Rs2D), .a3(RdW), .wd3(ResultW),
             .rd1(RD1D), .rd2(RD2D));

  extend ext(.instr(InstrD[31:7]), .immsrc(ImmSrcD), .immext(ImmExtD));

  // registro D/E: senales de control y datos
  flopenrc #(10) controlereg(.clk(clk), .reset(reset), .clr(FlushE), .en(1'b1),
                .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD}),
                .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE}));

  flopenrc #(175) dereg(.clk(clk), .reset(reset), .clr(FlushE), .en(1'b1),
                .d({RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D}),
                .q({RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E}));

  // ---------------- Execute ----------------
  mux3 #(32) forwardaemux(.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
  mux3 #(32) forwardbemux(.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(WriteDataE));
  mux2 #(32) srcbmux(.d0(WriteDataE), .d1(ImmExtE), .s(ALUSrcE), .y(SrcBE));

  alu alu(.a(SrcAE), .b(SrcBE), .alucontrol(ALUControlE), .result(ALUResultE), .zero(ZeroE));

  adder pcaddbranch(.a(PCE), .b(ImmExtE), .y(PCTargetE));

  assign PCSrcE = (BranchE & ZeroE) | JumpE;

  // registro E/M
  flopr #(4) controlmreg(.clk(clk), .reset(reset),
                .d({RegWriteE, ResultSrcE, MemWriteE}),
                .q({RegWriteM, ResultSrcM, MemWriteM}));

  flopr #(101) emreg(.clk(clk), .reset(reset),
                .d({ALUResultE, WriteDataE, RdE, PCPlus4E}),
                .q({ALUResultM, WriteDataM, RdM, PCPlus4M}));

  // ---------------- Memory ----------------
  // registro M/W
  flopr #(3) controlwreg(.clk(clk), .reset(reset),
                .d({RegWriteM, ResultSrcM}),
                .q({RegWriteW, ResultSrcW}));

  flopr #(101) mwreg(.clk(clk), .reset(reset),
                .d({ALUResultM, ReadDataM, RdM, PCPlus4M}),
                .q({ALUResultW, ReadDataW, RdW, PCPlus4W}));

  // ---------------- Writeback ----------------
  mux3 #(32) resultmux(.d0(ALUResultW), .d1(ReadDataW), .d2(PCPlus4W), .s(ResultSrcW), .y(ResultW));

  // ---------------- Hazard Unit ----------------
  hazardunit hu(.Rs1D(Rs1D), .Rs2D(Rs2D), .Rs1E(Rs1E), .Rs2E(Rs2E),
                .RdE(RdE), .RdM(RdM), .RdW(RdW),
                .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
                .ResultSrcE0(ResultSrcE[0]), .PCSrcE(PCSrcE),
                .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
                .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .FlushE(FlushE));

  // La instruccion que hay en cada etapa. No la usa el procesador,
  // solo sirve para seguir el programa en las waveforms.
  wire [31:0] InstrE, InstrM, InstrW;
  flopenrc #(32) instrereg(.clk(clk), .reset(reset), .clr(FlushE), .en(1'b1), .d(InstrD), .q(InstrE));
  flopr    #(32) instrmreg(.clk(clk), .reset(reset), .d(InstrE), .q(InstrM));
  flopr    #(32) instrwreg(.clk(clk), .reset(reset), .d(InstrM), .q(InstrW));
endmodule
