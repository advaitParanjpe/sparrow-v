#!/usr/bin/env python3
"""Validate and export the deterministic Sparrow-V sensor fixture."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from scripts import workload_fc as fc

MODEL_PATH = ROOT / "python/sparrowv_model/sensor_fixture_model.json"
SAMPLES_PATH = ROOT / "python/sparrowv_model/sensor_fixture_samples.json"
INT8_MIN, INT8_MAX = -128, 127
INT32_MIN, INT32_MAX = -(1 << 31), (1 << 31) - 1
PATTERN_CODE = {(0, 1): 0, (0, 2): 1, (0, 3): 2, (1, 2): 3, (1, 3): 4, (2, 3): 5}
SPAD_INPUT, SPAD_DENSE, SPAD_SPARSE = 0x00, 0x10, 0x50


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"invalid JSON {path}: {exc}") from exc


def _integer(value: Any, name: str, lower: int, upper: int) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or not lower <= value <= upper:
        raise ValueError(f"{name} must be an integer in [{lower}, {upper}]")
    return value


def load_model(path: Path = MODEL_PATH) -> dict[str, Any]:
    model = _load_json(path)
    required = {"model_name", "format_version", "data_layout_version", "input_features", "output_classes", "class_names", "weights_int8", "bias_int32"}
    if not isinstance(model, dict) or required - model.keys():
        raise ValueError("model is missing required fields")
    if model["format_version"] != 1 or model["data_layout_version"] != 1:
        raise ValueError("unsupported model format or data-layout version")
    features = _integer(model["input_features"], "input_features", 1, 256)
    classes = _integer(model["output_classes"], "output_classes", 1, 256)
    if features != 16 or classes != 4:
        raise ValueError("this exporter supports exactly 16 features and 4 classes")
    if not isinstance(model["model_name"], str) or not model["model_name"]:
        raise ValueError("model_name must be a nonempty string")
    names = model["class_names"]
    if not isinstance(names, list) or len(names) != classes or any(not isinstance(x, str) or not x for x in names) or len(set(names)) != len(names):
        raise ValueError("class_names must be unique and match output_classes")
    weights = model["weights_int8"]
    if not isinstance(weights, list) or len(weights) != classes:
        raise ValueError("weights_int8 row count does not match output_classes")
    for row_index, row in enumerate(weights):
        if not isinstance(row, list) or len(row) != features:
            raise ValueError(f"weights_int8 row {row_index} has wrong feature count")
        for lane, value in enumerate(row):
            _integer(value, f"weights_int8[{row_index}][{lane}]", INT8_MIN, INT8_MAX)
    biases = model["bias_int32"]
    if not isinstance(biases, list) or len(biases) != classes:
        raise ValueError("bias_int32 count does not match output_classes")
    for index, value in enumerate(biases):
        _integer(value, f"bias_int32[{index}]", INT32_MIN, INT32_MAX)
    if "feature_scaling" in model and not isinstance(model["feature_scaling"], dict):
        raise ValueError("feature_scaling must be an object")
    if "provenance_note" in model and not isinstance(model["provenance_note"], str):
        raise ValueError("provenance_note must be a string")
    return model


def load_samples(model: dict[str, Any], path: Path = SAMPLES_PATH) -> dict[str, Any]:
    data = _load_json(path)
    if not isinstance(data, dict) or data.get("format_version") != 1 or not isinstance(data.get("sample_set_name"), str) or not isinstance(data.get("samples"), list):
        raise ValueError("invalid sample-set format")
    seen: set[str] = set()
    for sample in data["samples"]:
        if not isinstance(sample, dict) or {"sample_id", "features_int8", "expected_label"} - sample.keys():
            raise ValueError("sample is missing required fields")
        ident = sample["sample_id"]
        if not isinstance(ident, str) or not ident or ident in seen:
            raise ValueError("sample IDs must be nonempty and unique")
        seen.add(ident)
        values = sample["features_int8"]
        if not isinstance(values, list) or len(values) != model["input_features"]:
            raise ValueError(f"sample {ident} has wrong feature count")
        for lane, value in enumerate(values):
            _integer(value, f"sample {ident} feature {lane}", INT8_MIN, INT8_MAX)
        if sample["expected_label"] not in model["class_names"]:
            raise ValueError(f"sample {ident} has unknown expected label")
    if len(data["samples"]) < 16:
        raise ValueError("sensor fixture must contain at least 16 samples")
    return data


def prune_group(group: list[int]) -> tuple[list[int], tuple[int, int], int, list[int]]:
    if len(group) != 4:
        raise ValueError("2:4 group must contain four weights")
    for value in group:
        _integer(value, "2:4 weight", INT8_MIN, INT8_MAX)
    lanes = tuple(sorted(sorted(range(4), key=lambda lane: (-abs(group[lane]), lane))[:2]))
    metadata = PATTERN_CODE[lanes]
    compressed = [group[lanes[0]], group[lanes[1]]]
    reconstructed = decompress_group(compressed, metadata)
    if sum(value != 0 for value in reconstructed) > 2 or reconstructed[lanes[0]] != compressed[0] or reconstructed[lanes[1]] != compressed[1]:
        raise AssertionError("invalid sparse 2:4 conversion")
    return compressed, lanes, metadata, reconstructed


def decompress_group(compressed: list[int], metadata: int) -> list[int]:
    if len(compressed) != 2 or metadata not in PATTERN_CODE.values():
        raise ValueError("invalid compressed sparse group")
    lanes = next(lanes for lanes, code in PATTERN_CODE.items() if code == metadata)
    result = [0, 0, 0, 0]
    result[lanes[0]], result[lanes[1]] = compressed
    return result


def sparse_model(model: dict[str, Any]) -> dict[str, Any]:
    compressed, metadata, reconstructed = [], [], []
    for row in model["weights_int8"]:
        comp_row, meta_row, dense_row = [], [], []
        for offset in range(0, model["input_features"], 4):
            comp, lanes, code, restored = prune_group(row[offset:offset + 4])
            assert tuple(sorted(lanes)) == lanes and code <= 5 and restored == decompress_group(comp, code)
            comp_row.append(comp); meta_row.append(code); dense_row.extend(restored)
        compressed.append(comp_row); metadata.append(meta_row); reconstructed.append(dense_row)
    return {"compressed_weights": compressed, "metadata": metadata, "dense_equivalent": reconstructed}


def infer(features: list[int], weights: list[list[int]], biases: list[int]) -> list[int]:
    logits = [bias + sum(feature * weight for feature, weight in zip(features, row)) for row, bias in zip(weights, biases)]
    if any(not INT32_MIN <= value <= INT32_MAX for value in logits):
        raise ValueError("inference logit exceeds signed INT32")
    return logits


def infer_compressed(features: list[int], sparse: dict[str, Any], biases: list[int]) -> list[int]:
    logits = []
    for output, bias in enumerate(biases):
        total = bias
        for group in range(4):
            lanes = next(lanes for lanes, code in PATTERN_CODE.items() if code == sparse["metadata"][output][group])
            weights = sparse["compressed_weights"][output][group]
            total += features[group * 4 + lanes[0]] * weights[0] + features[group * 4 + lanes[1]] * weights[1]
        logits.append(total)
    return logits


def argmax(values: list[int]) -> int:
    return max(range(len(values)), key=lambda index: values[index])


def storage_accounting() -> dict[str, Any]:
    dense, compressed, metadata_bits = 64, 32, 16 * 3
    metadata_bytes = (metadata_bits + 7) // 8
    total = compressed + metadata_bytes
    return {"dense_weight_bytes": dense, "compressed_weight_bytes": compressed, "metadata_bits": metadata_bits, "packed_metadata_bytes": metadata_bytes, "metadata_padding_bits": metadata_bytes * 8 - metadata_bits, "sparse_total_weight_metadata_bytes": total, "weight_storage_reduction_percent": (dense - total) * 100.0 / dense, "bias_bytes": 16}


def evaluate(model: dict[str, Any], sample_set: dict[str, Any]) -> dict[str, Any]:
    sparse = sparse_model(model); records = []
    counts = {name: {"samples": 0, "dense_correct": 0, "sparse_correct": 0} for name in model["class_names"]}
    for sample in sample_set["samples"]:
        dense = infer(sample["features_int8"], model["weights_int8"], model["bias_int32"])
        sparse_dense = infer(sample["features_int8"], sparse["dense_equivalent"], model["bias_int32"])
        compressed = infer_compressed(sample["features_int8"], sparse, model["bias_int32"])
        if sparse_dense != compressed:
            raise AssertionError("sparse decompressed and compressed inference differ")
        dense_pred, sparse_pred = argmax(dense), argmax(compressed)
        expected = model["class_names"].index(sample["expected_label"])
        counts[sample["expected_label"]]["samples"] += 1
        counts[sample["expected_label"]]["dense_correct"] += dense_pred == expected
        counts[sample["expected_label"]]["sparse_correct"] += sparse_pred == expected
        records.append({"sample_id": sample["sample_id"], "expected_label": sample["expected_label"], "dense_logits": dense, "sparse_logits": compressed, "dense_predicted_class": model["class_names"][dense_pred], "sparse_predicted_class": model["class_names"][sparse_pred], "dense_correct": dense_pred == expected, "sparse_correct": sparse_pred == expected})
    total = len(records); dense_correct = sum(record["dense_correct"] for record in records); sparse_correct = sum(record["sparse_correct"] for record in records)
    return {"accuracy_label": "fixture accuracy (deterministic deployment fixture; not general model accuracy)", "samples": records, "summary": {"sample_count": total, "dense_correct": dense_correct, "dense_accuracy": dense_correct / total, "sparse_correct": sparse_correct, "sparse_accuracy": sparse_correct / total, "prediction_disagreements": sum(a["dense_predicted_class"] != a["sparse_predicted_class"] for a in records), "per_class": counts}}


def vector_program(model: dict[str, Any], sparse: bool) -> list[int]:
    p = fc.Program(); p.emit(fc.addi(3, 0, fc.DMEM_OUT)); p.emit(fc.addi(4, 0, fc.DMEM_DONE))
    converted = sparse_model(model)
    for output, bias in enumerate(model["bias_int32"]):
        fc.check_imm(bias, 12); p.emit(fc.addi(5, 0, bias))
        for group in range(4):
            p.emit(fc.addi(1, 0, SPAD_INPUT + group * 4)); p.emit(fc.vload32(1, 1))
            offset = (SPAD_SPARSE if sparse else SPAD_DENSE) + (output * 4 + group) * 4
            p.emit(fc.addi(2, 0, offset)); p.emit(fc.vload32(2, 2))
            p.emit(fc.vsdot8(6, 1, 2, converted["metadata"][output][group]) if sparse else fc.vdot8(6, 1, 2))
            p.emit(fc.add(5, 5, 6))
        p.emit(fc.sw(5, 3, output * 4))
    p.emit(fc.addi(12, 0, 1)); p.emit(fc.sw(12, 4, 0)); p.emit(fc.beq(0, 0, 0))
    return p.words


def pack_metadata(codes: list[int]) -> list[int]:
    packed = [0] * ((len(codes) * 3 + 7) // 8)
    for index, code in enumerate(codes):
        bit = index * 3
        packed[bit // 8] |= (code << (bit % 8)) & 0xff
        if bit % 8 > 5:
            packed[bit // 8 + 1] |= code >> (8 - bit % 8)
    return packed


def spad_words(model: dict[str, Any], features: list[int]) -> list[int]:
    sparse = sparse_model(model); words = [0] * 64
    for group in range(4): words[group] = fc.pack_word(features[group * 4:group * 4 + 4])
    for output, row in enumerate(model["weights_int8"]):
        for group in range(4): words[4 + output * 4 + group] = fc.pack_word(row[group * 4:group * 4 + 4])
    for output, groups in enumerate(sparse["compressed_weights"]):
        for group, weights in enumerate(groups): words[20 + output * 4 + group] = fc.pack_word(weights + [0, 0])
    return words


def _write_mem(path: Path, words: list[int], size: int) -> None:
    fc.write_mem(path, words, size)


def _svh(model: dict[str, Any], evaluation: dict[str, Any], sample_set: dict[str, Any]) -> str:
    lines = ["// Generated by scripts/sensor_workload.py; do not edit.", "localparam integer SENSOR_SAMPLE_COUNT = 16;", "localparam integer SENSOR_WORKLOAD_WORDS = 8192;"]
    lines.append("function automatic logic [31:0] sensor_spad_word(input integer sample, input integer word); begin sensor_spad_word=32'h00000000; case(sample)")
    for index, sample in enumerate(sample_set["samples"]):
        lines.append(f"{index}: case(word)")
        for word, value in enumerate(spad_words(model, sample["features_int8"])[:36]): lines.append(f"{word}: sensor_spad_word=32'h{value:08x};")
        lines.append("endcase")
    lines += ["endcase end endfunction", "function automatic logic signed [31:0] sensor_expected_logit(input integer sample, input integer mode, input integer output_index); begin sensor_expected_logit=0; case(sample)"]
    for index, record in enumerate(evaluation["samples"]):
        lines.append(f"{index}: case(output_index)")
        for output, value in enumerate(record["dense_logits"]):
            dense_literal = f"-32'sd{-value}" if value < 0 else f"32'sd{value}"
            sparse_value = record["sparse_logits"][output]
            sparse_literal = f"-32'sd{-sparse_value}" if sparse_value < 0 else f"32'sd{sparse_value}"
            lines.append(f"{output}: sensor_expected_logit=(mode==1) ? {dense_literal} : {sparse_literal};")
        lines.append("endcase")
    lines += ["endcase end endfunction", "function automatic integer sensor_expected_prediction(input integer sample, input integer mode); begin sensor_expected_prediction=0; case(sample)"]
    for index, record in enumerate(evaluation["samples"]):
        dense = model["class_names"].index(record["dense_predicted_class"]); sparse = model["class_names"].index(record["sparse_predicted_class"])
        lines.append(f"{index}: sensor_expected_prediction=(mode==1) ? {dense} : {sparse};")
    lines += ["endcase end endfunction"]
    return "\n".join(lines) + "\n"


def export(out: Path) -> dict[str, Any]:
    model, samples = load_model(), None
    samples = load_samples(model); evaluation = evaluate(model, samples); sparse = sparse_model(model)
    out.mkdir(parents=True, exist_ok=True)
    _write_mem(out / "sensor_dense.mem", vector_program(model, False), 8192)
    _write_mem(out / "sensor_sparse.mem", vector_program(model, True), 8192)
    dense_words = [fc.pack_word(row[group * 4:group * 4 + 4]) for row in model["weights_int8"] for group in range(4)]
    sparse_words = [fc.pack_word(weights + [0, 0]) for row in sparse["compressed_weights"] for weights in row]
    codes = [code for row in sparse["metadata"] for code in row]
    _write_mem(out / "sensor_dense_weights.mem", dense_words, 16)
    _write_mem(out / "sensor_sparse_weights.mem", sparse_words, 16)
    _write_mem(out / "sensor_sparse_metadata.mem", pack_metadata(codes), 6)
    for index, sample in enumerate(samples["samples"]):
        dmem = [0] * 512
        for lane, value in enumerate(sample["features_int8"]): dmem[lane // 4] |= (value & 0xff) << (8 * (lane % 4))
        _write_mem(out / f"sensor_dmem_{index}.mem", dmem, 512)
    group_layout = [{"group": index, "output_class": index // 4, "feature_lanes": [4 * (index % 4), 4 * (index % 4) + 1, 4 * (index % 4) + 2, 4 * (index % 4) + 3], "compressed_weight_byte_offset": index * 2, "metadata_bit_offset": index * 3, "metadata_code": codes[index]} for index in range(16)]
    report = {"model_name": model["model_name"], "model_format_version": model["format_version"], "sample_set_name": samples["sample_set_name"], "sample_set_format_version": samples["format_version"], "input_features": 16, "output_classes": 4, "class_names": model["class_names"], "storage": storage_accounting(), "sparse_metadata_packing": "3-bit metadata codes packed little-endian by group: group 0 occupies bits [2:0]; trailing high bits are zero padding.", "scratchpad_offsets": {"activations": SPAD_INPUT, "dense_weights": SPAD_DENSE, "compressed_sparse_weights": SPAD_SPARSE}, "output_addresses": [fc.DMEM_OUT + 4 * output for output in range(4)], "program_images": ["sim/build/sensor_dense.mem", "sim/build/sensor_sparse.mem"], "memory_images": [f"sim/build/sensor_dmem_{index}.mem" for index in range(16)], "model_images": ["sim/build/sensor_dense_weights.mem", "sim/build/sensor_sparse_weights.mem", "sim/build/sensor_sparse_metadata.mem"], "sparse_group_layout": group_layout, "expected_operation_counts": {"dense": {"vload32": 32, "vdot8": 16, "vsdot8": 0, "conceptual_int8_multiplications": 64}, "sparse": {"vload32": 32, "vdot8": 0, "vsdot8": 16, "executed_int8_multiplications": 32, "skipped_int8_multiplications": 32}}, "evaluation": evaluation}
    (out / "sensor_expected.svh").write_text(_svh(model, evaluation, samples))
    (out / "sensor_export_report.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    manifest = {key: report[key] for key in report if key != "evaluation"}
    manifest["content_hashes"] = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted(out.iterdir()) if path.is_file() and path.name != "sensor_manifest.json"}
    (out / "sensor_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return report


def self_test() -> None:
    model, samples = load_model(), load_samples(load_model())
    report = evaluate(model, samples); assert len(report["samples"]) == 16
    assert storage_accounting() == {"dense_weight_bytes": 64, "compressed_weight_bytes": 32, "metadata_bits": 48, "packed_metadata_bytes": 6, "metadata_padding_bits": 0, "sparse_total_weight_metadata_bytes": 38, "weight_storage_reduction_percent": 40.625, "bias_bytes": 16}
    for lanes, code in PATTERN_CODE.items(): assert decompress_group([7, -9], code)[lanes[0]] == 7 and decompress_group([7, -9], code)[lanes[1]] == -9


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--emit", type=Path); parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test: self_test()
    if args.emit: export(args.emit)
