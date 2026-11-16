// Testbench del programa 5 de la E2: dos escrituras en el Register File
module tb_e2_p5;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones;

  // instantiate device to be tested
  top_dual #(.MEMFILE("e2_p5_regfile.mem")) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  // initialize test
  initial begin
    ciclos = 0; ultimo = 0; instrucciones = 0;
    reset = 1; #22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  // Cuenta los ciclos y las instrucciones que llegan a Writeback (una burbuja vale 0).
  // El programa termina cuando llega a Writeback su ultima instruccion,
  // fin: beq x0, x0, fin, que siempre se codifica como 00000063.
  // fin no se cuenta: los ciclos llegan hasta la ultima instruccion anterior a fin.
  always @(negedge clk) begin
    if (~reset) begin
      ciclos = ciclos + 1;
      if (dut.rvdual.dp.InstrW0 != 0 & dut.rvdual.dp.InstrW0 != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end
      if (dut.rvdual.dp.InstrW1 != 0 & dut.rvdual.dp.InstrW1 != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end

      if (dut.rvdual.dp.InstrW0 == 32'h00000063 | dut.rvdual.dp.InstrW1 == 32'h00000063) begin
        #1; // deja que termine la escritura del Register File de este ciclo
        // check results
        if (dut.dmem.RAM[25] === 42 & dut.rvdual.dp.rf.rf[3] === 9 & dut.rvdual.dp.rf.rf[5] === 20 & dut.rvdual.dp.rf.rf[11] === 39)
          $display("Programa 5 correcto");
        else
          $display("Programa 5 fallo");
        $display("%0d instrucciones en %0d ciclos, IPC = %.2f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo);
        $stop;
      end

      if (ciclos == 200) begin
        $display("Programa 5: el programa no termino");
        $stop;
      end
    end
  end
endmodule
