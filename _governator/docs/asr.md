# Architecturally Significant Requirements

## ASR-1: Plex-compatible naming and metadata
- Stimulus: Plex scans the library and users browse episodes by season/order.
- Environment: Local filesystem with Plex configured for TV content.
- Required Response: Output uses the required directory and filename format,
  embeds title/description/artist/thumbnail metadata, and uses mp4/jpg only.
- Measurable Threshold: 100% of imported files conform to naming and metadata
  rules and appear in correct chronological order in Plex.
- Why this shapes architecture: Requires deterministic naming, metadata
  embedding, and a publish-date ordering strategy.

## ASR-2: Idempotent and resumable sync
- Stimulus: User reruns sync or resumes after interruption.
- Environment: Partial downloads or processing artifacts on disk.
- Required Response: The system detects already-processed items and avoids
  duplicate downloads/renames.
- Measurable Threshold: A run with no new videos produces no filesystem
  changes; repeated runs never create duplicates.
- Why this shapes architecture: Requires persistent local state and a
  deterministic pipeline.

## ASR-3: Configurable filtering before download
- Stimulus: User configures skip rules (shorts/livestreams, size/duration,
  title patterns).
- Environment: Metadata available prior to download via yt-dlp.
- Required Response: The system excludes matching items before download begins.
- Measurable Threshold: 100% of items matching skip criteria are not
  downloaded.
- Why this shapes architecture: Requires a metadata inspection stage ahead of
  download and clearly defined filter inputs.

## ASR-4: Testability without long downloads
- Stimulus: CI or local tests run in constrained time.
- Environment: Limited network access and time budgets.
- Required Response: Tests rely on small fixtures or mocks and avoid full
  downloads.
- Measurable Threshold: Test suite completes in under 5 minutes and does not
  require downloading full-length videos.
- Why this shapes architecture: Encourages separable stages and injectable
  inputs for testing.

## ASR-5: Operational transparency
- Stimulus: User runs scheduled syncs and needs to understand outcomes.
- Environment: Long-running CLI execution with potential partial failures.
- Required Response: Each run logs per-video outcomes and a final summary; any
  failures are surfaced via exit status.
- Measurable Threshold: Every processed item has a logged outcome and runs with
  failures exit non-zero.
- Why this shapes architecture: Requires consistent logging and error handling
  conventions across stages.
