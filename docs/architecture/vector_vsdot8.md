# Experimental Sparse INT8 Dot Product

`VSDOT8 rd, va, vw, pattern` is one experimental Custom-0 operation for a single four-lane 2:4 group. It is not general sparse-vector support.

Opcode is `0x0b`, `funct3=111`; `rs1=va`, `rs2=vw`, and `rd` is the scalar destination. `instr[31:29]` carries `pattern`; `instr[28:25]` is reserved and must be zero. `vw[7:0]` is weight 0 and `vw[15:8]` weight 1; `vw[31:16]` is ignored.

| Pattern | Lanes |
| --- | --- |
| 000 | {0,1} |
| 001 | {0,2} |
| 010 | {0,3} |
| 011 | {1,2} |
| 100 | {1,3} |
| 101 | {2,3} |

Weight 0 maps to the lower selected lane and weight 1 to the higher selected lane. Both operands are signed INT8, products are signed INT16, and both are sign-extended before exact signed 32-bit accumulation.

Patterns `110` and `111` complete exceptionally with cause 18 and have no architectural write or compute event. Successful operations return a scalar result and write nonzero `rd` only at completion retirement; they never write vector or scratchpad state.

Test-only `dbg_vsdot_mul_exec_valid` and `dbg_vsdot_mul_skip_valid` assert only at successful completion. Each represents two multiplications: two executed and two dense-equivalent skipped. They are suppressed by backpressure, reset cancellation, wrong-path suppression, and metadata exception. Verification independently constructs dense weights and uses seed `0x5a17c0de` for 96 randomized cases.

Remaining limits: one 32-bit group only; no sparse memory, masks, multiple groups, INT16, saturation, compiler support, or final ISA commitment.
