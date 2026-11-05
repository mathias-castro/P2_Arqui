module flopenrc #(parameter WIDTH = 8)
                 (input  clk, reset, clr, en,
                  input  [WIDTH-1:0] d,
                  output reg [WIDTH-1:0] q);

  always @(posedge clk or posedge reset) begin
    if (reset) q <= 0;
    else if (clr) q <= 0;
    else if (en) q <= d;
  end
endmodule