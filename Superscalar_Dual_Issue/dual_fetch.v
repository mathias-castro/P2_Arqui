
module dual_fetch(
    input clk,
    input reset,
    output reg [31:0] PC0,
    output wire [31:0] PC1
);

    assign PC1 = PC0 + 32'd4;

    always @(posedge clk or posedge reset) begin
        if (reset)
            PC0 <= 32'd0;
        else
            PC0 <= PC0 + 32'd8;
    end

endmodule
