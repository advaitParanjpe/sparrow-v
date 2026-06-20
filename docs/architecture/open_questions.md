# Architecture Open Questions and Planning Audit

## Intended system

Sparrow-V is a compact, programmable RV32I edge processor. A single-issue in-order scalar core controls program flow and issues a compact custom vector ISA to a tightly coupled engine with separate vector state. The intended baseline is four physical lanes, eight 128-bit vector registers, signed INT8/INT16 arithmetic, dense vector operations, and later explicit 2:4 structured sparse dot products. Scalar and vector paths share a banked, software-managed scratchpad; instruction memory is separate. The software flow is bare-metal C/assembly helpers plus Python quantization, pruning, export, and golden models. Verification is layered: directed unit/subsystem/system tests, scoreboards, assertions, randomized seeds, then implementation and benchmark evidence.

The staged plan is scalar CPU (Phase 1), C bring-up (2), blocking extension interface (3), dense vector engine (4), scratchpad/vector LSU (5), sparse execution (6), workload (7), verification hardening (8), and FPGA/ASIC-style work (9).

## Ambiguities and inconsistencies

- Phase 0's roadmap requests a frozen scalar instruction subset and custom opcode allocation, but the scalar subset and exact custom encoding remain explicit open questions. They cannot truthfully be reported frozen yet.
- The charter names eight 128-bit vector registers as the initial target, while the open-questions document still offers 8 versus 16 registers and 128 versus 64 bits. Treat the charter values as a proposal until an ADR is accepted.
- `vdot rd, ...` is described as writing a scalar register, yet the open questions still ask whether it writes scalar or vector state. The instruction table and interface cannot be finalized until this is resolved.
- The documents recommend 32-bit dot accumulation and wrapping add/subtract, but leave accumulator width, saturation, tail behavior, masked-lane behavior, signedness details, and exception semantics unfrozen.
- The sparse instruction shows `rs_meta`, while the microarchitecture permits a metadata pointer or immediate and the open questions permit scalar register, vector register, or memory stream. The metadata transport and packing are not defined.
- A four-bank, 32-bit word-interleaved scratchpad is proposed, but capacity, byte/element addressing, arbitration policy, response latency, vector request granularity, and outstanding-request bounds are open.
- Version 1 permits blocking vector issue, whereas later documents discuss scoreboarding and tags. The minimum blocking protocol needs exact stall, scalar-result, reset-cancellation, and illegal-instruction semantics before Phase 3.
- The project says use Verilator and/or Icarus, but tool versions, testbench framework details, ISA/reference-model conformance boundary, FPGA part, ASIC PDK/configuration, and clock targets are not selected.
- The benchmark document recommends vibration-fault classification, while the software plan lists five candidates and does not freeze whether feature extraction executes on Sparrow-V. Benchmark scope and comparison fairness remain open.

## Decisions required before RTL begins

Phase 1 requires the scalar-pipeline, core-provenance, supported RV32I subset/traps, reset polarity, program-image convention, and baseline memory-interface contract. Phase 3 additionally requires custom encoding and the blocking extension protocol. Dense vector RTL requires vector-state organization and arithmetic semantics. Scratchpad and sparse RTL require their respective formats and ordering rules. The full list and owners are represented by the Proposed ADRs in `docs/decisions/`.

## Minimum viable scope versus stretch goals

Minimum viable scope is a simple RV32I scalar core, blocking custom-vector interface, four-lane dense INT8/INT16 vector operations, shared banked scratchpad, 2:4 sparse dot path, one reproducible bare-metal workload, and evidence-based evaluation. Decoupled multi-instruction vector issue, cache hierarchy, custom compiler backend, 16 registers/alternate widths, advanced masking/saturation, Basys3 board demonstration, and tinyNPU comparison are stretch work unless later approved.
