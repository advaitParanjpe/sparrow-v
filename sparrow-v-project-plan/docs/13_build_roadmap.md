# Build Roadmap

## Phase 0 — Repository and specification freeze

Deliverables:

- repository skeleton;
- top-level Makefile;
- coding rules;
- architecture decision log;
- initial CI-style syntax checks;
- frozen scalar instruction subset;
- frozen custom opcode allocation.

Exit gate:

- documentation and source hierarchy agree;
- no RTL functionality claimed yet.

## Phase 1 — Scalar RV32I core

Deliverables:

- scalar datapath and control;
- instruction and data memory models;
- register file;
- branches, loads, stores;
- basic counters;
- directed instruction tests;
- small assembly programs.

Exit gate:

- core executes known programs correctly;
- all supported instructions are tested;
- no vector logic integrated.

## Phase 2 — C software bring-up

Deliverables:

- startup code;
- linker script;
- ELF/binary conversion;
- simulated console or exit mechanism;
- compiled C smoke test.

Exit gate:

- a C program runs and exits with an expected result.

## Phase 3 — Extension interface

Deliverables:

- custom instruction decode;
- scalar-to-vector issue interface;
- blocking completion interface;
- illegal-instruction handling;
- interface assertions.

Exit gate:

- dummy multi-cycle vector operation can be issued and completed safely.

## Phase 4 — Dense vector engine

Deliverables:

- vector register file;
- INT8/INT16 modes;
- vector add/subtract;
- vector multiply;
- dot product;
- reduction;
- masks;
- Python model;
- randomized vector tests.

Exit gate:

- all dense vector instructions match the model across randomized tests.

## Phase 5 — Banked scratchpad and vector LSU

Deliverables:

- multi-bank scratchpad;
- scalar/vector arbitration;
- contiguous vector load/store;
- bank-conflict handling;
- memory counters;
- stress tests.

Exit gate:

- scalar and vector accesses remain correct under stalls and conflicts.

## Phase 6 — Sparse execution

Deliverables:

- 2:4 metadata format;
- sparse decoder;
- sparse dot instruction;
- skipped-operation counters;
- dense-equivalence tests;
- Python exporter.

Exit gate:

- sparse results are bit-exact against reconstructed dense execution;
- actual multiply count is measurably reduced.

## Phase 7 — End-to-end IoT workload

Deliverables:

- selected model/workload;
- quantization;
- structured pruning;
- exported weights;
- bare-metal runtime;
- scalar, dense-vector, and sparse-vector execution;
- accuracy and cycle results.

Exit gate:

- one reproducible command produces all three execution modes and compares outputs.

## Phase 8 — Verification hardening

Deliverables:

- regression suite;
- assertions;
- coverage summary;
- randomized seeds;
- reset/backpressure/error tests;
- documented known limitations.

Exit gate:

- clean full regression with reproducible report.

## Phase 9 — FPGA and ASIC-style implementation

Deliverables:

- FPGA synthesis and timing;
- optional Basys3 demonstration;
- Yosys synthesis;
- OpenLane/OpenROAD flow;
- PPA results;
- parameter sweeps.

Exit gate:

- generated reports and artifact paths are documented;
- no unsupported timing-closure or signoff claims.

## Phase 10 — Final evaluation and presentation

Deliverables:

- benchmark tables;
- architecture diagrams;
- dense versus sparse comparison;
- area/performance tradeoff analysis;
- README polish;
- final report;
- CV-ready project bullets grounded in results.

