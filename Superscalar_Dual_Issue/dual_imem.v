module dual_imem #(parameter MEMFILE = "programs/dual_prelim.mem")(
    input [31:0] a0, a1,
    output [31:0] rd0, rd1
);
    reg [31:0] ROM [0:255];
    initial $readmemh(MEMFILE, ROM);
    assign rd0 = ROM[a0[31:2]];
    assign rd1 = ROM[a1[31:2]];
endmodule
