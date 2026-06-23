STATUS: COMPLETE
MILESTONE: Final Integration, Documentation, and Portfolio Release
COMPLETED_AT: 2026-06-23

SUMMARY
Completed the documentation-and-release integration without adding RTL or ISA
functionality. The repository now has a portfolio landing page, Mermaid
architecture and sparse-dataflow diagrams, canonical results/provenance,
reproduction guide, release checklist, accurate source manifest, improved
target help, and repository-wide relative Markdown-link validation.

HEADLINE_RESULTS
- All FC paths produce `[382, -446, -246, 1054]`; scalar/dense/sparse measured
  7,399/484/484 cycles and 3,948/109/109 retired instructions.
- Sparse FC measured 32 executed and 32 skipped multiplies; dense storage is
  64 bytes and sparse weight-plus-metadata storage is 38 bytes (40.625%
  reduction).
- Sensor fixture: 16/16 correct dense and sparse predictions; zero disagreements.
- Generic Yosys 0.66 `cmos2` totals: scalar 14,029, dense 62,928, sparse
  65,691 cells. Sparse adds 2,763 cells (4.39%) over dense.

CHANGED_FILES
- Updated: `README.md`, `Makefile`, `docs/architecture.md`,
  `docs/architecture/vector_vadd8.md`, `docs/codex_context.md`,
  `docs/implementation_status.md`, `docs/milestone_history.md`,
  `docs/source_manifest.md`, `docs/verification_plan.md`, and
  `scripts/check_repo.py`.
- Added: `docs/final_results.md`, `docs/reproduction.md`, and
  `docs/release_readiness.md`.
- Removed: no files. No stale `.codex/milestone_result.md` reference, tracked
  generated artifact, or `.DS_Store` file was found.

COMMANDS_AND_OUTCOMES
- `make test-vector-vsdot-all`: PASS.
- `make docs-check`: initial FAIL for pre-existing README heading requirements;
  headings restored, then PASS with repository-wide relative-link validation.
- `make test-workload-all`: PASS; reported all headline FC measurements.
- `make test-sensor-all`: PASS; Python export tests and 16 dense plus 16 sparse
  RTL runs passed.
- `make ppa-all`: PASS; regenerated ignored `results/ppa/` artifacts.
- `make test-vector-regression`: PASS.
- `make test-full-regression`: initial FAIL because the expanded link checker
  removed a unit-test-imported helper; compatibility wrapper added. Rerun PASS
  across scalar/vector regression, Python tests, lint, repository, and docs.
- `make check`: PASS.
- `make lint`: PASS with documented non-fatal Verilator filename, empty-pin,
  multi-top, and unused-signal warnings.
- `make docs-check` (final): PASS.
- `make help`: PASS; stable target list printed.
- `git diff --check`: PASS.

KNOWN_WARNINGS_AND_LIMITATIONS
Icarus emits existing non-fatal `always_*` sensitivity/synthesis-context and
bounded `$readmemh` image-size warnings. Verilator emits the documented
non-fatal synthesis-wrapper warnings. `rv32_core_pipe` remains experimental;
Sparrow-V is not full RVV and has fixed 32-bit vectors, one outstanding vector
command, fixed dense/sparse latency, no compressed sparse load, no full compiler
backend, no SRAM macros, no physical timing closure, and no measured power.
Sensor accuracy is fixture-only. Generic cell counts are not ASIC area, timing,
or power claims.

RELEASE_READINESS
Documentation, diagrams, metrics, reproducibility commands, source ownership,
link validation, and final regression are complete. A human must still review
the working-tree diff and make any release commit/tag manually.

SAFETY_AND_SCOPE
No architectural feature was added. `rtl/core/rv32_core.sv` is unchanged.
Generated PPA and simulation artifacts remain ignored. No commit or push
occurred.
