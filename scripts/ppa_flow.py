#!/usr/bin/env python3
"""Deterministic generic-Yosys PPA comparison for the three Sparrow-V configs."""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "ppa"
CONFIG_PATH = ROOT / "config" / "ppa_configurations.json"
LOCALPARAMS = """localparam logic [3:0] ALU_ADD=0, ALU_SUB=1, ALU_SLL=2, ALU_SLT=3, ALU_SLTU=4, ALU_XOR=5, ALU_SRL=6, ALU_SRA=7, ALU_OR=8, ALU_AND=9;\nlocalparam logic [2:0] MEM_NONE=0, MEM_LOAD=1, MEM_STORE=2, SZ_BYTE=0, SZ_HALF=1, SZ_WORD=2;\nlocalparam logic [3:0] CAUSE_ILLEGAL=4'd2, CAUSE_I_MISALIGN=0, CAUSE_L_MISALIGN=4, CAUSE_S_MISALIGN=6, CAUSE_ECALL=11, CAUSE_EBREAK=3;\n"""


def stage_source(source: Path, destination: Path) -> None:
    text = source.read_text()
    if source.name == "sparrowv_scalar_pkg.sv":
        return
    text = re.sub(r"\bsparrowv_scalar_pkg::alu_op_t\b", "logic [3:0]", text)
    text = re.sub(r"\bsparrowv_scalar_pkg::mem_op_t\b", "logic [2:0]", text)
    text = re.sub(r"\bsparrowv_scalar_pkg::mem_size_t\b", "logic [2:0]", text)
    text = text.replace("import sparrowv_scalar_pkg::*;", LOCALPARAMS)
    text = re.sub(r"\balu_op_t\b", "logic [3:0]", text)
    text = re.sub(r"\bmem_op_t\b", "logic [2:0]", text)
    text = re.sub(r"\bmem_size_t\b", "logic [2:0]", text)
    text = re.sub(r"\bcause_t\b", "logic [3:0]", text)
    text = re.sub(r"\s*initial begin\s*\n\s*if .*?\n\s*\$error\(.*?\);\s*\n\s*end\s*\n", "\n", text)
    # Yosys's Verilog frontend does not accept the repository's immediate
    # simulation assertions. They have no hardware semantics and remain in
    # the original RTL and simulation builds; the staged copy is synthesis-only.
    text = "\n".join(line for line in text.splitlines() if "assert" not in line and "$error" not in line) + "\n"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text)


def stat_metrics(stat_path: Path) -> dict[str, int]:
    data = json.loads(stat_path.read_text())
    modules = data["modules"]
    module = next(iter(modules.values()))
    by_type = module.get("num_cells_by_type", {})
    cells = int(module.get("num_cells", 0))
    sequential = sum(count for name, count in by_type.items() if "DFF" in name.upper() or "LATCH" in name.upper())
    multipliers = sum(count for name, count in by_type.items() if "MUL" in name.upper())
    muxes = sum(count for name, count in by_type.items() if "MUX" in name.upper())
    latches = sum(count for name, count in by_type.items() if "LATCH" in name.upper())
    return {"total_cells": cells, "sequential_cells": sequential, "combinational_cells": cells - sequential,
            "multiplier_cells": multipliers, "mux_cells": muxes, "latch_cells": latches}


def workload_metrics(name: str) -> dict[str, object]:
    if name == "scalar":
        return {"fc_cycles": 7399, "fc_retired": 3948, "fc_exec_multiplies": 64, "fc_skipped_multiplies": 0,
                "fc_weight_bytes": 64, "sensor_cycles": None, "sensor_retired": None}
    return {"fc_cycles": 484, "fc_retired": 109, "fc_exec_multiplies": 64 if name == "dense" else 32,
            "fc_skipped_multiplies": 0 if name == "dense" else 32, "fc_weight_bytes": 64 if name == "dense" else 38,
            "sensor_cycles": 484, "sensor_retired": 109}


def synthesize(name: str, config: dict, yosys: str, version: str, targets: list[float]) -> dict:
    manifest = ROOT / config["manifest"]
    if not manifest.exists():
        raise RuntimeError(f"missing manifest: {manifest.relative_to(ROOT)}")
    sources = [line.strip() for line in manifest.read_text().splitlines() if line.strip() and not line.startswith("#")]
    if any(path.startswith("tb/") or path.startswith("sim/") for path in sources):
        raise RuntimeError(f"simulation source in {manifest.relative_to(ROOT)}")
    if name == "scalar" and any("vector/" in path for path in sources):
        raise RuntimeError("scalar manifest must exclude vector RTL")
    if name == "dense" and any("vsdot" in path.lower() for path in sources):
        raise RuntimeError("dense manifest must exclude sparse-only RTL")
    run_dir = OUT / name
    staged = run_dir / "staged"
    shutil.rmtree(run_dir, ignore_errors=True)
    staged.mkdir(parents=True)
    staged_sources = []
    for relative in sources:
        source = ROOT / relative
        if not source.exists():
            raise RuntimeError(f"missing source: {relative}")
        if source.name == "sparrowv_scalar_pkg.sv":
            continue
        destination = staged / relative
        stage_source(source, destination)
        staged_sources.append(destination.relative_to(ROOT).as_posix())
    script = [f"read_verilog -sv {path}" for path in staged_sources]
    script += [f"hierarchy -check -top {config['top']}", "flatten", "proc", "opt", "memory -nomap", "opt",
               "memory_map", "opt", "techmap", "opt", "abc -g cmos2", "clean",
               f"tee -o {run_dir.relative_to(ROOT).as_posix()}/stat.json stat -json",
               "ltp -noff", f"write_json {run_dir.relative_to(ROOT).as_posix()}/netlist.json"]
    command = [yosys, "-ql", str(run_dir / "yosys.log"), "-p", "; ".join(script)]
    completed = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    (run_dir / "command.txt").write_text(" ".join(command) + "\n")
    if completed.returncode:
        (run_dir / "stderr.txt").write_text(completed.stderr)
        raise RuntimeError(f"Yosys failed for {name}; see results/ppa/{name}/yosys.log")
    metrics = stat_metrics(run_dir / "stat.json")
    log = (run_dir / "yosys.log").read_text()
    match = re.search(r"Longest topological path.*?length=(\d+)", log)
    metrics["logic_depth_cells"] = int(match.group(1)) if match else None
    metrics.update({"configuration": name, "top_module": config["top"], "defines_or_parameters": config["defines"],
                    "source_manifest": config["manifest"], "tool_version": version, "technology": "Yosys generic cmos2 gate mapping",
                    "memory_bits": config["memory_bits"], "memory_inference": "flip-flops and muxes after generic memory_map; not an SRAM macro",
                    "timing": {"target_clock_ns": targets, "worst_slack_ns": None, "critical_path": "logic-depth proxy only",
                               "timing_status": "unconstrained: no Liberty/timing engine", "unconstrained_warnings": True},
                    "power": {"total": None, "dynamic": None, "leakage": None, "assumptions": "unavailable: no characterized library or switching activity"}})
    metrics.update(workload_metrics(name))
    nominal_hz = 100_000_000
    metrics["fc_latency_at_100mhz_ns"] = metrics["fc_cycles"] * 10
    metrics["throughput_proxy_per_s_at_100mhz"] = nominal_hz / metrics["fc_cycles"]
    metrics["area_normalized_throughput_proxy"] = metrics["throughput_proxy_per_s_at_100mhz"] / metrics["total_cells"]
    (run_dir / "metrics.json").write_text(json.dumps(metrics, indent=2, sort_keys=True) + "\n")
    return metrics


def fmt(value: object) -> str:
    if value is None:
        return "N/A"
    if isinstance(value, float):
        return f"{value:.6g}"
    return str(value)


def percent(new: float, old: float) -> str:
    return f"{(new / old - 1) * 100:.2f}%"


def comparison(metrics: list[dict], targets: list[float], version: str) -> str:
    scalar, dense, sparse = metrics
    rows = [("Total generic cells", "total_cells"), ("Sequential cells", "sequential_cells"),
            ("Combinational cells", "combinational_cells"), ("Multiplier-related cells", "multiplier_cells"),
            ("Mux-related cells", "mux_cells"), ("Memory bits", "memory_bits"),
            ("Logic-depth proxy (cells)", "logic_depth_cells"), ("Worst slack", None), ("Timing status", None),
            ("Estimated power", None), ("FC workload cycles", "fc_cycles"), ("Sensor workload cycles/sample", "sensor_cycles"),
            ("FC retired instructions", "fc_retired"), ("FC multiplies executed", "fc_exec_multiplies"),
            ("FC multiplies skipped", "fc_skipped_multiplies"), ("FC weight storage (bytes)", "fc_weight_bytes"),
            ("FC latency at 100 MHz (ns; derived)", "fc_latency_at_100mhz_ns"),
            ("Area-normalized throughput proxy", "area_normalized_throughput_proxy")]
    lines = ["# Sparrow-V Generic Synthesis Comparison", "", f"Yosys: `{version}`.",
             "Technology basis: generic `cmos2` mapping only; it is not a standard-cell or physical result.",
             f"Clock constraints recorded: {', '.join(f'{target:g} ns' for target in targets)}. No Liberty timing data is available, so slack, Fmax, and power are N/A.", "",
             "| Metric | Scalar | Dense Vector | Sparse Vector |", "| --- | ---: | ---: | ---: |"]
    for label, key in rows:
        if key is None and label == "Worst slack": values = ["N/A", "N/A", "N/A"]
        elif key is None and label == "Timing status": values = [item["timing"]["timing_status"] for item in metrics]
        elif key is None: values = ["N/A", "N/A", "N/A"]
        else: values = [fmt(item[key]) for item in metrics]
        lines.append(f"| {label} | {values[0]} | {values[1]} | {values[2]} |")
    lines += ["", "## Overheads", "",
              f"- Dense versus scalar cells: {dense['total_cells'] - scalar['total_cells']:+d} ({percent(dense['total_cells'], scalar['total_cells'])}).",
              f"- Sparse versus dense cells: {sparse['total_cells'] - dense['total_cells']:+d} ({percent(sparse['total_cells'], dense['total_cells'])}).",
              f"- Sparse versus scalar cells: {sparse['total_cells'] - scalar['total_cells']:+d} ({percent(sparse['total_cells'], scalar['total_cells'])}).",
              f"- FC cycle speedup: dense {scalar['fc_cycles'] / dense['fc_cycles']:.2f}x and sparse {scalar['fc_cycles'] / sparse['fc_cycles']:.2f}x versus scalar; dense and sparse are both {dense['fc_cycles']} cycles.",
              f"- FC instruction reduction: dense/sparse {(1 - dense['fc_retired'] / scalar['fc_retired']) * 100:.2f}% versus scalar.",
              "- Sparse arithmetic reduction: 32 of 64 FC multiplications are skipped (50.00%); sparse weight-plus-metadata storage is 38 bytes versus 64 bytes (40.625% reduction).",
              "", "## Interpretation", "",
              "Dense and sparse take equal cycles because VDOT8 and VSDOT8 use the same fixed-latency command/completion state machine; the current schedule has equal vector-load and scalar-accumulation work. Sparse arithmetic is not yet exposed as latency reduction.",
              "The vector register file (32 x 32 bits) and scratchpad (256 x 8 bits) are generic-memory-mapped into flip-flops/muxes. Their 3072 bits are reported separately and must not be compared to an SRAM macro area.",
              "No power estimate is reported: there is no characterized cell library or switching activity. No OpenLane/OpenROAD flow was run.", ""]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", choices=("scalar", "dense", "sparse"))
    parser.add_argument("--all", action="store_true")
    args = parser.parse_args()
    if not args.config and not args.all:
        parser.error("one of --config or --all is required")
    yosys = shutil.which("yosys")
    if not yosys:
        raise SystemExit("error: yosys is required but was not found in PATH")
    config_data = json.loads(CONFIG_PATH.read_text())
    version = subprocess.check_output([yosys, "-V"], text=True).strip()
    names = [args.config] if args.config else ["scalar", "dense", "sparse"]
    metrics = [synthesize(name, config_data["configurations"][name], yosys, version, config_data["clock_targets_ns"]) for name in names]
    if args.all:
        (OUT / "summary.json").write_text(json.dumps({"tool_version": version, "technology": config_data["technology"], "configurations": metrics}, indent=2, sort_keys=True) + "\n")
        (OUT / "comparison.md").write_text(comparison(metrics, config_data["clock_targets_ns"], version))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
