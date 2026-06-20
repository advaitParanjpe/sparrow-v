# Scalar Core Requirements

## Baseline ISA

Implement RV32I instructions required for bare-metal integer programs:

- integer arithmetic and logic;
- shifts;
- comparisons;
- branches;
- jumps;
- upper-immediate operations;
- aligned loads and stores;
- minimal CSR support for counters and trap handling if needed.

The exact supported instruction list must be recorded in a machine-readable or tabular form before RTL implementation begins.

## Recommended pipeline

A simple three-stage or five-stage in-order pipeline is acceptable.

Recommended five-stage organization:

1. IF — instruction fetch;
2. ID — decode/register read;
3. EX — ALU/address/branch;
4. MEM — load/store access;
5. WB — register writeback.

A three-stage implementation is also acceptable if it simplifies bring-up:

1. fetch;
2. decode/execute;
3. memory/writeback.

## Hazards

The scalar core must explicitly handle:

- RAW dependencies;
- load-use hazards;
- branch redirects;
- register x0 invariance;
- writeback conflicts;
- extension-interface stalls;
- memory backpressure.

## Branch behavior

Version 1 may use:

- predict-not-taken;
- pipeline flush on taken branch or jump;
- no branch target buffer;
- no dynamic predictor.

## Memory behavior

Version 1 may require naturally aligned accesses.

Supported initially:

- `LB`, `LBU`, `LH`, `LHU`, `LW`;
- `SB`, `SH`, `SW`.

Unaligned accesses may trap or return an error; they should not silently produce incorrect results.

## CSR and counters

At minimum expose:

- cycle count;
- retired scalar instruction count;
- retired vector instruction count;
- scratchpad stall count;
- sparse operations skipped;
- vector busy cycles.

## Program loading

The simulation flow should support one of:

- `$readmemh` program image;
- ELF-to-hex conversion script;
- direct memory initialization from a generated binary.

## Scalar verification

Before integrating the vector unit, the scalar core must pass:

- instruction-level directed tests;
- branch and hazard tests;
- load/store tests;
- small assembly programs;
- at least one compiled C program;
- randomized differential tests against a software model if practical.

