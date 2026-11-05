module tb_programa3;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;
  integer     ciclos, stalls, burbujas, saltos, i;
  reg         stall_anterior;

  top #(.MEMFILE("programa3.mem")) dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  initial begin
    $dumpfile("programa3.vcd");
    $dumpvars(0, tb_programa3);
    ciclos = 0; stalls = 0; burbujas = 0; saltos = 0;
    stall_anterior = 0;
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
      if (stall_anterior && dut.rvsingle.dp.RegWriteE === 1'b0 &&
          dut.rvsingle.dp.MemWriteE === 1'b0)
        burbujas = burbujas + 1;
      stall_anterior = (dut.rvsingle.dp.StallD === 1'b1);
      if (dut.rvsingle.dp.StallD === 1'b1) stalls = stalls + 1;
      if (dut.rvsingle.dp.PCSrcE === 1'b1) saltos = saltos + 1;

      if (MemWrite === 1'b1 && DataAdr === 252) begin
        if (dut.rvsingle.dp.rf.rf[2] === 21 &&
            dut.rvsingle.dp.rf.rf[3] === 42 &&
            dut.rvsingle.dp.rf.rf[4] === 42 &&
            dut.dmem.RAM[0]          === 21 &&
            dut.dmem.RAM[1]          === 42 &&
            dut.dmem.RAM[2]          === 42 &&
            WriteData                === 3  &&
            stalls == 2 && burbujas == 2 && saltos == 0)
          $display("Programa 3 correcto en %0d ciclos: %0d stalls, %0d burbujas", ciclos, stalls, burbujas);
        else
          $display("Programa 3 fallo");
        $finish;
      end

      if (ciclos == 200) begin
        $display("Programa 3 fallo: tiempo agotado");
        $finish;
      end
    end
  end
endmodule
