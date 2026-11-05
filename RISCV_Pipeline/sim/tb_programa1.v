module tb_programa1;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;
  integer     ciclos, forwards, stalls, saltos, i;

  top #(.MEMFILE("programa1.mem")) dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  initial begin
    $dumpfile("programa1.vcd");
    $dumpvars(0, tb_programa1);
    ciclos = 0; forwards = 0; stalls = 0; saltos = 0;
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
      if (dut.rvsingle.dp.ForwardAE != 0 || dut.rvsingle.dp.ForwardBE != 0)
        forwards = forwards + 1;
      if (dut.rvsingle.dp.StallD === 1'b1) stalls = stalls + 1;
      if (dut.rvsingle.dp.PCSrcE === 1'b1) saltos = saltos + 1;

      if (MemWrite === 1'b1 && DataAdr === 252) begin
        if (dut.rvsingle.dp.rf.rf[4]  === 17 &&
            dut.rvsingle.dp.rf.rf[5]  === 7  &&
            dut.rvsingle.dp.rf.rf[6]  === 4  &&
            dut.rvsingle.dp.rf.rf[7]  === 13 &&
            dut.rvsingle.dp.rf.rf[8]  === 1  &&
            dut.rvsingle.dp.rf.rf[9]  === 1  &&
            dut.rvsingle.dp.rf.rf[10] === 4  &&
            dut.rvsingle.dp.rf.rf[11] === 13 &&
            dut.rvsingle.dp.rf.rf[12] === 32'hFFFFFFFC &&
            dut.rvsingle.dp.rf.rf[13] === 12 &&
            dut.rvsingle.dp.rf.rf[14] === 72 &&
            dut.dmem.RAM[0]           === 12 &&
            WriteData                 === 1  &&
            forwards == 0 && stalls == 0 && saltos == 1)
          $display("Programa 1 correcto en %0d ciclos: %0d forwards, %0d stalls", ciclos, forwards, stalls);
        else
          $display("Programa 1 fallo");
        $finish;
      end

      if (ciclos == 200) begin
        $display("Programa 1 fallo: tiempo agotado");
        $finish;
      end
    end
  end
endmodule
