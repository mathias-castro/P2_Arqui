`timescale 1ns/1ps
// Regresion del programa riscvtest de Harris y Harris, figura 7.64.
module testbench;
  reg clk = 0, reset = 1;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;
  integer cycles = 0;
  top dut(clk, reset, WriteData, DataAdr, MemWrite);
  always #5 clk = ~clk;
  initial #12 reset = 0;
  always @(posedge clk) if (!reset) begin
    cycles = cycles + 1;
    if (cycles > 100) $fatal(1, "Timeout en riscvtest");
    if (MemWrite) begin
      if (DataAdr === 100 && WriteData === 25) begin
        #1;
        if (dut.dmem.RAM[25] !== 25) $fatal(1, "El store final no se escribio");
        $display("PASS HARRIS: Mem[100]=25");
        $finish;
      end else if (DataAdr !== 96 || WriteData !== 7)
        $fatal(1, "Escritura incorrecta en riscvtest");
    end
  end
endmodule
