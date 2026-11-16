// Testbench de la EF, prueba 1: bucle cerrado con un salto hacia atras
module tb_ef_p1;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones, saltos, fallos;

  // instantiate device to be tested
  top_dual #(.MEMFILE("ef_p1_bucle.mem")) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  // initialize test
  initial begin
    ciclos = 0; ultimo = 0; instrucciones = 0; saltos = 0; fallos = 0;
    reset = 1; #22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  // Cuenta los ciclos, las instrucciones que llegan a Writeback (una burbuja vale 0),
  // los saltos que se resuelven en Execute y cuantos de ellos se predijeron mal.
  // El programa termina cuando llega a Writeback fin: beq x0, x0, fin (00000063).
  // fin no se cuenta: los ciclos llegan hasta la ultima instruccion anterior a fin.
  always @(negedge clk) begin
    if (~reset) begin
      ciclos = ciclos + 1;
      if (dut.rvdual.dp.InstrW0 != 0 & dut.rvdual.dp.InstrW0 != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end
      if (dut.rvdual.dp.InstrW1 != 0 & dut.rvdual.dp.InstrW1 != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end
      if ((dut.rvdual.dp.BranchE | dut.rvdual.dp.JumpE) & (dut.rvdual.dp.BranchSelE ? dut.rvdual.dp.InstrE1 : dut.rvdual.dp.InstrE0) != 32'h00000063) saltos = saltos + 1;
      if (dut.rvdual.dp.MispredE & (dut.rvdual.dp.BranchSelE ? dut.rvdual.dp.InstrE1 : dut.rvdual.dp.InstrE0) != 32'h00000063) fallos = fallos + 1;

      if (dut.rvdual.dp.InstrW0 == 32'h00000063 | dut.rvdual.dp.InstrW1 == 32'h00000063) begin
        #1; // deja que termine la escritura del Register File de este ciclo
        // check results
        if (dut.dmem.RAM[25] === 55 & dut.rvdual.dp.rf.rf[1] === 10)
          $display("Prueba 1 de la EF correcto");
        else
          $display("Prueba 1 de la EF fallo");
        $display("%0d instrucciones en %0d ciclos, IPC = %.2f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo);
        $display("%0d saltos, %0d mal predichos", saltos, fallos);
        $stop;
      end

      if (ciclos == 300) begin
        $display("Prueba 1 de la EF: el programa no termino");
        $stop;
      end
    end
  end
endmodule
