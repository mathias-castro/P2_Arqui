# Capturas del programa del profesor en la version C (tb_profesor_opt).
import json
E='/home/juanpedrovv/Desktop/Proyecto Arch/entrega_EF/'
OUT=E+'informe/figuras/'
TB='tb_profesor_opt'
def spec(name, t0, t1, rows, markers, width=2000):
    sigs=[]
    for r in rows:
        n, _, rad = r.partition(':')
        if n.startswith('M+'):                       # palabra de memoria M[x1 + desp]
            d = int(n[2:])
            sigs.append({'path': f'/{TB}/dut/dmem/RAM[{(1536 + d) // 4}]', 'radix': 'dec', 'name': f'M[x1+{d}]'})
        elif n.startswith('x'):
            sigs.append({'path': f'/{TB}/dut/rvdual/dp/rf/rf[{n[1:]}]', 'radix': 'dec', 'name': n})
        elif n in ('chk', 'ok', 'etapa', 'pasadas'):
            dd = {'path': f'/{TB}/{n}'}
            if rad: dd['radix'] = rad
            sigs.append(dd)
        else:
            dd = {'path': f'/{TB}/dut/rvdual/dp/{n}'}
            if rad: dd['radix'] = rad
            sigs.append(dd)
    s={'sources':[E+'dual_issue_opt/src/*.v', E+f'dual_issue_opt/tb/{TB}.v'], 'memdir': E+'programas', 'top': TB,
       'run':'3000ns', 't0_ns':t0,'t1_ns':t1,'width':width,'scale':150,'show_range':False,'cursor_ns':t0,'signals':sigs,
       'markers':[{'t_ns':(t//10)*10+1.2,'label':str(l)} for l,t in markers], 'out': OUT+name+'.png'}
    json.dump(s, open(name+'.json','w'), indent=1)

chk = ['chk', 'etapa:ascii', 'ok', 'pasadas:unsigned']
spec('wave_prof_A', 110, 150, chk + ['x5', 'x6', 'x9', 'x10', 'M+0', 'M+4', 'M+8'], [(1, 130)], width=1300)
spec('wave_prof_B', 240, 280, chk + ['x12', 'x15', 'x16', 'x17', 'x18', 'M+12', 'M+16', 'M+20'], [(1, 260)], width=1300)
spec('wave_prof_C', 2190, 2230, chk + ['x21', 'x22', 'x24', 'M+24', 'M+28', 'M+32'], [(1, 2210)], width=1300)
spec('wave_prof_D', 2910, 2950, chk + ['x28', 'x29', 'x31', 'M+36', 'M+40', 'M+44', 'M+48', 'M+52'], [(1, 2930)], width=1300)
U='unsigned'; B='bin'
spec('wave_prof_k1', 50, 100, ['Issue1', 'ForwardAE0:'+B, 'ForwardBE0:'+B, 'ForwardAE1:'+B, 'ForwardBE1:'+B,
     'ALUResultE0:dec', 'ALUResultE1:dec', 'RdM0:'+U, 'ALUResultM0:dec', 'RdM1:'+U, 'ALUResultM1:dec'], [(1, 60), (2, 70), (3, 90)], width=1250)
spec('wave_prof_k2', 160, 230, ['Issue0', 'Issue1', 'StallF', 'MemWriteM', 'DataAdrM:'+U, 'WriteDataM:dec', 'ReadDataM:dec',
     'RdW0:'+U, 'ResultW0:dec'], [(1, 170), (2, 190), (3, 200), (4, 210), (5, 220)], width=1450)
