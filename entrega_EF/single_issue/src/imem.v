module imem #(parameter MEMFILE = "riscvtest.mem")
            (input  [31:0] a,
             output [31:0] rd);

  reg [31:0] RAM[127:0];   // 128 instrucciones
  integer i;

  // lo que queda despues del programa se llena con nop (addi x0, x0, 0)
  initial begin
      for (i = 0; i < 128; i = i + 1) RAM[i] = 32'h00000013;
      $readmemh(MEMFILE, RAM);
  end

  assign rd = RAM[a[31:2]]; // word aligned
endmodule
