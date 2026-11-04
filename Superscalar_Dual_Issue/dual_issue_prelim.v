
module dual_issue_prelim(
    input clk,
    input reset,

    output [31:0] PC0,
    output [31:0] PC1,
    output [31:0] Instr0,
    output [31:0] Instr1,

    output [6:0] opcode0,
    output [4:0] rd0,
    output [4:0] rs10,
    output [4:0] rs20,
    output [2:0] funct30,

    output [6:0] opcode1,
    output [4:0] rd1,
    output [4:0] rs11,
    output [4:0] rs21,
    output [2:0] funct31
);

    // Datos leídos del Register File
    wire [31:0] rs10_data;
    wire [31:0] rs20_data;
    wire [31:0] rs11_data;
    wire [31:0] rs21_data;

    // -------------------------
    // DUAL FETCH
    // -------------------------
    dual_fetch fetch(
        .clk(clk),
        .reset(reset),
        .PC0(PC0),
        .PC1(PC1)
    );

    // -------------------------
    // DUAL INSTRUCTION MEMORY
    // -------------------------
    dual_imem imem(
        .a0(PC0),
        .a1(PC1),
        .rd0(Instr0),
        .rd1(Instr1)
    );

    // -------------------------
    // DUAL DECODE
    // -------------------------
    dual_decode decode(
        .Instr0(Instr0),
        .Instr1(Instr1),

        .opcode0(opcode0),
        .rd0(rd0),
        .rs10(rs10),
        .rs20(rs20),
        .funct30(funct30),

        .opcode1(opcode1),
        .rd1(rd1),
        .rs11(rs11),
        .rs21(rs21),
        .funct31(funct31)
    );

    // -------------------------
    // DUAL REGISTER FILE
    // -------------------------
    dual_regfile regfile(
        .clk(clk),

        .we0(1'b0),
        .we1(1'b0),

        .ra10(rs10),
        .ra20(rs20),
        .ra11(rs11),
        .ra21(rs21),

        .wa0(rd0),
        .wa1(rd1),

        .wd0(32'd0),
        .wd1(32'd0),

        .rd10(rs10_data),
        .rd20(rs20_data),
        .rd11(rs11_data),
        .rd21(rs21_data)
    );

endmodule
