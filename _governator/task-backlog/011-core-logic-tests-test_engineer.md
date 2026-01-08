---
milestone: m2
epic: e6
task: 011
---

# Task: Add core logic tests and fixtures

## Objective
Add fast, deterministic tests that validate core logic (parsing, filtering,
ordering, naming, and state handling) without downloading real videos.

## Context
- ASR-4 requires tests that avoid long downloads and complete quickly.
- Core logic is implemented across the pipeline stages in milestone m1.

## Requirements
- [ ] Create tests for subscription parsing and configuration defaults.
- [ ] Create tests for filtering rules (shorts/livestreams default skip,
      size/duration limits, title pattern matches).
- [ ] Create tests for publish-date ordering and episode numbering.
- [ ] Create tests for filename sanitization and naming conventions.
- [ ] Create tests for state store read/write behavior.
- [ ] Use small local fixtures or mocks only; no network calls or full media
      downloads.

## Non-Goals
- Do not implement or modify production code beyond test support files.
- Do not add end-to-end downloads or integration tests.

## Constraints
- Tests must run in under 5 minutes.
- Avoid introducing new test dependencies unless explicitly approved.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Tests cover all required areas and run locally without network access
- [ ] Failures are clear and actionable

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:41:52Z [governator]: Assigned to test_engineer.

## Governator Block

2026-01-08T21:43:00Z [governator]: Missing worker branch origin/worker/test_engineer/011-core-logic-tests-test_engineer for 011-core-logic-tests-test_engineer.

## Unblock Note

Blocking condition was an absent worker branch. Requeueing the task without
changing scope or requirements.
