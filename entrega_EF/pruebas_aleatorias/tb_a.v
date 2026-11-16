module tb;
  reg clk, reset; wire [31:0] WD, DA; wire MW;
  integer ciclos, instr, post, i; reg done;
  top #(.MEMFILE("prog.mem")) dut(.clk(clk), .reset(reset), .WriteDataM(WD), .DataAdrM(DA), .MemWriteM(MW));
  initial begin ciclos=0; instr=0; post=0; done=0; reset=1; #22; reset=0; end
  always begin clk=1; #5; clk=0; #5; end
  always @(negedge clk) if (~reset) begin
    if (!done) begin
      ciclos = ciclos + 1;
      if (dut.rv.dp.InstrW != 0) instr = instr + 1;
      if (dut.rv.dp.InstrW == 32'h00000063) done = 1;
      if (ciclos == 5000) begin $display("HANG %0d", instr); $finish; end
    end else begin
      post = post + 1;
      if (post == 10) begin
        #1;
        $display("END %0d %0d", instr, ciclos);
        for (i=1;i<32;i=i+1) $display("R %0d %h", i, dut.rv.dp.rf.rf[i]);
        for (i=0;i<64;i=i+1) $display("M %0d %h", i, dut.dmem.RAM[i]);
        $finish;
      end
    end
  end
endmodule
