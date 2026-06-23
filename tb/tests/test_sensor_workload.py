import copy
import json
import tempfile
import unittest
from pathlib import Path

from scripts import sensor_workload as sensor


class SensorWorkloadTests(unittest.TestCase):
    def setUp(self):
        self.model = sensor.load_model()
        self.samples = sensor.load_samples(self.model)

    def write_json(self, data):
        tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False)
        json.dump(data, tmp); tmp.close()
        return Path(tmp.name)

    def test_valid_fixture_and_reference(self):
        report = sensor.evaluate(self.model, self.samples)
        self.assertEqual(16, len(report["samples"]))
        self.assertEqual(16, report["summary"]["dense_correct"])
        self.assertEqual(16, report["summary"]["sparse_correct"])
        for record in report["samples"]:
            self.assertEqual(record["dense_predicted_class"], record["expected_label"])
            self.assertEqual(record["sparse_predicted_class"], record["expected_label"])

    def test_model_rejections(self):
        for mutate in (
            lambda m: m.__setitem__("format_version", 2),
            lambda m: m["weights_int8"].__setitem__(0, [1] * 15),
            lambda m: m["weights_int8"][0].__setitem__(0, 128),
            lambda m: m["bias_int32"].__setitem__(0, 1 << 31),
            lambda m: m.__setitem__("class_names", ["a", "b"]),
        ):
            broken = copy.deepcopy(self.model); mutate(broken)
            with self.assertRaises(ValueError): sensor.load_model(self.write_json(broken))

    def test_sample_rejections(self):
        for mutate in (
            lambda s: s["samples"][0].__setitem__("features_int8", [0] * 15),
            lambda s: s["samples"][0]["features_int8"].__setitem__(0, 128),
            lambda s: s["samples"][0].__setitem__("expected_label", "unknown"),
            lambda s: s["samples"].append(copy.deepcopy(s["samples"][0])),
        ):
            broken = copy.deepcopy(self.samples); mutate(broken)
            with self.assertRaises(ValueError): sensor.load_samples(self.model, self.write_json(broken))

    def test_sparse_patterns_ties_extremes_and_decompression(self):
        for lanes, code in sensor.PATTERN_CODE.items():
            group = [0, 0, 0, 0]; group[lanes[0]], group[lanes[1]] = -128, 127
            compressed, selected, actual, restored = sensor.prune_group(group)
            self.assertEqual(lanes, selected); self.assertEqual(code, actual)
            self.assertEqual(restored, sensor.decompress_group(compressed, actual))
        compressed, lanes, _, restored = sensor.prune_group([7, -7, 7, 0])
        self.assertEqual((0, 1), lanes)
        self.assertEqual([7, -7], compressed)
        self.assertEqual(2, sum(value != 0 for value in restored))

    def test_storage_accounting_and_metadata_packing(self):
        account = sensor.storage_accounting()
        self.assertEqual(64, account["dense_weight_bytes"])
        self.assertEqual(32, account["compressed_weight_bytes"])
        self.assertEqual(48, account["metadata_bits"])
        self.assertEqual(6, account["packed_metadata_bytes"])
        self.assertEqual(0, account["metadata_padding_bits"])
        self.assertEqual(38, account["sparse_total_weight_metadata_bytes"])
        self.assertEqual(40.625, account["weight_storage_reduction_percent"])
        self.assertEqual([0x88, 0xC6, 0x02], sensor.pack_metadata([0, 1, 2, 3, 4, 5]))

    def test_deterministic_artifacts_and_repository_relative_manifest(self):
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            sensor.export(Path(first)); sensor.export(Path(second))
            first_files = sorted(path.name for path in Path(first).iterdir())
            self.assertEqual(first_files, sorted(path.name for path in Path(second).iterdir()))
            for name in first_files:
                self.assertEqual((Path(first) / name).read_bytes(), (Path(second) / name).read_bytes())
            before = (Path(first) / "sensor_manifest.json").read_bytes()
            sensor.export(Path(first))
            self.assertEqual(before, (Path(first) / "sensor_manifest.json").read_bytes())
            manifest = json.loads((Path(first) / "sensor_manifest.json").read_text())
            self.assertTrue(all(not Path(path).is_absolute() for path in manifest["memory_images"]))
            self.assertEqual(16, len(manifest["memory_images"]))
            self.assertEqual(3, len(manifest["model_images"]))
            self.assertEqual(16, len(manifest["sparse_group_layout"]))
            self.assertEqual(45, manifest["sparse_group_layout"][-1]["metadata_bit_offset"])


if __name__ == "__main__":
    unittest.main()
