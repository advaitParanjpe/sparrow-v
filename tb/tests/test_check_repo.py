"""Tests for the Phase 0 repository-check implementation."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts import check_repo


class CheckRepoTests(unittest.TestCase):
    def test_required_directory_check_reports_missing_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            errors = check_repo.validate_required_directories(Path(temporary_directory))
        self.assertIn("missing required directory: rtl/core", errors)

    def test_manifest_check_accepts_existing_local_link(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            docs = root / "docs"
            docs.mkdir()
            (root / "source.md").write_text("# Source\n", encoding="utf-8")
            (docs / "source_manifest.md").write_text("[source](../source.md)\n", encoding="utf-8")
            errors = check_repo.validate_manifest_links(root)
        self.assertEqual(errors, [])

    def test_placeholder_check_rejects_reserved_marker(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / "notes.md").write_text("TODO_FILL\n", encoding="utf-8")
            errors = check_repo.validate_placeholders(root)
        self.assertEqual(errors, ["unresolved placeholder TODO_FILL: notes.md"])

    def test_generated_output_check_rejects_python_cache(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            cache = root / "scripts" / "__pycache__"
            cache.mkdir(parents=True)
            (cache / "check_repo.pyc").write_bytes(b"cache")
            errors = check_repo.validate_generated_outputs(root)
        self.assertEqual(errors, ["generated Python cache present: scripts/__pycache__/check_repo.pyc"])
