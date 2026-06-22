#!/usr/bin/env python3
"""Deterministic RV32I/vector program generator for the sparse FC workload."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

INPUTS = [1, -2, 0, 127, -128, 3, -4, 5, -6, 7, 0, -8, 9, -10, 11, -12]
BIASES = [17, -23, 31, -37]
# Every four-weight group has exactly two nonzero values.  Dense and sparse
# programs deliberately use these same mathematical weights.
PATTERNS = [[0, 2], [1, 3], [0, 1], [2, 3]]
COMPRESSED = [
    [[3, -4], [5, 6], [-7, 8], [9, -10]],
    [[-11, 12], [13, -14], [15, 16], [-17, 18]],
    [[19, -20], [-21, 22], [23, -24], [25, 26]],
    [[-27, 28], [29, -30], [-31, 32], [33, -34]],
]
PATTERN_CODE = {(0, 1): 0, (0, 2): 1, (0, 3): 2, (1, 2): 3, (1, 3): 4, (2, 3): 5}
DMEM_OUT = 0x100
DMEM_DONE = 0x1F0
SPAD_INPUT = 0x00
SPAD_DENSE = 0x10
SPAD_SPARSE = 0x50


def check_reg(reg: int) -> None:
    if not 0 <= reg < 32:
        raise ValueError(f"register out of range: {reg}")


def check_imm(value: int, bits: int) -> None:
    if not -(1 << (bits - 1)) <= value < (1 << (bits - 1)):
        raise ValueError(f"signed {bits}-bit immediate out of range: {value}")


def r_type(f7: int, rs2: int, rs1: int, f3: int, rd: int, opcode: int = 0x33) -> int:
    for r in (rs1, rs2, rd): check_reg(r)
    if not 0 <= f7 < 128 or not 0 <= f3 < 8: raise ValueError("invalid R fields")
    return f7 << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | rd << 7 | opcode


def i_type(imm: int, rs1: int, f3: int, rd: int, opcode: int = 0x13) -> int:
    check_imm(imm, 12); check_reg(rs1); check_reg(rd)
    if not 0 <= f3 < 8: raise ValueError("invalid funct3")
    return (imm & 0xfff) << 20 | rs1 << 15 | f3 << 12 | rd << 7 | opcode


def s_type(imm: int, rs2: int, rs1: int, f3: int, opcode: int = 0x23) -> int:
    check_imm(imm, 12); check_reg(rs1); check_reg(rs2)
    return ((imm >> 5) & 0x7f) << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | (imm & 0x1f) << 7 | opcode


def b_type(imm: int, rs2: int, rs1: int, f3: int) -> int:
    if imm & 1: raise ValueError(f"branch immediate must be aligned: {imm}")
    check_imm(imm, 13); check_reg(rs1); check_reg(rs2)
    return ((imm >> 12) & 1) << 31 | ((imm >> 5) & 0x3f) << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | ((imm >> 1) & 0xf) << 8 | ((imm >> 11) & 1) << 7 | 0x63


def addi(rd: int, rs1: int, imm: int) -> int: return i_type(imm, rs1, 0, rd)
def lb(rd: int, rs1: int, imm: int) -> int: return i_type(imm, rs1, 0, rd, 0x03)
def lw(rd: int, rs1: int, imm: int) -> int: return i_type(imm, rs1, 2, rd, 0x03)
def sw(rs2: int, rs1: int, imm: int) -> int: return s_type(imm, rs2, rs1, 2)
def add(rd: int, rs1: int, rs2: int) -> int: return r_type(0, rs2, rs1, 0, rd)
def sub(rd: int, rs1: int, rs2: int) -> int: return r_type(0x20, rs2, rs1, 0, rd)
def xor(rd: int, rs1: int, rs2: int) -> int: return r_type(0, rs2, rs1, 4, rd)
def band(rd: int, rs1: int, rs2: int) -> int: return r_type(0, rs2, rs1, 7, rd)
def slli(rd: int, rs1: int, amount: int) -> int: return i_type(amount, rs1, 1, rd)
def srli(rd: int, rs1: int, amount: int) -> int: return i_type(amount, rs1, 5, rd)
def beq(rs1: int, rs2: int, imm: int) -> int: return b_type(imm, rs2, rs1, 0)
def bne(rs1: int, rs2: int, imm: int) -> int: return b_type(imm, rs2, rs1, 1)
def blt(rs1: int, rs2: int, imm: int) -> int: return b_type(imm, rs2, rs1, 4)
def ecall() -> int: return 0x00000073


def custom(f3: int, rd: int, rs1: int, rs2: int = 0, upper: int = 0) -> int:
    for r in (rd, rs1, rs2): check_reg(r)
    if not 0 <= f3 < 8 or not 0 <= upper < 128: raise ValueError("invalid custom fields")
    return upper << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | rd << 7 | 0x0B


def vload32(vd: int, base: int, imm: int = 0) -> int: return i_type(imm, base, 5, vd, 0x0B)
def vstore32(vs: int, base: int, imm: int = 0) -> int: return s_type(imm, vs, base, 6, 0x0B)
def vdot8(rd: int, va: int, vw: int) -> int: return custom(4, rd, va, vw)
def vsdot8(rd: int, va: int, vw: int, metadata: int) -> int:
    if not 0 <= metadata <= 5: raise ValueError(f"invalid 2:4 metadata: {metadata}")
    return custom(7, rd, va, vw, metadata << 4)


def dense_weights() -> list[list[int]]:
    out = []
    for neuron in COMPRESSED:
        dense = []
        for lanes, weights in zip(PATTERNS, neuron):
            group = [0, 0, 0, 0]
            group[lanes[0]], group[lanes[1]] = weights
            dense.extend(group)
        out.append(dense)
    return out


def golden() -> dict:
    dense = dense_weights()
    scalar = [BIASES[j] + sum(x * w for x, w in zip(INPUTS, dense[j])) for j in range(4)]
    sparse = []
    for j in range(4):
        acc = BIASES[j]
        for group in range(4):
            lanes = PATTERNS[group]
            weights = COMPRESSED[j][group]
            acc += INPUTS[group * 4 + lanes[0]] * weights[0] + INPUTS[group * 4 + lanes[1]] * weights[1]
        sparse.append(acc)
    assert scalar == sparse
    assert all(sum(w != 0 for w in dense[j][g * 4:g * 4 + 4]) == 2 for j in range(4) for g in range(4))
    return {"outputs": scalar, "dense_weight_bytes": 64, "sparse_weight_bytes": 32,
            "metadata_bytes": 6, "sparse_total_bytes": 38, "dense_multiplications": 64,
            "sparse_multiplications": 32, "sparse_skipped": 32}


class Program:
    def __init__(self) -> None: self.words: list[int] = []
    def emit(self, word: int) -> None: self.words.append(word & 0xffffffff)
    def branch(self, kind: str, rs1: int, rs2: int, target: int) -> None:
        offset = (target - len(self.words)) * 4
        self.emit({"beq": beq, "bne": bne, "blt": blt}[kind](rs1, rs2, offset))


def scalar_program() -> list[int]:
    # x1 input base, x2 weight base, x3 output base, x4 done address, x5 accumulator.
    p = Program(); dense = dense_weights()
    p.emit(addi(1, 0, 0)); p.emit(addi(3, 0, DMEM_OUT)); p.emit(addi(4, 0, DMEM_DONE)); p.emit(addi(13, 0, 1))
    for j in range(4):
        p.emit(addi(5, 0, BIASES[j]))
        for k in range(16):
            p.emit(lb(6, 1, k)); p.emit(lb(7, 1, 16 + j * 16 + k))
            # Signed INT8 software multiplication: abs operands, 8-bit shift/add,
            # then restore sign. x8 product, x9 sign, x10 loop count, x11 scratch.
            p.emit(addi(8, 0, 0)); p.emit(addi(9, 0, 0))
            neg_a = len(p.words); p.emit(blt(6, 0, 0)); skip_a = len(p.words); p.emit(beq(0, 0, 0))
            a_fix = len(p.words); p.emit(sub(6, 0, 6)); p.emit(xor(9, 9, 13)); after_a = len(p.words)
            p.words[neg_a] = blt(6, 0, (a_fix - neg_a) * 4); p.words[skip_a] = beq(0, 0, (after_a - skip_a) * 4)
            neg_b = len(p.words); p.emit(blt(7, 0, 0)); skip_b = len(p.words); p.emit(beq(0, 0, 0))
            b_fix = len(p.words); p.emit(sub(7, 0, 7)); p.emit(xor(9, 9, 13)); after_b = len(p.words)
            p.words[neg_b] = blt(7, 0, (b_fix - neg_b) * 4); p.words[skip_b] = beq(0, 0, (after_b - skip_b) * 4); p.emit(addi(10, 0, 8))
            loop = len(p.words); p.emit(band(11, 7, 13)); skip = len(p.words); p.emit(beq(11, 0, 0)); p.emit(add(8, 8, 6)); p.words[skip] = beq(11, 0, (len(p.words) - skip) * 4)
            p.emit(slli(6, 6, 1)); p.emit(srli(7, 7, 1)); p.emit(addi(10, 10, -1)); p.branch("bne", 10, 0, loop)
            no_neg = len(p.words); p.emit(beq(9, 0, 0)); p.emit(sub(8, 0, 8)); p.words[no_neg] = beq(9, 0, (len(p.words) - no_neg) * 4)
            p.emit(add(5, 5, 8))
        p.emit(sw(5, 3, j * 4))
    p.emit(addi(12, 0, 1)); p.emit(sw(12, 4, 0)); p.emit(beq(0, 0, 0))
    return p.words


def vector_program(sparse: bool) -> list[int]:
    p = Program(); p.emit(addi(3, 0, DMEM_OUT)); p.emit(addi(4, 0, DMEM_DONE))
    for j in range(4):
        p.emit(addi(5, 0, BIASES[j]))
        for g in range(4):
            p.emit(addi(1, 0, SPAD_INPUT + g * 4)); p.emit(vload32(1, 1))
            offset = (SPAD_SPARSE + (j * 4 + g) * 4) if sparse else (SPAD_DENSE + (j * 4 + g) * 4)
            p.emit(addi(2, 0, offset)); p.emit(vload32(2, 2))
            p.emit(vsdot8(6, 1, 2, PATTERN_CODE[tuple(PATTERNS[g])]) if sparse else vdot8(6, 1, 2))
            p.emit(add(5, 5, 6))
        p.emit(sw(5, 3, j * 4))
    p.emit(addi(12, 0, 1)); p.emit(sw(12, 4, 0)); p.emit(beq(0, 0, 0))
    return p.words


def pack_word(data: list[int]) -> int:
    return sum((x & 0xff) << (8 * i) for i, x in enumerate(data))


def write_mem(path: Path, words: list[int], size: int = 8192) -> None:
    if len(words) > size: raise ValueError(f"program exceeds image bounds: {len(words)} > {size}")
    path.write_text("\n".join(f"{x:08x}" for x in words) + "\n")


def emit(out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    write_mem(out / "workload_scalar.mem", scalar_program())
    write_mem(out / "workload_dense.mem", vector_program(False))
    write_mem(out / "workload_sparse.mem", vector_program(True))
    dmem = [0] * 512
    raw = INPUTS + [x for row in dense_weights() for x in row]
    for i, value in enumerate(raw): dmem[i // 4] |= (value & 0xff) << (8 * (i % 4))
    write_mem(out / "workload_dmem.mem", dmem, 512)
    spad = [0] * 64
    for g in range(4): spad[(SPAD_INPUT // 4) + g] = pack_word(INPUTS[g * 4:g * 4 + 4])
    for j, row in enumerate(dense_weights()):
        for g in range(4): spad[(SPAD_DENSE // 4) + j * 4 + g] = pack_word(row[g * 4:g * 4 + 4])
    for j, groups in enumerate(COMPRESSED):
        for g, weights in enumerate(groups): spad[(SPAD_SPARSE // 4) + j * 4 + g] = pack_word(weights + [0, 0])
    g = golden()
    lines = ["// Generated by scripts/workload_fc.py; do not edit.", "localparam integer WORKLOAD_WORDS = 8192;"]
    for i, value in enumerate(spad): lines.append(f"localparam logic [31:0] WORKLOAD_SPAD_{i} = 32'h{value:08x};")
    for i, value in enumerate(g["outputs"]):
        literal = f"-32'sd{-value}" if value < 0 else f"32'sd{value}"
        lines.append(f"localparam logic signed [31:0] WORKLOAD_OUT_{i} = {literal};")
    (out / "workload_expected.svh").write_text("\n".join(lines) + "\n")
    (out / "workload_metrics.json").write_text(json.dumps(g, indent=2, sort_keys=True) + "\n")


def self_test() -> None:
    g = golden(); assert g["outputs"] == [0, 0, 0, 0] or len(g["outputs"]) == 4
    assert vload32(3, 4, -4) == 0xffc2518b
    assert vstore32(3, 4, -4) == 0xfe326e0b
    assert vdot8(5, 6, 7) == 0x0073428b
    assert vsdot8(5, 6, 7, 4) == 0x8073728b
    for bad in (-1, 6, 7):
        try: vsdot8(1, 2, 3, bad)
        except ValueError: pass
        else: raise AssertionError("invalid metadata accepted")
    for bad in (-1, 32):
        try: addi(bad, 0, 0)
        except ValueError: pass
        else: raise AssertionError("invalid register accepted")
    try: addi(1, 0, 2048)
    except ValueError: pass
    else: raise AssertionError("invalid immediate accepted")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--emit", type=Path); parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test: self_test()
    if args.emit: emit(args.emit)
