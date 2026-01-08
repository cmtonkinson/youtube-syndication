---
milestone: m1
epic: e3
task: 008
---

# Task: Implement serialized download stage

## Objective
Implement the download stage that fetches pending videos and thumbnails in a
serialized manner and records outcomes in state.

## Context
- Downloads must be serialized per project constraints.
- `yt-dlp` is the required download engine (ADR-0002).

## Requirements
- [ ] Download only items marked as pending by the sync stage.
- [ ] Use `yt-dlp` to download mp4 files and jpg thumbnails into a staging
      location.
- [ ] Ensure downloads are serialized (no parallelism).
- [ ] Record success/failure and file paths in the state store.
- [ ] Skip items already downloaded or processed according to state.

## Non-Goals
- Do not embed metadata or perform final import.
- Do not change filtering or ordering logic.

## Constraints
- Must remain bash-only and use `yt-dlp`.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Downloads are serialized and recorded in state
- [ ] Items already handled are not downloaded again

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-08T21:30:50Z [governator]: Assigned to generalist.

## Change Summary
- Implemented serialized download stage using yt-dlp with per-item logging and state updates.
- Extended state store records to include downloaded video and thumbnail paths.
- Added skip handling for already downloaded or processed items based on state.
