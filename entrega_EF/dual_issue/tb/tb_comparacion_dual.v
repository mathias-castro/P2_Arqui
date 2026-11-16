// Comparacion (arquitectura B, Dual-Issue).
// Mismo criterio que tb_comparacion del Single-Issue: fin no se cuenta, los ciclos
// llegan hasta que la ultima instruccion antes de fin esta en Writeback y una
// instruccion retirada es una que llega a Writeback y no es burbuja.
module tb_comparacion_dual;
  parameter MEMFILE   = "propio.mem";
  parameter MAXCICLOS = 3000;

  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones, dobles, stalls, saltos, tomados;
  wire [31:0] InstrSaltoE = dut.rvdual.dp.BranchSelE ? dut.rvdual.dp.InstrE1 : dut.rvdual.dp.InstrE0;
  wire        real0 = dut.rvdual.dp.InstrW0 != 0 & ~esfin(dut.rvdual.dp.InstrW0);
  wire        real1 = dut.rvdual.dp.InstrW1 != 0 & ~esfin(dut.rvdual.dp.InstrW1);

  top_dual #(.MEMFILE(MEMFILE)) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  function esfin(input [31:0] i);
    esfin = (i == 32'h00000063) | (i == 32'h0000006f);
  endfunction

  initial begin
    ciclos = 0; ultimo = 0; instrucciones = 0; dobles = 0; stalls = 0; saltos = 0; tomados = 0;
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
      if (real0) instrucciones = instrucciones + 1;
      if (real1) instrucciones = instrucciones + 1;
      if (real0 | real1) ultimo = ciclos;
      if (real0 & real1) dobles = dobles + 1;
      if (dut.rvdual.dp.StallD) stalls = stalls + 1;
      if ((dut.rvdual.dp.BranchE | dut.rvdual.dp.JumpE) & ~esfin(InstrSaltoE)) saltos = saltos + 1;
      if (dut.rvdual.dp.PCSrcE & ~esfin(InstrSaltoE)) tomados = tomados + 1;

      if (esfin(dut.rvdual.dp.InstrW0) | esfin(dut.rvdual.dp.InstrW1)) begin
        $display("B Dual-Issue | %s", MEMFILE);
        $display("  %0d instrucciones en %0d ciclos, IPC = %.3f, CPI = %.3f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo, 1.0 * ultimo / instrucciones);
        $display("  ciclos con dos instrucciones en Writeback = %0d, stalls = %0d", dobles, stalls);
        $display("  saltos = %0d, tomados (flush) = %0d", saltos, tomados);
        $finish;
      end
      if (ciclos == MAXCICLOS) begin
        $display("B Dual-Issue | %s | el programa no termino", MEMFILE);
        $finish;
      end
    end
  end
endmodule
