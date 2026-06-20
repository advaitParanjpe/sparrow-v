# Phase 0 Repository Setup Report

## Scope

This report records Phase 0 repository audit, planning validation, and scaffolding only. No functional RTL, testbench, model, software runtime, synthesis configuration, FPGA build, ASIC build, timing result, or benchmark result has been added.

## Source preservation

All original Markdown planning documents remain in `sparrow-v-project-plan/`. No planning document was moved or substantially rewritten. `docs/source_manifest.md` indexes every original Markdown source and the new derived documents.

## Scaffold added

- Future source partitions: `rtl/`, `tb/`, `sim/`, `sw/`, `python/`, `scripts/`, `synth/`, `constraints/`, `fpga/`, `openlane/`, `results/`, `config/`, and `third_party/`.
- Phase 0 project documents, open-issue audit, dependency map, and eleven Proposed ADRs.
- Standard-library repository checker with a real Python unit-test suite.
- Make targets for structural/documentation checks and truthful status output.

## Validation scope

`make check` and `make docs-check` validate only repository structure and documentation hygiene. They check required paths, required documentation, placeholder markers, source-manifest links, and accidental generated output patterns. They explicitly do not run RTL simulation or claim implementation status. `make test` runs unit tests for the checker itself.

## Unresolved items

The decision records are Proposed because the supplied plans intentionally leave material architecture and evaluation choices open. The Phase 0 roadmap's specification-freeze gate is therefore not fully met until the relevant ADRs are reviewed and accepted.
