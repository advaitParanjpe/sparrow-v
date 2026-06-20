# Codex Initial Build Prompt

You are starting a new RTL project named **Sparrow-V: Sparse-Aware RISC-V Edge Processor**.

Read every Markdown file in this repository before making changes. The documentation defines the intended architecture, scope, coding rules, verification philosophy, and phased roadmap.

## Current objective

Implement **Phase 0 only** from `docs/13_build_roadmap.md`.

Do not implement the CPU, vector engine, sparse unit, or application yet.

## Required work

1. Create the repository skeleton described in `docs/12_repo_structure.md`.
2. Add a top-level `Makefile` with placeholder-safe targets such as:
   - `make check`
   - `make lint`
   - `make test`
   - `make clean`
3. Add a Python package scaffold for architectural models and scripts.
4. Add a minimal CI-style repository checker that validates:
   - expected directories exist;
   - no generated files are committed in source directories;
   - documentation links are valid where practical;
   - placeholder RTL files are clearly marked and not presented as implemented functionality.
5. Create an architecture decision record directory and an initial ADR covering:
   - new scalar core versus adapting an existing permissively licensed core;
   - three-stage versus five-stage scalar pipeline;
   - reset polarity;
   - initial custom opcode allocation strategy.
6. Create one canonical machine-readable or code-based ISA definition location for future scalar/vector opcode fields, but do not fill in invented final encodings without documenting them.
7. Add a project status document showing every phase as `not started`, `in progress`, `blocked`, or `complete`.
8. Add basic Python tests for the repository checker.
9. Add a concise build report describing exactly what was added, commands run, and any unresolved decisions.

## Constraints

- Do not overbuild Phase 0.
- Do not claim any RTL functionality exists.
- Do not silently resolve open architectural questions.
- Do not add third-party CPU RTL yet.
- Do not add generated binaries, tool outputs, or vendor files.
- Keep all changes deterministic and locally runnable.
- Prefer standard-library Python unless a dependency is justified.
- Preserve the documentation as the source of truth and update it only when necessary.

## Expected validation

Run and report:

```text
make check
make test
```

If a tool is unavailable, document the limitation rather than faking success.

## Final response format

Return:

1. summary of completed work;
2. files added or modified;
3. commands run and results;
4. unresolved architectural decisions;
5. recommended next prompt for Phase 1.

