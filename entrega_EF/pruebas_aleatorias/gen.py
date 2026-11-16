#!/usr/bin/env python3
"""Random RV32I-subset program generator focused on branches/loops + reference ISS.
Supported: lw sw add sub and or slt addi andi ori slti beq jal.
"""
import random, os
SAFEJAL = os.environ.get('SAFEJAL') == '1'
FILL = os.environ.get('FILL') == '1'

POOL = ['x1', 'x5', 'x6', 'x7', 'x8', 'x9', 'x10', 'x11']   # data registers (init in prologue)
CNT = ['x20', 'x21', 'x22']     # loop counters by depth
LIM = ['x24', 'x25', 'x26']     # loop limits by depth
TMP = ['x28', 'x29', 'x30']     # loop temps by depth
ONE = 'x3'                      # constant 1
BASE = 'x4'                     # constant small aligned base
INIT_ADDRS = [0, 8, 20, 40, 100]   # words initialised in prologue (lw only reads these)
RTYPE = ['add', 'sub', 'and', 'or', 'slt']
ITYPE = ['addi', 'andi', 'ori', 'slti']


class Gen:
    def __init__(self, seed):
        self.r = random.Random(seed)
        self.lab = 0
        self.lines = []
        self.n = 0          # static instruction count
        self.base = 0

    def L(self):
        self.lab += 1
        return 'L%d' % self.lab

    def emit(self, s):
        self.lines.append('        ' + s)
        self.n += 1

    def label(self, l):
        self.lines.append(l + ':')

    def src(self, rd):
        r = self.r
        c = r.random()
        if c < 0.08:
            return 'x0'
        if c < 0.25 and rd:
            return r.choice(rd)
        return r.choice(POOL)

    def dst(self):
        return 'x0' if self.r.random() < 0.06 else self.r.choice(POOL)

    def imm(self):
        r = self.r
        return r.choice([r.randint(-8, 8), r.randint(-2048, 2047), r.randint(0, 3)])

    def alu(self, readable, d=None, s1=None):
        r = self.r
        d = d or self.dst()
        s1 = s1 or self.src(readable)
        if r.random() < 0.5:
            self.emit('%s %s, %s, %s' % (r.choice(RTYPE), d, s1, self.src(readable)))
        else:
            self.emit('%s %s, %s, %d' % (r.choice(ITYPE), d, s1, self.imm()))
        return d

    def addr(self, readonly):
        r = self.r
        a = r.choice(INIT_ADDRS) if readonly else r.choice(INIT_ADDRS + [4 * r.randint(0, 63)])
        if r.random() < 0.4 and a >= self.base and a - self.base <= 2047:
            return '%d(%s)' % (a - self.base, BASE)
        return '%d(x0)' % a

    def lw(self, d=None):
        d = d or self.dst()
        self.emit('lw %s, %s' % (d, self.addr(True)))
        return d

    def sw(self, readable):
        # writes to the initialised set keep values defined; to elsewhere is fine too
        self.emit('sw %s, %s' % (self.src(readable), self.addr(False)))

    def cond(self, readable, d=None):
        """two operands for a beq; mix of always/never/data dependent."""
        r = self.r
        c = r.random()
        if c < 0.1:
            return 'x0', 'x0'
        a = d or self.src(readable)
        if c < 0.2:
            return a, a
        return a, (self.src(readable) if r.random() < 0.7 else 'x0')

    # ---------------- blocks ----------------
    def block(self, budget, depth, readable, exitlab=None):
        r = self.r
        start = self.n
        while self.n - start < budget:
            left = budget - (self.n - start)
            k = r.random()
            if k < 0.22:
                self.alu(readable)
            elif k < 0.28:          # RAW chain
                d = self.alu(readable)
                for _ in range(r.randint(1, 3)):
                    if d == 'x0':
                        break
                    d = self.alu(readable, s1=d)
            elif k < 0.31:          # WAW pair
                d = r.choice(POOL)
                self.alu(readable, d=d)
                self.alu(readable, d=d)
            elif k < 0.38:
                self.lw()
            elif k < 0.44:
                self.sw(readable)
            elif k < 0.50:          # load feeding a branch
                d = self.lw(d=r.choice(POOL))
                a, b = self.cond(readable, d)
                if r.random() < 0.5:
                    a, b = b, a
                l = self.L()
                self.emit('beq %s, %s, %s' % (a, b, l))
                self.block(r.randint(0, 3), depth, readable)
                self.label(l)
            elif k < 0.58:          # forward skip
                l = self.L()
                a, b = self.cond(readable)
                self.emit('beq %s, %s, %s' % (a, b, l))
                self.block(r.randint(0, 4), depth, readable)
                self.label(l)
            elif k < 0.62:          # back-to-back branches
                l1, l2 = self.L(), self.L()
                a, b = self.cond(readable)
                self.emit('beq %s, %s, %s' % (a, b, l1))
                a, b = self.cond(readable)
                self.emit('beq %s, %s, %s' % (a, b, l2))
                self.block(r.randint(0, 2), depth, readable)
                self.label(l1)
                self.block(r.randint(0, 2), depth, readable)
                self.label(l2)
            elif k < 0.66:          # branch whose target is a branch
                l1, l2 = self.L(), self.L()
                a, b = self.cond(readable)
                self.emit('beq %s, %s, %s' % (a, b, l1))
                self.block(r.randint(0, 2), depth, readable)
                self.label(l1)
                a, b = self.cond(readable)
                self.emit('beq %s, %s, %s' % (a, b, l2))
                self.block(r.randint(0, 2), depth, readable)
                self.label(l2)
            elif k < 0.71:          # forward jal (link register used later as data)
                l = self.L()
                rd = r.choice(['x0', 'x1', 'x1', r.choice(POOL)])
                self.emit('jal %s, %s' % (rd, l))
                self.block(r.randint(0, 2), depth, readable)   # dead code
                self.label(l)
                if SAFEJAL and rd != 'x0':
                    # avoid known C bug: jal link value forwarded from Memory stage
                    ok = [p for p in POOL if p != rd]
                    for _ in range(3):
                        self.emit('addi %s, %s, %d' % (r.choice(ok), r.choice(ok), self.imm()))
            elif k < 0.74 and exitlab:   # early exit from enclosing loop
                a, b = self.cond(readable)
                self.emit('beq %s, %s, %s' % (a, b, exitlab))
            elif k < 0.95 and depth < 3 and left >= 4:
                self.loop(depth, readable, min(left, 14))
            else:
                self.alu(readable)

    def loop(self, depth, readable, room):
        r = self.r
        c, lim, t = CNT[depth], LIM[depth], TMP[depth]
        n = r.randint(1, [8, 5, 3][depth])
        rd = readable + [c]
        top, ex = self.L(), self.L()
        body = r.choice([0, 1, 1, 2, 3, r.randint(2, max(2, room - 4))])
        kind = r.randint(0, 3)
        fill = lambda: [self.alu(readable) for _ in range(r.choice([0, 0, 1, 2]) if FILL else 0)]
        if kind == 0:       # top-test, count down, jal back-edge
            self.emit('addi %s, x0, %d' % (c, n))
            self.label(top)
            self.emit('beq %s, x0, %s' % (c, ex))
            self.block(body, depth + 1, rd, ex)
            self.emit('addi %s, %s, -1' % (c, c))
            self.emit('jal x0, %s' % top)
            self.label(ex)
        elif kind == 1:     # bottom-test, count up, beq to exit + jal back-edge
            self.emit('addi %s, x0, 0' % c)
            self.emit('addi %s, x0, %d' % (lim, n))
            self.label(top)
            self.block(body, depth + 1, rd + [lim], ex)
            self.emit('addi %s, %s, 1' % (c, c))
            fill()
            self.emit('beq %s, %s, %s' % (c, lim, ex))
            self.emit('jal x0, %s' % top)
            self.label(ex)
        elif kind == 2:     # bottom-test backward beq taken while c < n  (slti + beq x3)
            self.emit('addi %s, x0, 0' % c)
            self.label(top)
            self.block(body, depth + 1, rd, ex)
            self.emit('addi %s, %s, 1' % (c, c))
            self.emit('slti %s, %s, %d' % (t, c, n))
            fill()
            self.emit('beq %s, %s, %s' % (t, ONE, top))
            self.label(ex)
        else:               # count down to zero, backward beq on (c<1)==0
            self.emit('addi %s, x0, %d' % (c, n))
            self.label(top)
            self.block(body, depth + 1, rd, ex)
            self.emit('addi %s, %s, -1' % (c, c))
            self.emit('slti %s, %s, 1' % (t, c))
            fill()
            self.emit('beq %s, x0, %s' % (t, top))
            self.label(ex)

    def program(self, budget):
        r = self.r
        self.base = 4 * r.randint(0, 8)
        pro = [('addi %s, x0, %d' % (p, self.imm())) for p in POOL]
        pro += ['addi %s, x0, 1' % ONE, 'addi %s, x0, %d' % (BASE, self.base)]
        r.shuffle(pro)
        for p in pro:
            self.emit(p)
        for a in INIT_ADDRS:
            self.emit('sw %s, %d(x0)' % (r.choice(POOL), a))
        # optional padding to shift alignment (lanes / BTB aliasing)
        for _ in range(r.randint(0, 3)):
            self.alu([])
        self.block(budget, 0, [])
        self.label('fin')
        self.emit('beq x0, x0, fin')
        return '\n'.join(self.lines) + '\n'


# ---------------- reference ISS on machine code ----------------
def sx(v, b):
    v &= (1 << b) - 1
    return v - (1 << b) if v >> (b - 1) else v


def iss(words, maxinstr=4000):
    M = 0xffffffff
    R = [None] * 32
    R[0] = 0
    mem = [None] * 64
    pc = 0
    cnt = 0
    while True:
        if cnt > maxinstr:
            return None
        ins = words[pc >> 2] if (pc >> 2) < len(words) else 0x13
        cnt += 1
        if ins == 0x63:
            return cnt, R, mem
        op = ins & 0x7f
        rd = (ins >> 7) & 31
        f3 = (ins >> 12) & 7
        rs1 = (ins >> 15) & 31
        rs2 = (ins >> 20) & 31
        f7 = ins >> 25
        npc = pc + 4

        def rr(i):
            if R[i] is None:
                raise ValueError('read of uninitialised x%d at pc %d' % (i, pc))
            return R[i]

        def wr(i, v):
            if i:
                R[i] = v & M
        if op == 0x33:
            a, b = rr(rs1), rr(rs2)
            if f3 == 0:
                v = a - b if f7 & 0x20 else a + b
            elif f3 == 7:
                v = a & b
            elif f3 == 6:
                v = a | b
            elif f3 == 2:
                v = int(sx(a, 32) < sx(b, 32))
            else:
                raise ValueError('bad')
            wr(rd, v)
        elif op == 0x13:
            a, imm = rr(rs1), sx(ins >> 20, 12)
            if f3 == 0:
                v = a + imm
            elif f3 == 7:
                v = a & (imm & M)
            elif f3 == 6:
                v = a | (imm & M)
            elif f3 == 2:
                v = int(sx(a, 32) < imm)
            else:
                raise ValueError('bad')
            wr(rd, v)
        elif op == 0x03:
            a = (rr(rs1) + sx(ins >> 20, 12)) & M
            assert a % 4 == 0 and a < 256, a
            if mem[a >> 2] is None:
                raise ValueError('read of uninitialised mem %d' % a)
            wr(rd, mem[a >> 2])
        elif op == 0x23:
            imm = sx(((ins >> 25) << 5) | ((ins >> 7) & 31), 12)
            a = (rr(rs1) + imm) & M
            assert a % 4 == 0 and a < 256, a
            mem[a >> 2] = rr(rs2)
        elif op == 0x63:
            imm = sx((((ins >> 31) & 1) << 12) | (((ins >> 7) & 1) << 11) |
                     (((ins >> 25) & 0x3f) << 5) | (((ins >> 8) & 0xf) << 1), 13)
            if rr(rs1) == rr(rs2):
                npc = pc + imm
        elif op == 0x6f:
            imm = sx((((ins >> 31) & 1) << 20) | (((ins >> 12) & 0xff) << 12) |
                     (((ins >> 20) & 1) << 11) | (((ins >> 21) & 0x3ff) << 1), 21)
            wr(rd, pc + 4)
            npc = pc + imm
        else:
            raise ValueError('bad op %x' % op)
        pc = npc
