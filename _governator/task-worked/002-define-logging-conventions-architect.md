---
milestone: m1
epic: e1
task: 002
---

# Task: Define logging and run summary conventions

## Objective
Document the required logging format and run summary outputs so operational
transparency (ASR-5) is implemented consistently.

## Context
- ASR-5 mandates per-video outcomes and a final run summary.
- `arc42.md` lists log format and machine-readable summary outputs as deferred
  decisions.

## Requirements
- [ ] Define the log line format (fields, ordering, and severity levels).
- [ ] Specify run summary content and where it is emitted (stdout/stderr or
      summary file).
- [ ] Clarify exit status rules for partial or total failures.
- [ ] Record the conventions in `_governator/docs` (update or add a doc).

## Non-Goals
- Do not implement logging or modify production code.
- Do not change project scope or external tool requirements.

## Constraints
- Must align with ASR-5 and `GOVERNATOR.md`.
- Must be human-readable and bash-friendly.
- Changes limited to `_governator/docs`.

## Acceptance Criteria
- [ ] All requirements satisfied
- [ ] Documentation clearly defines log and summary conventions
- [ ] No production code changes

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:24:52Z [governator]: Assigned to architect.

## Change Summary
- Added a logging conventions document defining logfmt fields, severity levels,
  standard events, summary output, and exit codes.
- Updated arc42 deferred decisions to remove the logging format item.
- Assumptions: the summary file is written to `./run-summary.logfmt`, and exit
  codes use 0/1/2 for success/fatal/partial failure.
