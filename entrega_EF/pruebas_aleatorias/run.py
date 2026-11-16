#!/usr/bin/env python3
"""Usage: run.py START COUNT   (random seeds)   |   run.py --mem file.mem ...
Runs each program on A, B, C (+ reference ISS) and compares."""
import os, sys, subprocess, shutil, json, multiprocessing as mp
from gen import Gen, iss

D = os.path.dirname(os.path.abspath(__file__))
B = os.path.join(D, 'build')


def assemble(src, wd):
    s = os.path.join(wd, 'p.s')
    open(s, 'w').write(src)
    cmds = [['riscv64-unknown-elf-as', '-march=rv32i', '-mabi=ilp32', '-mno-relax', 'p.s', '-o', 'p.o'],
            ['riscv64-unknown-elf-ld', '-m', 'elf32lriscv', '-Ttext=0', '--no-relax', '-e', '0', 'p.o', '-o', 'p.elf'],
            ['riscv64-unknown-elf-objcopy', '-O', 'binary', '-j', '.text', 'p.elf', 'p.bin']]
    for c in cmds:
        subprocess.run(c, cwd=wd, check=True, capture_output=True)
    out = subprocess.run(['od', '-An', '-tx4', '-w4', '-v', 'p.bin'], cwd=wd, check=True,
                         capture_output=True, text=True).stdout
    return [w.strip() for w in out.split() if w.strip()]


def sim(x, wd):
    out = subprocess.run(['vvp', '-n', os.path.join(B, x + '.vvp')], cwd=wd,
                         capture_output=True, text=True, timeout=120).stdout
    res = {'R': {}, 'M': {}, 'cov': None}
    for ln in out.splitlines():
        t = ln.split()
        if not t:
            continue
        if t[0] == 'HANG':
            res['hang'] = True
            res['n'] = int(t[1])
        elif t[0] == 'END':
            res['n'], res['cyc'] = int(t[1]), int(t[2])
        elif t[0] == 'R':
            res['R'][int(t[1])] = t[2]
        elif t[0] == 'M':
            res['M'][int(t[1])] = t[2]
        elif t[0] == 'COV':
            res['cov'] = [int(v) for v in t[1:]]
    return res


def check(name, words, wd, src=None):
    """returns dict with status."""
    open(os.path.join(wd, 'prog.mem'), 'w').write('\n'.join(words) + '\n')
    ref = None
    try:
        ref = iss([int(w, 16) for w in words])
    except Exception as e:
        ref = ('err', str(e))
    rs = {x: sim(x, wd) for x in 'abc'}
    diffs = []
    for x in 'abc':
        if rs[x].get('hang'):
            diffs.append('%s HANG' % x)
    if not diffs:
        if not (rs['a']['n'] == rs['b']['n'] == rs['c']['n']):
            diffs.append('count A=%d B=%d C=%d' % (rs['a']['n'], rs['b']['n'], rs['c']['n']))
        for k in ('R', 'M'):
            for i in rs['a'][k]:
                va, vb, vc = rs['a'][k][i], rs['b'][k][i], rs['c'][k][i]
                if not (va == vb == vc):
                    diffs.append('%s%d A=%s B=%s C=%s' % ('x' if k == 'R' else 'mem', i, va, vb, vc))
        if isinstance(ref, tuple) and ref[0] != 'err':
            n, R, mem = ref
            if n != rs['a']['n']:
                diffs.append('count ISS=%d A=%d' % (n, rs['a']['n']))
            for i in range(1, 32):
                if R[i] is not None and '%08x' % R[i] != rs['a']['R'][i]:
                    diffs.append('ISS x%d=%08x A=%s' % (i, R[i], rs['a']['R'][i]))
            for i in range(64):
                if mem[i] is not None and '%08x' % mem[i] != rs['a']['M'][i]:
                    diffs.append('ISS mem%d=%08x A=%s' % (i, mem[i], rs['a']['M'][i]))
    out = {'name': name, 'diffs': diffs, 'n': rs['a'].get('n'),
           'cyc': {x: rs[x].get('cyc') for x in 'abc'}, 'cov': rs['c']['cov'],
           'iss': 'err:' + ref[1] if ref and ref[0] == 'err' else 'ok'}
    if diffs:
        fd = os.path.join(D, 'fails', name)
        os.makedirs(fd, exist_ok=True)
        if src:
            open(os.path.join(fd, 'p.s'), 'w').write(src)
        open(os.path.join(fd, 'prog.mem'), 'w').write('\n'.join(words) + '\n')
        open(os.path.join(fd, 'diffs.txt'), 'w').write('\n'.join(diffs) + '\n')
    return out


def wdir():
    wd = os.path.join(D, 'work', 'w%d' % os.getpid())
    os.makedirs(wd, exist_ok=True)
    return wd


def do_seed(seed):
    wd = wdir()
    for attempt in range(50):
        g = Gen(seed * 100 + attempt)
        src = g.program(g.r.randint(15, 45))
        try:
            words = assemble(src, wd)
        except subprocess.CalledProcessError as e:
            return {'name': 's%d' % seed, 'diffs': ['ASM ERROR ' + e.stderr.decode()[:300]], 'n': None}
        if len(words) > 64:
            continue
        try:
            ref = iss([int(w, 16) for w in words], 1300)
        except Exception as e:
            return {'name': 's%d' % seed, 'diffs': ['GEN invalid: ' + str(e)], 'n': None}
        if ref is None:
            continue
        return check('s%d' % seed, words, wd, src)
    return {'name': 's%d' % seed, 'skip': True, 'diffs': [], 'n': None}


def do_mem(path):
    wd = wdir()
    words = [l.strip() for l in open(path) if l.strip()]
    s = path[:-4] + '.s'
    return check(os.path.basename(path), words, wd, open(s).read() if os.path.exists(s) else None)


if __name__ == '__main__':
    pool = mp.Pool(12)
    if sys.argv[1] == '--mem':
        jobs, fn, log = sys.argv[2:], do_mem, 'logs/existing.jsonl'
    else:
        a, n = int(sys.argv[1]), int(sys.argv[2])
        jobs, fn, log = range(a, a + n), do_seed, 'logs/random_%d_%d.jsonl' % (a, n)
    nf = 0
    with open(os.path.join(D, log), 'w') as f:
        for i, r in enumerate(pool.imap_unordered(fn, jobs, chunksize=4)):
            f.write(json.dumps(r) + '\n')
            if r['diffs']:
                nf += 1
                print('FAIL', r['name'], r['diffs'][:6], flush=True)
            if i % 500 == 0:
                print('progress', i, 'fails', nf, flush=True)
    print('done', len(jobs), 'fails', nf)
