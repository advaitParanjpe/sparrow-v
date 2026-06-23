# Release Readiness Checklist

- [ ] Start from a clean working tree before creating a human-reviewed release commit or tag.
- [x] README describes the project, architecture, verification, results, reproduction, and limitations.
- [x] Repository-native Mermaid architecture and sparse-dataflow diagrams are present in `docs/architecture.md`.
- [x] Canonical metrics and claim boundaries are consolidated in `docs/final_results.md`.
- [x] Stable scalar/vector/workload/sensor/PPA/lint/check/documentation targets are documented.
- [x] Source manifest identifies reference, experimental, vector, synthesis, verification, workload, sensor, documentation, and ignored-output ownership.
- [x] Generated artifacts are ignored; no `.DS_Store` is tracked or present.
- [x] Relative Markdown links are checked by `make docs-check`.
- [x] No secrets or personal data were identified in the tracked project content during the final cleanup audit.
- [x] Full validation path in `docs/reproduction.md` passed for this milestone; rerun it on the exact intended release tree before tagging.
- [ ] Confirm no unexpected tracked changes remain, then perform human review and create any version tag manually.

The unchecked items are deliberate release-process gates. This checklist does
not authorize commits, tags, or pushes.
