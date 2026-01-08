---
milestone: m1
epic: e1
task: 003
---

# Task: Create CLI entrypoint and stage orchestration

## Objective
Provide the `yts.sh` entrypoint with basic argument handling and orchestration
for the sync -> download -> process -> import pipeline order.

## Context
- `GOVERNATOR.md` requires a single main executable entrypoint named `yts.sh`.
- ADR-0001 sets a bash-first CLI pipeline architecture.

## Requirements
- [ ] Add an executable `yts.sh` at the repository root using bash.
- [ ] Support running the full pipeline in order: sync, download, process,
      import.
- [ ] Provide a `--help` output describing the pipeline and required inputs.
- [ ] Delegate stage logic to functions or scripts that can be filled in by
      later tasks.
- [ ] Exit non-zero if any stage fails or returns an error.

## Non-Goals
- Do not implement stage logic (sync/download/process/import).
- Do not implement configuration parsing or logging conventions.

## Constraints
- Must remain bash-only and avoid new runtime dependencies.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] `yts.sh` exists and is executable
- [ ] Pipeline orchestration order is enforced
- [ ] `--help` is available and accurate

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:24:55Z [governator]: Assigned to generalist.

## Change Summary
- Added bash `yts.sh` entrypoint with help output and ordered stage orchestration.

## Review Result

2026-01-08T21:27:01Z [reviewer]: Decision: approve
2026-01-08T21:27:01Z [reviewer]: Comments:
2026-01-08T21:27:01Z [reviewer]: - yts.sh provides the bash entrypoint with accurate help text and ordered stage orchestration that exits non-zero on failure, matching the task requirements.
2026-01-08T21:27:01Z [reviewer]: - Optional: consider adding stricter error handling once stage functions are implemented.
