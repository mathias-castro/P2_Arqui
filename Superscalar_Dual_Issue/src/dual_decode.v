module dual_decode(
    input [31:0] Instr0, Instr1,
    output [4:0] rd0, rs10, rs20, rd1, rs11, rs21,
    output RegWrite0, MemWrite0, ALUSrc0, Branch0, Jump0,
    output RegWrite1, MemWrite1, ALUSrc1, Branch1, Jump1,
    output [1:0] ResultSrc0, ResultSrc1,
    output [2:0] ALUControl0, ALUControl1,
    output [31:0] ImmExt0, ImmExt1
);
    wire [1:0] ImmSrc0, ImmSrc1;
    assign {rd0, rs10, rs20} = {Instr0[11:7], Instr0[19:15], Instr0[24:20]};
    assign {rd1, rs11, rs21} = {Instr1[11:7], Instr1[19:15], Instr1[24:20]};

    controller c0(
        .op(Instr0[6:0]), .funct3(Instr0[14:12]), .funct7b5(Instr0[30]),
        .ResultSrc(ResultSrc0), .MemWrite(MemWrite0), .ALUSrc(ALUSrc0),
        .RegWrite(RegWrite0), .Jump(Jump0), .ImmSrc(ImmSrc0),
        .ALUControl(ALUControl0), .Branch(Branch0)
    );
    controller c1(
        .op(Instr1[6:0]), .funct3(Instr1[14:12]), .funct7b5(Instr1[30]),
        .ResultSrc(ResultSrc1), .MemWrite(MemWrite1), .ALUSrc(ALUSrc1),
        .RegWrite(RegWrite1), .Jump(Jump1), .ImmSrc(ImmSrc1),
        .ALUControl(ALUControl1), .Branch(Branch1)
    );
    extend ext0(Instr0[31:7], ImmSrc0, ImmExt0);
    extend ext1(Instr1[31:7], ImmSrc1, ImmExt1);
endmodule
