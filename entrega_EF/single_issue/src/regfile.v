module regfile(input  clk, 
               input  we3, 
               input  [ 4:0] a1, a2, a3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2); 

  reg [31:0] rf[31:0]; 

  // Al encender todos los registros valen 0, como quedan en la FPGA al configurarla.
  // El programa del profesor supone esto ("registros no indicados = 0").
  integer i;
  initial for (i = 0; i < 32; i = i + 1) rf[i] = 0;

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on falling edge of clock (A3/WD3/WE3),
  // asi lo que se escribe en la primera mitad del ciclo se puede leer en la segunda
  // register 0 hardwired to 0

  always @(negedge clk) begin 
    if (we3) rf[a3] <= wd3; 
  end
  
  assign rd1 = (a1 != 0) ? rf[a1] : 0; 
  assign rd2 = (a2 != 0) ? rf[a2] : 0; 
endmodule
