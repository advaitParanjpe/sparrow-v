# Milestone: External Sensor Workload Interface for SparrowML Integration

## Objective

Add a small, documented, source-controlled external-workload interface to Sparrow-V so another repository can execute the existing dense and sparse sensor RTL paths using externally supplied model and sample data.

This milestone must:

1. preserve the existing checked-in sensor fixture workflow;
2. accept an external 16-feature INT8 sample;
3. accept an external dense INT8 `Linear(16, 4)` model;
4. accept an external compressed 2:4 INT8 `Linear(16, 4)` model;
5. generate all testbench inputs in an isolated workspace;
6. invoke the existing dense and sparse RTL simulation paths;
7. emit machine-readable architectural results and counters;
8. make no RTL, ISA, or architectural behavior changes;
9. provide stable commands for SparrowML to invoke later.

This is an integration-interface milestone, not a new workload, model-training, compiler, or RTL-design milestone.

## Current Existing Interfaces

The existing Sparrow-V repository already provides:

- `make test-sensor-rtl-dense`
- `make test-sensor-rtl-sparse`
- `scripts/sensor_workload.py`
- `tb/integration/tb_sensor_workload.sv`
- checked-in fixture files under `python/sparrowv_model/`

The current workflow always consumes the Sparrow-V-owned fixture.

Preserve all current commands and results.

## Repository Boundary

Sparrow-V owns:

- RTL execution;
- testbench behavior;
- instruction semantics;
- architectural counters;
- workload file generation required by the testbench.

External tools own:

- model training;
- quantization;
- pruning;
- deployment-package production;
- expected-output calculation.

This milestone must not copy SparrowML code into Sparrow-V.

## Supported External Model Scope

Support exactly:

### Dense

- input: 16 signed INT8 features;
- weights: shape `[4, 16]`, signed INT8;
- biases: four signed INT32 values;
- four output accumulators;
- existing dense dot-product execution path.

### Sparse

- input: 16 signed INT8 features;
- compressed weights: 32 signed INT8 values;
- metadata: 16 legal three-bit 2:4 codes;
- biases: four signed INT32 values;
- four output accumulators;
- existing sparse dot-product execution path.

Do not add arbitrary dimensions, layers, dynamic shapes, new operators, or general model support.

## External Input Contract

Define a versioned input manifest, preferably JSON:

```text
sparrowv_external_sensor_workload_v1
```

It must include:

- format version;
- execution mode: `dense_int8` or `sparse_2of4_int8`;
- sample ID;
- class names;
- input INT8 values;
- dense weights or compressed sparse weights;
- sparse metadata when applicable;
- INT32 biases;
- optional expected accumulators for testbench self-checking;
- optional source package identity.

Validate:

- exactly 16 inputs;
- exactly 64 dense weights;
- exactly 32 sparse weights;
- exactly 16 sparse metadata values;
- exactly four biases;
- signed integer ranges;
- legal metadata values only;
- no absolute-path requirements inside the manifest.

## CLI

Extend the existing workload generator or add a narrowly scoped script.

Preferred interface:

```bash
python3 scripts/sensor_workload.py \
  --external-manifest /path/to/workload.json \
  --workspace /path/to/workspace \
  --emit
```

Execution may be exposed through a wrapper such as:

```bash
python3 scripts/run_external_sensor_workload.py \
  --manifest /path/to/workload.json \
  --workspace /path/to/workspace
```

or stable Make targets:

```bash
make test-sensor-rtl-external-dense \
  SENSOR_MANIFEST=/path/to/workload.json \
  SENSOR_WORKSPACE=/path/to/workspace
```

```bash
make test-sensor-rtl-external-sparse \
  SENSOR_MANIFEST=/path/to/workload.json \
  SENSOR_WORKSPACE=/path/to/workspace
```

Choose the smallest design that reuses the existing implementation cleanly.

## Isolated Workspace

All generated files must be written beneath the explicitly supplied workspace.

Requirements:

- do not overwrite checked-in fixture files;
- do not modify tracked source files;
- reject unsafe workspace paths if necessary;
- dense and sparse workspaces may coexist;
- remove or overwrite stale generated outputs deterministically;
- document generated file names.

## Existing RTL and Testbench

Reuse the existing:

- processor RTL;
- vector execution paths;
- dense instruction semantics;
- sparse instruction semantics;
- integration testbench;
- simulator commands.

Do not modify RTL unless a genuine pre-existing bug prevents the documented fixed fixture from functioning. Such a discovery is a blocker requiring human review.

A testbench-only parameterization is permitted only if required to point it at workspace-generated files and it does not alter architectural behavior. Prefer plusargs, parameters, environment variables, or generated include/data paths over source rewriting.

## Machine-Readable Result

Emit a result file such as:

```text
result.json
```

with version:

```text
sparrowv_external_sensor_result_v1
```

Include:

- execution mode;
- sample ID;
- simulator exit status;
- termination reason;
- four signed INT32 accumulators;
- predicted class if already computed by the runtime;
- expected accumulators if supplied;
- exact-match status if self-checking is enabled;
- cycles;
- retired instructions;
- vector loads;
- vector stores;
- dense dot-product count;
- sparse dot-product count;
- measured executed/skipped multiplication counters if available;
- clearly labelled derived counters otherwise;
- trap/assertion status.

Do not invent counters that the current design does not expose.

## Stdout Contract

Also print concise parseable marker lines for debugging, for example:

```text
SPARROWV_RESULT mode=dense_int8 sample_id=...
SPARROWV_ACCUMULATORS a0=... a1=... a2=... a3=...
SPARROWV_COUNTER cycles=...
SPARROWV_STATUS PASS
```

The JSON result is canonical; stdout markers are secondary.

## Existing Workflow Preservation

The following must remain unchanged and passing:

```bash
make test-sensor-rtl-dense
make test-sensor-rtl-sparse
```

The checked-in fixture remains the default when no external manifest is supplied.

## Tests

Add focused tests for:

- dense external manifest validation;
- sparse external manifest validation;
- invalid dimensions;
- invalid integer ranges;
- invalid sparse metadata;
- deterministic generated files;
- isolated workspace behavior;
- no tracked fixture overwrite;
- dense real RTL execution;
- sparse real RTL execution;
- exact accumulator reporting;
- result JSON schema;
- missing counter handling;
- existing fixture regression.

Tests must not require internet, GPU, synthesis, FPGA, OpenLane, or SparrowML.

## Documentation

Update:

- README sensor workload section;
- relevant workload/testbench documentation;
- Make help;
- source manifest if required.

Document:

- external manifest schema;
- supported dimensions;
- dense and sparse commands;
- workspace behavior;
- result schema;
- measured versus derived counters;
- repository-boundary guarantee;
- exact reproduction examples.

## Validation

Run:

```bash
python3 -m compileall scripts python
pytest
make test-sensor-rtl-dense
make test-sensor-rtl-sparse
make test-sensor-rtl-external-dense
make test-sensor-rtl-external-sparse
make check
git diff --check
```

Use small deterministic manifests derived from the existing checked-in fixture for repository-local external-interface tests.

## Acceptance Criteria

The milestone is complete only when:

1. A versioned external workload manifest exists.
2. Dense external models are supported.
3. Sparse external models are supported.
4. Inputs are validated.
5. Weights are validated.
6. Biases are validated.
7. Sparse metadata is validated.
8. External files are generated in an isolated workspace.
9. Checked-in fixture files are not overwritten.
10. Existing dense fixture regression passes.
11. Existing sparse fixture regression passes.
12. External dense RTL simulation passes.
13. External sparse RTL simulation passes.
14. Four INT32 accumulators are emitted.
15. A versioned JSON result is emitted.
16. Simulator failures are reported clearly.
17. Traps and assertion failures are reported.
18. Available counters are emitted.
19. Missing counters are labelled unavailable.
20. Derived counters are labelled derived.
21. No RTL change is made.
22. No ISA change is made.
23. No architectural behavior change is made.
24. No SparrowML dependency is added.
25. Documentation is complete.
26. `make check` passes.
27. `git diff --check` passes.
28. No commit or push occurs.
29. The milestone result file is finalized.

## Stop Conditions

Stop for human review only if:

- the existing testbench cannot consume workspace-generated files without an RTL or ISA change;
- current dense or sparse fixture regressions fail before changes;
- external execution reveals a genuine RTL correctness defect;
- simulator tools are unavailable;
- the smallest interface would require modifying architectural behavior.

Ordinary CLI, manifest, workspace, testbench-path, parsing, counter, and documentation issues are not stop conditions.

## Token Efficiency

- inspect only the current sensor workload generator, Make targets, integration testbench, directly instantiated modules, and relevant docs;
- do not audit unrelated CPU, vector, synthesis, FPGA, or ASIC flows;
- reuse the current fixture generation path;
- avoid generalizing beyond 16 inputs and 4 outputs;
- run focused tests first and aggregate checks once;
- do not commit or push.

## Result File

Finalize the repository’s tracked milestone result with:

```text
STATUS: COMPLETE
```

only if the external dense and sparse RTL executions succeed.

Include:

- chosen CLI and manifest schema;
- generated workspace files;
- dense command and result;
- sparse command and result;
- emitted accumulators;
- counter availability;
- existing fixture regression results;
- changed files;
- confirmation of no RTL/ISA changes;
- remaining limitations;
- confirmation that no commit or push occurred.