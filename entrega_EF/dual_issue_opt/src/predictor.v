// Predictor de saltos: branch target buffer (BTB) de 16 entradas con un contador de 2 bits
// por entrada. Se indexa con los bits 5:2 del PC.
//   Cada entrada guarda: valida, el PC del salto, su destino y el contador.
//   Contador: 11 strongly taken, 10 weakly taken, 01 weakly not taken, 00 strongly not taken.
//   Se predice que el salto se toma si la entrada coincide con el PC y el contador es 1x.
//
// En Fetch se consulta con las dos instrucciones que se leen (PCF y PCF + 4).
// En Execute se actualiza con el beq o jal que se acaba de resolver.
module predictor(input         clk, reset,
                 // consulta en Fetch
                 input  [31:0] PCF0, PCF1,
                 output        PredF0, PredF1,
                 output [31:0] PredTargetF0, PredTargetF1,
                 // actualizacion en Execute
                 input         UpdateE,          // hay un beq o jal en Execute
                 input  [31:0] BranchPCE, PCTargetE,
                 input         TakenE);          // el salto se tomo

  reg        valid  [15:0];
  reg [31:0] pc     [15:0];
  reg [31:0] target [15:0];
  reg [1:0]  cnt    [15:0];
  integer    i;

  wire [3:0] i0 = PCF0[5:2];
  wire [3:0] i1 = PCF1[5:2];
  wire [3:0] iE = BranchPCE[5:2];

  // consulta: hay hit si la entrada es valida y guarda el mismo PC
  wire hit0 = valid[i0] & (pc[i0] == PCF0);
  wire hit1 = valid[i1] & (pc[i1] == PCF1);
  wire hitE = valid[iE] & (pc[iE] == BranchPCE);
  wire [1:0] CntE = cnt[iE];   // contador del salto que esta en Execute

  assign PredF0       = hit0 & cnt[i0][1];
  assign PredF1       = hit1 & cnt[i1][1];
  assign PredTargetF0 = target[i0];
  assign PredTargetF1 = target[i1];

  // actualizacion al final del ciclo en que el salto esta en Execute
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < 16; i = i + 1) begin
        valid[i] <= 1'b0;
        pc[i]    <= 32'b0;
        target[i] <= 32'b0;
        cnt[i]   <= 2'b00;
      end
    end
    else if (UpdateE) begin
      if (hitE) begin
        // el salto ya esta en la tabla: el contador sube si se tomo y baja si no
        if (TakenE & (CntE != 2'b11))  cnt[iE] <= CntE + 1;
        if (~TakenE & (CntE != 2'b00)) cnt[iE] <= CntE - 1;
      end
      else begin
        // primera vez que se ve (o otra entrada ocupaba el lugar): se guarda
        // con weakly taken si se tomo y con weakly not taken si no
        valid[iE]  <= 1'b1;
        pc[iE]     <= BranchPCE;
        target[iE] <= PCTargetE;
        cnt[iE]    <= TakenE ? 2'b10 : 2'b01;
      end
    end
  end
endmodule
