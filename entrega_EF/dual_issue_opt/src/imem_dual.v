// Memoria de instrucciones con dos lecturas: la instruccion de la direccion a y la siguiente
module imem_dual #(parameter MEMFILE = "riscvtest.mem")
                 (input  [31:0] a,
                  output [31:0] rd0, rd1);

  reg [31:0] RAM[127:0];   // 128 instrucciones
  integer i;

  // lo que queda despues del programa se llena con nop (addi x0, x0, 0)
  initial begin
      for (i = 0; i < 128; i = i + 1) RAM[i] = 32'h00000013;
      $readmemh(MEMFILE, RAM);
  end

  // Como se lee por adelantado, la direccion puede pasar el final de la memoria.
  // Ahi no hay instrucciones, asi que se entrega un nop.
  assign rd0 = (a[31:2] < 128) ? RAM[a[31:2]]     : 32'h00000013;
  assign rd1 = (a[31:2] < 127) ? RAM[a[31:2] + 1] : 32'h00000013;
endmodule
