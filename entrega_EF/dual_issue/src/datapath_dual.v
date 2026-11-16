// Datapath del procesador Dual-Issue. Las senales terminan en 0 o 1 segun la via:
// la via 0 lleva la primera instruccion del par (la mas antigua) y la via 1 la segunda.
module datapath_dual(input         clk, reset,
                     // memoria de instrucciones: dos instrucciones seguidas
                     output [31:0] PCF,
                     input  [31:0] InstrF0, InstrF1,
                     // control unit de cada via (las senales salen en Decode)
                     output [31:0] InstrD0, InstrD1,
                     input         RegWriteD0, MemWriteD0, JumpD0, BranchD0, ALUSrcD0,
                     input  [1:0]  ResultSrcD0, ImmSrcD0,
                     input  [2:0]  ALUControlD0,
                     input         RegWriteD1, MemWriteD1, JumpD1, BranchD1, ALUSrcD1,
                     input  [1:0]  ResultSrcD1, ImmSrcD1,
                     input  [2:0]  ALUControlD1,
                     // memoria de datos: un solo puerto
                     output        MemWriteM,
                     output [31:0] DataAdrM, WriteDataM,
                     input  [31:0] ReadDataM);

  // Fetch
  wire [31:0] PCNextF, PCPlus4F, PCPlus8F;
  wire [95:0] FD0, FD1;
  // Decode
  wire [31:0] PCD0, PCPlus4D0, PCD1, PCPlus4D1;
  wire [31:0] RD1D, RD2D, RD4D, RD5D, ImmExtD0, ImmExtD1;
  wire [6:0]  opD0, opD1;
  wire        UsaRs2D0, UsaRs2D1;
  wire [4:0]  Rs1D0, Rs2D0, RdD0, Rs1D1, Rs2D1, RdD1;
  wire        Issue0, Issue1;
  // Execute
  wire        RegWriteE0, MemWriteE0, JumpE0, BranchE0, ALUSrcE0;
  wire        RegWriteE1, MemWriteE1, JumpE1, BranchE1, ALUSrcE1;
  wire [1:0]  ResultSrcE0, ResultSrcE1;
  wire [2:0]  ALUControlE0, ALUControlE1;
  wire [31:0] RD1E, RD2E, PCE0, ImmExtE0, PCPlus4E0;
  wire [31:0] RD4E, RD5E, PCE1, ImmExtE1, PCPlus4E1;
  wire [4:0]  Rs1E0, Rs2E0, RdE0, Rs1E1, Rs2E1, RdE1;
  wire [31:0] SrcAE0, SrcBE0, WriteDataE0, ALUResultE0;
  wire [31:0] SrcAE1, SrcBE1, WriteDataE1, ALUResultE1;
  wire        ZeroE0, ZeroE1;
  wire        BranchSelE, BranchE, JumpE, ZeroE, PCSrcE;
  wire [31:0] BranchPCE, BranchImmE, PCTargetE;
  // Memory
  wire        RegWriteM0, MemWriteM0, RegWriteM1, MemWriteM1;
  wire [1:0]  ResultSrcM0, ResultSrcM1;
  wire [31:0] ALUResultM0, WriteDataM0, PCPlus4M0;
  wire [31:0] ALUResultM1, WriteDataM1, PCPlus4M1;
  wire [4:0]  RdM0, RdM1;
  wire        MemSelM;
  // Writeback
  wire        RegWriteW0, RegWriteW1;
  wire [1:0]  ResultSrcW0, ResultSrcW1;
  wire [31:0] ALUResultW0, ReadDataW0, PCPlus4W0, ResultW0;
  wire [31:0] ALUResultW1, ReadDataW1, PCPlus4W1, ResultW1;
  wire [4:0]  RdW0, RdW1;
  // Hazard Unit
  wire [2:0]  ForwardAE0, ForwardBE0, ForwardAE1, ForwardBE1;
  wire        StallF, StallD, FlushD, FlushE0, FlushE1, FlushM1;

  // ---------------- Fetch ----------------
  // Siguiente PC: PCTargetE si se toma un salto. Si no, el PC avanza 8 cuando salieron
  // las dos instrucciones del par y 4 cuando solo salio la primera.
  mux3 #(32) pcmux(.d0(PCPlus4F), .d1(PCPlus8F), .d2(PCTargetE),
                   .s({PCSrcE, Issue1}), .y(PCNextF));

  flopenrc #(32) pcreg(.clk(clk), .reset(reset), .clr(1'b0), .en(~StallF),
                       .d(PCNextF), .q(PCF));

  adder pcadd4(.a(PCF), .b(32'd4), .y(PCPlus4F));
  adder pcadd8(.a(PCF), .b(32'd8), .y(PCPlus8F));

  // Registro F/D. Cada posicion guarda la instruccion, su PC y su PC + 4.
  // Si la segunda instruccion no salio (Issue1 = 0) se queda en el registro como
  // primera del siguiente par y a su lado entra la primera instruccion de Fetch.
  mux2 #(96) fdmux0(.d0({InstrD1, PCD1, PCPlus4D1}), .d1({InstrF0, PCF, PCPlus4F}),
                    .s(Issue1), .y(FD0));
  mux2 #(96) fdmux1(.d0({InstrF0, PCF, PCPlus4F}), .d1({InstrF1, PCPlus4F, PCPlus8F}),
                    .s(Issue1), .y(FD1));

  flopenrc #(96) fdreg0(.clk(clk), .reset(reset), .clr(FlushD), .en(~StallD),
                        .d(FD0), .q({InstrD0, PCD0, PCPlus4D0}));
  flopenrc #(96) fdreg1(.clk(clk), .reset(reset), .clr(FlushD), .en(~StallD),
                        .d(FD1), .q({InstrD1, PCD1, PCPlus4D1}));

  // ---------------- Decode ----------------
  assign opD0 = InstrD0[6:0];
  assign opD1 = InstrD1[6:0];

  // rs1 lo leen todas las instrucciones menos jal, y rs2 solo las tipo R, sw y beq.
  // En las demas esos bits son parte del inmediato, asi que se toma x0 para que
  // no aparezcan dependencias falsas.
  assign UsaRs2D0 = (opD0 == 7'b0110011) | (opD0 == 7'b0100011) | (opD0 == 7'b1100011);
  assign UsaRs2D1 = (opD1 == 7'b0110011) | (opD1 == 7'b0100011) | (opD1 == 7'b1100011);

  assign Rs1D0 = (opD0 == 7'b1101111) ? 5'b0 : InstrD0[19:15];
  assign Rs2D0 = UsaRs2D0 ? InstrD0[24:20] : 5'b0;
  assign RdD0  = InstrD0[11:7];
  assign Rs1D1 = (opD1 == 7'b1101111) ? 5'b0 : InstrD1[19:15];
  assign Rs2D1 = UsaRs2D1 ? InstrD1[24:20] : 5'b0;
  assign RdD1  = InstrD1[11:7];

  regfile_dual rf(.clk(clk),
                  .we3(RegWriteW0), .a3(RdW0), .wd3(ResultW0),
                  .we6(RegWriteW1), .a6(RdW1), .wd6(ResultW1),
                  .a1(Rs1D0), .a2(Rs2D0), .rd1(RD1D), .rd2(RD2D),
                  .a4(Rs1D1), .a5(Rs2D1), .rd4(RD4D), .rd5(RD5D));

  extend ext0(.instr(InstrD0[31:7]), .immsrc(ImmSrcD0), .immext(ImmExtD0));
  extend ext1(.instr(InstrD1[31:7]), .immsrc(ImmSrcD1), .immext(ImmExtD1));

  issueunit iu(.Rs1D0(Rs1D0), .Rs2D0(Rs2D0), .RdD0(RdD0),
               .Rs1D1(Rs1D1), .Rs2D1(Rs2D1),
               .RegWriteD0(RegWriteD0),
               .MemWriteD0(MemWriteD0), .LoadD0(ResultSrcD0[0]), .BranchD0(BranchD0), .JumpD0(JumpD0),
               .MemWriteD1(MemWriteD1), .LoadD1(ResultSrcD1[0]), .BranchD1(BranchD1), .JumpD1(JumpD1),
               .RdE0(RdE0), .RdE1(RdE1),
               .LoadE0(ResultSrcE0[0]), .LoadE1(ResultSrcE1[0]),   // ResultSrc[0] = 1 solo en lw
               .Issue0(Issue0), .Issue1(Issue1));

  // registros D/E, uno por via: senales de control y datos
  flopenrc #(10) controlereg0(.clk(clk), .reset(reset), .clr(FlushE0), .en(1'b1),
                .d({RegWriteD0, ResultSrcD0, MemWriteD0, JumpD0, BranchD0, ALUControlD0, ALUSrcD0}),
                .q({RegWriteE0, ResultSrcE0, MemWriteE0, JumpE0, BranchE0, ALUControlE0, ALUSrcE0}));
  flopenrc #(175) dereg0(.clk(clk), .reset(reset), .clr(FlushE0), .en(1'b1),
                .d({RD1D, RD2D, PCD0, Rs1D0, Rs2D0, RdD0, ImmExtD0, PCPlus4D0}),
                .q({RD1E, RD2E, PCE0, Rs1E0, Rs2E0, RdE0, ImmExtE0, PCPlus4E0}));

  flopenrc #(10) controlereg1(.clk(clk), .reset(reset), .clr(FlushE1), .en(1'b1),
                .d({RegWriteD1, ResultSrcD1, MemWriteD1, JumpD1, BranchD1, ALUControlD1, ALUSrcD1}),
                .q({RegWriteE1, ResultSrcE1, MemWriteE1, JumpE1, BranchE1, ALUControlE1, ALUSrcE1}));
  flopenrc #(175) dereg1(.clk(clk), .reset(reset), .clr(FlushE1), .en(1'b1),
                .d({RD4D, RD5D, PCD1, Rs1D1, Rs2D1, RdD1, ImmExtD1, PCPlus4D1}),
                .q({RD4E, RD5E, PCE1, Rs1E1, Rs2E1, RdE1, ImmExtE1, PCPlus4E1}));

  // ---------------- Execute ----------------
  // muxes de forwarding: 000 RF, 001 ResultW0, 010 ResultW1, 011 ALUResultM0, 100 ALUResultM1
  mux5 #(32) forwardaemux0(.d0(RD1E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                           .s(ForwardAE0), .y(SrcAE0));
  mux5 #(32) forwardbemux0(.d0(RD2E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                           .s(ForwardBE0), .y(WriteDataE0));
  mux2 #(32) srcbmux0(.d0(WriteDataE0), .d1(ImmExtE0), .s(ALUSrcE0), .y(SrcBE0));
  alu alu0(.a(SrcAE0), .b(SrcBE0), .alucontrol(ALUControlE0), .result(ALUResultE0), .zero(ZeroE0));

  mux5 #(32) forwardaemux1(.d0(RD4E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                           .s(ForwardAE1), .y(SrcAE1));
  mux5 #(32) forwardbemux1(.d0(RD5E), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
                           .s(ForwardBE1), .y(WriteDataE1));
  mux2 #(32) srcbmux1(.d0(WriteDataE1), .d1(ImmExtE1), .s(ALUSrcE1), .y(SrcBE1));
  alu alu1(.a(SrcAE1), .b(SrcBE1), .alucontrol(ALUControlE1), .result(ALUResultE1), .zero(ZeroE1));

  // Un solo recurso para resolver saltos. La Issue Unit no deja salir dos saltos
  // juntos, asi que en Execute hay como maximo uno. BranchSelE = 1 si esta en la via 1.
  assign BranchSelE = BranchE1 | JumpE1;

  mux2 #(67) branchmux(.d0({BranchE0, JumpE0, ZeroE0, PCE0, ImmExtE0}),
                       .d1({BranchE1, JumpE1, ZeroE1, PCE1, ImmExtE1}),
                       .s(BranchSelE),
                       .y({BranchE, JumpE, ZeroE, BranchPCE, BranchImmE}));

  adder pcaddbranch(.a(BranchPCE), .b(BranchImmE), .y(PCTargetE));

  assign PCSrcE = (BranchE & ZeroE) | JumpE;

  // registros E/M. El de la via 1 se limpia con FlushM1 cuando el salto de la via 0
  // se toma: su pareja ya esta en Execute y no debe seguir.
  flopr #(4) controlmreg0(.clk(clk), .reset(reset),
                .d({RegWriteE0, ResultSrcE0, MemWriteE0}),
                .q({RegWriteM0, ResultSrcM0, MemWriteM0}));
  flopr #(101) emreg0(.clk(clk), .reset(reset),
                .d({ALUResultE0, WriteDataE0, RdE0, PCPlus4E0}),
                .q({ALUResultM0, WriteDataM0, RdM0, PCPlus4M0}));

  flopenrc #(4) controlmreg1(.clk(clk), .reset(reset), .clr(FlushM1), .en(1'b1),
                .d({RegWriteE1, ResultSrcE1, MemWriteE1}),
                .q({RegWriteM1, ResultSrcM1, MemWriteM1}));
  flopenrc #(101) emreg1(.clk(clk), .reset(reset), .clr(FlushM1), .en(1'b1),
                .d({ALUResultE1, WriteDataE1, RdE1, PCPlus4E1}),
                .q({ALUResultM1, WriteDataM1, RdM1, PCPlus4M1}));

  // ---------------- Memory ----------------
  // Un solo puerto de memoria de datos. La Issue Unit no deja salir dos accesos
  // juntos. MemSelM = 1 si el lw o el sw esta en la via 1.
  assign MemSelM   = MemWriteM1 | ResultSrcM1[0];
  assign MemWriteM = MemWriteM0 | MemWriteM1;

  mux2 #(64) memmux(.d0({ALUResultM0, WriteDataM0}), .d1({ALUResultM1, WriteDataM1}),
                    .s(MemSelM), .y({DataAdrM, WriteDataM}));

  // registros M/W. ReadDataM va a las dos vias, pero solo lo usa la que tiene el lw.
  flopr #(3) controlwreg0(.clk(clk), .reset(reset),
                .d({RegWriteM0, ResultSrcM0}),
                .q({RegWriteW0, ResultSrcW0}));
  flopr #(101) mwreg0(.clk(clk), .reset(reset),
                .d({ALUResultM0, ReadDataM, RdM0, PCPlus4M0}),
                .q({ALUResultW0, ReadDataW0, RdW0, PCPlus4W0}));

  flopr #(3) controlwreg1(.clk(clk), .reset(reset),
                .d({RegWriteM1, ResultSrcM1}),
                .q({RegWriteW1, ResultSrcW1}));
  flopr #(101) mwreg1(.clk(clk), .reset(reset),
                .d({ALUResultM1, ReadDataM, RdM1, PCPlus4M1}),
                .q({ALUResultW1, ReadDataW1, RdW1, PCPlus4W1}));

  // ---------------- Writeback ----------------
  mux3 #(32) resultmux0(.d0(ALUResultW0), .d1(ReadDataW0), .d2(PCPlus4W0), .s(ResultSrcW0), .y(ResultW0));
  mux3 #(32) resultmux1(.d0(ALUResultW1), .d1(ReadDataW1), .d2(PCPlus4W1), .s(ResultSrcW1), .y(ResultW1));

  // ---------------- Hazard Unit ----------------
  hazardunit_dual hu(.Rs1E0(Rs1E0), .Rs2E0(Rs2E0), .Rs1E1(Rs1E1), .Rs2E1(Rs2E1),
                     .RdM0(RdM0), .RdM1(RdM1), .RdW0(RdW0), .RdW1(RdW1),
                     .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
                     .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1),
                     .Issue0(Issue0), .Issue1(Issue1),
                     .PCSrcE(PCSrcE), .BranchSelE(BranchSelE),
                     .ForwardAE0(ForwardAE0), .ForwardBE0(ForwardBE0),
                     .ForwardAE1(ForwardAE1), .ForwardBE1(ForwardBE1),
                     .StallF(StallF), .StallD(StallD),
                     .FlushD(FlushD), .FlushE0(FlushE0), .FlushE1(FlushE1), .FlushM1(FlushM1));

  // La instruccion que hay en cada etapa de cada via. No la usa el procesador,
  // solo sirve para seguir el programa en las waveforms.
  wire [31:0] InstrE0, InstrE1, InstrM0, InstrM1, InstrW0, InstrW1;
  flopenrc #(32) instrereg0(.clk(clk), .reset(reset), .clr(FlushE0), .en(1'b1), .d(InstrD0), .q(InstrE0));
  flopenrc #(32) instrereg1(.clk(clk), .reset(reset), .clr(FlushE1), .en(1'b1), .d(InstrD1), .q(InstrE1));
  flopr    #(32) instrmreg0(.clk(clk), .reset(reset), .d(InstrE0), .q(InstrM0));
  flopenrc #(32) instrmreg1(.clk(clk), .reset(reset), .clr(FlushM1), .en(1'b1), .d(InstrE1), .q(InstrM1));
  flopr    #(32) instrwreg0(.clk(clk), .reset(reset), .d(InstrM0), .q(InstrW0));
  flopr    #(32) instrwreg1(.clk(clk), .reset(reset), .d(InstrM1), .q(InstrW1));
endmodule
