# ADR-010: Benchmark Application Selection

## Status

Proposed.

## Context

The benchmark plan recommends vibration-fault classification with a small quantized MLP or 1D feature pipeline. The software plan lists vibration, keyword spotting, ECG, activity, and gesture options and permits precomputed features.

## Considered options

- Vibration-fault classification with precomputed features and a small quantized/pruned MLP.
- Keyword spotting using precomputed MFCCs.
- ECG, activity-recognition, or gesture-classification workload with documented input preprocessing.

## Decision

Not decided. Select one workload, dataset/license, model topology, quantization/pruning procedure, scalar/dense/sparse equivalence boundary, and reproducible reporting command before Phase 7.

## Consequences

The workload determines data sizes, scratchpad capacity pressure, supported kernels, accuracy metric, and fairness of comparisons.

## Unresolved questions

Will preprocessing run on the host, and is a tinyNPU comparison in scope and demonstrably fair?
