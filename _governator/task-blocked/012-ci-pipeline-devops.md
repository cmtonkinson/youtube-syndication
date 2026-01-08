---
milestone: m2
epic: e7
task: 012
---

# Task: Add CI pipeline with lint and unit test jobs

## Objective
Create a GitHub Actions workflow that runs linting and unit tests in separate
jobs to validate changes automatically.

## Context
- `GOVERNATOR.md` requires a CI pipeline with distinct lint and unit test jobs.
- Tests from Task 011 must run without long downloads.

## Requirements
- [ ] Add a GitHub Actions workflow under `.github/workflows/`.
- [ ] Configure separate jobs for linting and unit tests.
- [ ] Ensure required tools for linting/tests are installed in CI.
- [ ] Use repository-defined lint/test commands; if none exist, add minimal
      bash-friendly commands and document them.
- [ ] CI runs on pull requests and main branch pushes.

## Non-Goals
- Do not add deployment or release automation.
- Do not expand CI beyond lint and unit tests.

## Constraints
- Must align with project bash/tooling constraints.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] CI workflow runs lint and unit tests in separate jobs
- [ ] Jobs succeed in a clean CI environment

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:44:04Z [governator]: Assigned to devops.

## Governator Block

2026-01-08T21:45:07Z [governator]: Missing worker branch origin/worker/devops/012-ci-pipeline-devops for 012-ci-pipeline-devops.
