# Risks and Tradeoffs

## Risk: Building a CPU from scratch consumes too much time

Mitigation:

- keep scalar ISA to RV32I;
- use a simple in-order pipeline;
- bring up assembly before C;
- do not add caches, privilege modes, or advanced prediction early.

Fallback:

- adapt a small permissively licensed educational RV32I core only if provenance and modifications are documented clearly.

## Risk: Full vector implementation becomes too large

Mitigation:

- use a custom compact ISA;
- use 4 physical lanes;
- iterate over 128-bit architectural vectors;
- begin with add, multiply, dot, and load/store only.

Fallback:

- reduce vector register width or instruction set while preserving dense-versus-sparse comparison.

## Risk: Sparse metadata overhead removes benefit

Mitigation:

- measure metadata bytes explicitly;
- compare compute savings and traffic savings separately;
- use workloads large enough for metadata amortization.

Fallback:

- retain sparse compute as an architectural experiment even if net workload speedup is limited, and report the negative result honestly.

## Risk: End-to-end ML application is too complex

Mitigation:

- use precomputed sensor features;
- use a small quantized MLP;
- keep training outside RTL work;
- prioritize reproducible inference.

Fallback:

- use sparse matrix-vector and FIR workloads first, then add application integration later.

## Risk: FPGA resource usage exceeds Basys3 capacity

Mitigation:

- parameterize lane count and vector width;
- synthesize reduced configurations;
- infer BRAM for scratchpad where possible.

Fallback:

- provide synthesis-only FPGA results and use simulation for full configuration.

## Risk: OpenLane flow does not close timing

Mitigation:

- pipeline vector arithmetic;
- separate architecture comparison from signoff claims;
- sweep clock periods.

Fallback:

- report achieved timing and remaining violations honestly, as done for tinyNPU.

## Tradeoff: Scratchpad versus cache

Scratchpad is less transparent to software but simpler, deterministic, and easier to evaluate. It is preferred for version 1.

## Tradeoff: Blocking versus decoupled vector issue

Blocking issue is simpler and sufficient for a functional first version. Decoupling offers better overlap but requires scoreboarding and more verification.

## Tradeoff: Flop-based versus memory-based vector register file

Flops simplify multiport access but increase area. A later implementation may infer SRAM or replicate memories for read bandwidth.

