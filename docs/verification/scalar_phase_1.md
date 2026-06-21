# Phase 1 Scalar Verification

`tb/integration/tb_scalar_core.sv` is a self-checking directed integration test. Its program exercises arithmetic, signed/unsigned comparisons, six branch forms, forward/backward branches, JAL/JALR, byte/halfword/word stores and loads, sign/zero extension, FENCE, ECALL, EBREAK, custom-0 illegal instruction, load/store misalignment, x0, reset, counters, delayed responses, and request backpressure.

The test memory applies two/three-cycle response delays and periodic request backpressure. It checks register and memory-visible results, trap causes, and counters; it does not pass merely on program termination.

RTL assertions check PC alignment, x0 immutability, valid-stage writeback, valid memory requests, and trap/writeback exclusion. The testbench also asserts request-field stability across every cycle of request backpressure. Broader randomized, coverage, formal, and separate unit-test layers remain future work.

## Differential development-core verification

`tb/integration/tb_scalar_differential.sv` runs the production core and isolated pipeline against the same deterministic in-test program and initialized memory. It normalizes PC/instruction retirement, register writes, accepted store requests, final x0–x31 state, final memory, and terminal PC/cause; cycles and raw stalls are intentionally not compared. The generated campaign exercises LUI/AUIPC, OP-IMM/OP arithmetic and shifts, LW/SW, all conditional branches, JAL/JALR, and ECALL. It does not yet randomize byte/halfword loads/stores, FENCE, EBREAK, illegal encodings, or misalignment.

Modes are immediate, request-backpressured, delayed-response, and mixed. The 32-seed immediate campaign and seed 17 modes 1–3 pass. `test-scalar-diff-negative` intentionally perturbs final x2 and succeeds only when detection is reported. A redirect/backpressure regression covers the fixed stale-response phantom-outstanding-fetch bug: redirect consumed a stale response while a younger request was held, and the old `out_v` was not cleared.
