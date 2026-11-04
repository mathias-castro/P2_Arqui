// Registro ID/EX y ALU de una via. MEM y WB se integraran en E2.
module dual_execute_lane(
    input clk, reset, FlushE,
    input [31:0] RD1D, RD2D, ImmExtD, PCD,
    input [4:0] RdD,
    input RegWriteD, MemWriteD, ALUSrcD, BranchD, JumpD,
    input [1:0] ResultSrcD,
    input [2:0] ALUControlD,
    output [31:0] PCE, ALUResultE, WriteDataE,
    output [4:0] RdE,
    output RegWriteE, MemWriteE, BranchE, JumpE,
    output [1:0] ResultSrcE
);
    wire [31:0] RD1E, RD2E, ImmExtE, SrcBE;
    wire [2:0] ALUControlE;
    wire ALUSrcE, ZeroE;
    flopenrc #(143) idex(
        .clk(clk), .reset(reset), .clr(FlushE), .en(1'b1),
        .d({RD1D, RD2D, ImmExtD, PCD, RdD, RegWriteD, ResultSrcD,
            MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcD}),
        .q({RD1E, RD2E, ImmExtE, PCE, RdE, RegWriteE, ResultSrcE,
            MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcE})
    );
    assign WriteDataE = RD2E;
    mux2 #(32) srcbmux(RD2E, ImmExtE, ALUSrcE, SrcBE);
    alu alu(RD1E, SrcBE, ALUControlE, ALUResultE, ZeroE);
endmodule
