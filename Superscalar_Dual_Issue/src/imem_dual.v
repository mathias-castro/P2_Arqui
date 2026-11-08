module imem_dual #(parameter MEMFILE = "e2_programa1.mem")
                 (input  [31:0] a,
                  output [31:0] rd0, rd1);

  reg [31:0] RAM[0:63];

  initial begin
      $readmemh(MEMFILE, RAM);
  end

  assign rd0 = RAM[a[31:2]];
  assign rd1 = RAM[a[31:2] + 1];
endmodule
