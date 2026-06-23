# Reproduction Guide

Run commands from the repository root. Required local tools are GNU Make,
Python 3, Icarus Verilog, and Verilator; `make ppa-all` also requires Yosys.
No compiler installation procedure is assumed or required by these flows.

## Quick reviewer path

```sh
make check
make test-vector-vsdot-all
make test-workload-all
make test-sensor-all
make ppa-all
```

These respectively validate repository/documentation hygiene, focused sparse
execution, the scalar/dense/sparse FC comparison, all 16 dense and sparse
sensor fixture runs, and generated generic-PPA reports.

## Full validation path

```sh
make check
make test-vector-regression
make test-workload-all
make test-sensor-all
make ppa-all
make test-full-regression
make lint
make docs-check
git diff --check
```

Successful simulation targets end with their testbench PASS indication. `make
ppa-all` writes `results/ppa/summary.json` and `results/ppa/comparison.md` and
reports the three generic cell totals. `make check` and `make docs-check`
report their respective checks passed. `git diff --check` is silent on success.

`make test-full-regression` is the aggregate final correctness command and
includes scalar and vector regressions, Python tests, lint, and repository/
documentation checks. Run it once after changes are stable; the preceding
commands isolate failures during development.

## Generated artifacts

Simulation images and executables are placed under `sim/build/`; PPA logs,
netlists, staged sources, JSON, and Markdown reports are under `results/ppa/`.
They are ignored reproducible outputs. PPA regeneration must not alter tracked
RTL, scripts, or documentation; inspect `git status --short` after a run.

The authoritative inputs are the checked-in RTL, testbenches, `scripts/`,
`config/ppa_configurations.json`, and `synth/yosys/manifests/`. See the
[source manifest](source_manifest.md) and [results provenance](final_results.md#provenance).
