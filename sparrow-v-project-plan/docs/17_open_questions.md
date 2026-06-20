# Open Questions

These decisions should be resolved explicitly. Codex must not silently choose and then spread assumptions through the codebase.

## Scalar core

- Three-stage or five-stage pipeline?
- New scalar core or adapted permissively licensed core?
- Exact RV32I instruction subset for first milestone?
- Trap behavior for illegal and misaligned instructions?
- Reset polarity?

## Vector ISA

- Exact custom opcode and funct fields?
- Tail policy for inactive vector elements?
- Masked-off element policy?
- Saturating or wrapping arithmetic?
- Exact accumulator width?
- Does `vdot` write a scalar register or vector register?

## Vector register file

- 8 or 16 registers?
- 128-bit or 64-bit initial width?
- Flop implementation or inferred memory?

## Sparse format

- Metadata passed in a scalar register, vector register, or memory stream?
- One sparse instruction per full architectural vector or per chunk?
- Canonical ordering of the two nonzero indices?
- Invalid metadata behavior?

## Memory

- Scratchpad size?
- Scalar-priority or round-robin arbitration?
- Separate scalar and vector address spaces or unified?
- Maximum outstanding vector memory operations?

## Software

- Initial application: vibration, keyword spotting, ECG, activity, or gesture?
- Precomputed features or raw-signal preprocessing on Sparrow-V?
- C macros or Python-generated assembly for first vector programs?

## Evaluation

- Which scalar baseline compiler optimization level?
- Which clock target for FPGA and ASIC-style flow?
- Which configuration sweeps are mandatory?
- Whether tinyNPU comparison is fair and in scope?

