# Phase 1 Scalar Verification

`tb/integration/tb_scalar_core.sv` is a self-checking directed integration test. Its program exercises arithmetic, signed/unsigned comparisons, six branch forms, forward/backward branches, JAL/JALR, byte/halfword/word stores and loads, sign/zero extension, FENCE, ECALL, EBREAK, custom-0 illegal instruction, load/store misalignment, x0, reset, counters, delayed responses, and request backpressure.

The test memory applies two/three-cycle response delays and periodic request backpressure. It checks register and memory-visible results, trap causes, and counters; it does not pass merely on program termination.

RTL assertions check PC alignment, x0 immutability, valid-stage writeback, valid memory requests, and trap/writeback exclusion. The testbench also asserts request-field stability across every cycle of request backpressure. Broader randomized, coverage, formal, and separate unit-test layers remain future work.
