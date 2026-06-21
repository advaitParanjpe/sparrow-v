PYTHON ?= python3

RTL_SOURCES := $(shell find rtl -name '*.sv' | sort)
SCALAR_TB := tb/integration/tb_scalar_core.sv
SIM_BUILD := sim/build

.PHONY: check docs-check status test test-repo lint sim-scalar test-scalar test-scalar-directed test-scalar-random test-scalar-reference test-scalar-pipeline test-scalar-pipe-dev test-scalar-pipe-alu test-scalar-pipe-forward test-scalar-pipe-control test-scalar-pipe-redirect clean

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
