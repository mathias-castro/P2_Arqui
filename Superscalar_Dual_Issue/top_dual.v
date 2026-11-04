
module top_dual(
    input clk,
    input reset,

    output [31:0] PC0,
    output [31:0] PC1,
    output [31:0] Instr0,
    output [31:0] Instr1
);

    dual_issue_prelim dual(
        .clk(clk),
        .reset(reset),

        .PC0(PC0),
        .PC1(PC1),
        .Instr0(Instr0),
        .Instr1(Instr1),

        .opcode0(),
        .rd0(),
        .rs10(),
        .rs20(),
        .funct30(),

        .opcode1(),
        .rd1(),
        .rs11(),
        .rs21(),
        .funct31()
    );

endmodule
