module tb_programa2;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;
  integer     ciclos, forwards, stalls, saltos, i;
  reg         vioA01, vioA10, vioB01, vioB10;

  top #(.MEMFILE("programa2.mem")) dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  initial begin
    $dumpfile("programa2.vcd");
    $dumpvars(0, tb_programa2);
    ciclos = 0; forwards = 0; stalls = 0; saltos = 0;
    vioA01 = 0; vioA10 = 0; vioB01 = 0; vioB10 = 0;
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
      if (dut.rvsingle.dp.ForwardAE == 2'b01) vioA01 = 1;
      if (dut.rvsingle.dp.ForwardAE == 2'b10) vioA10 = 1;
      if (dut.rvsingle.dp.ForwardBE == 2'b01) vioB01 = 1;
      if (dut.rvsingle.dp.ForwardBE == 2'b10) vioB10 = 1;
      if (dut.rvsingle.dp.StallD === 1'b1) stalls = stalls + 1;
      if (dut.rvsingle.dp.PCSrcE === 1'b1) saltos = saltos + 1;

      if (MemWrite === 1'b1 && DataAdr === 252) begin
        if (dut.rvsingle.dp.rf.rf[3] === 12 &&
            dut.rvsingle.dp.rf.rf[4] === 7  &&
            dut.rvsingle.dp.rf.rf[5] === 19 &&
            dut.rvsingle.dp.rf.rf[6] === 9  &&
            dut.rvsingle.dp.rf.rf[7] === 18 &&
            dut.rvsingle.dp.rf.rf[8] === 0  &&
            dut.dmem.RAM[1]          === 18 &&
            WriteData                === 2  &&
            vioA01 && vioA10 && vioB01 && vioB10 &&
            stalls == 0 && saltos == 0)
          $display("Programa 2 correcto en %0d ciclos: %0d ciclos con forwarding, %0d stalls", ciclos, forwards, stalls);
        else
          $display("Programa 2 fallo");
        $finish;
      end

      if (ciclos == 200) begin
        $display("Programa 2 fallo: tiempo agotado");
        $finish;
      end
    end
  end
endmodule
