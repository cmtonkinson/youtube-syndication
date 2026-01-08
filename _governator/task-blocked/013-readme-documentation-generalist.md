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

2026-01-08T21:44:52Z [governator]: Assigned to generalist.

## Change Summary
- Added a README describing dependencies, configuration schema, usage, skip
  filters, and current vs. target output layouts.
- Noted that config parsing and some stages are placeholders to match current
  implementation behavior.

## Review Result

2026-01-08T21:46:43Z [reviewer]: Decision: block

## Governator Block

2026-01-08T21:47:58Z [governator]: Missing worker branch origin/worker/generalist/013-readme-documentation-generalist for 013-readme-documentation-generalist.
