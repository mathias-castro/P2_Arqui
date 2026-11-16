module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);
  
  // 512 palabras (2 KB): el programa del profesor guarda sus datos desde la direccion 1536
  reg [31:0] RAM[511:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always @(posedge clk) begin 
    if (we) RAM[a[31:2]] <= wd; 
  end
endmodule