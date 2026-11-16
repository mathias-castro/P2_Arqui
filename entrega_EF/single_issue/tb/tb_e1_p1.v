// Testbench del programa 1 de la E1: instrucciones soportadas, sin dependencias
module tb_e1_p1;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones;

  // instantiate device to be tested
  top #(.MEMFILE("e1_p1_isa.mem")) dut(.clk(clk), .reset(reset),
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
        if (dut.dmem.RAM[25] === 17 & dut.rv.dp.rf.rf[5] === 7 & dut.rv.dp.rf.rf[6] === 4 & dut.rv.dp.rf.rf[7] === 13 & dut.rv.dp.rf.rf[8] === 1 &
            dut.rv.dp.rf.rf[9] === 1 & dut.rv.dp.rf.rf[10] === 4 & dut.rv.dp.rf.rf[11] === 13 & dut.rv.dp.rf.rf[12] === 68 & dut.rv.dp.rf.rf[13] === 12)
          $display("Programa 1 correcto");
        else
          $display("Programa 1 fallo");
        $display("%0d instrucciones en %0d ciclos, IPC = %.2f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo);
        $stop;
      end

      if (ciclos == 200) begin
        $display("Programa 1: el programa no termino");
        $stop;
      end
    end
  end
endmodule
