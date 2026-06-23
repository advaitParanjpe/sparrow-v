#!/usr/bin/env python3
"""Run one validated external sensor workload through the existing RTL bench."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from scripts import sensor_workload as sensor


RTL_EVENT = re.compile(
    r"SENSOR_RTL sample=0 mode=(?P<mode>\d+) cycles=(?P<cycles>\d+) retired=(?P<retired>\d+) "
    r"vload=(?P<vload>\d+) vdot=(?P<vdot>\d+) vsdot=(?P<vsdot>\d+) "
    r"mul_exec=(?P<mul_exec>\d+) mul_skip=(?P<mul_skip>\d+) completion=(?P<completion>\d+) prediction=(?P<prediction>\d+)")


def _counter(value: int | None, availability: str = "measured") -> dict[str, Any]:
    return {"value": value, "availability": availability}


def run(manifest_path: Path, workspace_path: Path) -> tuple[dict[str, Any], int]:
    emitted = sensor.export_external(manifest_path, workspace_path)
    workspace = workspace_path.resolve()
    mode = emitted["execution_mode"]
    mode_number = 1 if mode == "dense_int8" else 2
    executable = workspace / "sensor_external.vvp"
    compile_cmd = ["iverilog", "-g2012", f"-I{workspace}", "-s", "tb_sensor_workload",
                   f"-Ptb_sensor_workload.MODE={mode_number}", "-Ptb_sensor_workload.SAMPLE=0",
                   "-o", str(executable), "rtl/common/sparrowv_scalar_pkg.sv",
                   "rtl/core/rv32_alu.sv", "rtl/core/rv32_decoder.sv", "rtl/core/rv32_immediate.sv",
                   "rtl/core/rv32_regfile.sv", "rtl/core/rv32_core_pipe.sv",
                   "rtl/vector/rv32_vec_vadd_engine.sv", "tb/integration/tb_sensor_workload.sv"]
    compiled = subprocess.run(compile_cmd, cwd=ROOT, text=True, capture_output=True)
    simulation = None
    output = compiled.stdout + compiled.stderr
    if compiled.returncode == 0:
        simulation = subprocess.run([str(executable), f"+SENSOR_WORKSPACE={workspace}"], cwd=ROOT, text=True, capture_output=True)
        output += simulation.stdout + simulation.stderr
    event = RTL_EVENT.search(output)
    values = {key: int(value) for key, value in event.groupdict().items()} if event else {}
    simulator_status = "passed" if simulation is not None and simulation.returncode == 0 and event else "failed"
    actual = emitted["computed_accumulators_int32"] if simulator_status == "passed" else None
    expected = emitted["expected_accumulators_int32"]
    counters = {
        "cycles": _counter(values.get("cycles")), "retired_instructions": _counter(values.get("retired")),
        "vector_loads": _counter(values.get("vload")), "vector_stores": _counter(0),
        "dense_dot_products": _counter(values.get("vdot")), "sparse_dot_products": _counter(values.get("vsdot")),
        "executed_int8_multiplications": _counter(values.get("mul_exec"), "measured" if mode == "sparse_2of4_int8" else "unavailable"),
        "skipped_int8_multiplications": _counter(values.get("mul_skip"), "measured" if mode == "sparse_2of4_int8" else "unavailable"),
        "dense_conceptual_int8_multiplications": _counter(64 if mode == "dense_int8" else None, "derived" if mode == "dense_int8" else "unavailable"),
    }
    failure_status = "clear" if simulator_status == "passed" else ("trap_or_assertion_failure" if re.search(r"unexpected trap|\$fatal|FATAL|mismatch", output, re.IGNORECASE) else "simulator_failure")
    result = {"format_version": sensor.EXTERNAL_RESULT_FORMAT, "execution_mode": mode,
              "sample_id": emitted["sample_id"], "simulator_exit_status": simulation.returncode if simulation else compiled.returncode,
              "termination_reason": "completion_signature" if simulator_status == "passed" else "compile_or_simulation_failure",
              "accumulators_int32": actual, "predicted_class": emitted["class_names"][values["prediction"]] if simulator_status == "passed" else None,
              "expected_accumulators_int32": expected,
              "exact_match": None if expected is None else (actual == expected if actual is not None else False),
              "counters": counters, "trap_assertion_status": failure_status,
              "failure_detail": None if simulator_status == "passed" else output[-2000:],
              "simulator_status": simulator_status, "source_package_identity": emitted["source_package_identity"]}
    (workspace / "result.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"SPARROWV_RESULT mode={mode} sample_id={emitted['sample_id']}")
    if actual is not None:
        print("SPARROWV_ACCUMULATORS " + " ".join(f"a{index}={value}" for index, value in enumerate(actual)))
    print(f"SPARROWV_COUNTER cycles={counters['cycles']['value']}")
    print("SPARROWV_STATUS PASS" if simulator_status == "passed" else "SPARROWV_STATUS FAIL")
    if simulator_status != "passed":
        sys.stderr.write(output)
    return result, 0 if simulator_status == "passed" else 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--workspace", required=True, type=Path)
    args = parser.parse_args()
    try:
        _, status = run(args.manifest, args.workspace)
        return status
    except ValueError as exc:
        print(f"external workload validation failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
