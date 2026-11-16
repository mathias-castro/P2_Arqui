# Specs de las capturas del pipeline Single-Issue y de la evidencia de Dual Fetch / Dual Decode
import json
E='/home/juanpedrovv/Desktop/Proyecto Arch/entrega_E2/'
OUT=E+'informe/figuras/'
I='hex'; U='unsigned'; D='dec'; B='bin'
def spec(name, arch, tb, t0, t1, rows, markers, width=2000, desfase=1.0):
    dp=f'/{tb}/dut/rv/dp/' if arch=='single' else f'/{tb}/dut/rvdual/dp/'
    sigs=[]
    for r in rows:
        if r.startswith('--'): sigs.append({'divider': r[2:]}); continue
        n,_,rad=r.partition(':')
        if n=='clk': sigs.append({'path': f'/{tb}/clk'}); continue
        d={'path': dp+n}
        if n=='lwStall': d['path']=dp+'hu/lwStall'
        if rad: d['radix']=rad
        sigs.append(d)
    folder='single_issue' if arch=='single' else 'dual_issue'
    s={'sources':[E+folder+'/src/*.v', E+folder+f'/tb/{tb}.v'], 'memdir': E+'programas', 'top': tb,
       'run':'400ns','run_extra':'30ns','t0_ns':t0,'t1_ns':t1,'width':width,'scale':150,'show_range':False,'cursor_ns':t0,
       'signals':sigs,'markers':[{'t_ns':t+desfase,'label':str(l)} for l,t in markers],'out':OUT+name+'.png'}
    json.dump(s, open(name+'.json','w'), indent=1)
etapas=['clk','PCF:'+U,'InstrF:'+I,'InstrD:'+I,'InstrE:'+I,'InstrM:'+I,'InstrW:'+I]
wb=['RegWriteW','RdW:'+U,'ResultW:'+D]
mem=['MemWriteM','ALUResultM:'+D,'WriteDataM:'+D]
p1=etapas+['ALUResultE:'+D,'ForwardAE:'+B,'ForwardBE:'+B,'StallF','PCSrcE']+mem+wb
spec('wave_s1a','single','tb_e1_p1',20,150,p1,[(1,40),(2,60),(3,90)])
spec('wave_s1b','single','tb_e1_p1',140,270,p1,[(4,180),(5,200),(6,220),(7,240)])
spec('wave_s2','single','tb_e1_p2',20,150,etapas+['--Execute','Rs1E:'+U,'Rs2E:'+U,'ForwardAE:'+B,'ForwardBE:'+B,'SrcAE:'+D,'SrcBE:'+D,'ALUResultE:'+D,
      '--Memory','RegWriteM','RdM:'+U]+mem+['--Writeback']+wb, [(1,50),(2,60),(3,70),(4,100),(5,110)])
spec('wave_s3','single','tb_e1_p3',20,160,etapas+['--Decode y Execute','Rs1D:'+U,'Rs2D:'+U,'RdE:'+U,'ResultSrcE:'+B,'lwStall','StallF','StallD','FlushE','ForwardAE:'+B,'ForwardBE:'+B,
      '--Memory']+mem+['ReadDataM:'+D,'--Writeback']+wb, [(1,60),(2,70),(3,80),(4,100),(5,120)])
spec('wave_s4','single','tb_e1_p4',20,190,etapas+['--Execute','BranchE','JumpE','ZeroE','PCSrcE','PCTargetE:'+U,'FlushD','FlushE','--Memory']+mem+['--Writeback']+wb,
     [(1,60),(2,70),(3,90),(4,110),(5,130),(6,160)], width=2400)
v0=['InstrD0:'+I,'PCD0:'+U,'Rs1D0:'+U,'Rs2D0:'+U,'RdD0:'+U,'ALUControlD0:'+B,'ALUSrcD0','RegWriteD0']
spec('wave_dfd','dual','tb_e2_p1',20,100,['clk','--Fetch','PCF:'+U,'InstrF0:'+I,'InstrF1:'+I,'--Decode, vía 0']+v0+['--Decode, vía 1']+[x.replace('D0','D1') for x in v0],
     [(1,20),(2,30),(3,50),(4,60)], width=1700, desfase=1.3)
