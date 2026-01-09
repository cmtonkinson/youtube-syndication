---
milestone: m1
epic: e5
task: 010
---

# Task: Implement import, naming, and cleanup

## Objective
Move processed media into the Plex-compatible `youtube/` library with correct
naming and remove staging artifacts so only destination copies remain.

## Context
- `GOVERNATOR.md` defines the naming pattern and directory rules.
- ASR-6 requires single-copy storage after import.

## Requirements
- [ ] Create destination directories per channel/playlist name under `youtube/`.
- [ ] Rename files to `<name> - S01EXX - <title>.mp4` using publish-date
      ordering for episode numbers.
- [ ] Sanitize filenames safely and handle naming collisions deterministically.
- [ ] Remove staging artifacts after successful import so only destination
      copies remain.
- [ ] Update state to mark items as imported.

## Non-Goals
- Do not re-download or re-embed metadata.
- Do not create season subdirectories.

## Constraints
- Output must be mp4 with jpg thumbnails only.
- Only one season per subscription, no season directories.
- Do not modify `_governator/` files.

## Acceptance Criteria
- [ ] Imported files conform to Plex naming and layout rules
- [ ] Staging copies are removed after successful import
- [ ] State reflects imported items and collisions are logged

=============================================================================
=============================================================================

## Notes

## Assignment

2026-01-09T00:29:07Z [governator]: Assigned to generalist.

## Change Summary
- Implemented import stage to name/move processed media into the Plex library, handle collisions, and clean staging artifacts.
- Added metadata lookup and filename sanitization helpers to drive channel/title naming and episode ordering by publish date.
- Assumed yt-dlp metadata is available via .info.json near processed files; fallback uses subscription/video id when missing.
