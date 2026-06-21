/* Hand-authored Phase 1 smoke-test source. Build with a future RV32I toolchain. */
.section .text
.globl _start
_start:
  li a0, 5
  li a1, 7
  add a2, a0, a1
  beq a2, a1, fail
  li t0, 0x200
  sw a2, 0(t0)
  lw a3, 0(t0)
  bne a2, a3, fail
  li t1, 1
  sw t1, 4(t0)       /* pass signature */
  ecall
fail:
  sw zero, 4(t0)     /* fail signature */
  ebreak
