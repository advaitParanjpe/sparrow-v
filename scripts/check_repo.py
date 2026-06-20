#!/usr/bin/env python3
"""Phase 0 repository and documentation hygiene checks for Sparrow-V."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_DIRECTORIES = (
    "rtl/core", "rtl/vector", "rtl/memory", "rtl/interface", "rtl/common", "rtl/top",
    "tb/unit", "tb/integration", "tb/assertions", "tb/models", "tb/tests", "sim",
    "sw/runtime", "sw/benchmarks", "sw/tests", "sw/tools", "scripts",
    "synth/yosys", "synth/vivado", "synth/openlane", "docs/architecture",
    "docs/verification", "docs/software", "docs/results", "docs/decisions",
    "docs/build_reports", "config", "third_party", "python/sparrowv_model",
    "python/export", "python/verification", "python/analysis", "constraints", "fpga",
    "openlane", "results/simulation", "results/synthesis", "results/fpga", "results/asic",
)

REQUIRED_FILES = (
    "README.md", "STATUS.md", "CONTRIBUTING.md", ".gitignore", "Makefile",
    "docs/source_manifest.md", "docs/architecture/open_questions.md",
    "docs/architecture/phase_dependencies.md",
    "docs/build_reports/phase_0_repository_setup.md",
)

REQUIRED_SECTION_HEADINGS = {
    "README.md": ("Project purpose", "Current phase", "Planned subsystems", "Repository layout", "Expected toolchain", "Initial commands"),
    "STATUS.md": ("Current phase", "Completed work", "Active blockers", "Next approved task", "Tests currently available", "Known limitations"),
}

PLACEHOLDER_MARKERS = ("TODO_FILL", "TBD_UNRESOLVED")
GENERATED_FILE_NAMES = {".DS_Store"}
GENERATED_SUFFIXES = {".vcd", ".fst", ".wlf", ".jou", ".str", ".bit", ".elf", ".hex", ".mem"}
SOURCE_DIRS = ("rtl", "tb", "sw", "scripts", "python")
MARKDOWN_LINK = re.compile(r"(?<!!)\[[^]]*\]\(([^)]+)\)")


def markdown_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.md") if ".git" not in path.parts)


def validate_required_directories(root: Path) -> list[str]:
    return [f"missing required directory: {path}" for path in REQUIRED_DIRECTORIES if not (root / path).is_dir()]


def validate_required_files(root: Path) -> list[str]:
    return [f"missing required file: {path}" for path in REQUIRED_FILES if not (root / path).is_file()]


def validate_placeholders(root: Path) -> list[str]:
    errors: list[str] = []
    for path in markdown_files(root):
        text = path.read_text(encoding="utf-8")
        for marker in PLACEHOLDER_MARKERS:
            if marker in text:
                errors.append(f"unresolved placeholder {marker}: {path.relative_to(root)}")
    return errors


def validate_required_sections(root: Path) -> list[str]:
    errors: list[str] = []
    for relative, headings in REQUIRED_SECTION_HEADINGS.items():
        path = root / relative
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for heading in headings:
            match = re.search(rf"^## {re.escape(heading)}\s*$", text, re.MULTILINE)
            if not match:
                errors.append(f"missing required section '{heading}': {relative}")
                continue
            remainder = text[match.end():]
            body = re.split(r"^## ", remainder, maxsplit=1, flags=re.MULTILINE)[0]
            if not body.strip():
                errors.append(f"empty required section '{heading}': {relative}")
    return errors


def validate_manifest_links(root: Path) -> list[str]:
    manifest = root / "docs/source_manifest.md"
    if not manifest.is_file():
        return ["cannot validate source manifest: docs/source_manifest.md is missing"]
    errors: list[str] = []
    text = manifest.read_text(encoding="utf-8")
    links = MARKDOWN_LINK.findall(text)
    if not links:
        return ["source manifest contains no Markdown links"]
    for target in links:
        target = target.split("#", 1)[0]
        if not target or "://" in target or target.startswith("mailto:"):
            continue
        if not (manifest.parent / target).resolve().exists():
            errors.append(f"source manifest references missing path: {target}")
    return errors


def validate_generated_outputs(root: Path) -> list[str]:
    errors: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        relative = path.relative_to(root)
        if path.name in GENERATED_FILE_NAMES:
            errors.append(f"generated operating-system file present: {relative}")
        if "__pycache__" in relative.parts:
            errors.append(f"generated Python cache present: {relative}")
        if relative.parts and relative.parts[0] in SOURCE_DIRS and path.suffix.lower() in GENERATED_SUFFIXES:
            errors.append(f"generated output in source directory: {relative}")
    return errors


def run_checks(root: Path, docs_only: bool) -> list[str]:
    errors = validate_required_files(root)
    errors.extend(validate_placeholders(root))
    errors.extend(validate_required_sections(root))
    errors.extend(validate_manifest_links(root))
    if not docs_only:
        errors = validate_required_directories(root) + errors
        errors.extend(validate_generated_outputs(root))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--all", action="store_true", help="run structure and documentation checks")
    parser.add_argument("--docs-only", action="store_true", help="run documentation checks only")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    if args.all == args.docs_only:
        parser.error("select exactly one of --all or --docs-only")
    root = args.root.resolve()
    errors = run_checks(root, docs_only=args.docs_only)
    if errors:
        print("repository checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    scope = "documentation" if args.docs_only else "repository structure and documentation"
    print(f"Phase 0 {scope} checks passed: {root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
