PYTHON ?= python3

RTL_SOURCES := $(shell find rtl -name '*.sv' | sort)
SCALAR_TB := tb/integration/tb_scalar_core.sv
SIM_BUILD := sim/build

.PHONY: help check docs-check status test test-repo lint sim-scalar test-scalar test-scalar-directed test-scalar-random test-scalar-reference test-scalar-pipeline check-scalar-throughput-experiment test-scalar-pipe-dev test-scalar-pipe-alu test-scalar-pipe-forward test-scalar-pipe-control test-scalar-pipe-redirect test-scalar-pipe-memory test-scalar-pipe-trap test-scalar-pipe-store-retire test-scalar-pipe-vec-stub test-scalar-pipe-vec-cmd-stall test-scalar-pipe-vec-exception test-scalar-pipe-vec-no-writeback test-scalar-pipe-vec-reset test-scalar-pipe-vec-wrong-path test-scalar-pipe-vec-stub-all test-vector-regfile test-vector-vadd-directed test-vector-vadd-alias test-vector-vadd-backpressure test-vector-vadd-reset test-vector-vadd-random test-vector-vadd-invalid test-vector-vadd-all test-vector-vdot-directed test-vector-vdot-backpressure test-vector-vdot-reset test-vector-vdot-redirect test-vector-vdot-random test-vector-vdot-invalid test-vector-vdot-all test-vector-scratchpad test-vector-vmem-directed test-vector-vmem-backpressure test-vector-vmem-reset test-vector-vmem-redirect test-vector-vmem-errors test-vector-vmem-random test-vector-vmem-all test-vector-vsdot-patterns test-vector-vsdot-directed test-vector-vsdot-backpressure test-vector-vsdot-reset test-vector-vsdot-redirect test-vector-vsdot-invalid test-vector-vsdot-random test-vector-vsdot-all test-workload-encoder test-workload-golden test-workload-scalar test-workload-dense test-workload-sparse test-workload-compare test-workload-all generate-sensor-workload test-sensor-export test-sensor-rtl-dense test-sensor-rtl-sparse test-sensor-workload test-sensor-all test-scalar-diff-smoke test-scalar-diff-random test-scalar-diff-stall test-scalar-diff-seed test-scalar-diff-negative test-scalar-diff-redirect-backpressure test-scalar-diff-subword-directed test-scalar-diff-subword-random test-scalar-diff-subword-stall test-scalar-diff-subword-seed test-scalar-diff-subword-negative test-scalar-diff-store-retire test-scalar-diff-store-retire-negative test-scalar-regression test-vector-regression test-full-regression clean

help:
	@printf '%s\n' \
	  'Focused: test-scalar-directed, test-scalar-pipe-*, test-scalar-pipe-vec-stub-all' \
	  'VADD aliases: test-vector-regfile and test-vector-vadd-alias use test-vector-vadd-directed coverage' \
	  'Aggregates: test-scalar-regression, test-vector-regression, test-full-regression' \
	  'Checks: lint, check, docs-check' \
	  'Non-blocking expected-fail: check-scalar-throughput-experiment'

.PHONY: test-scalar-pipe-dev
test-scalar-pipe-dev:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_dev -o $(SIM_BUILD)/tb_scalar_pipe_dev.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_dev.sv
	$(SIM_BUILD)/tb_scalar_pipe_dev.vvp

test-scalar-pipe-alu:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_alu -o $(SIM_BUILD)/tb_scalar_pipe_alu.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_alu.sv
	$(SIM_BUILD)/tb_scalar_pipe_alu.vvp
	iverilog -g2012 -s tb_scalar_pipe_illegal -o $(SIM_BUILD)/tb_scalar_pipe_illegal.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_illegal.sv
	$(SIM_BUILD)/tb_scalar_pipe_illegal.vvp

test-scalar-pipe-forward:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_forward -o $(SIM_BUILD)/tb_scalar_pipe_forward.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_forward.sv
	$(SIM_BUILD)/tb_scalar_pipe_forward.vvp

test-scalar-pipe-control:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_control -o $(SIM_BUILD)/tb_scalar_pipe_control.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_control.sv
	$(SIM_BUILD)/tb_scalar_pipe_control.vvp

test-scalar-pipe-redirect:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_redirect -o $(SIM_BUILD)/tb_scalar_pipe_redirect.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_redirect.sv
	$(SIM_BUILD)/tb_scalar_pipe_redirect.vvp

test-scalar-pipe-memory:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_memory -o $(SIM_BUILD)/tb_scalar_pipe_memory.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_memory.sv
	$(SIM_BUILD)/tb_scalar_pipe_memory.vvp

test-scalar-pipe-trap:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_trap -o $(SIM_BUILD)/tb_scalar_pipe_trap.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_trap.sv
	$(SIM_BUILD)/tb_scalar_pipe_trap.vvp

test-scalar-pipe-store-retire:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_store_retire -o $(SIM_BUILD)/tb_scalar_pipe_store_retire.vvp rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv tb/integration/tb_scalar_pipe_store_retire.sv
	$(SIM_BUILD)/tb_scalar_pipe_store_retire.vvp

test-scalar-pipe-memory-stall: test-scalar-pipe-memory

VEC_STUB_RTL := rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core_pipe.sv rtl/vector/rv32_vec_stub_engine.sv
test-scalar-pipe-vec-stub:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=0 -o $(SIM_BUILD)/tb_scalar_pipe_vec_stub.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_stub.vvp
test-scalar-pipe-vec-cmd-stall:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=1 -o $(SIM_BUILD)/tb_scalar_pipe_vec_cmd_stall.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_cmd_stall.vvp
test-scalar-pipe-vec-cpl-stall:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=2 -o $(SIM_BUILD)/tb_scalar_pipe_vec_cpl_stall.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_cpl_stall.vvp
test-scalar-pipe-vec-exception:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=3 -o $(SIM_BUILD)/tb_scalar_pipe_vec_exception.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_exception.vvp
test-scalar-pipe-vec-no-writeback:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=4 -o $(SIM_BUILD)/tb_scalar_pipe_vec_no_writeback.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_no_writeback.vvp
test-scalar-pipe-vec-reset:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=5 -o $(SIM_BUILD)/tb_scalar_pipe_vec_reset.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_reset.vvp
test-scalar-pipe-vec-wrong-path:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipe_vec_stub -Ptb_scalar_pipe_vec_stub.MODE=6 -o $(SIM_BUILD)/tb_scalar_pipe_vec_wrong_path.vvp $(VEC_STUB_RTL) tb/integration/tb_scalar_pipe_vec_stub.sv
	$(SIM_BUILD)/tb_scalar_pipe_vec_wrong_path.vvp
test-scalar-pipe-vec-stub-all: test-scalar-pipe-vec-stub test-scalar-pipe-vec-cmd-stall test-scalar-pipe-vec-cpl-stall test-scalar-pipe-vec-exception test-scalar-pipe-vec-no-writeback test-scalar-pipe-vec-reset test-scalar-pipe-vec-wrong-path

VEC_VADD_RTL := $(VEC_STUB_RTL) rtl/vector/rv32_vec_vadd_engine.sv
test-vector-vadd-directed:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vadd -Ptb_vector_vadd.MODE=0 -o $(SIM_BUILD)/tb_vector_vadd.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vadd.sv
	$(SIM_BUILD)/tb_vector_vadd.vvp
test-vector-regfile: test-vector-vadd-directed
test-vector-vadd-alias: test-vector-vadd-directed
test-vector-vadd-random:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vadd -Ptb_vector_vadd.MODE=4 -o $(SIM_BUILD)/tb_vector_vadd_random.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vadd.sv
	$(SIM_BUILD)/tb_vector_vadd_random.vvp
test-vector-vadd-invalid:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vadd -Ptb_vector_vadd.MODE=5 -o $(SIM_BUILD)/tb_vector_vadd_invalid.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vadd.sv
	$(SIM_BUILD)/tb_vector_vadd_invalid.vvp
test-vector-vadd-backpressure:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vadd -Ptb_vector_vadd.MODE=1 -o $(SIM_BUILD)/tb_vector_vadd_cmd.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vadd.sv
	$(SIM_BUILD)/tb_vector_vadd_cmd.vvp
	iverilog -g2012 -s tb_vector_vadd -Ptb_vector_vadd.MODE=2 -o $(SIM_BUILD)/tb_vector_vadd_cpl.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vadd.sv
	$(SIM_BUILD)/tb_vector_vadd_cpl.vvp
test-vector-vadd-reset:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vadd -Ptb_vector_vadd.MODE=3 -o $(SIM_BUILD)/tb_vector_vadd_reset.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vadd.sv
	$(SIM_BUILD)/tb_vector_vadd_reset.vvp
test-vector-vadd-all: test-vector-regfile test-vector-vadd-directed test-vector-vadd-alias test-vector-vadd-backpressure test-vector-vadd-reset test-vector-vadd-random test-vector-vadd-invalid

test-vector-vdot-directed:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=0 -o $(SIM_BUILD)/tb_vector_vdot.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot.vvp
test-vector-vdot-backpressure:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=1 -o $(SIM_BUILD)/tb_vector_vdot_cmd.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot_cmd.vvp
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=2 -o $(SIM_BUILD)/tb_vector_vdot_cpl.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot_cpl.vvp
test-vector-vdot-reset:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=3 -o $(SIM_BUILD)/tb_vector_vdot_reset.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot_reset.vvp
test-vector-vdot-redirect:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=6 -o $(SIM_BUILD)/tb_vector_vdot_redirect.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot_redirect.vvp
test-vector-vdot-random:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=4 -o $(SIM_BUILD)/tb_vector_vdot_random.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot_random.vvp
test-vector-vdot-invalid:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vdot -Ptb_vector_vdot.MODE=5 -o $(SIM_BUILD)/tb_vector_vdot_invalid.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vdot.sv
	$(SIM_BUILD)/tb_vector_vdot_invalid.vvp
test-vector-vdot-all: test-vector-vdot-directed test-vector-vdot-backpressure test-vector-vdot-reset test-vector-vdot-redirect test-vector-vdot-random test-vector-vdot-invalid

test-vector-vsdot-patterns test-vector-vsdot-directed:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vsdot -Ptb_vector_vsdot.MODE=0 -o $(SIM_BUILD)/tb_vector_vsdot.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vsdot.sv
	$(SIM_BUILD)/tb_vector_vsdot.vvp
test-vector-vsdot-backpressure:
	@mkdir -p $(SIM_BUILD)
	@for mode in 1 2; do iverilog -g2012 -s tb_vector_vsdot -Ptb_vector_vsdot.MODE=$$mode -o $(SIM_BUILD)/tb_vector_vsdot_$$mode.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vsdot.sv && $(SIM_BUILD)/tb_vector_vsdot_$$mode.vvp || exit $$?; done
test-vector-vsdot-reset:
	@mkdir -p $(SIM_BUILD)
	@for mode in 3 4; do iverilog -g2012 -s tb_vector_vsdot -Ptb_vector_vsdot.MODE=$$mode -o $(SIM_BUILD)/tb_vector_vsdot_$$mode.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vsdot.sv && $(SIM_BUILD)/tb_vector_vsdot_$$mode.vvp || exit $$?; done
test-vector-vsdot-redirect:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vsdot -Ptb_vector_vsdot.MODE=5 -o $(SIM_BUILD)/tb_vector_vsdot_redirect.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vsdot.sv
	$(SIM_BUILD)/tb_vector_vsdot_redirect.vvp
test-vector-vsdot-invalid:
	@mkdir -p $(SIM_BUILD)
	@for mode in 6 8; do iverilog -g2012 -s tb_vector_vsdot -Ptb_vector_vsdot.MODE=$$mode -o $(SIM_BUILD)/tb_vector_vsdot_invalid_$$mode.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vsdot.sv && $(SIM_BUILD)/tb_vector_vsdot_invalid_$$mode.vvp || exit $$?; done
test-vector-vsdot-random:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vsdot -Ptb_vector_vsdot.MODE=7 -o $(SIM_BUILD)/tb_vector_vsdot_random.vvp $(VEC_VADD_RTL) tb/integration/tb_vector_vsdot.sv
	$(SIM_BUILD)/tb_vector_vsdot_random.vvp
test-vector-vsdot-all: test-vector-vsdot-patterns test-vector-vsdot-directed test-vector-vsdot-backpressure test-vector-vsdot-reset test-vector-vsdot-redirect test-vector-vsdot-invalid test-vector-vsdot-random

WORKLOAD_TB := tb/integration/tb_workload_fc.sv
test-workload-encoder test-workload-golden:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) scripts/workload_fc.py --self-test
test-workload-scalar:
	@mkdir -p $(SIM_BUILD)
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) scripts/workload_fc.py --emit $(SIM_BUILD)
	iverilog -g2012 -I$(SIM_BUILD) -s tb_workload_fc -Ptb_workload_fc.MODE=0 -o $(SIM_BUILD)/$@.vvp $(VEC_VADD_RTL) $(WORKLOAD_TB)
	$(SIM_BUILD)/$@.vvp
test-workload-dense:
	@mkdir -p $(SIM_BUILD)
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) scripts/workload_fc.py --emit $(SIM_BUILD)
	iverilog -g2012 -I$(SIM_BUILD) -s tb_workload_fc -Ptb_workload_fc.MODE=1 -o $(SIM_BUILD)/$@.vvp $(VEC_VADD_RTL) $(WORKLOAD_TB)
	$(SIM_BUILD)/$@.vvp
test-workload-sparse:
	@mkdir -p $(SIM_BUILD)
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) scripts/workload_fc.py --emit $(SIM_BUILD)
	iverilog -g2012 -I$(SIM_BUILD) -s tb_workload_fc -Ptb_workload_fc.MODE=2 -o $(SIM_BUILD)/$@.vvp $(VEC_VADD_RTL) $(WORKLOAD_TB)
	$(SIM_BUILD)/$@.vvp
test-workload-compare: test-workload-scalar test-workload-dense test-workload-sparse
test-workload-all: test-workload-encoder test-workload-golden test-workload-compare

SENSOR_WORKLOAD_TB := tb/integration/tb_sensor_workload.sv
generate-sensor-workload:
	@mkdir -p $(SIM_BUILD)
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) scripts/sensor_workload.py --emit $(SIM_BUILD)
test-sensor-export: generate-sensor-workload
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest tb.tests.test_sensor_workload
test-sensor-rtl-dense: generate-sensor-workload
	@for sample in $$(seq 0 15); do iverilog -g2012 -I$(SIM_BUILD) -s tb_sensor_workload -Ptb_sensor_workload.MODE=1 -Ptb_sensor_workload.SAMPLE=$$sample -o $(SIM_BUILD)/test-sensor-dense_$$sample.vvp $(VEC_VADD_RTL) $(SENSOR_WORKLOAD_TB) && $(SIM_BUILD)/test-sensor-dense_$$sample.vvp || exit $$?; done
test-sensor-rtl-sparse: generate-sensor-workload
	@for sample in $$(seq 0 15); do iverilog -g2012 -I$(SIM_BUILD) -s tb_sensor_workload -Ptb_sensor_workload.MODE=2 -Ptb_sensor_workload.SAMPLE=$$sample -o $(SIM_BUILD)/test-sensor-sparse_$$sample.vvp $(VEC_VADD_RTL) $(SENSOR_WORKLOAD_TB) && $(SIM_BUILD)/test-sensor-sparse_$$sample.vvp || exit $$?; done
test-sensor-workload: test-sensor-export test-sensor-rtl-dense test-sensor-rtl-sparse
test-sensor-all: test-sensor-workload

VEC_VMEM_TB := tb/integration/tb_vector_vmem.sv
test-vector-vmem-directed:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vmem -Ptb_vector_vmem.MODE=0 -o $(SIM_BUILD)/tb_vector_vmem.vvp $(VEC_VADD_RTL) $(VEC_VMEM_TB)
	$(SIM_BUILD)/tb_vector_vmem.vvp
test-vector-scratchpad: test-vector-vmem-directed
test-vector-vmem-backpressure:
	@mkdir -p $(SIM_BUILD)
	@for mode in 1 2; do iverilog -g2012 -s tb_vector_vmem -Ptb_vector_vmem.MODE=$$mode -o $(SIM_BUILD)/tb_vector_vmem_$$mode.vvp $(VEC_VADD_RTL) $(VEC_VMEM_TB) && $(SIM_BUILD)/tb_vector_vmem_$$mode.vvp || exit $$?; done
test-vector-vmem-reset:
	@mkdir -p $(SIM_BUILD)
	@for mode in 3 8 9; do iverilog -g2012 -s tb_vector_vmem -Ptb_vector_vmem.MODE=$$mode -o $(SIM_BUILD)/tb_vector_vmem_reset_$$mode.vvp $(VEC_VADD_RTL) $(VEC_VMEM_TB) && $(SIM_BUILD)/tb_vector_vmem_reset_$$mode.vvp || exit $$?; done
test-vector-vmem-random:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vmem -Ptb_vector_vmem.MODE=4 -o $(SIM_BUILD)/tb_vector_vmem_random.vvp $(VEC_VADD_RTL) $(VEC_VMEM_TB)
	$(SIM_BUILD)/tb_vector_vmem_random.vvp
test-vector-vmem-errors:
	@mkdir -p $(SIM_BUILD)
	@for mode in 5 7 10 11 12; do iverilog -g2012 -s tb_vector_vmem -Ptb_vector_vmem.MODE=$$mode -o $(SIM_BUILD)/tb_vector_vmem_errors_$$mode.vvp $(VEC_VADD_RTL) $(VEC_VMEM_TB) && $(SIM_BUILD)/tb_vector_vmem_errors_$$mode.vvp || exit $$?; done
test-vector-vmem-redirect:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_vector_vmem -Ptb_vector_vmem.MODE=6 -o $(SIM_BUILD)/tb_vector_vmem_redirect.vvp $(VEC_VADD_RTL) $(VEC_VMEM_TB)
	$(SIM_BUILD)/tb_vector_vmem_redirect.vvp
test-vector-vmem-all: test-vector-scratchpad test-vector-vmem-directed test-vector-vmem-backpressure test-vector-vmem-reset test-vector-vmem-redirect test-vector-vmem-errors test-vector-vmem-random

DIFF_TB := tb/integration/tb_scalar_differential.sv
DIFF_RTL := rtl/common/sparrowv_scalar_pkg.sv rtl/core/rv32_alu.sv rtl/core/rv32_decoder.sv rtl/core/rv32_immediate.sv rtl/core/rv32_regfile.sv rtl/core/rv32_core.sv rtl/core/rv32_core_pipe.sv
SEED ?= 1
MODE ?= 0

test-scalar-diff-seed:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=$(SEED) -Ptb_scalar_differential.MODE=$(MODE) -o $(SIM_BUILD)/tb_scalar_differential.vvp $(DIFF_RTL) $(DIFF_TB)
	$(SIM_BUILD)/tb_scalar_differential.vvp

test-scalar-diff-smoke: test-scalar-diff-seed

test-scalar-diff-random:
	@mkdir -p $(SIM_BUILD)
	@for seed in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32; do \
		iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=$$seed -Ptb_scalar_differential.MODE=0 -o $(SIM_BUILD)/tb_scalar_differential.vvp $(DIFF_RTL) $(DIFF_TB) && $(SIM_BUILD)/tb_scalar_differential.vvp || exit $$?; \
	done

test-scalar-diff-stall:
	@mkdir -p $(SIM_BUILD)
	@for mode in 1 2 3; do \
		iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=17 -Ptb_scalar_differential.MODE=$$mode -o $(SIM_BUILD)/tb_scalar_differential.vvp $(DIFF_RTL) $(DIFF_TB) && $(SIM_BUILD)/tb_scalar_differential.vvp || exit $$?; \
	done

test-scalar-diff-negative:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=1 -Ptb_scalar_differential.MODE=0 -Ptb_scalar_differential.NEGATIVE=1 -o $(SIM_BUILD)/tb_scalar_differential_negative.vvp $(DIFF_RTL) $(DIFF_TB)
	$(SIM_BUILD)/tb_scalar_differential_negative.vvp

test-scalar-diff-store-retire:
	@for mode in 0 1 2 3; do \
		$(MAKE) --no-print-directory test-scalar-diff-seed SEED=17 MODE=$$mode || exit $$?; \
	done

test-scalar-diff-store-retire-negative:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=17 -Ptb_scalar_differential.MODE=3 -Ptb_scalar_differential.NEGATIVE_STORE_RETIRE=1 -o $(SIM_BUILD)/tb_scalar_differential_store_retire_negative.vvp $(DIFF_RTL) $(DIFF_TB)
	$(SIM_BUILD)/tb_scalar_differential_store_retire_negative.vvp

test-scalar-diff-subword-seed: test-scalar-diff-seed

test-scalar-diff-subword-directed:
	$(MAKE) test-scalar-diff-subword-seed SEED=1 MODE=0

test-scalar-diff-subword-random:
	@mkdir -p $(SIM_BUILD)
	@for seed in $$(seq 1 128); do \
		iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=$$seed -Ptb_scalar_differential.MODE=0 -o $(SIM_BUILD)/tb_scalar_differential_subword.vvp $(DIFF_RTL) $(DIFF_TB) && $(SIM_BUILD)/tb_scalar_differential_subword.vvp || exit $$?; \
	done

test-scalar-diff-subword-stall:
	@for mode in 1 2 3; do \
		$(MAKE) --no-print-directory test-scalar-diff-subword-seed SEED=17 MODE=$$mode || exit $$?; \
	done

test-scalar-diff-subword-negative:
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -Wall -s tb_scalar_differential -Ptb_scalar_differential.SEED=1 -Ptb_scalar_differential.MODE=0 -Ptb_scalar_differential.NEGATIVE_MEMORY=1 -o $(SIM_BUILD)/tb_scalar_differential_subword_negative.vvp $(DIFF_RTL) $(DIFF_TB)
	$(SIM_BUILD)/tb_scalar_differential_subword_negative.vvp

# Focused reproducer for stale response + redirect + held request (seed 17).
test-scalar-diff-redirect-backpressure:
	$(MAKE) test-scalar-diff-seed SEED=17 MODE=1

# Final scalar correctness suite. Excludes the known expected-fail throughput experiment.
test-scalar-regression: test-repo test-scalar-directed test-scalar-pipe-dev test-scalar-pipe-alu test-scalar-pipe-forward test-scalar-pipe-control test-scalar-pipe-redirect test-scalar-pipe-memory test-scalar-pipe-trap test-scalar-pipe-store-retire test-scalar-diff-smoke test-scalar-diff-random test-scalar-diff-stall test-scalar-diff-negative test-scalar-diff-redirect-backpressure test-scalar-diff-subword-directed test-scalar-diff-subword-random test-scalar-diff-subword-stall test-scalar-diff-subword-negative test-scalar-diff-store-retire test-scalar-diff-store-retire-negative

test-vector-regression: test-scalar-pipe-vec-stub-all test-vector-vadd-all test-vector-vdot-all test-vector-vmem-all test-vector-vsdot-all test-workload-all test-sensor-workload

# One final acceptance command after a milestone is stable.
test-full-regression: test-scalar-regression test-vector-regression lint check docs-check

check:
	$(PYTHON) scripts/check_repo.py --all

docs-check:
	$(PYTHON) scripts/check_repo.py --docs-only

status:
	@sed -n '1,240p' STATUS.md

test: test-repo test-scalar

test-repo:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest discover -s tb/tests -p 'test_*.py'

lint:
	verilator --lint-only --timing -Wall -Wno-fatal $(RTL_SOURCES)

sim-scalar: $(SIM_BUILD)/tb_scalar_core.vvp
	$(SIM_BUILD)/tb_scalar_core.vvp

test-scalar: sim-scalar

test-scalar-directed: test-scalar

test-scalar-random:
	@echo "Random retirement/reference regression is blocked pending the request-buffered IF hardening documented in docs/build_reports/phase_1_5_audit.md"; exit 1

test-scalar-reference:
	PYTHONDONTWRITEBYTECODE=1 $(PYTHON) -m unittest tb.tests.test_reference

THROUGHPUT_EXPERIMENT_TB := tb/integration/tb_scalar_pipeline.sv
# Historical Phase 1.7 throughput experiment: it instantiates rv32_core and
# intentionally fails until a broad pipeline-control redesign is approved.
# It is not a required scalar or development-pipeline correctness regression.
check-scalar-throughput-experiment: $(SIM_BUILD)/tb_scalar_pipeline.vvp
	@echo "Running non-blocking Phase 1.7 throughput experiment (expected to fail)"
	$(SIM_BUILD)/tb_scalar_pipeline.vvp

test-scalar-pipeline:
	@echo "Deprecated alias: use check-scalar-throughput-experiment; this is a non-blocking expected-fail experiment."
	$(MAKE) check-scalar-throughput-experiment

$(SIM_BUILD)/tb_scalar_pipeline.vvp: $(RTL_SOURCES) $(THROUGHPUT_EXPERIMENT_TB)
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipeline -o $@ $(RTL_SOURCES) $(THROUGHPUT_EXPERIMENT_TB)

$(SIM_BUILD)/tb_scalar_core.vvp: $(RTL_SOURCES) $(SCALAR_TB)
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -Wall -s tb_scalar_core -o $@ $(RTL_SOURCES) $(SCALAR_TB)

clean:
	rm -rf $(SIM_BUILD)
