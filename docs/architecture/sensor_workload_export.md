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
