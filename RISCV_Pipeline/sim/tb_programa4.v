module tb_programa4;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;
  integer     ciclos, stalls, saltos, i;

  top #(.MEMFILE("programa4.mem")) dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  initial begin
    $dumpfile("programa4.vcd");
    $dumpvars(0, tb_programa4);
    ciclos = 0; stalls = 0; saltos = 0;
    for (i = 0; i < 64; i = i + 1) dut.dmem.RAM[i] = 0;
    reset = 1; #22;
    reset = 0;
  end

  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  always @(negedge clk) begin
    if (!reset) begin
      ciclos = ciclos + 1;
      if (dut.rvsingle.dp.StallD === 1'b1) stalls = stalls + 1;
      if (dut.rvsingle.dp.PCSrcE === 1'b1) saltos = saltos + 1;

      if (MemWrite === 1'b1 && DataAdr === 252) begin
        if (dut.rvsingle.dp.rf.rf[4] === 0  &&
            dut.rvsingle.dp.rf.rf[5] === 0  &&
            dut.rvsingle.dp.rf.rf[6] === 10 &&
            dut.rvsingle.dp.rf.rf[7] === 44 &&
            dut.dmem.RAM[4]          === 0  &&
            dut.dmem.RAM[5]          === 0  &&
            WriteData                === 4  &&
            stalls == 0 && saltos == 2)
          $display("Programa 4 correcto en %0d ciclos: %0d saltos tomados, %0d stalls", ciclos, saltos, stalls);
        else
          $display("Programa 4 fallo");
        $finish;
      end

      if (ciclos == 200) begin
        $display("Programa 4 fallo: tiempo agotado");
        $finish;
      end
    end
  end
endmodule
