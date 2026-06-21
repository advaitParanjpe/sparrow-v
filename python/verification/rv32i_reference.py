"""Independent architectural model for the implemented RV32I subset."""
from dataclasses import dataclass, field
MASK = 0xffffffff
def sx(x, n): return ((x & ((1 << n) - 1)) ^ (1 << (n - 1))) - (1 << (n - 1))
@dataclass
class RV32IReference:
    pc: int = 0
    regs: list[int] = field(default_factory=lambda: [0] * 32)
    mem: bytearray = field(default_factory=lambda: bytearray(4096))
    cycles: int = 0
    instret: int = 0
    trap: tuple[int, int] | None = None
    def read(self, index): return 0 if index == 0 else self.regs[index] & MASK
    def write(self, index, value):
        if index: self.regs[index] = value & MASK
    def step(self, ins):
        if self.pc & 3: self.trap = (self.pc, 0); return
        op, rd, f3 = ins & 0x7f, (ins >> 7) & 31, (ins >> 12) & 7
        a, b, next_pc = self.read((ins >> 15) & 31), self.read((ins >> 20) & 31), (self.pc + 4) & MASK
        ii = sx(ins >> 20, 12); iu = ins & 0xfffff000
        ib = sx(((ins >> 31) << 12) | (((ins >> 7) & 1) << 11) | (((ins >> 25) & 63) << 5) | (((ins >> 8) & 15) << 1), 13)
        ij = sx(((ins >> 31) << 20) | (((ins >> 12) & 255) << 12) | (((ins >> 20) & 1) << 11) | (((ins >> 21) & 1023) << 1), 21)
        trap = None
        if op == 0x37: self.write(rd, iu)
        elif op == 0x17: self.write(rd, self.pc + iu)
        elif op == 0x6f: self.write(rd, next_pc); next_pc = (self.pc + ij) & MASK
        elif op == 0x67:
            if f3: trap = 2
            else: self.write(rd, next_pc); next_pc = (a + ii) & ~1
        elif op == 0x13:
            vals = {0: a + ii, 2: int(sx(a,32) < ii), 3: int(a < (ii & MASK)), 4: a ^ ii, 6: a | ii, 7: a & ii}
            if f3 in vals: self.write(rd, vals[f3])
            elif f3 == 1 and ins >> 25 == 0: self.write(rd, a << ((ins >> 20) & 31))
            elif f3 == 5: self.write(rd, sx(a,32) >> ((ins >> 20) & 31) if ins >> 30 & 1 else a >> ((ins >> 20) & 31))
            else: trap = 2
        elif op == 0x73: trap = 11 if ins == 0x73 else 3 if ins == 0x100073 else 2
        elif op == 0x0f: trap = None if f3 == 0 else 2
        else: trap = 2
        if next_pc & 3: trap = 0
        if trap is None: self.pc = next_pc; self.instret += 1
        else: self.trap = (self.pc, trap)
        self.regs[0] = 0; self.cycles += 1
