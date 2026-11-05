module top_dual(
    input clk, reset, Stall,
    output [31:0] PC0, PC1, Instr0, Instr1,
    output [31:0] ALUResult0E, ALUResult1E
);
    dual_issue_prelim dual(clk, reset, Stall, PC0, PC1, Instr0, Instr1,
                          ALUResult0E, ALUResult1E);
endmodule
