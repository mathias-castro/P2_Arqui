`timescale 1ns/1ps
module tb_pipeline;
  reg clk = 0;
  reg reset = 1;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;
  integer program_id, i, cycles = 0, stalls = 0, redirects = 0;
  integer stores = 0, forward_cycles = 0;
  reg [3:0] observed = 0;
  reg [1023:0] vcdfile;
  reg [31:0] saved_pc, saved_instr, target;
  reg was_stall, was_redirect, finished;

  top #(.MEMFILE("")) dut(clk, reset, WriteData, DataAdr, MemWrite);
  always #5 clk = ~clk;

  // Seguimiento de instrucciones para las waveforms; no controla el procesador.
  wire [31:0] InstrF = dut.Instr;
  wire [31:0] InstrD = dut.rvsingle.dp.InstrD;
  reg [31:0] InstrE, InstrM, InstrW;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      InstrE <= 0;
      InstrM <= 0;
      InstrW <= 0;
    end else begin
      InstrE <= dut.rvsingle.dp.FlushE ? 32'b0 : InstrD;
      InstrM <= InstrE;
      InstrW <= InstrM;
    end
  end

  task check;
    input condition;
    input [511:0] message;
    begin
      if (condition !== 1'b1) $fatal(1, "P%0d ciclo %0d: %0s", program_id, cycles, message);
    end
  endtask

  task check_reg;
    input [4:0] regnum;
    input [31:0] expected;
    begin
      if (dut.rvsingle.dp.rf.rf[regnum] !== expected)
        $fatal(1, "P%0d x%0d: esperado %h, obtenido %h", program_id, regnum,
               expected, dut.rvsingle.dp.rf.rf[regnum]);
    end
  endtask

  task check_store;
    input [31:0] address, value;
    begin
      check(DataAdr === address && WriteData === value, "Escritura de memoria incorrecta o fuera de orden");
    end
  endtask

  initial begin
    $timeformat(-9, 0, " ns", 0);
    if (!$value$plusargs("P=%d", program_id)) program_id = 1;
    if (!$value$plusargs("VCD=%s", vcdfile)) vcdfile = "build/pipeline.vcd";
    $dumpfile(vcdfile);
    $dumpvars(0, tb_pipeline);
    #1;
    // Solo la memoria de datos se inicializa; los registros los escribe el programa.
    for (i = 0; i < 64; i = i + 1) dut.dmem.RAM[i] = 0;
    case (program_id)
      1: $readmemh("programs/p1_isa.mem", dut.imem.RAM);
      2: $readmemh("programs/p2_forwarding.mem", dut.imem.RAM);
      3: $readmemh("programs/p3_stalling.mem", dut.imem.RAM);
      4: $readmemh("programs/p4_flushing.mem", dut.imem.RAM);
      default: $fatal(1, "Programa desconocido");
    endcase
    #11 reset = 0;
  end

  // Se observa el estado antes del flanco; #1 comprueba el efecto del flanco.
  always @(posedge clk) if (!reset) begin
    cycles = cycles + 1;
    check(cycles < 200, "Timeout: el programa no llego al final");
    check((^dut.PC) !== 1'bx, "PC desconocido");
    saved_pc = dut.PC;
    saved_instr = dut.rvsingle.dp.InstrD;
    was_stall = dut.rvsingle.dp.StallF;
    was_redirect = dut.rvsingle.dp.PCSrcE;
    target = dut.rvsingle.dp.PCTarget;
    finished = 0;

    if (was_stall) begin
      stalls = stalls + 1;
      check(program_id == 3, "Stall inesperado");
      check(dut.rvsingle.dp.PCD == 12 || dut.rvsingle.dp.PCD == 24,
            "Stall fuera de las dos dependencias Load-Use");
      $display("STALL t=%0t PCF=%0d PCD=%0d RdE=x%0d", $time, dut.PC,
               dut.rvsingle.dp.PCD, dut.rvsingle.dp.RdE);
    end
    if (was_redirect) begin
      redirects = redirects + 1;
      $display("FLUSH t=%0t PCE=%0d destino=%0d", $time, dut.rvsingle.dp.PCE, target);
    end
    if (dut.rvsingle.dp.ForwardAE != 0 || dut.rvsingle.dp.ForwardBE != 0)
      forward_cycles = forward_cycles + 1;

    if (program_id == 2) begin
      case (dut.rvsingle.dp.PCE)
        8: begin
          check(dut.rvsingle.dp.ForwardAE == 1 && dut.rvsingle.dp.ForwardBE == 2,
                "add x3 requiere WB en A y MEM en B");
          check(dut.rvsingle.dp.ALUResultE === 32'd12, "Resultado intermedio x3");
          observed[0] = 1;
        end
        16: begin
          check(dut.rvsingle.dp.ALUResultE === 32'd19, "Resultado intermedio x5");
          observed[1] = 1;
        end
        28: begin
          check(dut.rvsingle.dp.ForwardAE == 2 && dut.rvsingle.dp.ForwardBE == 2,
                "MEM debe tener prioridad sobre WB para x6");
          check(dut.rvsingle.dp.ALUResultE === 32'd18, "Se uso una version vieja de x6");
          observed[2] = 1;
        end
        32: begin
          check(dut.rvsingle.dp.WriteDataE === 32'd18, "Forwarding al dato de sw");
          observed[3] = 1;
        end
      endcase
    end
    if (program_id == 3 && dut.rvsingle.dp.PCE == 12) begin
      check(dut.rvsingle.dp.ForwardAE == 1 && dut.rvsingle.dp.ForwardBE == 1,
            "Load-Use debe usar WB despues de la burbuja");
      check(dut.rvsingle.dp.ALUResultE === 32'd42, "Resultado del Load-Use");
      observed[0] = 1;
    end

    if (MemWrite) begin
      case (program_id)
        1: case (stores)
          0: check_store(0, 12);
          1: check_store(252, 1);
          default: check(0, "Store adicional");
        endcase
        2: case (stores)
          0: check_store(4, 18);
          1: check_store(252, 2);
          default: check(0, "Store adicional");
        endcase
        3: case (stores)
          0: check_store(0, 21);
          1: check_store(4, 42);
          2: check_store(8, 42);
          3: check_store(252, 3);
          default: check(0, "Store adicional");
        endcase
        4: case (stores)
          0: check_store(12, 40);
          1: check_store(252, 4);
          default: check(0, "Store de una instruccion anulada");
        endcase
      endcase
      stores = stores + 1;
      $display("STORE t=%0t Mem[%0d]=%0d", $time, DataAdr, WriteData);
      finished = (DataAdr == 252);
    end

    #1;
    if (was_stall) begin
      check(dut.PC === saved_pc && dut.rvsingle.dp.InstrD === saved_instr,
            "El stall debe conservar PC e InstrD");
      check(dut.rvsingle.dp.RegWriteE == 0 && dut.rvsingle.dp.MemWriteE == 0,
            "La burbuja no debe escribir registros ni memoria");
    end
    if (was_redirect) begin
      check(dut.PC === target, "PC no redirigido al destino");
      check(dut.rvsingle.dp.InstrD == 0 && dut.rvsingle.dp.RegWriteE == 0 &&
            dut.rvsingle.dp.MemWriteE == 0 && dut.rvsingle.dp.JumpE == 0 &&
            dut.rvsingle.dp.BranchE == 0, "Flush no anulo las instrucciones jovenes");
    end
    if (finished) begin
      check(dut.dmem.RAM[63] === program_id, "El store final no se escribio");
      case (program_id)
        1: begin
          check_reg(1,12); check_reg(2,5); check_reg(3,-3);
          check_reg(4,17); check_reg(5,7); check_reg(6,4); check_reg(7,13);
          check_reg(8,1); check_reg(9,1); check_reg(10,4); check_reg(11,13);
          check_reg(12,-4); check_reg(13,12); check_reg(14,72); check_reg(15,1);
          check(stalls == 0 && forward_cycles == 0 && redirects == 1, "Hazards inesperados en P1");
        end
        2: begin
          check_reg(3,12); check_reg(4,7); check_reg(5,19); check_reg(6,9);
          check_reg(7,18); check_reg(8,0); check_reg(15,2);
          check(observed == 4'b1111 && stalls == 0 && redirects == 0, "Cobertura forwarding incompleta");
        end
        3: begin
          check_reg(2,21); check_reg(3,42); check_reg(4,42); check_reg(15,3);
          check(stalls == 2 && redirects == 0 && observed[0], "Deben ocurrir exactamente dos stalls");
        end
        4: begin
          check_reg(3,7); check_reg(5,36); check_reg(6,40); check_reg(7,0);
          check_reg(10,0); check_reg(15,4);
          check(dut.dmem.RAM[4] == 0 && dut.dmem.RAM[5] == 0 && dut.dmem.RAM[6] == 0,
                "Una instruccion anulada escribio memoria");
          check(stalls == 0 && redirects == 4, "Cantidad de redirecciones incorrecta");
        end
      endcase
      $display("PASS P%0d: ciclos=%0d stalls=%0d redirecciones=%0d ciclos_forward=%0d stores=%0d",
               program_id, cycles, stalls, redirects, forward_cycles, stores);
      $finish;
    end
  end
endmodule
