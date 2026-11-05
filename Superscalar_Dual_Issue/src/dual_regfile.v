
module dual_regfile(
    input clk,
    input we0,
    input we1,

    input [4:0] ra10,
    input [4:0] ra20,
    input [4:0] ra11,
    input [4:0] ra21,

    input [4:0] wa0,
    input [4:0] wa1,

    input [31:0] wd0,
    input [31:0] wd1,

    output [31:0] rd10,
    output [31:0] rd20,
    output [31:0] rd11,
    output [31:0] rd21
);

    reg [31:0] rf [1:31];

    // Lecturas combinacionales
    assign rd10 = (ra10 == 0) ? 32'd0 : rf[ra10];
    assign rd20 = (ra20 == 0) ? 32'd0 : rf[ra20];
    assign rd11 = (ra11 == 0) ? 32'd0 : rf[ra11];
    assign rd21 = (ra21 == 0) ? 32'd0 : rf[ra21];

    // Escrituras síncronas
    always @(negedge clk) begin
        if (we0 && wa0 != 0 && !(we1 && wa1 == wa0))
            rf[wa0] <= wd0;

        // La via 1 es la mas joven del par y conserva la ultima escritura.
        if (we1 && wa1 != 0)
            rf[wa1] <= wd1;
    end

endmodule
