// Comparacion (arquitectura C, Dual-Issue con prediccion de saltos).
// Mismo criterio que en A y B (fin no se cuenta). Ademas cuenta cuantos saltos se
// predijeron mal (cada uno es un flush) y la precision del predictor.
module tb_comparacion_opt;
  parameter MEMFILE   = "propio.mem";
  parameter MAXCICLOS = 3000;

  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones, dobles, stalls, saltos, fallos, tomados;
  wire [31:0] InstrSaltoE = dut.rvdual.dp.BranchSelE ? dut.rvdual.dp.InstrE1 : dut.rvdual.dp.InstrE0;
  wire        real0 = dut.rvdual.dp.InstrW0 != 0 & ~esfin(dut.rvdual.dp.InstrW0);
  wire        real1 = dut.rvdual.dp.InstrW1 != 0 & ~esfin(dut.rvdual.dp.InstrW1);

  top_dual #(.MEMFILE(MEMFILE)) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  function esfin(input [31:0] i);
    esfin = (i == 32'h00000063) | (i == 32'h0000006f);
  endfunction

  initial begin
    ciclos = 0; ultimo = 0; instrucciones = 0; dobles = 0; stalls = 0; saltos = 0; fallos = 0; tomados = 0;
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
      if (dut.rvdual.dp.TakenE & ~esfin(InstrSaltoE)) tomados = tomados + 1;
      if (dut.rvdual.dp.MispredE & ~esfin(InstrSaltoE)) fallos = fallos + 1;

      if (esfin(dut.rvdual.dp.InstrW0) | esfin(dut.rvdual.dp.InstrW1)) begin
        $display("C Dual-Issue con prediccion | %s", MEMFILE);
        $display("  %0d instrucciones en %0d ciclos, IPC = %.3f, CPI = %.3f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo, 1.0 * ultimo / instrucciones);
        $display("  ciclos con dos instrucciones en Writeback = %0d, stalls = %0d", dobles, stalls);
        $display("  saltos = %0d, tomados = %0d, mal predichos (flush) = %0d, precision = %.1f %%",
                 saltos, tomados, fallos, 100.0 * (saltos - fallos) / saltos);
        $finish;
      end
      if (ciclos == MAXCICLOS) begin
        $display("C Dual-Issue con prediccion | %s | el programa no termino", MEMFILE);
        $finish;
      end
    end
  end
endmodule
