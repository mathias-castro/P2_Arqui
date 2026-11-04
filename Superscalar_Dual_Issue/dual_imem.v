
module dual_imem(
    input [31:0] a0,
    input [31:0] a1,
    output [31:0] rd0,
    output [31:0] rd1
);

    reg [31:0] ROM [0:255];

    initial begin
        $readmemh("dual_program.mem", ROM);
    end

    assign rd0 = ROM[a0[9:2]];
    assign rd1 = ROM[a1[9:2]];

endmodule
