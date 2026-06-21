# Phase 1.5 Scalar Audit

## Audit finding

The Phase 1 core is structurally IF/DX/MW but globally serializes instruction progress: instruction fetch is gated by `!mw_valid`, and the original DX path waited for MW to empty. Independent ALU work does not sustain one retirement per cycle.

## Targeted changes and remaining blocker

MW-to-DX forwarding and a simulation retirement trace were added. The trace contains PC, instruction, register write, store, trap fields, and stall counters. Attempting speculative instruction requests while MW completes exposed a genuine request-stability/control-redirect failure under backpressure; the safe fetch gate remains enabled until a request-buffer/flush protocol is designed and verified.

Phase 1.5 therefore does not certify the scalar core as ready for vector integration. Finish a request-buffered IF stage, demonstrate overlap through trace CPI tests, and compare every retirement event against the reference model before that decision.

## Warning classification

Icarus `constant selects in always_*` and `unique case ignored` messages are simulator limitations. `$error/$fatal cannot be synthesized` messages come from simulation assertions embedded in RTL/testbench; Verilator lint is the active checking flow. These should move to bindable assertion code before synthesis work.
