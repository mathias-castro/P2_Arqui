import json
E='/home/juanpedrovv/Desktop/Proyecto Arch/entrega_E2/'
OUT=E+'informe/figuras/'
def spec(name, tb, t0, t1, rows, markers, extra=None):
    dp=f'/{tb}/dut/rvdual/dp/'
    sigs=[]
    for r in rows:
        if r.startswith('--'): sigs.append({'divider': r[2:]}); continue
        n,_,rad=r.partition(':')
        if n=='clk': sigs.append({'path': f'/{tb}/clk'}); continue
        path = dp+n if not n.startswith('x') else dp+f'rf/rf[{n[1:]}]'
        d={'path': path}
        if rad: d['radix']=rad
        if n.startswith('x'): d['name']=n
        sigs.append(d)
    s={'sources':[E+'dual_issue/src/*.v', E+f'dual_issue/tb/{tb}.v'], 'memdir': E+'programas', 'top': tb, 'run':'400ns','run_extra':'30ns',
       't0_ns':t0,'t1_ns':t1,'width':2000,'scale':150,'show_range':False,'cursor_ns':t0,'signals':sigs,
       'markers':[{'t_ns':(t//10)*10+1.2,'label':str(l)} for l,t in markers], 'out': OUT+name+'.png'}
    if extra: s.update(extra)
    json.dump(s, open(name+'.json','w'), indent=1)
I='hex'; U='unsigned'; D='dec'; B='bin'
fet=['--Fetch','PCF:'+U,'InstrF0:'+I,'InstrF1:'+I]
dec=['--Decode','InstrD0:'+I,'InstrD1:'+I,'Issue0','Issue1']
exe=['--Execute','InstrE0:'+I,'InstrE1:'+I]
insm=['InstrM0:'+I,'InstrM1:'+I]
insw=['InstrW0:'+I,'InstrW1:'+I]
wb=['RegWriteW0','RdW0:'+U,'ResultW0:'+D,'RegWriteW1','RdW1:'+U,'ResultW1:'+D]
mem=['MemWriteM','DataAdrM:'+D,'WriteDataM:'+D]
spec('wave_p1','tb_e2_p1',20,140, ['clk']+fet+dec+exe+['SrcAE0:'+D,'SrcBE0:'+D,'ALUResultE0:'+D,'SrcAE1:'+D,'SrcBE1:'+D,'ALUResultE1:'+D,
      '--Memory']+insm+mem+['--Writeback']+insw+wb, [(1,35),(2,45),(3,65),(4,125)])
spec('wave_p2','tb_e2_p2',20,140, ['clk']+fet+dec+exe+['ForwardAE0:'+B,'ForwardBE0:'+B,'SrcAE0:'+D,'SrcBE0:'+D,'ForwardAE1:'+B,'ForwardBE1:'+B,'SrcAE1:'+D,'SrcBE1:'+D,
      '--Memory']+insm+['ALUResultM0:'+D,'ALUResultM1:'+D]+mem+['--Writeback']+insw+['ResultW0:'+D,'ResultW1:'+D], [(1,35),(2,45),(3,65),(4,75),(5,95),(6,125)])
p3=['clk']+fet+dec+['StallF','FlushE0','FlushE1']+exe+['--Memory']+insm+['MemSelM','MemWriteM','DataAdrM:'+D,'WriteDataM:'+D,'ReadDataM:'+D,'--Writeback']+insw+wb
spec('wave_p3a','tb_e2_p3',20,100,p3,[(1,45),(2,55),(3,65),(4,75),(5,85)])
spec('wave_p3b','tb_e2_p3',80,160,p3,[(6,95),(7,105),(8,125),(9,135),(10,145)])
p4=['clk']+fet+dec+['StallF']+exe+['BranchSelE','PCSrcE','PCTargetE:'+U,'FlushD','FlushE0','FlushE1','FlushM1','--Memory']+insm+mem+['--Writeback']+insw+wb
spec('wave_p4a','tb_e2_p4',20,130,p4,[(1,55),(2,65),(3,85),(4,95),(5,115),(6,125)])
spec('wave_p4b','tb_e2_p4',120,240,p4,[(7,135),(8,155),(9,165),(10,185),(11,215)])
spec('wave_p5','tb_e2_p5',20,140,['clk']+fet+['--Decode','InstrD0:'+I,'InstrD1:'+I]+exe+['--Memory']+insm+['MemWriteM','DataAdrM:'+D,'WriteDataM:'+D,'ReadDataM:'+D,'--Writeback']+insw+wb+['--Register File']+[f'x{i}:'+D for i in (1,2,3,4,5,6,7,8,10)],
     [(1,67),(2,77),(3,87),(4,107),(5,127)])
spec('wave_p6','tb_e2_p6',20,150,['clk']+fet+dec+exe+['--Memory']+insm+mem+['--Writeback']+insw+wb,
     [(1,45),(2,55),(3,75),(4,135)])
