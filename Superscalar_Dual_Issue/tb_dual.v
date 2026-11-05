`timescale 1ns/1ps
module tb_dual;
    reg clk = 0, reset = 1, Stall = 0;
    wire [31:0] PC0, PC1, Instr0, Instr1, ALUResult0E, ALUResult1E;
    integer pairs = 0, cycles = 0, i;
    reg [31:0] oldPC, oldPCD, oldInstr0D, oldInstr1D;
    reg oldValidD;
    top_dual dut(clk, reset, Stall, PC0, PC1, Instr0, Instr1, ALUResult0E, ALUResult1E);
    always #5 clk = ~clk;

    task check;
        input condition;
        input [511:0] message;
        begin
            if (condition !== 1'b1) $fatal(1, "Dual ciclo %0d: %0s", cycles, message);
        end
    endtask

    initial begin
        $dumpfile("build/dual.vcd");
        $dumpvars(0, tb_dual);
        // Valores de prueba para observar las cuatro lecturas sin un WB integrado.
        for (i = 1; i < 32; i = i + 1) dut.dual.rf.rf[i] = 0;
        dut.dual.rf.rf[1] = 12;
        dut.dual.rf.rf[2] = 5;
        dut.dual.rf.rf[3] = 4;
        dut.dual.rf.rf[4] = 9;
        #12 reset = 0;
        #20 Stall = 1;
        #20 Stall = 0;
    end

    always @(posedge clk) if (!reset) begin
        cycles = cycles + 1;
        check(cycles < 20, "Timeout");
        check(PC1 === PC0 + 4, "Las direcciones Fetch deben ser consecutivas");
        check(Instr0 === dut.dual.imem.ROM[PC0/4] &&
              Instr1 === dut.dual.imem.ROM[PC0/4+1], "Par Fetch incorrecto");
        oldPC = PC0;
        oldPCD = dut.dual.PC0D;
        oldInstr0D = dut.dual.Instr0D;
        oldInstr1D = dut.dual.Instr1D;
        oldValidD = dut.dual.ValidD;

        if (oldValidD && !Stall) begin
            check(oldPCD == pairs * 8, "Par perdido, repetido o fuera de orden");
            check(dut.dual.PC1D == oldPCD + 4, "PC incorrecto en Decode");
            case (oldPCD)
                0: begin
                    check(dut.dual.Rd0D == 5 && dut.dual.Rd1D == 6, "rd de ambos decoders");
                    check(dut.dual.ALUControl0D == 0 && dut.dual.ALUControl1D == 1, "add/sub en paralelo");
                    check(dut.dual.RD10D == 12 && dut.dual.RD20D == 5 &&
                          dut.dual.RD11D == 12 && dut.dual.RD21D == 4, "Cuatro puertos de lectura");
                end
                8: check(dut.dual.ResultSrc0D == 1 && dut.dual.ALUSrc0D &&
                         dut.dual.ImmExt0D == 8 && dut.dual.ALUControl1D == 2, "Decode lw/and");
                16: check(dut.dual.ALUControl0D == 3 && dut.dual.MemWrite1D &&
                          !dut.dual.RegWrite1D && dut.dual.ImmExt1D == 12, "Decode or/sw");
                24: check(dut.dual.Branch0D && dut.dual.ImmExt0D == 16 &&
                          dut.dual.ALUSrc1D && dut.dual.ImmExt1D == -4, "Inmediatos B e I");
                32: check(dut.dual.ALUControl0D == 5 && dut.dual.Jump1D &&
                          dut.dual.ResultSrc1D == 2 && dut.dual.ImmExt1D == 4, "Decode slt/jal");
                40: check(dut.dual.ImmExt0D == 1 && dut.dual.ImmExt1D == 2, "Ultimo par");
            endcase
            $display("DECODE PC0D=%0d PC1D=%0d Instr0D=%h Instr1D=%h", oldPCD,
                     dut.dual.PC1D, oldInstr0D, oldInstr1D);
            pairs = pairs + 1;
        end
        #1;
        if (Stall) begin
            check(PC0 === oldPC && dut.dual.PC0D === oldPCD &&
                  dut.dual.Instr0D === oldInstr0D && dut.dual.Instr1D === oldInstr1D,
                  "Stall debe conservar PC y ambas instrucciones");
            check(!dut.dual.ValidE && !dut.dual.RegWrite0E && !dut.dual.RegWrite1E &&
                  !dut.dual.MemWrite0E && !dut.dual.MemWrite1E, "Burbuja EX durante Stall");
        end else begin
            check(PC0 === oldPC + 8, "Fetch debe avanzar ocho bytes");
            check(dut.dual.PC0D === oldPC, "Falta registro IF/ID");
            if (oldValidD) begin
                check(dut.dual.PC0E == oldPCD && dut.dual.PC1E == oldPCD + 4,
                      "Datos y PC desalineados en ID/EX");
                case (oldPCD)
                    0: check(ALUResult0E == 17 && ALUResult1E == 8, "Resultados add/sub");
                    8: check(ALUResult0E == 20 && ALUResult1E == 4, "Direccion lw y resultado and");
                    16: check(ALUResult0E == 13 && ALUResult1E == 16 && dut.dual.WriteData1E == 9,
                              "Resultado or y direccion/dato sw");
                    24: check(ALUResult0E == 7 && ALUResult1E == 8, "Comparacion y addi");
                    32: check(ALUResult0E == 1 && dut.dual.Jump1E, "Control de jal en EX");
                    40: check(ALUResult0E == 1 && ALUResult1E == 2, "Resultados del ultimo par");
                endcase
            end
        end
        if (pairs == 6) begin
            check(dut.dual.rf.rf[5] == 0 && dut.dual.rf.rf[6] == 0, "WB debe seguir desconectado");
            $display("PASS DUAL: 6 pares, Decode completo, 4 lecturas, 2 ALU y hold de 2 ciclos");
            #4; // Dejar visible el resultado del ultimo par en la waveform.
            $finish;
        end
    end
endmodule
