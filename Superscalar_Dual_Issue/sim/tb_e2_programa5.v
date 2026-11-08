// Programa 5 de la E2: dos escrituras en el Register File.
module tb_e2_programa5;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, fin, i, errores;
  integer     dobles, parciales, stalls, saltos, anuladas1, raw_par, conf_mem, conf_branch,
              loaduse, lu1, wb_dobles;
  reg         fM0, fM1, fW0, fW1;
  reg  [31:0] exp_rf [1:31];
  reg  [31:0] exp_mem[0:63];
  localparam  N = 14;   // instrucciones hasta el sw final

  top_dual #(.MEMFILE("e2_programa5.mem")) dut(
    .clk(clk),
    .reset(reset),
    .WriteDataM(WriteDataM),
    .DataAdrM(DataAdrM),
    .MemWriteM(MemWriteM)
  );

  initial begin
    exp_rf[1] = 32'h00000001;
    exp_rf[2] = 32'h00000002;
    exp_rf[3] = 32'h00000004;
    exp_rf[4] = 32'h00000006;
    exp_rf[5] = 32'h00000003;
    exp_rf[6] = 32'h0000000a;
    exp_rf[7] = 32'h00000002;
    exp_rf[8] = 32'h00000002;
    exp_rf[9] = 32'h0000000d;
    exp_rf[10] = 32'h00000004;
    exp_rf[11] = 32'h00000000;
    exp_rf[12] = 32'h00000000;
    exp_rf[13] = 32'h00000000;
    exp_rf[14] = 32'h00000000;
    exp_rf[15] = 32'h00000000;
    exp_rf[16] = 32'h00000000;
    exp_rf[17] = 32'h00000000;
    exp_rf[18] = 32'h00000000;
    exp_rf[19] = 32'h00000000;
    exp_rf[20] = 32'h00000000;
    exp_rf[21] = 32'h00000000;
    exp_rf[22] = 32'h00000000;
    exp_rf[23] = 32'h00000000;
    exp_rf[24] = 32'h00000000;
    exp_rf[25] = 32'h00000000;
    exp_rf[26] = 32'h00000000;
    exp_rf[27] = 32'h00000000;
    exp_rf[28] = 32'h00000000;
    exp_rf[29] = 32'h00000000;
    exp_rf[30] = 32'h00000000;
    exp_rf[31] = 32'h00000000;
    exp_mem[0] = 32'h00000002;
    exp_mem[1] = 32'h00000000;
    exp_mem[2] = 32'h00000000;
    exp_mem[3] = 32'h00000000;
    exp_mem[4] = 32'h00000000;
    exp_mem[5] = 32'h00000000;
    exp_mem[6] = 32'h00000000;
    exp_mem[7] = 32'h00000000;
    exp_mem[8] = 32'h00000000;
    exp_mem[9] = 32'h00000000;
    exp_mem[10] = 32'h00000000;
    exp_mem[11] = 32'h00000000;
    exp_mem[12] = 32'h00000000;
    exp_mem[13] = 32'h00000000;
    exp_mem[14] = 32'h00000000;
    exp_mem[15] = 32'h00000000;
    exp_mem[16] = 32'h00000000;
    exp_mem[17] = 32'h00000000;
    exp_mem[18] = 32'h00000000;
    exp_mem[19] = 32'h00000000;
    exp_mem[20] = 32'h00000000;
    exp_mem[21] = 32'h00000000;
    exp_mem[22] = 32'h00000000;
    exp_mem[23] = 32'h00000000;
    exp_mem[24] = 32'h00000000;
    exp_mem[25] = 32'h00000000;
    exp_mem[26] = 32'h00000000;
    exp_mem[27] = 32'h00000000;
    exp_mem[28] = 32'h00000000;
    exp_mem[29] = 32'h00000000;
    exp_mem[30] = 32'h00000000;
    exp_mem[31] = 32'h00000000;
    exp_mem[32] = 32'h00000000;
    exp_mem[33] = 32'h00000000;
    exp_mem[34] = 32'h00000000;
    exp_mem[35] = 32'h00000000;
    exp_mem[36] = 32'h00000000;
    exp_mem[37] = 32'h00000000;
    exp_mem[38] = 32'h00000000;
    exp_mem[39] = 32'h00000000;
    exp_mem[40] = 32'h00000000;
    exp_mem[41] = 32'h00000000;
    exp_mem[42] = 32'h00000000;
    exp_mem[43] = 32'h00000000;
    exp_mem[44] = 32'h00000000;
    exp_mem[45] = 32'h00000000;
    exp_mem[46] = 32'h00000000;
    exp_mem[47] = 32'h00000000;
    exp_mem[48] = 32'h00000000;
    exp_mem[49] = 32'h00000000;
    exp_mem[50] = 32'h00000000;
    exp_mem[51] = 32'h00000000;
    exp_mem[52] = 32'h00000000;
    exp_mem[53] = 32'h00000000;
    exp_mem[54] = 32'h00000000;
    exp_mem[55] = 32'h00000000;
    exp_mem[56] = 32'h00000000;
    exp_mem[57] = 32'h00000000;
    exp_mem[58] = 32'h00000000;
    exp_mem[59] = 32'h00000000;
    exp_mem[60] = 32'h00000000;
    exp_mem[61] = 32'h00000000;
    exp_mem[62] = 32'h00000000;
    exp_mem[63] = 32'h00000004;
  end

  initial begin
    $dumpfile("e2_programa5.vcd");
    $dumpvars(0, tb_e2_programa5);
    ciclos = 0; fin = -1; errores = 0;
    dobles = 0; parciales = 0; stalls = 0; saltos = 0; anuladas1 = 0;
    raw_par = 0; conf_mem = 0; conf_branch = 0; loaduse = 0; lu1 = 0; wb_dobles = 0;
    fM0 = 0; fM1 = 0; fW0 = 0; fW1 = 0;
    for (i = 0; i < 32; i = i + 1) dut.rvdual.dp.rf.rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) dut.dmem.RAM[i] = 0;
    reset = 1; #22;
    reset = 0;
  end

  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  always @(negedge clk) begin
    if (!reset && fin < 0) begin
      ciclos = ciclos + 1;
      if (!dut.rvdual.dp.PCSrcE) begin
        if (dut.rvdual.dp.Issue1 && dut.rvdual.dp.InstrD0 != 0 && dut.rvdual.dp.InstrD1 != 0) begin
          dobles = dobles + 1;
          $display("ciclo %0d: emite pc=%0d y pc=%0d", ciclos, dut.rvdual.dp.PCD, dut.rvdual.dp.PCPlus4D);
        end else if (dut.rvdual.dp.Issue0 && dut.rvdual.dp.InstrD0 != 0) begin
          $display("ciclo %0d: emite pc=%0d", ciclos, dut.rvdual.dp.PCD);
          if (dut.rvdual.dp.Realign && dut.rvdual.dp.InstrD1 != 0) parciales = parciales + 1;
        end else if (!dut.rvdual.dp.Issue0)
          $display("ciclo %0d: no emite (Load-Use)", ciclos);
        if (dut.rvdual.dp.StallD) stalls = stalls + 1;
        if (dut.rvdual.dp.Realign && dut.rvdual.dp.RAWpar) raw_par = raw_par + 1;
        if (dut.rvdual.dp.Realign && dut.rvdual.dp.MemConflict) conf_mem = conf_mem + 1;
        if (dut.rvdual.dp.Realign && dut.rvdual.dp.BranchConflict) conf_branch = conf_branch + 1;
        if (dut.rvdual.dp.Realign && dut.rvdual.dp.LoadUse1) lu1 = lu1 + 1;
        if (dut.rvdual.dp.LoadUse0 || dut.rvdual.dp.LoadUse1) loaduse = loaduse + 1;
      end else
        $display("ciclo %0d: salto tomado a pc=%0d", ciclos, dut.rvdual.dp.PCTargetE);
      if (dut.rvdual.dp.PCSrcE) saltos = saltos + 1;
      if (dut.rvdual.dp.FlushM1 && dut.rvdual.dp.InstrE1 != 0) anuladas1 = anuladas1 + 1;
      if (dut.rvdual.dp.RegWriteW0 && dut.rvdual.dp.RdW0 != 0 &&
          dut.rvdual.dp.RegWriteW1 && dut.rvdual.dp.RdW1 != 0) wb_dobles = wb_dobles + 1;
      if (dut.rvdual.dp.ForwardAE0 == 3'b011 || dut.rvdual.dp.ForwardBE0 == 3'b011 ||
          dut.rvdual.dp.ForwardAE1 == 3'b011 || dut.rvdual.dp.ForwardBE1 == 3'b011) fM0 = 1;
      if (dut.rvdual.dp.ForwardAE0 == 3'b100 || dut.rvdual.dp.ForwardBE0 == 3'b100 ||
          dut.rvdual.dp.ForwardAE1 == 3'b100 || dut.rvdual.dp.ForwardBE1 == 3'b100) fM1 = 1;
      if (dut.rvdual.dp.ForwardAE0 == 3'b001 || dut.rvdual.dp.ForwardBE0 == 3'b001 ||
          dut.rvdual.dp.ForwardAE1 == 3'b001 || dut.rvdual.dp.ForwardBE1 == 3'b001) fW0 = 1;
      if (dut.rvdual.dp.ForwardAE0 == 3'b010 || dut.rvdual.dp.ForwardBE0 == 3'b010 ||
          dut.rvdual.dp.ForwardAE1 == 3'b010 || dut.rvdual.dp.ForwardBE1 == 3'b010) fW1 = 1;
      if (MemWriteM === 1'b1 && DataAdrM === 252) fin = ciclos;
      if (ciclos == 200) begin
        $display("Programa 5 fallo: tiempo agotado");
        $finish;
      end
    end
  end

  // dos ciclos despues ya escribieron todas las instrucciones anteriores al sw
  always @(negedge clk) begin
    if (fin > 0 && ciclos == fin) begin
      repeat (2) @(negedge clk);
      for (i = 1; i < 32; i = i + 1)
        if (dut.rvdual.dp.rf.rf[i] !== exp_rf[i]) begin
          errores = errores + 1;
          $display("  x%0d = %h, esperado %h", i, dut.rvdual.dp.rf.rf[i], exp_rf[i]);
        end
      for (i = 0; i < 64; i = i + 1)
        if (dut.dmem.RAM[i] !== exp_mem[i]) begin
          errores = errores + 1;
          $display("  Mem[%0d] = %h, esperado %h", 4*i, dut.dmem.RAM[i], exp_mem[i]);
        end
      $display("ciclos=%0d instrucciones=%0d IPC=%0d.%02d | pares dobles=%0d parciales=%0d stalls=%0d saltos=%0d anuladas via1=%0d",
               fin, N, N / fin, (100 * N / fin) % 100, dobles, parciales, stalls, saltos, anuladas1);
      $display("parciales por: RAW=%0d memoria=%0d branch=%0d Load-Use slot 1=%0d | ciclos con Load-Use=%0d WB dobles=%0d forwarding M0/M1/W0/W1=%0d%0d%0d%0d",
               raw_par, conf_mem, conf_branch, lu1, loaduse, wb_dobles, fM0, fM1, fW0, fW1);
      if (errores == 0 && (wb_dobles >= 4))
        $display("Programa 5 correcto");
      else
        $display("Programa 5 fallo");
      $finish;
    end
  end
endmodule
