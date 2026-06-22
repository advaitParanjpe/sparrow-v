# Bare-Metal INT8 Sparse Fully Connected Workload

`scripts/workload_fc.py` is the deterministic instruction encoder and
independent golden model for the bounded workload.  It emits standard RV32I
instructions plus Custom-0 `VLOAD32`, `VSTORE32`, `VDOT8`, and `VSDOT8` forms;
it validates register, immediate, and sparse-metadata ranges and writes
reproducible simulation images.  `tb/integration/tb_workload_fc.sv` executes
those images through `rv32_core_pipe` and `rv32_vec_vadd_engine`.

The layer is `y[j] = bias[j] + sum(x[k] * w[j][k])`, with 16 signed INT8
features and four signed INT32 outputs. Inputs are
`[1,-2,0,127,-128,3,-4,5,-6,7,0,-8,9,-10,11,-12]`; biases are
`[17,-23,31,-37]`; golden outputs are `[382,-446,-246,1054]`.

Each output has four groups. The shared lane patterns are `{0,2}`, `{1,3}`,
`{0,1}`, and `{2,3}` (metadata `001`, `100`, `000`, `101`), respectively.
Each compressed group stores the two weights in increasing selected-lane order.
Reconstruction places them at those lanes and writes zero to the other two
lanes, which is independently checked before simulation. The workload includes
positive, negative, and zero inputs/weights, both `127` and `-128`,
cancellation, nonzero biases, and positive and negative results.

## Memory layout

Scalar data memory uses bytes `0x00..0x0f` for activations, `0x10..0x4f` for
the 64 dense weight bytes, `0x100..0x10f` for the four output words, and
`0x1f0` for the one completion signature. The scalar program uses a bounded
eight-iteration signed shift/add routine for each of its 64 multiplications;
no RV32M instruction or custom instruction is used.

The 256-byte vector scratchpad uses little-endian words: activation groups at
`0x00..0x0f`, dense weight groups at `0x10..0x4f`, and compressed sparse words
at `0x50..0x8f`. A sparse word has weight 0 in byte 0 and weight 1 in byte 1;
bytes 2–3 are zero. Dense and sparse datasets occupy 144 bytes together, so
they fit in one scratchpad initialization. Results and completion remain in
scalar memory; all three runs are otherwise separated and deterministic.

## Measured comparison

Cycles and retired instructions are observed from reset release through the
cycle in which the completion signature retires; this interval includes the
deterministic scratchpad preload performed after reset release and before
instruction fetch. Scalar software-multiply invocations are observed by
retirement of the unique `addi x8,x0,0` multiply-routine entry instruction;
dense multiplication count is derived from the fixed 16-by-4 workload. Sparse
execute/skip events, vector transfers, and dot retirements are observed from
real command, retirement, and engine-debug events. Vector stores and runtime
scratchpad writes are zero.

| Metric | Scalar RV32I | Dense Vector | Sparse Vector |
|---|---:|---:|---:|
| Correct outputs | yes | yes | yes |
| Total cycles | 7399 | 484 | 484 |
| Retired instructions | 3948 | 109 | 109 |
| Scalar multiply operations | 64 observed retirements | 0 | 0 |
| Dense dot-product instructions | 0 | 16 | 0 |
| Sparse dot-product instructions | 0 | 0 | 16 |
| Multiplications executed | 64 derived | 64 derived | 32 observed |
| Multiplications skipped | 0 | 0 | 32 observed |
| Vector loads | 0 | 32 | 32 |
| Vector stores | 0 | 0 | 0 |
| Scratchpad writes after start | 0 | 0 | 0 |
| Weight bytes | 64 | 64 | 32 |
| Metadata bytes | 0 | 0 | 6 |
| Weight + metadata bytes | 64 | 64 | 38 |

Sparse metadata packs the sixteen 3-bit group codes into six bytes (48 bits).
Thus raw weight storage falls by 50%; weight-plus-metadata storage falls by
26 bytes (40.625%), not 50%.
