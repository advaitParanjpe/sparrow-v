# Custom Vector ISA

## Philosophy

Sparrow-V will not implement full RVV. It will define a compact custom ISA sufficient for quantized edge workloads while remaining small enough to implement and verify.

## Architectural state

Initial vector state:

- 8 vector registers: `v0` to `v7`;
- 128 bits per vector register;
- one mask register;
- configurable element mode: INT8 or INT16;
- optional vector length register for partial vectors.

## Instruction encoding

Use a custom RISC-V opcode space reserved for nonstandard extensions. The exact encoding must be documented in one central table and mirrored in:

- RTL decoder;
- assembler helper macros;
- Python model;
- tests.

Do not scatter magic bit fields across the codebase.

## Minimum instruction set

### Configuration

- `vsetmode` — set INT8 or INT16 element mode.
- `vsetlen` — set active element count.

### Memory

- `vld vd, (rs1)` — load contiguous vector.
- `vst vs, (rs1)` — store contiguous vector.

### Arithmetic

- `vadd vd, vs1, vs2`
- `vsub vd, vs1, vs2`
- `vmul vd, vs1, vs2`
- `vmax vd, vs1, vs2`
- `vmin vd, vs1, vs2`

### Dot and reductions

- `vdot rd, vs1, vs2` — signed dot product into scalar register.
- `vredsum rd, vs`
- `vredmax rd, vs`

### Masking

- `vcmpeq vm, vs1, vs2`
- `vcmpgt vm, vs1, vs2`
- masked variants may use the current mask register.

### Sparse execution

- `vspdot rd, vs_dense, vs_sparse_values, rs_meta`

The exact sparse operand encoding must be frozen before implementation.

## Arithmetic semantics

Every instruction must define:

- signedness;
- input width;
- intermediate width;
- output width;
- saturation or wraparound behavior;
- mask behavior;
- inactive-lane behavior;
- exception behavior.

Recommended initial policy:

- signed INT8 and INT16 operands;
- widening multiply;
- 32-bit dot-product accumulation;
- two's-complement wraparound for vector add/subtract unless saturation is explicitly added later.

## Partial vectors

Inactive elements beyond `vlen` must:

- preserve destination state, or
- be written with zero.

Choose one policy and test it consistently. Preserving destination state is closer to masked execution but requires more care.

## Assembly support

The first software interface may use:

- `.word` encodings;
- GNU assembler macros;
- inline assembly helper functions;
- C intrinsics implemented as inline wrappers.

A custom compiler backend is not required.

