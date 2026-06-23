# Sparrow-V Architecture Overview

Sparrow-V has two scalar implementations. `rv32_core` is the protected,
production/reference three-stage RV32I core. `rv32_core_pipe` is the
experimental integration core used for scalar/vector workloads. It is
single-issue, in-order, blocking, and non-speculative at the scalar/vector
boundary; it is not promoted to replace the reference core.

## System overview

```mermaid
flowchart LR
  IMEM[Instruction memory] --> PIPE[Experimental scalar pipeline]
  DMEM[Scalar data memory] <--> PIPE
  PIPE -- command: one outstanding --> ENG[Vector engine]
  ENG -- completion: result/status --> PIPE
  ENG --> VRF[32 x 32-bit vector register file]
  ENG <--> SPAD[256-byte vector scratchpad]
  ENG --> VADD[VADD8\nfour INT8 adds]
  ENG --> VDOT[VDOT8\nfour INT8 products]
  ENG --> VSDOT[VSDOT8\n2:4 sparse decode]
  PIPE --> WB[Scalar result writeback]
  VDOT --> WB
  VSDOT --> WB
```

The diagram depicts `rv32_core_pipe`; the reference core does not issue vector
commands. Scalar `dmem` and the vector scratchpad are separate state spaces.

## Command and state ownership

The pipe captures scalar operands and vector indices, holds the command stable
until the engine accepts it, then blocks scalar issue. The engine returns a
stable completion until accepted. Successful vector-state updates and scalar
result writeback occur only on that completion handshake. Exceptions are
precise; reset cancels outstanding work and a wrong-path instruction cannot
issue a command.

The engine exclusively owns 32 writable 32-bit vector registers (`v0`–`v31`)
and a 256-byte byte-addressed, little-endian scratchpad. The scalar owns
scalar registers, scalar retirement, traps, and scalar `dmem`. Test-only debug
ports are not architectural interfaces.

## Data paths

`VADD8` performs four modulo-256 lane additions. `VDOT8` interprets four
little-endian lanes as signed INT8 values, forms four signed products, and
returns their exact signed 32-bit sum. `VLOAD32`/`VSTORE32` transfer aligned
32-bit words to/from the vector-only scratchpad; misalignment and range/wrap
fail precisely.

`VSDOT8` consumes one activation word, two compressed weights in bytes 0 and
1 of a weight word, and a legal three-bit 2-of-4 pattern. Weight 0 maps to the
lower selected lane and weight 1 to the higher selected lane. It returns a
signed 32-bit scalar sum after two executed products; invalid patterns `110`
and `111` raise cause 18.

## Sparse dataflow

```mermaid
flowchart LR
  A0[activation lane 0] --> SEL{3-bit pattern}
  A1[activation lane 1] --> SEL
  A2[activation lane 2] --> SEL
  A3[activation lane 3] --> SEL
  META[pattern 001 = lanes 0,2] --> SEL
  W0[compressed weight 0] --> M0[multiply selected lower lane]
  W1[compressed weight 1] --> M1[multiply selected higher lane]
  SEL --> M0
  SEL --> M1
  M0 --> SUM[signed 32-bit sum]
  M1 --> SUM
  SKIP[Two non-selected lanes: two multiplies skipped] -. accounting .-> SUM
```

All legal mappings are `000={0,1}`, `001={0,2}`, `010={0,3}`, `011={1,2}`,
`100={1,3}`, and `101={2,3}`. The example in the figure uses `001`; it does
not imply a fixed pattern in software.

## Further detail

- [Scalar/vector command-completion contract](architecture/scalar_vector_interface.md)
- [VADD8 and VDOT8 semantics](architecture/vector_vadd8.md)
- [VSDOT8 metadata and accounting](architecture/vector_vsdot8.md)
- [Vector scratchpad transfers](architecture/vector_memory.md)
- [Workload layout and measurement definition](architecture/sparse_fc_workload.md)
