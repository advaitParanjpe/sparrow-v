# Implementation status

## Implemented and verified

- Production/reference scalar core: `rtl/core/rv32_core.sv`, with the directed integration regression invoked by `make test-scalar-directed`.
- Reusable scalar decoder, immediate generator, ALU, register file, package, directed testbench, Python repository checks, and reference helper.
- Repository documentation checks (`make check`) and Verilator lint (`make lint`) are defined.

## Implemented but incompletely verified

- `rtl/core/rv32_core_pipe.sv` and focused development testbenches document ALU/control-flow behavior, forwarding, fetch generations, and backpressure experiments. This implementation is isolated and has not replaced the production core.
- Development memory behavior is experimental. The focused `make test-scalar-pipe-memory` regression passed in this checkpoint after its test data was corrected, but it is not production integration evidence.

## Planned, not implemented

Vector engine/ISA, vector memory, INT8/INT16 lanes, masks/reductions/dot products, 2:4 sparse metadata, scratchpad, randomized scoreboards, formal verification, compiled bare-metal execution, synthesis, FPGA, and ASIC/OpenLane flows.

## Important sources and commands

| Area | Sources | Current command |
| --- | --- | --- |
| Production scalar | `rtl/core/rv32_core.sv`, `tb/integration/tb_scalar_core.sv` | `make test-scalar-directed` |
| Development pipeline | `rtl/core/rv32_core_pipe.sv`, `tb/integration/tb_scalar_pipe_*.sv` | focused `make test-scalar-pipe-*` targets |
| Repository checks | `scripts/check_repo.py`, `tb/tests/` | `make check`, `make test-repo` |
| Lint | all `rtl/**/*.sv` | `make lint` |

## Environmental blockers

The repository documentation records that a RISC-V bare-metal cross compiler is unavailable locally. No CI configuration or physical-design tool flow is present to validate synthesis/timing/area claims.
