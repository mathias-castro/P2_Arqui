`timescale 1ns/1ps
module tb_dual_regfile;
    reg clk = 0, we0 = 0, we1 = 0;
    reg [4:0] ra10 = 0, ra20 = 0, ra11 = 0, ra21 = 0, wa0 = 0, wa1 = 0;
    reg [31:0] wd0 = 0, wd1 = 0;
    wire [31:0] rd10, rd20, rd11, rd21;
    dual_regfile dut(clk, we0, we1, ra10, ra20, ra11, ra21, wa0, wa1, wd0, wd1,
                     rd10, rd20, rd11, rd21);
    always #5 clk = ~clk;
    initial begin
        $dumpfile("dual_regfile.vcd");
        $dumpvars(0, tb_dual_regfile);
        #1;
        we0 = 1; we1 = 1; wa0 = 1; wa1 = 2; wd0 = 12; wd1 = 5;
        ra10 = 1; ra20 = 2; ra11 = 1; ra21 = 2;
        @(negedge clk); #1;
        if ({rd10, rd20, rd11, rd21} !== {32'd12, 32'd5, 32'd12, 32'd5})
            begin $display("FALLA REGFILE: %s", "Fallo en dos escrituras y cuatro lecturas"); $finish; end
        wa0 = 3; wa1 = 3; wd0 = 7; wd1 = 9; ra10 = 3; ra11 = 3;
        @(negedge clk); #1;
        if (rd10 !== 9 || rd11 !== 9) begin $display("FALLA REGFILE: %s", "La instruccion joven debe ganar el WAW"); $finish; end
        wa0 = 0; wa1 = 0; wd0 = 99; wd1 = 88;
        ra10 = 0; ra20 = 0; ra11 = 0; ra21 = 0;
        @(negedge clk); #1;
        if ({rd10, rd20, rd11, rd21} !== 128'd0) begin $display("FALLA REGFILE: %s", "x0 debe permanecer en cero"); $finish; end
        we0 = 0; wa1 = 4; wd1 = 21; ra10 = 4;
        @(negedge clk); #1;
        if (rd10 !== 21) begin $display("FALLA REGFILE: %s", "Escritura independiente por el puerto 1"); $finish; end
        $display("PASS REGFILE: 4R/2W, prioridad de la via joven, x0 y puerto 1 independiente");
        $finish;
    end
endmodule
