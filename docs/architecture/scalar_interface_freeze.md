# Scalar Integration Interface Freeze, v1

## Scope and authority

This specification freezes the integration contract of the protected
production/reference implementation, `rtl/core/rv32_core.sv`, at commit
`5850b69813207055f1f1c7c1eebcb5dd63bda14b`.  It does not promote
`rv32_core_pipe`, which remains experimental despite matching the store
retirement semantics verified by the bounded trace-repair milestone. A future
scalar/vector integration must depend on this document, not on scalar
microarchitectural state or testbench hierarchy.

`rst_n` is synchronous and active low.  While reset is asserted, all valid
outputs are deasserted and state/output counters are zeroed except `mtvec`,
which is loaded from `MTVEC_RESET`.  `RESET_PC` initializes the next fetch
address.  Neither external memory is reset by the core.

## Stable architectural/integration ports

| Signals (direction from core) | Width | v1 contract and intended consumer |
| --- | ---: | --- |
| `clk` (in), `rst_n` (in) | 1 | System clock and synchronous active-low reset. |
| `RESET_PC`, `MTVEC_RESET` (parameters) | 32 | Reset-vector configuration; values must be fixed by the integrating top level. |
| `imem_req_valid` (out), `imem_req_ready` (in), `imem_req_addr` (out) | 1,1,32 | Decoupled instruction request. Acceptance is `valid && ready`; address is a byte address and remains stable while valid is held without ready. One accepted request/response may be outstanding. |
| `imem_resp_valid` (in), `imem_resp_ready` (out), `imem_resp_data` (in) | 1,1,32 | Decoupled instruction response. Responder holds data/valid until accepted. The core discards stale responses after redirects. |
| `dmem_req_valid` (out), `dmem_req_ready` (in), `dmem_req_write` (out), `dmem_req_addr` (out), `dmem_req_wdata` (out), `dmem_req_wstrb` (out) | 1,1,1,32,32,4 | Decoupled data request. Address is a word-aligned byte address; writes are little-endian and `wstrb[0]` selects the least-addressed byte. Fields remain stable while held. One transaction may be outstanding. |
| `dmem_resp_valid` (in), `dmem_resp_ready` (out), `dmem_resp_data` (in) | 1,1,32 | Decoupled data response for the sole outstanding transaction. Loads select/sign-extend byte/halfword lanes internally; stores retire only after a response handshake. |
| `trap_valid`, `mepc`, `mcause`, `mtvec` (out) | 1,32,32,32 | Terminal simulation trap state. `trap_valid` is sticky until reset; `mepc` is the trapping instruction PC and `mcause` uses the documented causes. A trap has no normal writeback or retirement. |
| `retire_valid`, `retire_pc`, `retire_instr`, `retire_rd_we`, `retire_rd`, `retire_rd_data`, `retire_mem_we`, `retire_mem_addr`, `retire_mem_data`, `retire_mem_wstrb`, `retire_trap`, `retire_cause` (out) | 1,32,32,1,5,32,1,32,32,4,1,32 | One-cycle retirement event for integration trace consumers. It represents a completed instruction; a store event carries effective byte address, unshifted scalar store data, and lane strobe. A trapping event has `retire_trap=1` and no normal destination write. |

All request/response order is strict program order.  Misaligned halfword/word
data accesses and misaligned instruction/control targets trap; the core does
not split them.  The scalar core permits no externally visible scalar
instruction or data operation to overtake an older one.

## Stable observability contract

`cycle_count` and `instret_count` are retained as 64-bit debug/integration
observability outputs, not CSR-visible architectural state.  In v1,
`cycle_count` increments on each non-reset clock; `instret_count` increments
once for each non-trapping completed instruction, including memory operations
only after their response.  They reset to zero.  Consumers requiring a
software ABI must not rely on either signal.

The retirement bundle is an integration trace contract, not a software ABI.
Its store fields are semantic in the reference core. `rv32_core_pipe` now
implements and has directed/differential evidence for equivalent store-
retirement behavior, but it remains experimental and must not be substituted
for the reference core without a separate human promotion decision.

## Verification-only interfaces

Differential trace arrays and snapshots, controlled-negative parameters,
testbench hierarchical accesses such as `dut.rf.regs`, and development-only
monitors (`taken_branch_redirects`, `stale_responses`, and related counters)
are verification-only.  They are not top-level system interfaces and must not
be exposed to the vector engine or software.

## Intentionally unstable/deferred items

`imem_stall_cycles`, `dmem_stall_cycles`, `dep_stall_cycles`, and
`control_flush_cycles` are implementation diagnostics, not frozen performance
contracts.  Pipeline-stage valid bits, fetch epochs, hazard/forwarding state,
raw memory-port timing, core naming, and future vector ports remain unstable.
The vector engine must not observe scalar register-file internals, fetch
state, stage valid bits, redirect epochs, internal hazards, or raw memory-port
timing.  It may use only the future extension boundary in
`scalar_vector_interface.md` and its own selected memory boundary.
