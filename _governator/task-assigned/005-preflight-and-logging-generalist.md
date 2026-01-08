---
milestone: m1
epic: e1
task: 005
---

# Task: Add preflight checks and logging helpers

## Objective
Add preflight checks for required external tools and implement reusable logging
helpers that conform to the documented logging conventions.

## Context
- ADR-0002 mandates `yt-dlp` and `AtomicParsley`.
- Logging conventions are defined by Task 002.

## Requirements
- [ ] Preflight verifies `yt-dlp` and `AtomicParsley` are available on PATH.
- [ ] Failure to meet preflight requirements exits non-zero with a clear error.
- [ ] Implement logging helpers that emit per-item outcomes and run summaries
      per the documented conventions.
- [ ] Logging helpers are reusable across pipeline stages.

## Non-Goals
- Do not implement stage logic (sync/download/process/import).
- Do not redefine logging format or summary fields.

## Constraints
- Must adhere to the conventions documented in Task 002.
- No new runtime dependencies.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Preflight checks fail fast when tools are missing
- [ ] Logging output matches documented conventions
- [ ] Helpers are available for use in later stages

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:25:00Z [governator]: Assigned to generalist.
