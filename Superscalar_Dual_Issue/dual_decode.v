
module dual_decode(
    input [31:0] Instr0,
    input [31:0] Instr1,

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

    assign opcode0 = Instr0[6:0];
    assign rd0     = Instr0[11:7];
    assign rs10    = Instr0[19:15];
    assign rs20    = Instr0[24:20];
    assign funct30 = Instr0[14:12];

    assign opcode1 = Instr1[6:0];
    assign rd1     = Instr1[11:7];
    assign rs11    = Instr1[19:15];
    assign rs21    = Instr1[24:20];
    assign funct31 = Instr1[14:12];

endmodule
