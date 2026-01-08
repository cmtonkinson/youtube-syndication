---
milestone: m1
epic: e1
task: 001
---

# Task: Define configuration schema for filters and paths

## Objective
Document the configuration file format, schema, defaults, and validation rules
needed for skip filters and pipeline paths, so implementation can proceed
without ambiguity.

## Context
- `GOVERNATOR.md` and `arc42.md` require `subscriptions.txt` plus local config
  files.
- `arc42.md` lists the final configuration schema and validation rules as
  deferred decisions.
- ASR-3 requires configurable filtering before download.

## Requirements
- [ ] Specify the config file name(s), location(s), and format suitable for
      bash parsing.
- [ ] Define schema fields for skip rules (shorts/livestreams default skip with
      explicit override, size limit, duration limit, title pattern).
- [ ] Define schema fields for relevant paths (output library, staging,
      state/metadata).
- [ ] Document defaults and validation rules for all fields.
- [ ] Record the schema in `_governator/docs` (update or add a doc).

## Non-Goals
- Do not implement parsing or any production code.
- Do not change project scope or constraints in `GOVERNATOR.md`.

## Constraints
- Must align with `GOVERNATOR.md`, ASR-3, and ADRs.
- Must remain bash-friendly and avoid new runtime dependencies.
- Changes limited to `_governator/docs`.

## Acceptance Criteria
- [ ] All requirements satisfied
- [ ] Documentation clearly specifies format, schema, defaults, and validation
- [ ] No production code changes

=============================================================================
=============================================================================

## Notes
