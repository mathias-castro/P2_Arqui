// Testbench del programa 3 de la E1: stalling (Load-Use)
module tb_e1_p3;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones;

  // instantiate device to be tested
  top #(.MEMFILE("e1_p3_stalling.mem")) dut(.clk(clk), .reset(reset),
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
      if (dut.rv.dp.InstrW != 0 & dut.rv.dp.InstrW != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end

      if (dut.rv.dp.InstrW == 32'h00000063) begin
        // check results
        if (dut.dmem.RAM[25] === 42 & dut.rv.dp.rf.rf[3] === 42)
          $display("Programa 3 correcto");
        else
          $display("Programa 3 fallo");
        $display("%0d instrucciones en %0d ciclos, IPC = %.2f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo);
        $stop;
      end

      if (ciclos == 200) begin
        $display("Programa 3: el programa no termino");
        $stop;
      end
    end
  end
endmodule
