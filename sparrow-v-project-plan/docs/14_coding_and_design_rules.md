# Coding and Design Rules

## RTL rules

- Use synthesizable SystemVerilog only under `rtl/`.
- Use `logic` rather than legacy `reg`.
- Use `always_ff` and `always_comb` appropriately.
- Provide default assignments in combinational blocks.
- Avoid inferred latches.
- Use nonblocking assignments in sequential logic.
- Keep reset behavior explicit.
- Do not rely on simulator-specific initialization for architectural state.
- Keep widths explicit; avoid unsized signed constants in arithmetic.
- Document signedness at module boundaries.
- Add elaboration checks for invalid parameters.
- Prefer ready/valid interfaces for backpressured channels.
- Do not silently drop requests under backpressure.
- Separate datapath from control where it improves clarity.

## State-machine rules

- Enumerate states with descriptive names.
- Document transition conditions.
- Define behavior under reset from every state.
- Add assertions for illegal states where practical.

## ISA rules

- One canonical encoding table.
- One canonical semantics document.
- RTL, Python model, and software wrappers must derive from or match the same definitions.
- No undocumented custom instruction variants.

## Verification rules

- Every bug fix requires a regression test.
- Every randomized failure must log its seed.
- Scoreboards must compare architectural behavior, not internal implementation details.
- Assertions should check invariants continuously.
- No correctness claim from waveform inspection alone.

## Software rules

- Use type hints in Python where reasonable.
- Keep generated artifacts out of source directories.
- Provide deterministic seeds.
- Fail loudly on invalid sparse metadata or unsupported dimensions.
- Validate exported binary sizes and alignments.

## Documentation rules

- Update architecture docs when interfaces change.
- Record major decisions in an ADR or changelog.
- Keep results tied to exact configuration and tool version.
- Clearly label planned, implemented, verified, and measured features.

