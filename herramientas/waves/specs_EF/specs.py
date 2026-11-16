import json
E='/home/juanpedrovv/Desktop/Proyecto Arch/entrega_EF/'
OUT=E+'informe/figuras/'
def spec(name, tb, t0, t1, rows, markers, run='600ns'):
    dp=f'/{tb}/dut/rvdual/dp/'
    sigs=[]
    for r in rows:
        if r.startswith('--'): sigs.append({'divider': r[2:]}); continue
        n,_,rad=r.partition(':')
        if n=='clk': sigs.append({'path': f'/{tb}/clk'}); continue
        d={'path': dp+n}
        if rad: d['radix']=rad
        if '/' in n: d['name']=n.split('/')[-1]
        sigs.append(d)
    s={'sources':[E+'dual_issue_opt/src/*.v', E+f'dual_issue_opt/tb/{tb}.v'], 'memdir': E+'programas', 'top': tb, 'run':run,'run_extra':'30ns',
       't0_ns':t0,'t1_ns':t1,'width':2000,'scale':150,'show_range':False,'cursor_ns':t0,'signals':sigs,
       'markers':[{'t_ns':(t//10)*10+1.2,'label':str(l)} for l,t in markers], 'out': OUT+name+'.png'}
    json.dump(s, open(name+'.json','w'), indent=1)
I='hex'; U='unsigned'; B='bin'
fet=['--Fetch','PCF:'+U,'InstrF0:'+I,'InstrF1:'+I,'PredF0','PredF1','PredTargetF0:'+U,'PredTargetF1:'+U,'PCNextF:'+U]
dec=['--Decode','InstrD0:'+I,'InstrD1:'+I,'PredD0','PredD1','Issue0','Issue1']
exe=['--Execute','InstrE0:'+I,'InstrE1:'+I,'BranchSelE','PredE','TakenE','MispredE','PCCorrectE:'+U,'bp/CntE:'+B]
fl=['FlushD','FlushE0','FlushE1','FlushM1']
mw=['--Memory y Writeback','InstrM0:'+I,'InstrM1:'+I,'InstrW0:'+I,'InstrW1:'+I]
rows=['clk']+fet+dec+exe+fl+mw
spec('wave_o1a','tb_ef_p1',50,140,rows,[(1,70),(2,100),(3,110),(4,120)])
spec('wave_o1b','tb_ef_p1',320,390,rows,[(1,340),(2,360),(3,370)])
spec('wave_o2','tb_ef_p2',230,300,rows,[(1,250),(2,260),(3,270)])
