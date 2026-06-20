# System Architecture

## Top-level view

```text
                    +----------------------+
                    | Instruction Memory   |
                    +----------+-----------+
                               |
                               v
+-------------------------------------------------------------+
|                        Sparrow-V SoC                         |
|                                                             |
|  +---------------------+                                    |
|  | RV32I Scalar Core   |                                    |
|  | fetch/decode/execute|                                    |
|  +----------+----------+                                    |
|             |                                               |
|             | custom vector instruction                     |
|             v                                               |
|  +----------------------+       +-------------------------+  |
|  | Extension Interface  |------>| Vector Issue/Scoreboard |  |
|  +----------------------+       +------------+------------+  |
|                                             |               |
|                      +----------------------+---------------+|
|                      |                                      ||
|                      v                                      ||
|            +-------------------+                            ||
|            | Vector Register   |                            ||
|            | File              |                            ||
|            +---------+---------+                            ||
|                      |                                      ||
|          +-----------+------------+                         ||
|          |                        |                         ||
|          v                        v                         ||
|  +---------------+       +------------------+               ||
|  | Dense Vector  |       | Sparse Dot Unit  |               ||
|  | ALU/MUL/DOT   |       | 2:4 Decode       |               ||
|  +-------+-------+       +---------+--------+               ||
|          |                         |                        ||
|          +-----------+-------------+                        ||
|                      |                                      ||
|                      v                                      ||
|            +-------------------+                            ||
|            | Vector Writeback  |                            ||
|            +---------+---------+                            ||
|                      |                                      ||
|  +-------------------+--------------------+                 ||
|  | Scalar Load/Store + Vector Load/Store |                 ||
|  +-------------------+--------------------+                 ||
|                      |                                      ||
|                      v                                      ||
|            +-------------------+                            ||
|            | Banked Scratchpad |                            ||
|            +-------------------+                            ||
+-------------------------------------------------------------+
```

## Architectural principles

### Scalar core owns control flow

Branches, loops, pointer updates, function calls, and program sequencing remain scalar operations.

### Vector operations are architectural instructions

Vector work is not launched through an MMIO accelerator command queue. The scalar decode stage identifies custom vector opcodes and issues them through a dedicated extension interface.

### Vector engine may be multi-cycle

The scalar pipeline may stall on vector issue, or continue until a dependency boundary depending on the implementation phase. Version 1 may use blocking vector issue. Later phases may add decoupled issue and completion.

### Scratchpad before cache

A banked software-managed scratchpad is the initial memory architecture because it offers deterministic behavior and exposes bank conflicts clearly. A data cache is optional future work.

### Sparse support is explicit

Sparse data must use a documented encoded representation. Sparse execution must consume metadata, select only nonzero operands, and perform fewer multiplications than dense execution.

## Top-level modules

- `sparrowv_top`
- `rv32_core`
- `rv32_regfile`
- `rv32_decoder`
- `rv32_alu`
- `rv32_lsu`
- `vector_extension_if`
- `vector_issue_unit`
- `vector_scoreboard`
- `vector_regfile`
- `vector_alu`
- `vector_mul_unit`
- `vector_dot_unit`
- `sparse_2of4_unit`
- `vector_lsu`
- `banked_scratchpad`
- `perf_counters`
- `uart_or_sim_console`

## Initial execution model

Phase 1 uses blocking custom instructions:

1. Scalar decode recognizes a vector instruction.
2. Scalar source operands and instruction fields are presented to the extension interface.
3. The vector unit accepts or stalls issue.
4. The scalar core waits until completion when required.
5. Scalar execution resumes.

Later phases may permit the scalar pipeline to continue past independent vector operations if the scoreboard and architectural state support it.

## Reset and clocking

- Single clock domain for version 1.
- Active-low or active-high reset must be selected once and used consistently.
- No asynchronous clock-domain crossings in the base design.
- Clock gating may be modeled later but must not complicate initial correctness.

