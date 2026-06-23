STATUS: COMPLETE
MILESTONE: External Sensor Workload Interface for SparrowML Integration
STARTED_AT: 2026-06-23T22:29:47Z

## Outcome

Implemented a versioned fixed-shape external sensor-workload interface for the
existing dense and sparse RTL paths. No RTL, ISA, or architectural behavior was
changed; `rv32_core` remains untouched. No SparrowML code or dependency was
added. Existing checked-in fixture commands remain default and pass.

## Changed files

- `scripts/sensor_workload.py`, `scripts/run_external_sensor_workload.py`,
  `tb/integration/tb_sensor_workload.sv`, `Makefile`, and `pytest.ini`.
- `tb/fixtures/external_sensor_dense.json`,
  `tb/fixtures/external_sensor_sparse.json`, and
  `tb/tests/test_external_sensor_workload.py`.
- `README.md`, `docs/architecture/sensor_workload_export.md`,
  `docs/implementation_status.md`, `docs/milestone_history.md`,
  `docs/source_manifest.md`, and `docs/verification_plan.md`.

## Verification

- PASS: `python3 -m compileall scripts python`.
- PASS: `pytest` (16 tests). Initial collection failed because pytest did not
  include the repository root; `pytest.ini` now sets `pythonpath = .`.
- PASS: `make test-sensor-rtl-dense` and `make test-sensor-rtl-sparse` (all
  existing 16-sample fixture runs).
- PASS: `make test-sensor-rtl-external-dense` and
  `make test-sensor-rtl-external-sparse` using source-controlled manifests.
- PASS: focused external tests cover validation, dimensions, integer ranges,
  sparse metadata, deterministic/stale workspace behavior, fixture protection,
  result schema, expected-accumulator assertion reporting, and real RTL runs.
- PASS: `make check`, `make docs-check`, and `git diff --check`.
- PASS: `make test-full-regression` once after implementation stability. The
  subsequent bounded workspace-safety correction was covered by focused
  external Make targets and pytest; it did not affect RTL or aggregate paths.

## Measurements and result contract

- Dense external fixture: accumulators `[977, 57, -129, 203]`; 484 cycles;
  109 retired; 32 measured vector loads; 16 dense dots; 64 derived conceptual
  INT8 multiplications.
- Sparse external fixture: accumulators `[977, -23, 31, 203]`; 484 cycles;
  109 retired; 32 measured vector loads; 16 sparse dots; 32 measured executed
  and 32 measured skipped INT8 multiplications.
- `result.json` is versioned as `sparrowv_external_sensor_result_v1`; measured,
  derived, and unavailable counter states are explicit. Simulation assertion or
  trap failures write a failure result where workspace generation succeeded.

## Final review

- Diff review: clean (`git diff --check`). No remaining implementation issues.
- Reference core: unchanged and still protected; experimental pipeline remains
  unpromoted.
- Commit safety: no commit or push occurred.
