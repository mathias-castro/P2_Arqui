module tb;
  reg clk, reset; wire [31:0] WD, DA; wire MW;
  integer ciclos, instr, post, i; reg done;
`ifdef OPT
  // coverage: index = {lane, isjump, pred, taken}
  integer cov[0:15]; integer repl, redir0, redir1, hitupd, jalfwd;
`endif
  top_dual #(.MEMFILE("prog.mem")) dut(.clk(clk), .reset(reset), .WriteDataM(WD), .DataAdrM(DA), .MemWriteM(MW));
  initial begin ciclos=0; instr=0; post=0; done=0; reset=1;
`ifdef OPT
    for (i=0;i<16;i=i+1) cov[i]=0; repl=0; redir0=0; redir1=0; hitupd=0; jalfwd=0;
`endif
    #22; reset=0; end
  always begin clk=1; #5; clk=0; #5; end
  always @(negedge clk) if (~reset) begin
    if (!done) begin
      ciclos = ciclos + 1;
      if (dut.rvdual.dp.InstrW0 != 0) instr = instr + 1;
      if (dut.rvdual.dp.InstrW1 != 0) instr = instr + 1;
`ifdef OPT
      if (dut.rvdual.dp.BranchE | dut.rvdual.dp.JumpE) begin
        cov[{dut.rvdual.dp.BranchSelE, dut.rvdual.dp.JumpE, dut.rvdual.dp.PredE, dut.rvdual.dp.TakenE}] =
          cov[{dut.rvdual.dp.BranchSelE, dut.rvdual.dp.JumpE, dut.rvdual.dp.PredE, dut.rvdual.dp.TakenE}] + 1;
        if (dut.rvdual.dp.bp.valid[dut.rvdual.dp.bp.iE] === 1'b1 && !dut.rvdual.dp.bp.hitE) repl = repl + 1;
      end
      if (((dut.rvdual.dp.ForwardAE0 == 3'b011 | dut.rvdual.dp.ForwardBE0 == 3'b011 |
            dut.rvdual.dp.ForwardAE1 == 3'b011 | dut.rvdual.dp.ForwardBE1 == 3'b011) & dut.rvdual.dp.ResultSrcM0 == 2'b10) |
          ((dut.rvdual.dp.ForwardAE0 == 3'b100 | dut.rvdual.dp.ForwardBE0 == 3'b100 |
            dut.rvdual.dp.ForwardAE1 == 3'b100 | dut.rvdual.dp.ForwardBE1 == 3'b100) & dut.rvdual.dp.ResultSrcM1 == 2'b10))
        jalfwd = jalfwd + 1;
      if (~dut.rvdual.dp.StallF & ~dut.rvdual.dp.MispredE & dut.rvdual.dp.PredF0) redir0 = redir0 + 1;
      if (~dut.rvdual.dp.StallF & ~dut.rvdual.dp.MispredE & ~dut.rvdual.dp.PredF0 & dut.rvdual.dp.Issue1 & dut.rvdual.dp.PredF1) redir1 = redir1 + 1;
`endif
      if (dut.rvdual.dp.InstrW0 == 32'h00000063 | dut.rvdual.dp.InstrW1 == 32'h00000063) done = 1;
      if (ciclos == 5000) begin $display("HANG %0d", instr); $finish; end
    end else begin
      post = post + 1;
      if (post == 10) begin
        #1;
        $display("END %0d %0d", instr, ciclos);
        for (i=1;i<32;i=i+1) $display("R %0d %h", i, dut.rvdual.dp.rf.rf[i]);
        for (i=0;i<64;i=i+1) $display("M %0d %h", i, dut.dmem.RAM[i]);
`ifdef OPT
        $write("COV");
        for (i=0;i<16;i=i+1) $write(" %0d", cov[i]);
        $display(" %0d %0d %0d %0d", repl, redir0, redir1, jalfwd);
`endif
        $finish;
      end
    end
  end
endmodule
