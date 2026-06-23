# Sensor Fixture Export and Inference

`python/sparrowv_model/sensor_fixture_model.json` and
`sensor_fixture_samples.json` define a deterministic, checked-in 16-input,
four-class sensor-classification deployment fixture. It is not trained from a
public dataset and its reported results are fixture accuracy, not general model
accuracy.

`make generate-sensor-workload` validates both files and regenerates ignored
`sim/build/sensor_*` artifacts. The generated manifest and report contain only
repository-relative paths. `make test-sensor-workload` reruns the Python
validation and independently executes every sample in dense and sparse form
through `rv32_core_pipe`; each simulation is reset and attributed separately.

The model layout is output-major `weights_int8[output][feature]`, with four
consecutive four-lane groups per output. INT8 lanes are packed little-endian.
Dense words are at scratchpad `0x10..0x4f`; compressed sparse words are at
`0x50..0x8f`; activations are at `0x00..0x0f`. Four signed INT32 logits are
stored at scalar data-memory `0x100..0x10f` and one completion signature is at
`0x1f0`.

Sparse projection selects the two greatest absolute values in each group. A
tie chooses the lower lane index. The selected lanes are sorted in ascending
lane order, so compressed byte 0 maps to the lower selected lane and byte 1 to
the higher lane, exactly matching `VSDOT8`. Metadata uses its six legal codes;
the 16 three-bit codes are packed little-endian by group, with group 0 at bits
`[2:0]`. This fixture has 64 dense weight bytes, 32 compressed-weight bytes,
48 metadata bits (6 bytes), zero padding bits, and 38 total sparse
weight-plus-metadata bytes: a 40.625% reduction, not 50%. Biases occupy a
separate 16 bytes.

Each dense sample executes 32 `VLOAD32`, 16 `VDOT8`, and 64 conceptual INT8
multiplications. Each sparse sample executes 32 `VLOAD32`, 16 `VSDOT8`, 32
observed executed multiplications, and 32 observed skipped multiplications.
The Python report verifies compressed sparse inference against decompressed
sparse inference; dense and sparse logits are deliberately allowed to differ.

## External workload interface

An external producer may submit one JSON manifest with
`format_version: "sparrowv_external_sensor_workload_v1"`. It is intentionally
limited to the existing RTL path: `execution_mode` is `dense_int8` or
`sparse_2of4_int8`; `sample_id`; four unique `class_names`; 16 signed
`input_int8` values; four signed `biases_int32`; and an optional four-value
`expected_accumulators_int32` self-check. `source_package_identity` is optional
but must be a non-absolute identifier. Dense manifests provide
`dense_weights_int8` as `[4][16]` signed INT8 values. Sparse manifests provide
`compressed_weights_int8` as `[4][4][2]` signed INT8 values and
`sparse_metadata` as `[4][4]` legal codes 0–5. No paths, dynamic dimensions,
layers, operators, training, pruning, or expected-output calculation are
accepted from the external package.

Generate only the workspace inputs with:

```sh
python3 scripts/sensor_workload.py --external-manifest /path/workload.json \
  --workspace /path/workspace --emit
```

Run the existing RTL testbench and produce `/path/workspace/result.json` with:

```sh
python3 scripts/run_external_sensor_workload.py --manifest /path/workload.json \
  --workspace /path/workspace
```

Equivalent stable Make targets are `make test-sensor-rtl-external-dense
SENSOR_MANIFEST=/path/workload.json SENSOR_WORKSPACE=/path/workspace` and
`make test-sensor-rtl-external-sparse` with the sparse manifest. With no
overrides, each target uses its matching source-controlled manifest under
`tb/fixtures/` and `sim/build/external-sensor`.

The workspace contains the selected program image (`sensor_dense.mem` or
`sensor_sparse.mem`), `sensor_dmem_0.mem`, `sensor_expected.svh`,
`external_workload.json`, simulator executable, and `result.json`. Known
generated names are deterministically replaced; no checked-in fixture is read
or overwritten. Dense and sparse workspaces can coexist by choosing different
paths.

`result.json` uses `format_version:
"sparrowv_external_sensor_result_v1"` and includes mode, sample ID, simulator
exit status, termination reason, four accumulators, predicted class, optional
expected accumulators and exact-match status, trap/assertion status, source
identity, and counters. `cycles`, retired instructions, vector loads/stores,
and dot counts are measured. Sparse executed/skipped multiplication events are
measured; dense conceptual multiplication count is explicitly `derived`; the
inapplicable counterpart is explicitly `unavailable`. The runner also prints
`SPARROWV_RESULT`, `SPARROWV_ACCUMULATORS`, `SPARROWV_COUNTER`, and
`SPARROWV_STATUS` markers. On a compile or simulation failure it still writes
`result.json` with failure status where workspace generation succeeded.

The repository owns only generation, testbench execution, and architectural
reporting. External tools retain training, quantization, pruning, package
production, and expected-output ownership. This interface adds no SparrowML
code or dependency and does not modify RTL, ISA, or architecture.
