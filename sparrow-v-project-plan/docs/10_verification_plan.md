# Verification Plan

## Verification philosophy

The project must use layered verification. Passing an end-to-end program is not sufficient evidence for individual RTL blocks.

## Test levels

### Unit tests

Test independently:

- scalar ALU;
- scalar decoder;
- register file;
- scalar LSU;
- vector register file;
- vector ALU;
- vector multiplier;
- dot-product unit;
- reduction unit;
- sparse metadata decoder;
- sparse dot unit;
- banked scratchpad;
- extension interface.

### Subsystem tests

- scalar pipeline instruction tests;
- dense vector instruction tests;
- sparse vector instruction tests;
- scalar/vector scratchpad arbitration;
- blocking extension issue and completion;
- stalls and backpressure.

### System tests

- assembly programs;
- compiled C programs;
- dense and sparse kernels;
- full IoT workload;
- randomized memory stalls;
- reset and error scenarios.

## Golden models

Use Python for:

- vector arithmetic;
- dot products;
- reductions;
- sparse reconstruction;
- sparse dot equivalence;
- expected memory images;
- end-to-end model output.

## Scoreboards

The testbench should track:

- accepted scalar instructions;
- register-file architectural state;
- vector-register architectural state;
- scratchpad contents;
- scalar/vector completion ordering;
- performance counters.

## Assertions

Required categories:

- valid/ready stability;
- no write to scalar x0;
- no vector register write without accepted instruction;
- accepted vector instruction completes exactly once;
- no duplicate completion;
- scratchpad response corresponds to request;
- no two vector destination writes collide;
- sparse metadata indices are valid;
- sparse actual multiply count does not exceed dense-equivalent count;
- reset clears outstanding operations;
- no architectural update from illegal instruction.

## Functional coverage

Cover:

- every scalar opcode;
- every vector opcode;
- INT8 and INT16 modes;
- every vector register as source/destination;
- partial vector lengths;
- mask patterns;
- scratchpad bank conflicts;
- scalar/vector arbitration outcomes;
- sparse metadata patterns;
- positive/negative/zero operands;
- overflow and sign-extension cases;
- backpressure combinations.

## Randomized testing

Generate randomized:

- vector instruction streams;
- operand values;
- vector lengths;
- sparse metadata;
- scratchpad delays;
- issue backpressure;
- result backpressure.

Random tests must be reproducible with logged seeds.

## Regression

Provide a single command that runs:

- lint or syntax checks;
- unit tests;
- subsystem tests;
- system tests;
- randomized seeds;
- summary report.

