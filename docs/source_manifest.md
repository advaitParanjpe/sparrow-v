# Source Manifest

This manifest distinguishes tracked source from reproducible generated output.
`make docs-check` validates every relative Markdown link in the repository.

## RTL ownership

- Production/reference scalar RTL: [`rtl/core/rv32_core.sv`](../rtl/core/rv32_core.sv), with shared decoder, ALU, immediate, register-file, and package sources in [`rtl/core/`](../rtl/core/) and [`rtl/common/`](../rtl/common/).
- Experimental scalar/vector pipeline: [`rtl/core/rv32_core_pipe.sv`](../rtl/core/rv32_core_pipe.sv). It is not the production core.
- Vector RTL: [`rtl/vector/rv32_vec_vadd_engine.sv`](../rtl/vector/rv32_vec_vadd_engine.sv) owns vector registers, scratchpad, VADD8, VDOT8, VSDOT8, and vector transfers; [`rv32_vec_stub_engine.sv`](../rtl/vector/rv32_vec_stub_engine.sv) is the protocol endpoint used by focused adapter tests.
- Synthesis wrappers: [`rtl/top/sparrowv_ppa_tops.sv`](../rtl/top/sparrowv_ppa_tops.sv), with configuration in [`config/ppa_configurations.json`](../config/ppa_configurations.json) and source manifests in [`synth/yosys/manifests/`](../synth/yosys/manifests/).

## Verification and software

- Integration testbenches: [`tb/integration/`](../tb/integration/), including scalar, differential, vector, workload, and sensor benches.
- Python unit/repository tests: [`tb/tests/`](../tb/tests/); independent RV32I helper: [`python/verification/rv32i_reference.py`](../python/verification/rv32i_reference.py).
- Workload encoder and golden model: [`scripts/workload_fc.py`](../scripts/workload_fc.py).
- Sensor export: [`scripts/sensor_workload.py`](../scripts/sensor_workload.py), with checked-in deterministic fixture assets in [`python/sparrowv_model/`](../python/sparrowv_model/).
- PPA flow and repository checks: [`scripts/ppa_flow.py`](../scripts/ppa_flow.py) and [`scripts/check_repo.py`](../scripts/check_repo.py).

## Documentation

- Landing page: [`README.md`](../README.md); architecture: [`architecture.md`](architecture.md); results: [`final_results.md`](final_results.md); reproduction: [`reproduction.md`](reproduction.md); release gates: [`release_readiness.md`](release_readiness.md).
- Detailed architecture: [`docs/architecture/`](architecture/); verification: [`verification_plan.md`](verification_plan.md); implementation status: [`implementation_status.md`](implementation_status.md); milestone record: [`milestone_history.md`](milestone_history.md).
- Original planning material is preserved in [`sparrow-v-project-plan/`](../sparrow-v-project-plan/); it is historical input, not a claim that every planned feature was implemented.

## Generated and ignored output

- [`sim/build/`](../sim/build/) contains generated images and simulation executables.
- [`results/ppa/`](../results/ppa/) contains regenerated Yosys logs, netlists, metadata, JSON, and Markdown comparison reports.
- These outputs are intentionally untracked. Regenerate them with the commands in [`reproduction.md`](reproduction.md).
