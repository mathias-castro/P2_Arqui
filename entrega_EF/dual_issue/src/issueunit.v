// Issue Unit: mira el par de instrucciones que esta en Decode y decide cuantas salen a Execute.
//   Issue0 = 1: sale la primera instruccion del par (via 0)
//   Issue1 = 1: sale tambien la segunda (via 1)
// La emision es en orden, asi que la segunda nunca sale si la primera se queda.
module issueunit(input  [4:0] Rs1D0, Rs2D0, RdD0,
                 input  [4:0] Rs1D1, Rs2D1,
                 input        RegWriteD0,
                 input        MemWriteD0, LoadD0, BranchD0, JumpD0,
                 input        MemWriteD1, LoadD1, BranchD1, JumpD1,
                 input  [4:0] RdE0, RdE1,
                 input        LoadE0, LoadE1,
                 output       Issue0, Issue1);

  wire lwStall0, lwStall1, RAW, MemConflict, BranchConflict;

  // Load-Use: hay un lw en Execute (en cualquiera de las dos vias) y la instruccion
  // usa su resultado, que recien va a estar despues de Memory. Las demas dependencias
  // con instrucciones anteriores se resuelven con forwarding.
  assign lwStall0 = (LoadE0 & ((Rs1D0 == RdE0) | (Rs2D0 == RdE0))) |
                    (LoadE1 & ((Rs1D0 == RdE1) | (Rs2D0 == RdE1)));
  assign lwStall1 = (LoadE0 & ((Rs1D1 == RdE0) | (Rs2D1 == RdE0))) |
                    (LoadE1 & ((Rs1D1 == RdE1) | (Rs2D1 == RdE1)));

  // RAW dentro del par: la segunda lee el registro que escribe la primera.
  // Las dos estarian juntas en Execute y ahi no hay de donde hacer forwarding.
  assign RAW = RegWriteD0 & (RdD0 != 0) & ((Rs1D1 == RdD0) | (Rs2D1 == RdD0));

  // Recursos compartidos: un puerto de memoria de datos y un recurso de branches.
  // Las ALU no se revisan porque hay una por via.
  assign MemConflict    = (MemWriteD0 | LoadD0) & (MemWriteD1 | LoadD1);
  assign BranchConflict = (BranchD0 | JumpD0) & (BranchD1 | JumpD1);

  assign Issue0 = ~lwStall0;
  assign Issue1 = Issue0 & ~lwStall1 & ~RAW & ~MemConflict & ~BranchConflict;
endmodule
