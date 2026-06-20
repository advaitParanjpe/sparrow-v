# Project Charter

## Objective

Design, implement, verify, and evaluate a compact RV32I processor with a tightly coupled sparse-aware vector extension for quantized AI and IoT workloads.

## Intended final artifact

A reproducible open hardware project containing:

- synthesizable SystemVerilog RTL;
- scalar and vector architectural documentation;
- a bare-metal software toolchain and runtime;
- a Python functional model;
- quantization and 2:4 pruning/export scripts;
- directed and randomized verification;
- FPGA synthesis results;
- ASIC-style synthesis and physical-design results;
- end-to-end application benchmarks;
- a final technical report.

## Design goals

1. **CPU-centric:** The scalar processor owns program flow and issues vector operations as instructions.
2. **Programmable:** The same hardware should run several kernels without RTL changes.
3. **Sparse-aware:** Structured sparsity must reduce real work or data movement, not merely increment a counter.
4. **Small and understandable:** The implementation should remain inspectable and verifiable by one developer.
5. **Measurable:** Every architectural feature must have counters and benchmark evidence.
6. **Reproducible:** Simulation and evaluation must be runnable from documented commands.
7. **Honest:** No performance, timing, power, or correctness claim may be made without generated evidence.

## Non-goals

Version 1 will not implement:

- full RISC-V Vector Extension compliance;
- Linux;
- virtual memory;
- privilege levels beyond the minimum required for bare-metal execution;
- floating point;
- multicore coherence;
- superscalar or out-of-order scalar execution;
- speculative execution;
- a production compiler backend;
- a full cache hierarchy;
- external DRAM controller RTL;
- tapeout or signoff claims.

## Initial target configuration

- ISA: RV32I scalar base.
- Scalar issue: single issue, in order.
- Vector lanes: 4.
- Vector element widths: INT8 and INT16.
- Vector register count: 8.
- Vector register width: 128 bits initially.
- Scratchpad banks: 4.
- Sparse format: 2:4 structured sparsity.
- Simulation: Verilator and/or Icarus Verilog.
- FPGA: Vivado synthesis, Basys3 optional.
- ASIC-style flow: Yosys and OpenLane/OpenROAD.

## Success definition

The project is successful when:

- compiled or assembled bare-metal programs run on the scalar core;
- dense vector programs produce bit-exact results against the Python model;
- sparse programs produce equivalent numerical results to dense execution for the encoded sparse model;
- measured sparse execution reduces operations and/or memory traffic;
- randomized verification passes across scalar, dense-vector, sparse-vector, and memory-stall scenarios;
- synthesis results are generated and documented;
- at least one end-to-end IoT workload is demonstrated.

