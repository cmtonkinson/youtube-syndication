---
milestone: m1
epic: e2
task: 007
---

# Task: Implement sync stage with filtering and ordering

## Objective
Implement the sync stage that enumerates video metadata, applies skip filters,
computes publish-date ordering, and updates state without downloading media.

## Context
- ASR-3 requires configurable filtering before download.
- Episode numbers derive from publish date ordering.
- Task 004 defines configuration inputs; Task 006 defines state storage.

## Requirements
- [ ] Use `yt-dlp` metadata listing to gather video id, title, publish date,
      duration, and size (when available) per subscription.
- [ ] Apply skip rules per configuration: shorts/livestreams default skip with
      explicit override, size/duration limits, and title pattern matches.
- [ ] Determine publish-date ordering and assign episode numbers consistently.
- [ ] Update the state store with pending items and ordering data.
- [ ] Produce a list of items ready for download without downloading media.

## Non-Goals
- Do not download videos or embed metadata.
- Do not change configuration schema or state file format.

## Constraints
- Must avoid full media downloads.
- Must use the JSON state store defined in Task 006.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Sync identifies eligible items and applies filters correctly
- [ ] Episode ordering is deterministic by publish date
- [ ] State reflects pending items without duplicates

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-09T00:28:59Z [governator]: Assigned to generalist.
