# Phase Dependencies

The following map records planning dependencies; arrows mean the upstream decision must be approved before the downstream phase can claim a stable interface.

```text
Phase 0 decision records
  ├─ scalar pipeline / provenance / RV32I subset / reset
  │    └─ Phase 1 scalar core
  │         └─ Phase 2 C bring-up (program image, traps, runtime ABI)
  ├─ custom opcode allocation + blocking extension protocol
  │    └─ Phase 3 extension interface
  │         └─ vector state + arithmetic/tail/mask semantics
  │              └─ Phase 4 dense vector engine + Python model
  ├─ scratchpad capacity/addressing/arbitration/ordering
  │    └─ Phase 5 vector LSU and bank-conflict tests
  ├─ 2:4 metadata packing/transport/invalid-data behavior
  │    └─ Phase 6 sparse execution + exporter
  ├─ benchmark workload and model boundary
  │    └─ Phase 7 end-to-end evaluation
  └─ FPGA part, ASIC flow/PDK, clocks, configuration sweeps
       └─ Phase 9 implementation results

Phases 1–7 verified behavior and Phase 8 regression evidence
  └─ Phase 10 final evaluation and claims
```

## Blocking decisions by phase

| Phase | Required frozen decisions | Not blocked by |
| --- | --- | --- |
| 1 — Scalar core | ADR-001, ADR-002; RV32I subset/trap/reset details captured in ADR-001/002 consequences | Sparse format, benchmark choice, physical targets |
| 2 — C bring-up | Phase 1 architectural contract; linker/load-image and exit ABI | Vector datapath details |
| 3 — Extension interface | ADR-003, ADR-004 | Scratchpad arbitration and sparse packing |
| 4 — Dense vector | ADR-004, ADR-005, ADR-006 | Sparse metadata and benchmark selection |
| 5 — Scratchpad | ADR-007, ADR-008 | Sparse metadata format |
| 6 — Sparse execution | ADR-005, ADR-006, ADR-009 | FPGA/ASIC target choice |
| 7 — Workload | ADR-010 and prior functional phases | Board demonstration |
| 9 — FPGA/ASIC | ADR-011 plus a stable verified RTL configuration | Optional tinyNPU comparison |
