module imem #(parameter MEMFILE = "RISCV_Pipeline/riscvtest.dat")
           (input  [31:0] a,
            output [31:0] rd);
  
  reg [31:0] RAM[0:255];
  integer i;

  initial begin
      for (i = 0; i < 256; i = i + 1) RAM[i] = 32'h00000013;
      if (MEMFILE != "") $readmemh(MEMFILE, RAM);
  end

  assign rd = RAM[a[31:2]]; // direccion en bytes, instrucciones de 4 bytes
endmodule
