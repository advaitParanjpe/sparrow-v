# Phase 1.7 Pipeline Proof

## Measured result

`tb_scalar_pipeline` runs 16 independent `addi` instructions with always-ready instruction memory and a one-cycle instruction response. It records retirement activity from the core trace.

| Metric | Result |
| --- | ---: |
| Cycles to terminal ECALL trap | 52 |
| Normal instructions retired | 16 |
| Approximate CPI | 3.25 |
| Maximum consecutive retirement cycles | 1 |
| Target | CPI near 1; consecutive retirement run at least 4 |

The test fails intentionally because the target is not met. This proves the implementation is not a sustained overlapping IF/DX/MW pipeline.

## Root cause

The new request/epoch state protects protocol stability and stale responses, but the execution control still only permits progress through a single IF/DX/MW handoff pattern. It lacks an explicit response/skid buffer and centralized simultaneous IF-to-DX, DX-to-MW, and MW-retire transfer logic. A targeted local fix would be unsafe because retirement, forwarding, redirect, and valid-bit control must change together.

## Decision

Stop Phase 1.7 incomplete. A scalar-only pipeline-control redesign is required before vector integration: add explicit IF response buffering, compute all stage ready/valid transfers centrally, make flush precedence explicit, and then rebuild trace/reference and randomized verification around that control.
