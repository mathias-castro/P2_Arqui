// Testbench de la EF, programa propio de comparacion (arquitectura B, Dual-Issue)
module tb_propio;
  reg         clk, reset;
  wire [31:0] WriteDataM, DataAdrM;
  wire        MemWriteM;
  integer     ciclos, ultimo, instrucciones, saltos, tomados;

  // instantiate device to be tested
  top_dual #(.MEMFILE("propio.mem")) dut(.clk(clk), .reset(reset),
      .WriteDataM(WriteDataM), .DataAdrM(DataAdrM), .MemWriteM(MemWriteM));

  // initialize test
  initial begin
    ciclos = 0; ultimo = 0; instrucciones = 0; saltos = 0; tomados = 0;
    reset = 1; #22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  // Cuenta los ciclos, las instrucciones que llegan a Writeback (una burbuja vale 0),
  // los saltos que se resuelven en Execute y cuantos se toman (cada uno es un flush).
  // El programa termina cuando llega a Writeback fin: beq x0, x0, fin (00000063).
  // fin no se cuenta: los ciclos llegan hasta la ultima instruccion anterior a fin.
  always @(negedge clk) begin
    if (~reset) begin
      ciclos = ciclos + 1;
      if (dut.rvdual.dp.InstrW0 != 0 & dut.rvdual.dp.InstrW0 != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end
      if (dut.rvdual.dp.InstrW1 != 0 & dut.rvdual.dp.InstrW1 != 32'h00000063) begin instrucciones = instrucciones + 1; ultimo = ciclos; end
      if ((dut.rvdual.dp.BranchE | dut.rvdual.dp.JumpE) & (dut.rvdual.dp.BranchSelE ? dut.rvdual.dp.InstrE1 : dut.rvdual.dp.InstrE0) != 32'h00000063) saltos = saltos + 1;
      if (dut.rvdual.dp.PCSrcE & (dut.rvdual.dp.BranchSelE ? dut.rvdual.dp.InstrE1 : dut.rvdual.dp.InstrE0) != 32'h00000063) tomados = tomados + 1;

      if (dut.rvdual.dp.InstrW0 == 32'h00000063 | dut.rvdual.dp.InstrW1 == 32'h00000063) begin
        #1; // deja que termine la escritura del Register File de este ciclo
        // check results: los mismos que en A y C
        if (dut.dmem.RAM[25] === 120 & dut.dmem.RAM[26] === 8 & dut.dmem.RAM[27] === 92 & dut.dmem.RAM[15] === 3)
          $display("Programa propio correcto");
        else
          $display("Programa propio fallo");
        $display("%0d instrucciones en %0d ciclos, IPC = %.2f",
                 instrucciones, ultimo, 1.0 * instrucciones / ultimo);
        $display("%0d saltos, %0d tomados (flush)", saltos, tomados);
        $stop;
      end

      if (ciclos == 1000) begin
        $display("Programa propio: el programa no termino");
        $stop;
      end
    end
  end
endmodule
