# Scalar Production-Readiness Assessment — 2026-06-22

## Evidence basis

Clean entry tree: `5850b69813207055f1f1c7c1eebcb5dd63bda14b`.
Tools: Icarus Verilog 13.0, Verilator 5.048, Python 3.13.0, GNU Make 3.81.
All required Phase-1 commands passed on that tree.  The differential campaign
passed immediate seeds 1–500 in 18.4 seconds and seeds 1–16 in each nonzero
mode; each differential run has a 4,000-cycle testbench timeout.  This is
simulation evidence for the exercised subset, not formal equivalence or PPA.

| Assessment item | `rv32_core` (production/reference) | `rv32_core_pipe` (experimental) |
| --- | --- | --- |
| ISA/decode | `rv32_decoder.sv` supports the documented RV32I subset; custom-0/unsupported encodings trap. Directed scalar test covers illegal/custom-0. | Uses the same decoder and focused illegal test; differential covers only generated shared normal subset. |
| Traps and side effects | Terminal sticky `trap_valid/mepc/mcause/mtvec`; directed test covers causes and trap suppression. | Focused trap test covers targets, LH/LW/SH/SW misalignment, fault PCs, suppression, terminal retirement, and x0. No formal proof. |
| Memory | One request/response per port, aligned port address, byte strobes and little-endian lane selection in `rv32_core.sv`; directed test exercises latency/backpressure. | Same intended protocol and subword dataport alignment; focused memory plus differential modes exercise it. |
| Fetch/redirect | Request buffer plus epochs documented in `fetch_frontend.md`; directed delayed/backpressured test passes. | Generation bookkeeping and stale-response redirect focused regression pass, including held request/response case. |
| Hazards and counters | Conservative no-overlap DX/MW interlock with limited result forwarding; counters and retirement bundle are explicitly implemented. | ALU forwarding and MW blocking are exercised by focused tests. Many internal counters are development monitors only. |
| Retirement trace | `retire_*` reports completed stores and normal/trap events (`rv32_core.sv`). | `retire_mem_we/addr/data/wstrb` are constant zero (`rv32_core_pipe.sv`), despite store completion. The harness compares accepted store requests instead, so it does not prove this interface. |
| External interface/synthesis | Ports are the frozen v1 reference-core integration contract. Assertions are simulation checks; no synthesis flow has been run. | Same broad port list but not identical semantics; hierarchy-coupled focused tests read development internals. Assertions/system tasks still require synthesis treatment. |
| Verification depth/blind spots | One directed integration test plus common differential reference role. No randomized program generator, coverage closure, formal, or PPA. | Focused tests, controlled negatives, and differential campaign establish tested functional agreement only. No direct pipe retirement-store check, formal, coverage, or synthesis evidence. |
| Performance | Throughput is intentionally not established; the non-blocking experiment on the reference core fails its target. | ALU test shows local consecutive retirements, but no end-to-end sustained-throughput/timing/area evidence. |

## Separate readiness ratings

| Category | `rv32_core` | `rv32_core_pipe` |
| --- | --- | --- |
| Correctness readiness | Limited production/reference readiness for the documented directed subset and memory modes. | Tested-subset confidence only; differential agreement is encouraging but bounded. |
| Interface stability | v1 frozen by `scalar_interface_freeze.md`. | Not stable: store-retirement trace semantics conflict with v1. |
| Verification maturity | Low-to-moderate directed maturity; no formal/randomized coverage closure. | Low-to-moderate focused/differential maturity; direct trace gap remains. |
| Performance readiness | Not ready; expected throughput experiment fails. | Not ready; no system performance or implementation evidence. |
| Production naming/integration readiness | Retains production/reference role; no synthesized integration proof. | Not ready; remains experimental and must not be substituted. |

## Decision

**C. Do not promote `rv32_core_pipe`.**  ADR-012 records the decision.  The
concrete blocker is the false `retire_mem_*` contract, not a stylistic
preference.  Required bounded follow-up: define and implement matching pipe
store retirement fields, add direct assertions/differential comparison of
them, then rerun the campaign before a new promotion decision.  `rv32_core`
remains the reference model and production integration core; no naming change
or RTL promotion is authorized.

`retire_*` is an integration trace contract for the frozen reference core;
`cycle_count`/`instret_count` are debug/integration observability, not CSR
architecture; terminal trap outputs are the current integration/simulation
contract, not a complete privileged-architecture ABI.  Stall/flush counters
and pipeline monitors are verification/development diagnostics.
