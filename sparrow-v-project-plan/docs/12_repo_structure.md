# Intended Repository Structure

```text
sparrow-v/
├── README.md
├── Makefile
├── pyproject.toml
├── rtl/
│   ├── common/
│   ├── scalar/
│   ├── vector/
│   ├── memory/
│   └── top/
├── tb/
│   ├── unit/
│   ├── subsystem/
│   ├── system/
│   ├── assertions/
│   └── models/
├── sw/
│   ├── crt/
│   ├── linker/
│   ├── include/
│   ├── tests/
│   ├── benchmarks/
│   └── apps/
├── python/
│   ├── sparrowv_model/
│   ├── export/
│   ├── verification/
│   └── analysis/
├── scripts/
│   ├── build_program.py
│   ├── elf_to_mem.py
│   ├── run_regression.py
│   ├── collect_metrics.py
│   └── check_repo.py
├── constraints/
├── openlane/
├── fpga/
├── docs/
│   ├── architecture/
│   ├── verification/
│   ├── software/
│   └── results/
├── results/
│   ├── simulation/
│   ├── synthesis/
│   ├── fpga/
│   └── asic/
└── .github/workflows/
```

## Organization rules

- Keep synthesizable RTL separate from testbench code.
- Keep shared definitions in one package or include structure.
- Avoid circular package dependencies.
- Generated files must go under `build/` or `results/`, not source directories.
- Every major phase should add or update documentation.
- Do not commit large tool-generated outputs unless selected artifacts are intentionally preserved.

