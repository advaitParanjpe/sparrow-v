# Vector Microarchitecture

## Baseline datapath

- 4 physical execution lanes.
- 128-bit vector registers.
- INT8 mode processes 16 elements per architectural vector.
- INT16 mode processes 8 elements per architectural vector.
- Execution may iterate over elements when architectural width exceeds physical lane count.

## Vector register file

Initial configuration:

- 8 registers;
- 128 bits each;
- two read ports and one write port conceptually;
- implementation may use flops initially, then infer memory if beneficial.

Required behaviors:

- deterministic reads;
- no write to unintended registers;
- correct read-after-write timing;
- mask register access;
- reset policy documented.

## Issue path

The vector issue unit receives:

- decoded operation;
- source and destination vector indices;
- scalar operands;
- element mode;
- vector length;
- sparse metadata pointer or immediate;
- instruction tag if decoupled completion is later supported.

## Execution units

### Vector ALU

Handles:

- add;
- subtract;
- min/max;
- compares;
- mask generation.

### Vector multiply unit

Handles signed INT8/INT16 multiplication. Implementation may be:

- one multiplier per lane;
- time-multiplexed multiplier resources;
- parameterized for PPA studies.

### Dot-product unit

Computes lane products and reduction accumulation. It should expose the accumulation width explicitly and avoid silent truncation.

### Reduction unit

Supports sum and max reductions across the active vector length.

### Sparse unit

Consumes compressed values and metadata, selects the corresponding dense operands, and forwards only valid nonzero products to the dot-product reduction path.

## Scoreboarding

Version 1 may block scalar issue until a vector instruction completes.

A later decoupled version should track:

- busy vector destination registers;
- scalar destination register for reductions;
- vector source dependencies;
- structural hazards;
- vector load/store completion.

## Latency model

Each operation must have a documented latency.

Example initial targets:

- `vadd`, `vsub`, compare: 1–4 cycles depending on strip mining;
- `vmul`: multi-cycle across vector chunks;
- `vdot`: chunked multiply-reduce;
- `vld`, `vst`: dependent on scratchpad bank conflicts;
- `vspdot`: metadata decode plus sparse multiply-reduce.

Correctness is more important than single-cycle execution.

## Parameterization

Parameters should include:

- lane count;
- vector register width;
- vector register count;
- supported element widths;
- multiplier count;
- scratchpad bank count.

Parameter values must be validated with elaboration-time checks.

