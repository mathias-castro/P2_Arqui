// Comparacion (arquitectura A, pipeline Single-Issue).
// Corre el programa MEMFILE y reporta instrucciones retiradas, ciclos, IPC y CPI.
// Criterio (el mismo en las tres arquitecturas, y el que pide el enunciado):
//  - el programa termina en fin, un salto a si mismo (beq x0, x0, fin o jal x0, fin);
//  - fin no se cuenta: ni como instruccion, ni como salto, ni sus ciclos;
//  - ciclos: desde que se suelta el reset hasta el ciclo en que la ultima instruccion
//    antes de fin esta en Writeback;
//  - instruccion retirada: la que llega a Writeback y no es burbuja.
module tb_comparacion;
  parameter MEMFILE   = "propio.mem";
  parameter MAXCICLOS = 3000;

  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones, stalls, saltos, tomados;

  top #(.MEMFILE(MEMFILE)) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  function esfin(input [31:0] i);
    esfin = (i == 32'h00000063) | (i == 32'h0000006f);
  endfunction

  initial begin
    ciclos = 0; ultimo = 0; instrucciones = 0; stalls = 0; saltos = 0; tomados = 0;
    reset = 1; #22;
    reset = 0;
  end

  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  always @(negedge clk) begin
    if (~reset) begin
      ciclos = ciclos + 1;
      if (dut.rv.dp.InstrW != 0 & ~esfin(dut.rv.dp.InstrW)) begin
        instrucciones = instrucciones + 1;
        ultimo = ciclos;
      end
      if (dut.rv.dp.StallD) stalls = stalls + 1;
      if ((dut.rv.dp.BranchE | dut.rv.dp.JumpE) & ~esfin(dut.rv.dp.InstrE)) saltos = saltos + 1;
      if (dut.rv.dp.PCSrcE & ~esfin(dut.rv.dp.InstrE)) tomados = tomados + 1;

      if (esfin(dut.rv.dp.InstrW)) begin
        $display("A Single-Issue | %s", MEMFILE);
        $display("  %0d instrucciones en %0d ciclos, IPC = %.3f, CPI = %.3f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo, 1.0 * ultimo / instrucciones);
        $display("  stalls = %0d, saltos = %0d, tomados (flush) = %0d", stalls, saltos, tomados);
        $finish;
      end
      if (ciclos == MAXCICLOS) begin
        $display("A Single-Issue | %s | el programa no termino", MEMFILE);
        $finish;
      end
    end
  end
endmodule
