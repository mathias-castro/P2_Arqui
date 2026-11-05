module dual_fetch(
    input clk, reset, Stall,
    output reg [31:0] PC0,
    output [31:0] PC1
);
    assign PC1 = PC0 + 32'd4;
    always @(posedge clk or posedge reset) begin
        if (reset) PC0 <= 0;
        else if (!Stall) PC0 <= PC0 + 32'd8;
    end
endmodule
