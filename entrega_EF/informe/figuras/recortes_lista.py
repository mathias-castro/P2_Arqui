# Recortes que usa el informe: recorte(captura, salida, t0, t1, filas, cajas, etapas)
# cajas: (senal, inicio del ciclo en ns, color)  o = naranja, y = amarillo, r = rojo, p = morado
# Programa 1 del pipeline: sw/lw y el jal
recorte('wave_s1b', 'r_s1.png', 180, 250,
        ['PCF', 'PCSrcE', 'MemWriteM', 'ALUResultM', 'WriteDataM', 'RegWriteW', 'RdW', 'ResultW'],
        [('MemWriteM', 180, 'o'), ('ALUResultM', 180, 'o'), ('WriteDataM', 180, 'o'),
         ('PCSrcE', 200, 'r'), ('ResultW', 200, 'y'), ('RdW', 200, 'y'), ('PCF', 210, 'r'),
         ('RdW', 220, 'y'), ('ResultW', 220, 'y'),
         ('MemWriteM', 240, 'o'), ('ALUResultM', 240, 'o'), ('WriteDataM', 240, 'o')],
        etapas=('F', 'D', 'E', 'M', 'W'))
# Programa 2: forwarding
recorte('wave_s2', 'r_s2.png', 50, 120,
        ['Rs1E', 'Rs2E', 'ForwardAE', 'ForwardBE', 'SrcAE', 'SrcBE', 'RdM', 'ALUResultM', 'RdW', 'ResultW'],
        [('ForwardAE', 50, 'o'), ('ALUResultM', 50, 'y'), ('ForwardAE', 60, 'o'), ('ForwardBE', 60, 'o'),
         ('ResultW', 60, 'y'), ('ALUResultM', 60, 'y'), ('ForwardAE', 70, 'o'), ('ALUResultM', 70, 'y'),
         ('ForwardAE', 100, 'o'), ('ForwardBE', 100, 'o'),
         ('ALUResultM', 100, 'y'), ('ResultW', 100, 'r'), ('ForwardBE', 110, 'o')])
# Programa 3: stall por lw
recorte('wave_s3', 'r_s3.png', 60, 130,
        ['PCF', 'Rs1D', 'Rs2D', 'RdE', 'lwStall', 'FlushE', 'ForwardAE', 'ForwardBE', 'ReadDataM', 'RdW', 'ResultW'],
        [('Rs1D', 60, 'p'), ('RdE', 60, 'p'), ('lwStall', 60, 'r'), ('FlushE', 60, 'r'), ('PCF', 70, 'r'),
         ('ReadDataM', 70, 'y'), ('ForwardAE', 80, 'o'), ('ResultW', 80, 'y'),
         ('Rs2D', 100, 'p'), ('RdE', 100, 'p'), ('lwStall', 100, 'r'), ('ForwardBE', 120, 'o'), ('ResultW', 120, 'y')])
# Programa 4: flush
recorte('wave_s4', 'r_s4.png', 60, 140,
        ['PCF', 'BranchE', 'JumpE', 'ZeroE', 'PCSrcE', 'PCTargetE', 'FlushD', 'FlushE', 'RdW', 'ResultW'],
        [('BranchE', 60, 'p'), ('ZeroE', 60, 'p'), ('PCSrcE', 60, 'r'), ('PCTargetE', 60, 'y'), ('FlushD', 60, 'r'),
         ('FlushE', 60, 'r'), ('PCF', 70, 'y'), ('ZeroE', 90, 'p'), ('PCSrcE', 90, 'o'),
         ('JumpE', 110, 'p'), ('PCSrcE', 110, 'r'), ('PCTargetE', 110, 'y'), ('FlushD', 110, 'r'), ('FlushE', 110, 'r'),
         ('PCF', 120, 'y'), ('RdW', 130, 'y'), ('ResultW', 130, 'y')])

# ---------- Dual-Issue ----------
recorte('wave_dfd', 'r_dfd.png', 20, 70,
        ['PCF', 'PCD0', 'Rs1D0', 'Rs2D0', 'RdD0', 'ALUControlD0', 'PCD1', 'Rs1D1', 'Rs2D1', 'RdD1', 'ALUControlD1'],
        [('PCF', 20, 'y'), ('PCF', 30, 'y'), ('PCD0', 30, 'p'), ('PCD1', 30, 'p'), ('Rs2D0', 30, 'o'), ('Rs2D1', 30, 'o'),
         ('RdD0', 30, 'y'), ('RdD1', 30, 'y'), ('ALUControlD0', 50, 'o'), ('ALUControlD1', 50, 'o'),
         ('ALUControlD0', 60, 'o'), ('ALUControlD1', 60, 'o')], etapas=('F', 'D'))
recorte('wave_p1', 'r_p1.png', 30, 80,
        ['PCF', 'Issue0', 'Issue1', 'ALUResultE0', 'ALUResultE1', 'RdW0', 'ResultW0', 'RdW1', 'ResultW1'],
        [('Issue0', 30, 'p'), ('Issue1', 30, 'p'), ('ALUResultE0', 40, 'y'), ('ALUResultE1', 40, 'y'),
         ('ALUResultE0', 60, 'y'), ('ALUResultE1', 60, 'y'),
         ('RdW0', 60, 'o'), ('ResultW0', 60, 'o'), ('RdW1', 60, 'o'), ('ResultW1', 60, 'o')], etapas=('F', 'D', 'E', 'W'))
recorte('wave_p2', 'r_p2.png', 30, 100,
        ['PCF', 'Issue1', 'ForwardAE0', 'ForwardBE0', 'SrcAE0', 'SrcBE0', 'ForwardAE1', 'ForwardBE1', 'SrcAE1', 'SrcBE1',
         'ALUResultM0', 'ALUResultM1'],
        [('Issue1', 30, 'r'), ('PCF', 40, 'y'),
         ('ForwardAE0', 60, 'o'), ('ForwardBE0', 60, 'o'), ('ForwardAE1', 60, 'o'), ('ForwardBE1', 60, 'o'),
         ('ALUResultM0', 60, 'y'), ('ALUResultM1', 60, 'y'),
         ('ForwardAE0', 70, 'o'), ('ForwardBE0', 70, 'o'), ('ForwardAE1', 70, 'o'), ('ForwardBE1', 70, 'o'),
         ('ForwardAE0', 90, 'o'), ('ForwardBE0', 90, 'o'), ('ALUResultM0', 90, 'y'), ('ALUResultM1', 90, 'y'),
         ('Issue1', 90, 'r')], etapas=('D', 'E', 'M'))
recorte('wave_p3a', 'r_p3a.png', 40, 100,
        ['PCF', 'Issue0', 'Issue1', 'StallF', 'FlushE0', 'FlushE1', 'MemWriteM', 'DataAdrM', 'ReadDataM'],
        [('Issue1', 40, 'r'), ('Issue1', 50, 'r'), ('Issue1', 60, 'r'), ('MemWriteM', 60, 'o'), ('DataAdrM', 60, 'o'),
         ('Issue0', 70, 'r'), ('StallF', 70, 'r'), ('FlushE0', 70, 'r'), ('FlushE1', 70, 'r'), ('PCF', 70, 'y'),
         ('Issue0', 80, 'p'), ('Issue1', 80, 'p'), ('ReadDataM', 80, 'y')], etapas=('D', 'E', 'M'))
recorte('wave_p3b', 'r_p3b.png', 90, 150,
        ['Issue0', 'Issue1', 'MemSelM', 'MemWriteM', 'DataAdrM', 'WriteDataM', 'ReadDataM'],
        [('Issue1', 90, 'r'), ('MemSelM', 100, 'o'), ('DataAdrM', 100, 'o'), ('ReadDataM', 100, 'y'), ('Issue1', 100, 'p'),
         ('MemSelM', 120, 'o'), ('MemWriteM', 120, 'o'), ('DataAdrM', 120, 'o'), ('WriteDataM', 120, 'y'),
         ('MemSelM', 130, 'o'), ('DataAdrM', 130, 'o'), ('ReadDataM', 130, 'y'),
         ('MemWriteM', 140, 'o'), ('DataAdrM', 140, 'o'), ('WriteDataM', 140, 'y')], etapas=('D', 'E', 'M'))
recorte('wave_p4a', 'r_p4a.png', 50, 130,
        ['PCF', 'Issue0', 'Issue1', 'StallF', 'BranchSelE', 'PCSrcE', 'PCTargetE', 'FlushD', 'FlushE0', 'FlushE1', 'FlushM1'],
        [('BranchSelE', 50, 'p'), ('PCSrcE', 50, 'r'), ('PCTargetE', 50, 'y'), ('FlushD', 50, 'r'), ('FlushE0', 50, 'r'),
         ('FlushE1', 50, 'r'), ('FlushM1', 50, 'r'), ('PCF', 60, 'y'),
         ('BranchSelE', 80, 'p'), ('PCSrcE', 80, 'o'),
         ('BranchSelE', 90, 'p'), ('PCSrcE', 90, 'r'), ('PCTargetE', 90, 'y'), ('FlushM1', 90, 'o'), ('Issue0', 90, 'r'),
         ('StallF', 90, 'o'), ('FlushD', 90, 'r'), ('PCF', 100, 'y'),
         ('Issue1', 110, 'r'), ('PCSrcE', 120, 'o')], etapas=('D', 'E', 'M'))
recorte('wave_p4b', 'r_p4b.png', 130, 190,
        ['BranchSelE', 'PCSrcE', 'PCTargetE', 'FlushM1', 'RdW0', 'ResultW0', 'RdW1', 'ResultW1'],
        [('BranchSelE', 130, 'p'), ('PCSrcE', 130, 'r'), ('PCTargetE', 130, 'y'), ('FlushM1', 130, 'r'),
         ('RdW0', 150, 'y'), ('ResultW0', 150, 'y'),
         ('BranchSelE', 160, 'p'), ('PCSrcE', 160, 'r'), ('PCTargetE', 160, 'y'), ('FlushM1', 160, 'o'),
         ('RdW0', 180, 'y'), ('ResultW0', 180, 'y'), ('RdW1', 180, 'y'), ('ResultW1', 180, 'y')], etapas=('D', 'E', 'M', 'W'))
recorte('wave_p5', 'r_p5.png', 60, 140,
        ['RdW0', 'ResultW0', 'RdW1', 'ResultW1', 'x1', 'x2', 'x3', 'x4', 'x6', 'x7', 'x10'],
        [('RdW0', 60, 'o'), ('RdW1', 60, 'o'), ('x1', 70, 'y'), ('x2', 70, 'y'),
         ('RdW0', 70, 'o'), ('ResultW0', 70, 'o'), ('RdW1', 70, 'o'), ('ResultW1', 70, 'o'), ('x3', 80, 'y'),
         ('RdW0', 80, 'r'), ('x4', 90, 'y'), ('ResultW0', 100, 'o'), ('ResultW1', 100, 'o'),
         ('x6', 110, 'y'), ('x7', 110, 'y'), ('x10', 130, 'y')], etapas=('E', 'W'))
recorte('wave_p6', 'r_p6.png', 40, 130,
        ['PCF', 'Issue1', 'RdW0', 'ResultW0', 'RdW1', 'ResultW1'],
        [('Issue1', 40, 'r'), ('PCF', 50, 'y'), ('Issue1', 50, 'p'), ('Issue1', 70, 'r'), ('Issue1', 80, 'r'),
         ('Issue1', 90, 'r'), ('Issue1', 100, 'r')], etapas=('F', 'D', 'E', 'W'))

# ---------- Optimizacion ----------
recorte('wave_o1a', 'r_o1a.png', 60, 130,
        ['PCF', 'PredF0', 'PredTargetF0', 'PCNextF', 'PredD0', 'PredE', 'TakenE', 'MispredE', 'FlushD'],
        [('TakenE', 70, 'p'), ('MispredE', 70, 'r'), ('FlushD', 70, 'r'), ('PCNextF', 70, 'y'),
         ('PredF0', 100, 'p'), ('PredTargetF0', 100, 'y'), ('PCNextF', 100, 'y'), ('PredD0', 110, 'p'),
         ('PredE', 120, 'p'), ('TakenE', 120, 'p'), ('MispredE', 120, 'o'), ('FlushD', 120, 'o')])
recorte('wave_o1b', 'r_o1b.png', 330, 390,
        ['PCF', 'PredF0', 'PCNextF', 'PredE', 'TakenE', 'MispredE', 'PCCorrectE', 'CntE', 'FlushD'],
        [('PredF0', 340, 'p'), ('PCNextF', 340, 'y'), ('PredE', 360, 'p'), ('TakenE', 360, 'p'), ('MispredE', 360, 'r'),
         ('PCCorrectE', 360, 'y'), ('CntE', 360, 'o'), ('FlushD', 360, 'r'), ('PCF', 370, 'y')])
recorte('wave_o2', 'r_o2.png', 240, 290,
        ['PCF', 'PredF1', 'PredTargetF1', 'Issue1', 'PCNextF', 'PredD1', 'BranchSelE', 'PredE', 'TakenE', 'MispredE'],
        [('PredF1', 250, 'p'), ('Issue1', 250, 'p'), ('PredTargetF1', 250, 'y'), ('PCNextF', 250, 'y'), ('PredD1', 260, 'p'),
         ('BranchSelE', 270, 'p'), ('PredE', 270, 'p'), ('TakenE', 270, 'p'), ('MispredE', 270, 'o')])

# ---------- Programa del profesor (version C) ----------
CHK = ['chk', 'etapa', 'ok', 'pasadas']
def cierre(w, sal, t0, t1, tc, vals, cajas_extra):
    recorte(w, sal, t0, t1, CHK + vals,
            [('chk', tc, 'p'), ('etapa', tc, 'p'), ('ok', tc, 'p'), ('pasadas', tc, 'p')] + cajas_extra, etapas=('M', 'W'))
cierre('wave_prof_A', 'r_prof_A.png', 110, 150, 130, ['x5', 'x6', 'x9', 'x10', 'M[x1+0]', 'M[x1+4]', 'M[x1+8]'],
       [('x9', 130, 'y'), ('x10', 130, 'y'), ('M[x1+0]', 130, 'y'), ('M[x1+4]', 130, 'y'), ('M[x1+8]', 130, 'o')])
cierre('wave_prof_B', 'r_prof_B.png', 240, 280, 260, ['x12', 'x15', 'x16', 'x17', 'x18', 'M[x1+12]', 'M[x1+16]', 'M[x1+20]'],
       [('x18', 260, 'y'), ('M[x1+12]', 260, 'y'), ('M[x1+16]', 260, 'y'), ('M[x1+20]', 260, 'o')])
cierre('wave_prof_C', 'r_prof_C.png', 2190, 2230, 2210, ['x21', 'x22', 'x24', 'M[x1+24]', 'M[x1+28]', 'M[x1+32]'],
       [('x21', 2210, 'y'), ('x22', 2210, 'y'), ('x24', 2210, 'y'), ('M[x1+24]', 2210, 'y'), ('M[x1+28]', 2210, 'y'), ('M[x1+32]', 2210, 'o')])
cierre('wave_prof_D', 'r_prof_D.png', 2910, 2950, 2930, ['x28', 'x29', 'x31', 'M[x1+36]', 'M[x1+40]', 'M[x1+44]', 'M[x1+48]', 'M[x1+52]'],
       [('x28', 2930, 'y'), ('x29', 2930, 'y'), ('M[x1+36]', 2930, 'y'), ('M[x1+40]', 2930, 'y'), ('M[x1+44]', 2930, 'r'),
        ('M[x1+48]', 2930, 'y'), ('M[x1+52]', 2930, 'o')])
recorte('wave_prof_k1', 'r_prof_k1.png', 50, 100,
        ['Issue1', 'ForwardAE0', 'ForwardBE0', 'ForwardAE1', 'ForwardBE1', 'ALUResultE0', 'ALUResultE1', 'RdM0', 'ALUResultM0', 'RdM1', 'ALUResultM1'],
        [('ForwardAE0', 60, 'o'), ('ForwardBE0', 60, 'o'), ('ForwardAE1', 60, 'o'), ('ForwardBE1', 60, 'o'),
         ('ALUResultE0', 60, 'y'), ('ALUResultE1', 60, 'y'), ('Issue1', 70, 'p'),
         ('Issue1', 90, 'r'), ('ForwardAE0', 90, 'o'), ('ALUResultE0', 90, 'y'),
         ('RdM0', 90, 'p'), ('ALUResultM0', 90, 'p'), ('RdM1', 90, 'p'), ('ALUResultM1', 90, 'o')], etapas=('D', 'E', 'M'))
recorte('wave_prof_k2', 'r_prof_k2.png', 160, 230,
        ['Issue0', 'Issue1', 'StallF', 'MemWriteM', 'DataAdrM', 'WriteDataM', 'ReadDataM'],
        [('Issue1', 170, 'r'), ('Issue1', 180, 'r'), ('Issue1', 190, 'r'), ('Issue1', 200, 'r'),
         ('MemWriteM', 190, 'o'), ('DataAdrM', 190, 'o'), ('WriteDataM', 190, 'o'),
         ('DataAdrM', 200, 'y'), ('ReadDataM', 200, 'y'),
         ('Issue0', 210, 'r'), ('StallF', 210, 'r'), ('MemWriteM', 210, 'o'), ('DataAdrM', 210, 'o'), ('WriteDataM', 210, 'o'),
         ('DataAdrM', 220, 'y'), ('ReadDataM', 220, 'y')], etapas=('D', 'E', 'M'))
