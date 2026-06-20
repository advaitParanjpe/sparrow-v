# Memory System

## Initial architecture

Use separate instruction memory and data scratchpad interfaces.

The vector and scalar data paths share a banked scratchpad through an arbiter.

## Scratchpad configuration

Initial target:

- 4 banks;
- 32-bit bank width;
- parameterized depth;
- word-interleaved bank mapping;
- one request per bank per cycle;
- deterministic ready/valid interface.

Example mapping:

```text
bank = word_address mod NUM_BANKS
row  = word_address / NUM_BANKS
```

## Scalar accesses

Scalar loads and stores use one bank per operation.

## Vector accesses

A vector load/store may access several banks in the same cycle. Bank conflicts require serialization or replay.

The vector LSU must:

- compute element addresses;
- group requests by bank;
- issue conflict-free subsets;
- preserve element ordering;
- track completion;
- increment bank-conflict counters.

## Arbitration

Initial policy may prioritize scalar accesses to preserve simple program progress, or use round-robin arbitration. The policy must be documented and measured.

## Alignment

Version 1 should support naturally aligned scalar and vector element accesses.

Misaligned accesses may:

- trap;
- return an error;
- be explicitly unsupported.

They must not silently return incorrect data.

## Optional future cache

A cache is not required in the initial design. If later added, it should be treated as a separate architectural phase with its own verification and evaluation.

## Memory initialization

Simulation must support:

- instruction image loading;
- data image loading;
- model-weight loading;
- golden-output comparison.

## Performance counters

- scalar memory requests;
- vector memory requests;
- scratchpad bank conflicts;
- scalar stall cycles due to vector memory;
- vector stall cycles due to scalar memory;
- bytes loaded and stored;
- dense versus sparse weight bytes consumed.

