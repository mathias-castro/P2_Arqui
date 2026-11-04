module hazardunit(input      [4:0] Rs1E, Rs2E,
                  input      [4:0] RdM, RdW,
                  input            RegWriteM, RegWriteW,
                  output reg [1:0] ForwardAE, ForwardBE,
                  input      [4:0] Rs1D, Rs2D, RdE,
                  input            ResultSrcE0,
                  input            PCSrcE,
                  output           StallF, StallD, FlushD, FlushE);

  wire lwStall;

  // Condicion Load-Use de Harris: el load en EX produce un registro leido en ID.
  assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
  assign StallF  = lwStall;
  assign StallD  = lwStall;
  assign FlushD  = PCSrcE;
  assign FlushE  = lwStall | PCSrcE;

  always @* begin
    if ((Rs1E == RdM) & RegWriteM & (Rs1E != 0))
      ForwardAE = 2'b10;
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0))
      ForwardAE = 2'b01;
    else
      ForwardAE = 2'b00;

    if ((Rs2E == RdM) & RegWriteM & (Rs2E != 0))
      ForwardBE = 2'b10;
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0))
      ForwardBE = 2'b01;
    else
      ForwardBE = 2'b00;
  end
endmodule
