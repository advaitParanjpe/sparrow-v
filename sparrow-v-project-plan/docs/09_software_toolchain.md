# Software Toolchain

## Goals

The software flow should make Sparrow-V usable rather than a testbench-only processor.

## Components

### RISC-V cross compiler

Use an existing RV32 bare-metal toolchain where possible.

### Linker script and startup code

Provide:

- reset entry;
- stack setup;
- `.data` initialization;
- `.bss` zeroing;
- call to `main`;
- simulation exit mechanism.

### Vector instruction helpers

Initially provide:

- assembler macros;
- inline assembly wrappers;
- C intrinsic-like functions.

### Python architectural model

The model should implement:

- scalar instruction reference behavior where practical;
- vector register state;
- dense vector operations;
- sparse metadata decode;
- sparse dot products;
- memory image generation;
- expected-output generation.

### Quantization and pruning exporter

The exporter should:

- load or accept model weights;
- quantize to INT8/INT16;
- apply 2:4 pruning;
- pack values and metadata;
- write C headers and binary files;
- produce accuracy and sparsity summaries.

## End-to-end application options

Prioritized options:

1. vibration-fault classification;
2. keyword spotting from precomputed MFCCs;
3. ECG anomaly classification;
4. activity recognition;
5. gesture classification.

The first application should be small enough to run entirely in bare-metal simulation.

## Reproducibility

Every software stage should have a documented command:

```text
train or load model
quantize
prune
export
compile
simulate
compare output
report metrics
```

## Version 1 simplifications

- No custom LLVM/GCC backend.
- No operating system.
- No dynamic memory allocation unless needed.
- No floating-point runtime.
- Precomputed input features are acceptable for the first IoT demo.

