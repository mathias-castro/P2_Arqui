// Prototipo E1: Fetch, Decode y dos vias EX, sin emision ni retiro completos.
module dual_issue_prelim(
    input clk, reset, Stall,
    output [31:0] PC0, PC1, Instr0, Instr1,
    output [31:0] ALUResult0E, ALUResult1E
);
    wire [31:0] PC0D, PC1D, Instr0D, Instr1D;
    wire [31:0] ImmExt0D, ImmExt1D, RD10D, RD20D, RD11D, RD21D;
    wire [4:0] Rd0D, Rs10D, Rs20D, Rd1D, Rs11D, Rs21D;
    wire RegWrite0D, MemWrite0D, ALUSrc0D, Branch0D, Jump0D;
    wire RegWrite1D, MemWrite1D, ALUSrc1D, Branch1D, Jump1D;
    wire [1:0] ResultSrc0D, ResultSrc1D;
    wire [2:0] ALUControl0D, ALUControl1D;
    wire ValidD, ValidE;
    wire [31:0] PC0E, PC1E, WriteData0E, WriteData1E;
    wire [4:0] Rd0E, Rd1E;
    wire RegWrite0E, MemWrite0E, Branch0E, Jump0E;
    wire RegWrite1E, MemWrite1E, Branch1E, Jump1E;
    wire [1:0] ResultSrc0E, ResultSrc1E;

    dual_fetch fetch(clk, reset, Stall, PC0, PC1);
    dual_imem imem(PC0, PC1, Instr0, Instr1);
    flopenrc #(128) ifid(
        .clk(clk), .reset(reset), .clr(1'b0), .en(!Stall),
        .d({PC0, PC1, Instr0, Instr1}), .q({PC0D, PC1D, Instr0D, Instr1D})
    );
    flopenrc #(1) validd(clk, reset, 1'b0, !Stall, 1'b1, ValidD);
    flopenrc #(1) valide(clk, reset, Stall, 1'b1, ValidD, ValidE);

    dual_decode decode(
        .Instr0(Instr0D), .Instr1(Instr1D),
        .rd0(Rd0D), .rs10(Rs10D), .rs20(Rs20D),
        .rd1(Rd1D), .rs11(Rs11D), .rs21(Rs21D),
        .RegWrite0(RegWrite0D), .MemWrite0(MemWrite0D), .ALUSrc0(ALUSrc0D),
        .Branch0(Branch0D), .Jump0(Jump0D), .ResultSrc0(ResultSrc0D),
        .ALUControl0(ALUControl0D), .ImmExt0(ImmExt0D),
        .RegWrite1(RegWrite1D), .MemWrite1(MemWrite1D), .ALUSrc1(ALUSrc1D),
        .Branch1(Branch1D), .Jump1(Jump1D), .ResultSrc1(ResultSrc1D),
        .ALUControl1(ALUControl1D), .ImmExt1(ImmExt1D)
    );
    // Los puertos WB quedan deshabilitados en este prototipo.
    dual_regfile rf(
        .clk(clk), .we0(1'b0), .we1(1'b0),
        .ra10(Rs10D), .ra20(Rs20D), .ra11(Rs11D), .ra21(Rs21D),
        .wa0(5'd0), .wa1(5'd0), .wd0(32'd0), .wd1(32'd0),
        .rd10(RD10D), .rd20(RD20D), .rd11(RD11D), .rd21(RD21D)
    );
    dual_execute_lane lane0(
        .clk(clk), .reset(reset), .FlushE(Stall),
        .RD1D(RD10D), .RD2D(RD20D), .ImmExtD(ImmExt0D), .PCD(PC0D), .RdD(Rd0D),
        .RegWriteD(RegWrite0D), .MemWriteD(MemWrite0D), .ALUSrcD(ALUSrc0D),
        .BranchD(Branch0D), .JumpD(Jump0D), .ResultSrcD(ResultSrc0D), .ALUControlD(ALUControl0D),
        .PCE(PC0E), .ALUResultE(ALUResult0E), .WriteDataE(WriteData0E), .RdE(Rd0E),
        .RegWriteE(RegWrite0E), .MemWriteE(MemWrite0E), .BranchE(Branch0E), .JumpE(Jump0E),
        .ResultSrcE(ResultSrc0E)
    );
    dual_execute_lane lane1(
        .clk(clk), .reset(reset), .FlushE(Stall),
        .RD1D(RD11D), .RD2D(RD21D), .ImmExtD(ImmExt1D), .PCD(PC1D), .RdD(Rd1D),
        .RegWriteD(RegWrite1D), .MemWriteD(MemWrite1D), .ALUSrcD(ALUSrc1D),
        .BranchD(Branch1D), .JumpD(Jump1D), .ResultSrcD(ResultSrc1D), .ALUControlD(ALUControl1D),
        .PCE(PC1E), .ALUResultE(ALUResult1E), .WriteDataE(WriteData1E), .RdE(Rd1E),
        .RegWriteE(RegWrite1E), .MemWriteE(MemWrite1E), .BranchE(Branch1E), .JumpE(Jump1E),
        .ResultSrcE(ResultSrc1E)
    );
endmodule
