---
milestone: m2
epic: e8
task: 013
---

# Task: Write project README

## Objective
Create a `README.md` that documents setup, dependencies, configuration, and
usage of the `yts.sh` pipeline.

## Context
- `GOVERNATOR.md` requires a proper README for the project.
- Configuration schema is defined by Task 001.

## Requirements
- [ ] Document required dependencies (`yt-dlp`, `AtomicParsley`, and any lint/
      test tools).
- [ ] Document configuration files and `subscriptions.txt` format.
- [ ] Provide usage examples for running the pipeline.
- [ ] Describe skip filters and defaults (shorts/livestreams, size/duration,
      title pattern).
- [ ] Explain the output directory layout and naming conventions.

## Non-Goals
- Do not add new features or modify implementation code.
- Do not create additional documentation beyond `README.md`.

## Constraints
- Must align with implemented behavior and documented schema.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] README covers setup, configuration, usage, and outputs
- [ ] Documentation matches actual CLI behavior

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-09T00:39:35Z [governator]: Assigned to generalist.

## Change Summary
- Updated README to reflect current pipeline stages, configuration, and output
  layout (including state files, staging, and Plex naming).
- Added usage example for custom config path and clarified skip filter defaults.

## Review Result

2026-01-09T00:43:53Z [reviewer]: Decision: reject
2026-01-09T00:43:53Z [reviewer]: Comments:
2026-01-09T00:43:53Z [reviewer]: - README.md: The state filename slugging description is inaccurate; slugify preserves '.', '_' and '-' but the doc says all non-alphanumeric characters become '_' (this violates the requirement that documentation match CLI behavior). Please update the wording in README.md to match the actual slugging rules.

## Change Summary
- Updated README slugging description to match `yts.sh` behavior.

## Review Result

2026-01-09T00:46:57Z [reviewer]: Decision: approve
2026-01-09T00:46:57Z [reviewer]: Comments:
2026-01-09T00:46:57Z [reviewer]: - README.md documents the pipeline stages, configuration, skip filters, and output layout in line with the current yts.sh behavior, including the corrected slugging rule for state files.
2026-01-09T00:46:57Z [reviewer]: - Optional: consider clarifying the Requirements note about lint/test tooling since scripts/lint.sh depends on shellcheck and scripts/test.sh exists.
