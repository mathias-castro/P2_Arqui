module hazardunit_dual(input  [4:0] Rs1E0, Rs2E0, Rs1E1, Rs2E1,
                       input  [4:0] RdM0, RdM1, RdW0, RdW1,
                       input        RegWriteM0, RegWriteM1, RegWriteW0, RegWriteW1,
                       output reg [2:0] ForwardAE0, ForwardBE0, ForwardAE1, ForwardBE1,
                       input  [6:0] opD0, opD1,
                       input  [4:0] Rs1D0, Rs2D0, Rs1D1, Rs2D1,
                       input  [4:0] RdE0, RdE1,
                       input        RegWriteE0, RegWriteE1,
                       input        ResultSrcE0b0, ResultSrcE1b0,   // 1 solo en lw
                       output       LoadUse0, LoadUse1,
                       input        Issue0, Issue1,
                       input        PCSrcE, TakenE0,
                       output       StallF, StallD, Realign,
                       output       FlushD, FlushE0, FlushE1, FlushM1);

  // ---------------- Forwarding ----------------
  // Prioridad: la etapa mas reciente y, dentro de ella, la via mas joven.
  // Todo entra como argumento: always @* no detecta senales leidas dentro de una funcion.
  function [2:0] fwd(input [4:0] rs,
                     input [4:0] rdM1, rdM0, rdW1, rdW0,
                     input       weM1, weM0, weW1, weW0);
    begin
      if      ((rs != 0) & weM1 & (rs == rdM1)) fwd = 3'b100;
      else if ((rs != 0) & weM0 & (rs == rdM0)) fwd = 3'b011;
      else if ((rs != 0) & weW1 & (rs == rdW1)) fwd = 3'b010;
      else if ((rs != 0) & weW0 & (rs == rdW0)) fwd = 3'b001;
      else                                      fwd = 3'b000;
    end
  endfunction

  always @* begin
    ForwardAE0 = fwd(Rs1E0, RdM1, RdM0, RdW1, RdW0, RegWriteM1, RegWriteM0, RegWriteW1, RegWriteW0);
    ForwardBE0 = fwd(Rs2E0, RdM1, RdM0, RdW1, RdW0, RegWriteM1, RegWriteM0, RegWriteW1, RegWriteW0);
    ForwardAE1 = fwd(Rs1E1, RdM1, RdM0, RdW1, RdW0, RegWriteM1, RegWriteM0, RegWriteW1, RegWriteW0);
    ForwardBE1 = fwd(Rs2E1, RdM1, RdM0, RdW1, RdW0, RegWriteM1, RegWriteM0, RegWriteW1, RegWriteW0);
  end

  // ---------------- Load-Use ----------------
  wire usaRs1D0 = (opD0 == 7'b0110011) | (opD0 == 7'b0010011) | (opD0 == 7'b0000011) |
                  (opD0 == 7'b0100011) | (opD0 == 7'b1100011);
  wire usaRs2D0 = (opD0 == 7'b0110011) | (opD0 == 7'b0100011) | (opD0 == 7'b1100011);
  wire usaRs1D1 = (opD1 == 7'b0110011) | (opD1 == 7'b0010011) | (opD1 == 7'b0000011) |
                  (opD1 == 7'b0100011) | (opD1 == 7'b1100011);
  wire usaRs2D1 = (opD1 == 7'b0110011) | (opD1 == 7'b0100011) | (opD1 == 7'b1100011);

  wire lwE0 = ResultSrcE0b0 & RegWriteE0 & (RdE0 != 0);
  wire lwE1 = ResultSrcE1b0 & RegWriteE1 & (RdE1 != 0);

  assign LoadUse0 = (lwE0 & ((usaRs1D0 & (Rs1D0 == RdE0)) | (usaRs2D0 & (Rs2D0 == RdE0)))) |
                    (lwE1 & ((usaRs1D0 & (Rs1D0 == RdE1)) | (usaRs2D0 & (Rs2D0 == RdE1))));
  assign LoadUse1 = (lwE0 & ((usaRs1D1 & (Rs1D1 == RdE0)) | (usaRs2D1 & (Rs2D1 == RdE0)))) |
                    (lwE1 & ((usaRs1D1 & (Rs1D1 == RdE1)) | (usaRs2D1 & (Rs2D1 == RdE1))));

  // ---------------- Stalls, reagrupamiento y flushing ----------------
  // Un salto tomado tiene prioridad: lo que esta en Decode es mas joven y se descarta.
  assign StallF  = ~Issue0 & ~PCSrcE;
  assign StallD  = ~Issue0 & ~PCSrcE;
  assign Realign = Issue0 & ~Issue1 & ~PCSrcE;

  assign FlushD  = PCSrcE;
  assign FlushE0 = ~Issue0 | PCSrcE;
  assign FlushE1 = ~Issue1 | PCSrcE;
  assign FlushM1 = TakenE0;
endmodule
