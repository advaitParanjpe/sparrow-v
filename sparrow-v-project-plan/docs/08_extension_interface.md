# Scalar-to-Vector Extension Interface

## Purpose

Provide a clean boundary between the RV32I scalar core and custom vector engine. The interface should be conceptually inspired by CV-X-IF without attempting full compliance in the first version.

## Issue channel

Inputs from scalar core:

- `issue_valid`;
- raw instruction or decoded operation;
- scalar source operands;
- program counter;
- scalar destination register index;
- optional transaction ID.

Outputs from vector engine:

- `issue_ready`;
- `issue_accept`;
- illegal-instruction indication.

## Completion channel

Outputs from vector engine:

- `result_valid`;
- scalar result data for reductions;
- scalar destination register index;
- exception/error indication;
- transaction ID if decoupled.

Input from scalar core:

- `result_ready`.

## Memory interaction

The vector engine may access the shared scratchpad through a dedicated vector LSU interface rather than routing all memory operations back through the scalar LSU.

## Initial blocking protocol

The first implementation may allow only one vector instruction in flight.

State sequence:

1. scalar decode presents instruction;
2. vector engine accepts;
3. scalar pipeline stalls;
4. vector engine executes;
5. result returns;
6. scalar pipeline resumes.

## Later decoupled protocol

Future work may support:

- multiple vector instructions in flight;
- scalar continuation while vector engine runs;
- explicit dependency checks;
- tagged completion;
- vector fences.

## Interface invariants

- An accepted issue must complete exactly once unless reset cancels it.
- A rejected instruction must not modify architectural state.
- Completion data must correspond to the accepted destination register.
- No vector state may change before issue acceptance.
- Backpressure must not drop issue or completion events.

