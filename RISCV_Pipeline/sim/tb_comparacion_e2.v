// Ciclos de los programas de la E2 en el Single-Issue, hasta que el sw final llega a MEM.
module tb_comparacion_e2;
  reg         clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;
  integer     i, ciclos, errores;
  reg  [31:0] exp_rf [1:31];
  reg  [31:0] exp_mem[0:63];

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  always begin
    clk = 1; #5;
    clk = 0; #5;
  end

  task correr(input [8*20-1:0] archivo, input integer n, input integer N);
    begin
      $readmemh(archivo, dut.imem.RAM);
      for (i = 0; i < 32; i = i + 1) dut.rvsingle.dp.rf.rf[i] = 0;
      for (i = 0; i < 64; i = i + 1) dut.dmem.RAM[i] = 0;
      reset = 1; ciclos = 0; errores = 0;
      // mismo instante de reset que los testbenches del Dual-Issue
      @(posedge clk); @(posedge clk); #2;
      reset = 0;
      @(negedge clk); ciclos = 1;
      while (!(MemWrite === 1'b1 && DataAdr === 252) && ciclos < 200) begin
        @(negedge clk); ciclos = ciclos + 1;
      end
      repeat (2) @(negedge clk);
      for (i = 1; i < 32; i = i + 1)
        if (dut.rvsingle.dp.rf.rf[i] !== exp_rf[i]) errores = errores + 1;
      for (i = 0; i < 64; i = i + 1)
        if (dut.dmem.RAM[i] !== exp_mem[i]) errores = errores + 1;
      $display("Programa %0d Single-Issue: ciclos=%0d instrucciones=%0d IPC=%0d.%02d %0s",
               n, ciclos, N, N / ciclos, (100 * N / ciclos) % 100,
               errores == 0 ? "correcto" : "fallo");
    end
  endtask

  initial begin
    for (i = 1; i < 32; i = i + 1) exp_rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) exp_mem[i] = 0;
    exp_rf[1]=32'h0000000a; exp_rf[2]=32'h00000014; exp_rf[3]=32'h0000001e; exp_rf[4]=32'h00000028; exp_rf[6]=32'h0000003e; exp_rf[7]=32'h00000028; exp_rf[8]=32'h00000014; exp_rf[9]=32'h00000001; exp_rf[11]=32'h0000000c; exp_rf[12]=32'h0000000f; exp_rf[13]=32'h0000003e; exp_rf[14]=32'h00000014;
    exp_mem[63]=32'h0000003e;
    correr("e2_programa1.mem", 1, 15);
    for (i = 1; i < 32; i = i + 1) exp_rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) exp_mem[i] = 0;
    exp_rf[1]=32'h00000005; exp_rf[2]=32'h00000008; exp_rf[3]=32'h00000007; exp_rf[4]=32'h0000000f; exp_rf[5]=32'h00000001; exp_rf[6]=32'h00000007; exp_rf[7]=32'h00000010; exp_rf[9]=32'h00000009; exp_rf[10]=32'h00000012; exp_rf[12]=32'h00000004; exp_rf[13]=32'h00000003; exp_rf[14]=32'h00000006;
    exp_mem[63]=32'h00000012;
    correr("e2_programa2.mem", 2, 14);
    for (i = 1; i < 32; i = i + 1) exp_rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) exp_mem[i] = 0;
    exp_rf[1]=32'h00000015; exp_rf[2]=32'h00000008; exp_rf[3]=32'h00000015; exp_rf[4]=32'h0000002a; exp_rf[5]=32'h00000003; exp_rf[6]=32'h00000008; exp_rf[7]=32'h00000032; exp_rf[9]=32'h00000015; exp_rf[10]=32'h00000001; exp_rf[11]=32'h00000002; exp_rf[12]=32'h00000007; exp_rf[13]=32'h0000002a;
    exp_mem[2]=32'h00000015; exp_mem[3]=32'h00000008; exp_mem[63]=32'h0000002a;
    correr("e2_programa3.mem", 3, 15);
    for (i = 1; i < 32; i = i + 1) exp_rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) exp_mem[i] = 0;
    exp_rf[1]=32'h00000001; exp_rf[2]=32'h00000002; exp_rf[3]=32'h00000003; exp_rf[5]=32'h00000005; exp_rf[7]=32'h00000034; exp_rf[9]=32'h00000034; exp_rf[11]=32'h00000006; exp_rf[14]=32'h00000048;
    exp_mem[63]=32'h00000006;
    correr("e2_programa4.mem", 4, 24);
    for (i = 1; i < 32; i = i + 1) exp_rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) exp_mem[i] = 0;
    exp_rf[1]=32'h00000001; exp_rf[2]=32'h00000002; exp_rf[3]=32'h00000004; exp_rf[4]=32'h00000006; exp_rf[5]=32'h00000003; exp_rf[6]=32'h0000000a; exp_rf[7]=32'h00000002; exp_rf[8]=32'h00000002; exp_rf[9]=32'h0000000d; exp_rf[10]=32'h00000004;
    exp_mem[0]=32'h00000002; exp_mem[63]=32'h00000004;
    correr("e2_programa5.mem", 5, 14);
    for (i = 1; i < 32; i = i + 1) exp_rf[i] = 0;
    for (i = 0; i < 64; i = i + 1) exp_mem[i] = 0;
    exp_rf[1]=32'h00000006; exp_rf[2]=32'h00000028; exp_rf[3]=32'h0000002e; exp_rf[4]=32'h0000002f;
    exp_mem[0]=32'h0000002e; exp_mem[63]=32'h0000002f;
    correr("e2_programa6.mem", 6, 15);
    $finish;
  end
endmodule
