# Generic Synthesis and PPA Evaluation

This is an implementation-cost study, not a physical-design or tapeout claim.
Run `make ppa-all` to regenerate `results/ppa/summary.json`,
`results/ppa/comparison.md`, and per-configuration Yosys logs, statistics,
netlists, commands, and staged frontend sources. The directory is ignored
because netlists and logs are reproducible tool output; the checked-in inputs
are `config/ppa_configurations.json`, `synth/yosys/manifests/*.f`, synthesis
tops, and `scripts/ppa_flow.py`.

## Configurations

| Configuration | Top | Sources | Selection |
| --- | --- | --- | --- |
| Scalar | `sparrowv_ppa_scalar_top` | `scalar.f` | protected `rv32_core`; vector RTL is not read |
| Dense | `sparrowv_ppa_dense_top` | `dense.f` | `rv32_core_pipe` and vector engine with `ENABLE_SPARSE=0` |
| Sparse | `sparrowv_ppa_sparse_top` | `sparse.f` | `rv32_core_pipe` and vector engine with `ENABLE_SPARSE=1` |

The scalar baseline is the protected reference core. Dense and sparse use the
same experimental scalar pipeline, so scalar-to-vector overhead must be read
with the microarchitecture difference clearly in mind. The dense parameter
removes the VSDOT8 branch, metadata validation, sparse arithmetic, and sparse
accounting from the elaborated endpoint. All three configurations have ordered
manifests and synthesis-only tops; no testbench source is read.

## Flow and limits

Yosys 0.66 elaborates, flattens, infers/maps memories, maps combinational
logic with the generic `cmos2` gate set, emits `stat -json`, and runs `ltp`.
The repository's package/import and immediate simulation assertions are staged
into a semantically equivalent Yosys-compatible frontend copy only; original
RTL and normal simulations are unchanged. No black boxes or latches are
accepted by the flow.

The recorded 10 ns (100 MHz) and 20 ns targets are common reporting
constraints. No characterized Liberty library, STA engine, or activity data is
available, so worst slack, Fmax, dynamic/leakage power, and mapped area are
`N/A`. `ltp` cell depth is a technology-independent logic-depth proxy, not a
timing result. The 32x32-bit vector register file plus 256x8-bit scratchpad
are 3072 bits and map to generic flip-flops/muxes, not SRAM macros.

## Results

The current generated comparison reports 14,029 scalar, 62,928 dense, and
65,691 sparse generic cells. Dense is +48,899 cells (+348.56%) versus the
reference scalar baseline; sparse is +2,763 cells (+4.39%) versus dense and
+51,662 (+368.25%) versus scalar. The generated report is authoritative for
tool-version-specific detail.

At the 100 MHz reporting assumption, the measured FC cycles yield derived
latencies of 73,990 ns scalar and 4,840 ns dense/sparse. The dense and sparse
workloads both take 484 cycles because VDOT8 and VSDOT8 use the same fixed
command/completion latency and schedule. Sparse halves observed multiply work
(32 executed, 32 skipped) and reduces FC weight-plus-metadata storage from 64
to 38 bytes, but does not currently reduce latency.

## Reproduction and functional checks

```sh
make synth-scalar
make synth-vector-dense
make synth-vector-sparse
make ppa-all
make test-config-scalar
make test-config-dense
make test-config-sparse
```

`test-config-dense` builds its vector tests with `SPARROWV_DENSE_ONLY`, which
sets the engine's default sparse parameter to zero without changing normal
simulation defaults. Physical implementation was not run because OpenLane,
OpenROAD, and a characterized open cell library are unavailable.
