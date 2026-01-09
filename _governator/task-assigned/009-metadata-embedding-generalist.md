---
milestone: m1
epic: e4
task: 009
---

# Task: Implement metadata embedding stage

## Objective
Embed title, description, artist/channel, and thumbnail metadata into mp4 files
using `AtomicParsley`, producing Plex-ready media.

## Context
- Metadata embedding is required for Plex compatibility (ASR-1).
- `AtomicParsley` is the mandated tool (ADR-0002).

## Requirements
- [ ] Read metadata from `yt-dlp` outputs (title, description, channel/artist).
- [ ] Use `AtomicParsley` to embed tags and thumbnail into mp4 files.
- [ ] Output mp4 files suitable for the import stage.
- [ ] Update state to reflect processed items and output paths.

## Non-Goals
- Do not perform final naming or import into the `youtube/` library.
- Do not change download behavior or filters.

## Constraints
- Must use `AtomicParsley`.
- Output formats limited to mp4 and jpg.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Processed mp4 files contain required metadata and thumbnails
- [ ] State reflects processing outcomes per item

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-09T00:29:05Z [governator]: Assigned to generalist.
