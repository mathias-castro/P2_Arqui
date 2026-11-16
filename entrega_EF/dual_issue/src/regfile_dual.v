// Register File con cuatro lecturas y dos escrituras
//   via 0: lee A1/RD1 y A2/RD2, escribe A3/WD3/WE3
//   via 1: lee A4/RD4 y A5/RD5, escribe A6/WD6/WE6
module regfile_dual(input         clk,
                    input         we3, we6,
                    input  [ 4:0] a1, a2, a3, a4, a5, a6,
                    input  [31:0] wd3, wd6,
                    output [31:0] rd1, rd2, rd4, rd5);

  reg [31:0] rf[31:0];

  // Al encender todos los registros valen 0, como quedan en la FPGA al configurarla.
  // El programa del profesor supone esto ("registros no indicados = 0").
  integer i;
  initial for (i = 0; i < 32; i = i + 1) rf[i] = 0;

  // se escribe en el flanco de bajada, igual que en el pipeline.
  // Si las dos vias escriben el mismo registro queda el dato de la via 1,
  // que es la instruccion mas joven.
  always @(negedge clk) begin
    if (we3 & ~(we6 & (a6 == a3))) rf[a3] <= wd3;
    if (we6)                       rf[a6] <= wd6;
  end

  // x0 siempre se lee como 0
  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
  assign rd4 = (a4 != 0) ? rf[a4] : 0;
  assign rd5 = (a5 != 0) ? rf[a5] : 0;
endmodule
