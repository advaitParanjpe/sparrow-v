PYTHON ?= python3

RTL_SOURCES := $(shell find rtl -name '*.sv' | sort)
SCALAR_TB := tb/integration/tb_scalar_core.sv
SIM_BUILD := sim/build

.PHONY: check docs-check status test test-repo lint sim-scalar test-scalar test-scalar-directed test-scalar-random test-scalar-reference test-scalar-pipeline test-scalar-pipe-dev test-scalar-pipe-alu test-scalar-pipe-forward test-scalar-pipe-control test-scalar-pipe-redirect test-scalar-pipe-memory test-scalar-diff-smoke test-scalar-diff-random test-scalar-diff-stall test-scalar-diff-seed test-scalar-diff-negative test-scalar-diff-redirect-backpressure clean

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

test-scalar-pipe-memory-stall: test-scalar-pipe-memory

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

# Focused reproducer for stale response + redirect + held request (seed 17).
test-scalar-diff-redirect-backpressure:
	$(MAKE) test-scalar-diff-seed SEED=17 MODE=1

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

PIPELINE_TB := tb/integration/tb_scalar_pipeline.sv
test-scalar-pipeline: $(SIM_BUILD)/tb_scalar_pipeline.vvp
	$(SIM_BUILD)/tb_scalar_pipeline.vvp

$(SIM_BUILD)/tb_scalar_pipeline.vvp: $(RTL_SOURCES) $(PIPELINE_TB)
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -s tb_scalar_pipeline -o $@ $(RTL_SOURCES) $(PIPELINE_TB)

$(SIM_BUILD)/tb_scalar_core.vvp: $(RTL_SOURCES) $(SCALAR_TB)
	@mkdir -p $(SIM_BUILD)
	iverilog -g2012 -Wall -s tb_scalar_core -o $@ $(RTL_SOURCES) $(SCALAR_TB)

clean:
	rm -rf $(SIM_BUILD)
