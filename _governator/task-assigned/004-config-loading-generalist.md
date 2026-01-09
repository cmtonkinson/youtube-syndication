---
milestone: m1
epic: e1
task: 004
---

# Task: Implement configuration and subscriptions loading

## Objective
Implement loading and validation of `subscriptions.txt` and the documented
configuration schema so pipeline stages can consume consistent inputs.

## Context
- `subscriptions.txt` is the primary input for subscriptions.
- Configuration schema is defined by Task 001.

## Requirements
- [ ] Read `subscriptions.txt` as one identifier per line.
- [ ] Load configuration file(s) per the documented schema and apply defaults.
- [ ] Validate required fields and fail with clear, actionable errors.
- [ ] Expose parsed configuration to downstream stages.
- [ ] Use bash-compatible parsing with no new runtime dependencies.

## Non-Goals
- Do not define or change the configuration schema.
- Do not implement filtering, downloads, or metadata embedding.

## Constraints
- Must follow the schema defined in Task 001.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Subscriptions and configuration load correctly
- [ ] Invalid or missing inputs produce clear errors
- [ ] No new runtime dependencies introduced

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:24:57Z [governator]: Assigned to generalist.

## Merge Failure

2026-01-08T21:41:34Z [governator]: Unable to fast-forward merge worker/generalist/004-config-loading-generalist into main.

## Governator Block

2026-01-08T21:41:45Z [governator]: Missing worker branch origin/worker/generalist/004-config-loading-generalist for 004-config-loading-generalist.

## Unblock Note

Blocking condition was an absent worker branch. Requeueing the task without
changing scope or requirements.

## Assignment

2026-01-08T21:45:24Z [governator]: Assigned to generalist.

## Change Summary
- Added bash config/subscription loader with defaults, validation, and path setup.
- Wired input loading into `yts.sh` so stages share parsed configuration.
- Assumption: blank lines and `#`-prefixed lines in `subscriptions.txt` are ignored.

## Review Result

2026-01-08T21:51:00Z [reviewer]: Decision: block

## Governator Block

2026-01-08T21:53:32Z [governator]: Missing worker branch origin/worker/generalist/004-config-loading-generalist for 004-config-loading-generalist.

## Unblock Note

2026-01-09T00:27:17Z [governator]: 007
2026-01-09T00:27:17Z [governator]: 008
2026-01-09T00:27:17Z [governator]: 009
2026-01-09T00:27:17Z [governator]: 010
2026-01-09T00:27:17Z [governator]: 011
2026-01-09T00:27:17Z [governator]: 012
2026-01-09T00:27:17Z [governator]: 013
