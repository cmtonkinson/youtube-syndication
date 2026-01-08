---
milestone: m1
epic: e2
task: 006
---

# Task: Implement JSON state store

## Objective
Implement a JSON state store to record video identifiers, publish dates, and
processing status so runs are idempotent and resumable.

## Context
- ADR-0003 selects a file-based JSON state store.
- ASR-2 requires idempotent and resumable sync behavior.

## Requirements
- [ ] State is stored as JSON files (per subscription or per run).
- [ ] Each record includes video identifier, publish date, and processing
      status.
- [ ] Reads handle missing or empty state gracefully.
- [ ] Writes are atomic (write to temp file then move).
- [ ] Provide lookup helpers to detect already processed items.

## Non-Goals
- Do not implement metadata fetching or filtering.
- Do not introduce a database or non-JSON storage.

## Constraints
- Must be bash-friendly.
- No new runtime dependencies.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] State store can read, write, and update records reliably
- [ ] Idempotent behavior is possible using stored records

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:27:08Z [governator]: Assigned to generalist.

## Change Summary
- Added bash JSON state store helpers for reading, upserting, and lookup.
- Implemented atomic writes with temp file moves and graceful handling of missing state.
- Added a processed-status lookup helper for idempotent checks.

## Review Result

2026-01-08T21:30:42Z [reviewer]: Decision: approve
2026-01-08T21:30:42Z [reviewer]: Comments:
2026-01-08T21:30:42Z [reviewer]: - The bash JSON state store helpers provide atomic upserts, graceful reads on missing/empty files, and processed-status lookups, matching the task requirements for idempotent state tracking.
