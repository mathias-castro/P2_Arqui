module hazardunit(input  [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
                  input  [4:0] RdE, RdM, RdW,
                  input        RegWriteM, RegWriteW,
                  input        ResultSrcE0, PCSrcE,
                  output reg [1:0] ForwardAE, ForwardBE,
                  output       StallF, StallD, FlushD, FlushE);

  wire lwStall;

  // forwarding: 10 = desde Memory, 01 = desde Writeback, 00 = sin forwarding
  always @* begin
    if      ((Rs1E == RdM) & RegWriteM & (Rs1E != 0)) ForwardAE = 2'b10;
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0)) ForwardAE = 2'b01;
    else                                              ForwardAE = 2'b00;

    if      ((Rs2E == RdM) & RegWriteM & (Rs2E != 0)) ForwardBE = 2'b10;
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0)) ForwardBE = 2'b01;
    else                                              ForwardBE = 2'b00;
  end

  // stall cuando hay un lw en Execute y la instruccion en Decode usa su resultado
  assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
  assign StallF  = lwStall;
  assign StallD  = lwStall;

  // flush cuando se toma un salto o cuando el stall mete una burbuja
  assign FlushD  = PCSrcE;
  assign FlushE  = lwStall | PCSrcE;
endmodule
