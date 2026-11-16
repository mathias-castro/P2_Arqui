// Programa del profesor (C, Dual-Issue con prediccion).
// Comprueba el estado al final de cada etapa (A, B, C y D) como pide el enunciado.
// El final de una etapa es el ciclo en que su ultimo sw llega a Writeback: en ese
// momento el sw ya escribio la memoria y todas las instrucciones anteriores ya
// escribieron sus registros. Ahi se comparan los 32 registros (los no indicados
// deben valer 0) y las palabras de memoria que da el enunciado.
// Senales para la waveform:
//   chk     = 1 durante el ciclo en que se comprueba una etapa
//   etapa   = letra de la ultima etapa comprobada (ASCII)
//   ok      = 1 si esa comprobacion fue correcta
//   pasadas = cuantas etapas pasaron hasta ahora
module tb_profesor_opt;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  reg         chk, ok, terminado;
  reg  [7:0]  etapa;
  integer     pasadas, ciclo, i, errores;
  reg  [31:0] esperado [0:31];

  top_dual #(.MEMFILE("profesor.mem")) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  initial begin
    chk = 0; ok = 0; terminado = 0; etapa = "-"; pasadas = 0;
    reset = 1; #22;
    reset = 0;
  end

  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  // M[x1 + desp], con x1 = 1536 (palabra 384 de la memoria de datos)
  function [31:0] M(input integer desp);
    M = dut.dmem.RAM[(1536 + desp) / 4];
  endfunction

  // compara los registros con esperado[] y cuenta las diferencias
  task revisar_registros;
    for (i = 1; i < 32; i = i + 1)
      if (dut.rvdual.dp.rf.rf[i] !== esperado[i]) begin
        $display("    x%0d = %0d, se esperaba %0d", i, dut.rvdual.dp.rf.rf[i], esperado[i]);
        errores = errores + 1;
      end
  endtask

  task revisar_memoria(input integer desp, input [31:0] valor);
    if (M(desp) !== valor) begin
      $display("    M[x1+%0d] = %0d, se esperaba %0d", desp, M(desp), valor);
      errores = errores + 1;
    end
  endtask

  task comprobar(input [7:0] e);
    begin
      errores = 0;
      for (i = 0; i < 32; i = i + 1) esperado[i] = 0;
      if (e == "A") begin
        esperado[1] = 1536; esperado[2] = 1; esperado[3] = 8; esperado[4] = 3; esperado[5] = 11; esperado[6] = 5;
        esperado[7] = 16; esperado[8] = 2; esperado[9] = 7; esperado[10] = 12;
        revisar_registros;
        revisar_memoria(0, 11); revisar_memoria(4, 5); revisar_memoria(8, 12);
      end
      if (e == "B") begin
        esperado[1] = 1536; esperado[2] = 1; esperado[3] = 8; esperado[4] = 3; esperado[5] = 11; esperado[6] = 5;
        esperado[7] = 16; esperado[8] = 2; esperado[9] = 7; esperado[10] = 12; esperado[11] = 11; esperado[12] = 16;
        esperado[13] = 5; esperado[14] = 12; esperado[15] = 7; esperado[16] = 7; esperado[17] = 16; esperado[18] = 23;
        revisar_registros;
        revisar_memoria(0, 11); revisar_memoria(4, 5); revisar_memoria(8, 12); revisar_memoria(12, 7);
        revisar_memoria(16, 16); revisar_memoria(20, 23);
      end
      if (e == "C") begin
        esperado[1] = 1536; esperado[2] = 1; esperado[3] = 8; esperado[4] = 3; esperado[5] = 11; esperado[6] = 5;
        esperado[7] = 16; esperado[8] = 2; esperado[9] = 7; esperado[10] = 12; esperado[11] = 11; esperado[12] = 16;
        esperado[13] = 5; esperado[14] = 12; esperado[15] = 7; esperado[16] = 7; esperado[17] = 16; esperado[18] = 23;
        esperado[19] = 12; esperado[20] = 12; esperado[21] = 24; esperado[22] = 18; esperado[24] = 24; esperado[26] = 6;
        revisar_registros;
        revisar_memoria(0, 11); revisar_memoria(4, 5); revisar_memoria(8, 12); revisar_memoria(12, 7);
        revisar_memoria(16, 16); revisar_memoria(20, 23); revisar_memoria(24, 24); revisar_memoria(28, 18);
        revisar_memoria(32, 24);
      end
      if (e == "D") begin
        esperado[1] = 1536; esperado[2] = 1; esperado[3] = 8; esperado[4] = 3; esperado[5] = 11; esperado[6] = 5;
        esperado[7] = 16; esperado[8] = 2; esperado[9] = 7; esperado[10] = 12; esperado[11] = 11; esperado[12] = 16;
        esperado[13] = 5; esperado[14] = 12; esperado[15] = 7; esperado[16] = 7; esperado[17] = 16; esperado[18] = 23;
        esperado[19] = 6; esperado[20] = 6; esperado[21] = 24; esperado[22] = 18; esperado[24] = 24; esperado[25] = 4;
        esperado[26] = 4; esperado[27] = 1560; esperado[28] = 74; esperado[29] = 4; esperado[30] = 23; esperado[31] = 1;
        revisar_registros;
        revisar_memoria(0, 11); revisar_memoria(4, 5); revisar_memoria(8, 12); revisar_memoria(12, 7);
        revisar_memoria(16, 16); revisar_memoria(20, 23); revisar_memoria(24, 24); revisar_memoria(28, 18);
        revisar_memoria(32, 24); revisar_memoria(36, 74); revisar_memoria(40, 4); revisar_memoria(44, 0);
        revisar_memoria(48, 1); revisar_memoria(52, 1);
      end
      chk = 1; etapa = e; ok = (errores == 0);
      if (ok) pasadas = pasadas + 1;
      if (ok) $display("Etapa %s comprobada en el ciclo %0d: correcta", e, ciclo);
      else    $display("Etapa %s comprobada en el ciclo %0d: con errores", e, ciclo);
    end
  endtask

  // termina dos ciclos despues de llegar a fin, para que se vea en la waveform
  always @(posedge terminado) #20 $finish;

  // Se revisa justo despues de cada flanco de subida, antes de que la instruccion
  // que esta en Writeback escriba el Register File en el flanco de bajada.
  always @(posedge clk) begin
    #1;
    chk = 0;
    if (~reset) begin
      ciclo = ($time - 20) / 10 + 1;      // mismo conteo de ciclos que tb_comparacion
      if (dut.rvdual.dp.InstrW0 == 32'h00a0a423 | dut.rvdual.dp.InstrW1 == 32'h00a0a423) comprobar("A");
      if (dut.rvdual.dp.InstrW0 == 32'h0120aa23 | dut.rvdual.dp.InstrW1 == 32'h0120aa23) comprobar("B");
      if (dut.rvdual.dp.InstrW0 == 32'h0380a023 | dut.rvdual.dp.InstrW1 == 32'h0380a023) comprobar("C");
      if (dut.rvdual.dp.InstrW0 == 32'h03f0aa23 | dut.rvdual.dp.InstrW1 == 32'h03f0aa23) comprobar("D");
      if ((dut.rvdual.dp.InstrW0 == 32'h0000006f | dut.rvdual.dp.InstrW1 == 32'h0000006f) & ~terminado) begin
        $display("fin alcanzado: %0d de 4 etapas correctas", pasadas);
        terminado = 1;
      end
      if (ciclo == 3000) begin
        $display("el programa no termino");
        $finish;
      end
    end
  end
endmodule
