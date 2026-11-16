// Hazard Unit del Dual-Issue con prediccion de saltos: forwarding entre las dos vias,
// stalls y flushes. Igual que en el Dual-Issue sin prediccion, pero los flushes dependen de MispredE
// (la prediccion del salto fallo) en lugar de PCSrcE (el salto se tomo).
module hazardunit_dual(input  [4:0] Rs1E0, Rs2E0, Rs1E1, Rs2E1,
                       input  [4:0] RdM0, RdM1, RdW0, RdW1,
                       input        RegWriteM0, RegWriteM1, RegWriteW0, RegWriteW1,
                       input        Issue0, Issue1,
                       input        MispredE, BranchSelE,
                       output reg [2:0] ForwardAE0, ForwardBE0, ForwardAE1, ForwardBE1,
                       output       StallF, StallD,
                       output       FlushD, FlushE0, FlushE1, FlushM1);

  // Forwarding. Cada operando puede venir de Memory o Writeback de cualquiera de las vias:
  //   000 = Register File    001 = ResultW0    010 = ResultW1
  //   011 = ALUResultM0      100 = ALUResultM1
  // Si el registro esta en varios lugares se toma el mas reciente: Memory antes
  // que Writeback y, en la misma etapa, la via 1 antes que la via 0.
  always @* begin
    if      ((Rs1E0 == RdM1) & RegWriteM1 & (Rs1E0 != 0)) ForwardAE0 = 3'b100;
    else if ((Rs1E0 == RdM0) & RegWriteM0 & (Rs1E0 != 0)) ForwardAE0 = 3'b011;
    else if ((Rs1E0 == RdW1) & RegWriteW1 & (Rs1E0 != 0)) ForwardAE0 = 3'b010;
    else if ((Rs1E0 == RdW0) & RegWriteW0 & (Rs1E0 != 0)) ForwardAE0 = 3'b001;
    else                                                  ForwardAE0 = 3'b000;

    if      ((Rs2E0 == RdM1) & RegWriteM1 & (Rs2E0 != 0)) ForwardBE0 = 3'b100;
    else if ((Rs2E0 == RdM0) & RegWriteM0 & (Rs2E0 != 0)) ForwardBE0 = 3'b011;
    else if ((Rs2E0 == RdW1) & RegWriteW1 & (Rs2E0 != 0)) ForwardBE0 = 3'b010;
    else if ((Rs2E0 == RdW0) & RegWriteW0 & (Rs2E0 != 0)) ForwardBE0 = 3'b001;
    else                                                  ForwardBE0 = 3'b000;

    if      ((Rs1E1 == RdM1) & RegWriteM1 & (Rs1E1 != 0)) ForwardAE1 = 3'b100;
    else if ((Rs1E1 == RdM0) & RegWriteM0 & (Rs1E1 != 0)) ForwardAE1 = 3'b011;
    else if ((Rs1E1 == RdW1) & RegWriteW1 & (Rs1E1 != 0)) ForwardAE1 = 3'b010;
    else if ((Rs1E1 == RdW0) & RegWriteW0 & (Rs1E1 != 0)) ForwardAE1 = 3'b001;
    else                                                  ForwardAE1 = 3'b000;

    if      ((Rs2E1 == RdM1) & RegWriteM1 & (Rs2E1 != 0)) ForwardBE1 = 3'b100;
    else if ((Rs2E1 == RdM0) & RegWriteM0 & (Rs2E1 != 0)) ForwardBE1 = 3'b011;
    else if ((Rs2E1 == RdW1) & RegWriteW1 & (Rs2E1 != 0)) ForwardBE1 = 3'b010;
    else if ((Rs2E1 == RdW0) & RegWriteW0 & (Rs2E1 != 0)) ForwardBE1 = 3'b001;
    else                                                  ForwardBE1 = 3'b000;
  end

  // Stall: si no sale ninguna instruccion se detienen el PC y el registro F/D.
  // Si en ese ciclo falla una prediccion manda el salto, porque lo que esta en Decode se anula.
  assign StallF = ~Issue0 & ~MispredE;
  assign StallD = ~Issue0 & ~MispredE;

  // Flush: si falla la prediccion se anula el par que esta en Decode y el que iba a entrar a Execute.
  // Tambien entra una burbuja a Execute en la via cuya instruccion no salio.
  assign FlushD  = MispredE;
  assign FlushE0 = ~Issue0 | MispredE;
  assign FlushE1 = ~Issue1 | MispredE;

  // Si el salto mal predicho esta en la via 0, la instruccion de la via 1 que salio
  // con el es mas joven y tambien se anula
  assign FlushM1 = MispredE & ~BranchSelE;
endmodule
