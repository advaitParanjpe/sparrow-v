# Phase 1 Trap Behavior

Traps redirect the PC to parameterized `mtvec`, record `mepc` and `mcause`, assert sticky `trap_valid`, and suppress normal retirement/writeback. There is no trap handler return, interrupt support, delegation, privilege transition, or writable CSR instruction in this phase.

| Condition | Cause |
| --- | ---: |
| Misaligned instruction PC or control-flow target | 0 |
| Unsupported/illegal instruction, including custom-0 | 2 |
| EBREAK | 3 |
| Misaligned halfword/word load | 4 |
| Misaligned halfword/word store | 6 |
| ECALL | 11 |
