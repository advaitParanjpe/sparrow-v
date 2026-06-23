import copy
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts import sensor_workload as sensor


ROOT = Path(__file__).resolve().parents[2]
DENSE = ROOT / "tb/fixtures/external_sensor_dense.json"
SPARSE = ROOT / "tb/fixtures/external_sensor_sparse.json"


class ExternalSensorWorkloadTests(unittest.TestCase):
    def load(self, path):
        return json.loads(path.read_text())

    def write(self, directory, content):
        path = Path(directory) / "manifest.json"
        path.write_text(json.dumps(content))
        return path

    def test_dense_and_sparse_manifest_validation(self):
        self.assertEqual("dense_int8", sensor.load_external_manifest(DENSE)["execution_mode"])
        self.assertEqual("sparse_2of4_int8", sensor.load_external_manifest(SPARSE)["execution_mode"])
        cases = [
            (DENSE, lambda data: data.__setitem__("input_int8", [0] * 15)),
            (DENSE, lambda data: data["dense_weights_int8"][0].pop()),
            (DENSE, lambda data: data["input_int8"].__setitem__(0, 128)),
            (DENSE, lambda data: data["biases_int32"].__setitem__(0, 1 << 31)),
            (SPARSE, lambda data: data["compressed_weights_int8"][0][0].pop()),
            (SPARSE, lambda data: data["sparse_metadata"][0].__setitem__(0, 6)),
        ]
        with tempfile.TemporaryDirectory() as temporary:
            for source, mutate in cases:
                broken = copy.deepcopy(self.load(source)); mutate(broken)
                with self.assertRaises(ValueError):
                    sensor.load_external_manifest(self.write(temporary, broken))

    def test_isolated_workspace_is_deterministic_and_preserves_fixture(self):
        fixture_model = ROOT / "python/sparrowv_model/sensor_fixture_model.json"
        fixture_before = fixture_model.read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary) / "workspace"
            first = sensor.export_external(DENSE, workspace)
            first_files = {path.name: path.read_bytes() for path in workspace.iterdir() if path.is_file()}
            second = sensor.export_external(DENSE, workspace)
            second_files = {path.name: path.read_bytes() for path in workspace.iterdir() if path.is_file()}
            self.assertEqual(first, second)
            self.assertEqual(first_files, second_files)
            self.assertEqual(fixture_before, fixture_model.read_bytes())
            sensor.export_external(SPARSE, workspace)
            self.assertFalse((workspace / "sensor_dense.mem").exists())
            self.assertTrue((workspace / "sensor_sparse.mem").exists())
        with self.assertRaises(ValueError):
            sensor.export_external(DENSE, ROOT / "docs/external-workspace")

    def test_dense_and_sparse_rtl_results(self):
        for manifest, mode, accumulators in (
            (DENSE, "dense_int8", [977, 57, -129, 203]),
            (SPARSE, "sparse_2of4_int8", [977, -23, 31, 203]),
        ):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as temporary:
                completed = subprocess.run(
                    ["python3", "scripts/run_external_sensor_workload.py", "--manifest", str(manifest), "--workspace", temporary],
                    cwd=ROOT, text=True, capture_output=True, check=False)
                self.assertEqual(0, completed.returncode, completed.stdout + completed.stderr)
                self.assertIn("SPARROWV_STATUS PASS", completed.stdout)
                result = json.loads((Path(temporary) / "result.json").read_text())
                self.assertEqual(sensor.EXTERNAL_RESULT_FORMAT, result["format_version"])
                self.assertEqual(mode, result["execution_mode"])
                self.assertEqual(accumulators, result["accumulators_int32"])
                self.assertTrue(result["exact_match"])
                self.assertEqual("clear", result["trap_assertion_status"])
                self.assertEqual("measured", result["counters"]["cycles"]["availability"])
                self.assertEqual("derived" if mode == "dense_int8" else "unavailable", result["counters"]["dense_conceptual_int8_multiplications"]["availability"])

    def test_simulator_assertion_failure_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary:
            manifest = self.load(DENSE)
            manifest["expected_accumulators_int32"][0] += 1
            manifest_path = self.write(temporary, manifest)
            workspace = Path(temporary) / "workspace"
            completed = subprocess.run(
                ["python3", "scripts/run_external_sensor_workload.py", "--manifest", str(manifest_path), "--workspace", str(workspace)],
                cwd=ROOT, text=True, capture_output=True, check=False)
            self.assertEqual(1, completed.returncode)
            result = json.loads((workspace / "result.json").read_text())
            self.assertEqual("failed", result["simulator_status"])
            self.assertEqual("trap_or_assertion_failure", result["trap_assertion_status"])
            self.assertIn("logit mismatch", result["failure_detail"])


if __name__ == "__main__":
    unittest.main()
