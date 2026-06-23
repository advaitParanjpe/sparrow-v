# Sparrow-V Final Results

This is the canonical source for headline results. Values below are measured
unless marked **derived**. Sparrow-V is an experimental prototype, not a full
RVV processor, production CPU, timing-closed ASIC, or power measurement.

## Functional workload

The deterministic 16-input, four-output INT8 fully connected workload has
golden output `[382, -446, -246, 1054]`. All three implementations produce it.
The measured interval runs from reset release through completion-signature
retirement and includes deterministic scratchpad preload.

| Metric | Scalar | Dense vector | Sparse vector | Source / definition |
| --- | ---: | ---: | ---: | --- |
| Cycles | 7,399 | 484 | 484 | Measured by `tb_workload_fc`. |
| Retired instructions | 3,948 | 109 | 109 | Measured retirement trace. |
| Dot instructions | 0 | 16 `VDOT8` | 16 `VSDOT8` | Measured retirement count. |
| Multiplications executed | 64 | 64 | 32 | Scalar/dense are **derived** from fixed layer shape; sparse is measured completion-gated accounting. |
| Multiplications skipped | 0 | 0 | 32 | Measured sparse completion-gated accounting. |

Dense and sparse both take 484 cycles because they use the same fixed-latency,
blocking command/completion schedule. Sparse arithmetic reduction is not a
latency reduction in this implementation.

## Sensor fixture

`scripts/sensor_workload.py` runs 16 deterministic samples in each mode:
normal, inner, outer, and ball. Dense and sparse both achieve 16/16
fixture-correct predictions, with zero prediction disagreements. Each run
measures 484 cycles and 109 retired instructions. These are fixture results;
they do not establish general dataset accuracy.

## Storage accounting

The fixed layer and sensor fixture each use 64 dense INT8 weight bytes. Sparse
representation has 32 compressed weight bytes plus 48 packed metadata bits
(6 bytes): 38 bytes total. The 26-byte reduction is **derived** accounting,
or 40.625% including metadata. Biases are separate.

## Generic synthesis comparison

`make ppa-all` runs `scripts/ppa_flow.py` with Yosys 0.66 and generic `cmos2`
mapping. Cell totals are measured parser results from reproducible ignored
outputs under `results/ppa/`.

| Configuration | Core selection | Total cells |
| --- | --- | ---: |
| Scalar | protected `rv32_core` | 14,029 |
| Dense vector | experimental pipe + engine, sparse disabled | 62,928 |
| Sparse vector | experimental pipe + engine, sparse enabled | 65,691 |

Sparse adds 2,763 cells over dense, a **derived** 4.39% increase. The vector
register file and scratchpad map to generic flip-flops and muxes, not SRAM
macros. Logic-depth values are only structural proxies. There is no
characterized standard-cell area, STA/Fmax, physical implementation, signoff
power, or measured energy result.

## Provenance

| Claim | Producer | Configuration / units |
| --- | --- | --- |
| Workload outputs, cycles, retirements, vector events | `make test-workload-all` / `tb_workload_fc.sv` | scalar, dense, sparse; cycles and events. |
| Sensor predictions and per-sample events | `make test-sensor-all` / `tb_sensor_workload.sv` | 16 independent dense and sparse samples. |
| Storage and sparse reconstruction | `scripts/workload_fc.py --self-test`, `scripts/sensor_workload.py` | bytes/bits; derived percentage. |
| Cell totals and overhead | `make ppa-all` / `scripts/ppa_flow.py` | Yosys 0.66, generic `cmos2`; cells. |

Deterministic vector coverage uses VADD8 seed `0x13579bdf` (32 cases), VDOT8
seed `0x2468ace1` (32), vector memory seed `0x1234abcd` (24), and VSDOT8 seed
`0x5a17c0de` (96). See [verification plan](verification_plan.md).

## Claim boundary and future work

`rv32_core_pipe` remains experimental. The design has fixed 32-bit vectors,
one outstanding vector command, no full RVV, no compressed sparse-load,
no full compiler backend, no SRAM macro mapping, no physical timing closure,
and no measured power. Future research includes packed sparse transfers,
fused sparse operations, latency crossover points, adaptive sparsity and
hardware-aware pruning, SRAM-backed implementation, real datasets, and
SparrowML integration.
