
module tb_dual;

    reg clk;
    reg reset;

    wire [31:0] PC0, PC1;
    wire [31:0] Instr0, Instr1;

    top_dual dut(
        .clk(clk),
        .reset(reset),
        .PC0(PC0),
        .PC1(PC1),
        .Instr0(Instr0),
        .Instr1(Instr1)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;

        #10 reset = 0;

        #100;
        $finish;
    end

    initial begin
        $dumpfile("dual.vcd");
        $dumpvars(0, tb_dual);
    end

endmodule
