STATUS: COMPLETE
MILESTONE: Scalar vs Dense-Vector vs Sparse-Vector Synthesis and PPA Evaluation
COMPLETED_AT: 2026-06-23

SUMMARY
Implemented three deterministic configurations, generic-Yosys synthesis, JSON/Markdown report generation, configuration-specific functional targets, and the required documentation. Scalar uses protected `rv32_core`; dense and sparse use the experimental pipe with the shared vector engine parameterized as `ENABLE_SPARSE=0/1`. No production-core change or promotion occurred.

CONFIGURATION_AND_PPA_RESULTS
- Tool/technology: Yosys 0.66; generic `cmos2` mapping. Clock reporting targets: 10 ns (100 MHz) and 20 ns.
- Scalar: 14,029 total cells; 1,311 sequential; 12,718 combinational; depth proxy 84; memory bits 0.
- Dense: 62,928 total cells; 4,842 sequential; 58,086 combinational; depth proxy 81; vector memory bits 3,072.
- Sparse: 65,691 total cells; 4,842 sequential; 60,849 combinational; depth proxy 83; vector memory bits 3,072.
- Overheads: dense/scalar +48,899 (+348.56%); sparse/dense +2,763 (+4.39%); sparse/scalar +51,662 (+368.25%).
- Memory: vector register file and scratchpad are generic flip-flop/mux mapped, not SRAM macros. No latches or black boxes were reported.
- Timing/power: no Liberty/STA or activity flow is installed. Worst slack, Fmax, mapped area, and dynamic/leakage power are N/A; logic depth is only a structural proxy. No physical implementation ran.
- Workloads: FC scalar/dense/sparse cycles are 7,399/484/484; derived 100-MHz latency is 73,990/4,840/4,840 ns. Sensor dense/sparse are 484 cycles/sample. Dense and sparse are equal because both use the same fixed-latency command/completion path and schedule. Sparse executes 32 and skips 32 FC multiplies, with 38-byte versus 64-byte weight storage.

CHANGED_FILES
- `Makefile`, `config/ppa_configurations.json`, `synth/yosys/manifests/*.f`, `scripts/ppa_flow.py`
- `rtl/top/sparrowv_ppa_tops.sv`, `rtl/vector/rv32_vec_vadd_engine.sv`
- `docs/architecture/synthesis_ppa_evaluation.md`, README/status/verification/history/source-manifest documentation, and this result file.

COMMANDS_AND_OUTCOMES
- `python3 scripts/ppa_flow.py --config scalar`: PASS.
- `make ppa-all`: PASS; generated ignored reproducible `results/ppa/` raw logs, netlists, metadata, JSON summary, and Markdown comparison.
- `make test-config-scalar && make test-config-dense && make test-config-sparse`: PASS. Dense checks used `SPARROWV_DENSE_ONLY`; sparse ran the complete vector regression.
- `make test-workload-all`: PASS; scalar/dense/sparse output `[382,-446,-246,1054]` and stated cycle counts.
- `make test-sensor-all`: PASS; all dense and sparse fixture invocations passed.
- `make test-vector-regression`: PASS.
- `make test-full-regression`: PASS (existing informational Icarus/Verilator warnings only).
- `make lint`: PASS with existing non-fatal warnings.
- `make check`: PASS.
- `make docs-check`: PASS.
- `git diff --check`: PASS after final result-file update.

REMAINING_LIMITATIONS
Generic gate counts are not standard-cell area or SRAM macro estimates. No physical timing closure, power estimate, OpenLane/OpenROAD run, or tapeout claim is made. `rv32_core_pipe` remains experimental.

REFERENCE_CORE_STATUS
`rtl/core/rv32_core.sv` is unchanged.

COMMIT_PUSH_STATUS
No commit or push occurred. The worktree is ready for human review; generated PPA artifacts remain ignored and reproducible via `make ppa-all`.
