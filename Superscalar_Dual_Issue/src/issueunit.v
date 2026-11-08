// Decide en Decode si se emite el par, solo el slot 0 o nada (en orden).
module issueunit(input  [6:0] opD0, opD1,
                 input  [4:0] RdD0, Rs1D1, Rs2D1,
                 input        RegWriteD0,
                 input        MemWriteD0, MemWriteD1,
                 input  [1:0] ResultSrcD0, ResultSrcD1,
                 input        BranchD0, JumpD0, BranchD1, JumpD1,
                 input        LoadUse0, LoadUse1,
                 output       RAWpar, MemConflict, BranchConflict,
                 output       Issue0, Issue1);

  wire usaRs1D1 = (opD1 == 7'b0110011) | (opD1 == 7'b0010011) | (opD1 == 7'b0000011) |
                  (opD1 == 7'b0100011) | (opD1 == 7'b1100011);
  wire usaRs2D1 = (opD1 == 7'b0110011) | (opD1 == 7'b0100011) | (opD1 == 7'b1100011);

  assign RAWpar = RegWriteD0 & (RdD0 != 0) &
                  ((usaRs1D1 & (Rs1D1 == RdD0)) | (usaRs2D1 & (Rs2D1 == RdD0)));

  wire memD0 = MemWriteD0 | (ResultSrcD0 == 2'b01);
  wire memD1 = MemWriteD1 | (ResultSrcD1 == 2'b01);
  assign MemConflict = memD0 & memD1;

  assign BranchConflict = (BranchD0 | JumpD0) & (BranchD1 | JumpD1);

  assign Issue0 = ~LoadUse0;
  assign Issue1 = Issue0 & ~LoadUse1 & ~RAWpar & ~MemConflict & ~BranchConflict;
endmodule
