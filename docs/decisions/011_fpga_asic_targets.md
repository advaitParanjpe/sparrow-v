# ADR-011: FPGA and ASIC Target Strategy

## Status

Proposed.

## Context

The plan names Vivado with optional Basys3, and Yosys with OpenLane/OpenROAD, while leaving FPGA device, clock target, ASIC PDK/flow configuration, configuration sweeps, and artifact policy unspecified.

## Considered options

- Vivado synthesis for Basys3-compatible Artix-7 plus Yosys/OpenLane evaluation using an approved open PDK flow.
- Synthesis-only FPGA results for a selected supported device plus generic Yosys statistics.
- Parameterized reduced configuration for constrained FPGA, full configuration evaluated only in simulation/ASIC-style flow.

## Decision

Not decided. Freeze target part/board, top-level I/O contract, clocks/constraints, PDK/flow version, parameter configurations, and required reports before Phase 9.

## Consequences

No timing, area, power, board, or signoff claim is meaningful without these parameters and retained generated reports.

## Unresolved questions

Which open PDK is available in the intended environment, and which configurations must be compared for reproducible PPA results?
