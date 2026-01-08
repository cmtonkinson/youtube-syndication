# arc42 Architecture Overview

## Goals & Constraints
- Business goals:
  - Automate creation of Plex-ready libraries from YouTube subscriptions.
  - Minimize manual effort while preserving correct ordering and metadata.
  - Support reliable incremental updates over time.
- Technical constraints:
  - Bash-based CLI with a single entrypoint `yts.sh`.
  - Use `yt-dlp` for downloads and `AtomicParsley` for metadata embedding.
  - Output mp4 videos and jpg thumbnails only.
  - Shorts and livestreams are skipped by default where detectable.
  - Only destination copies are retained; source downloads are not kept.
  - One season per subscription; episode ordering by publish date.
  - Downloads must be serialized; processing/import may be parallelized.
  - Configuration begins with `subscriptions.txt` and local config files.

## Context & Scope
- In scope:
  - Local CLI pipeline for sync, download, process, and import stages.
  - Metadata extraction, embedding, and Plex-compatible naming.
  - Local state to support idempotent runs and reporting.
  - Skip filters (shorts, livestreams, size/duration, title patterns).
- Out of scope:
  - Streaming server, UI, or web service.
  - Multi-user authentication/authorization.
  - Cloud storage, CDN integration, or distributed processing.

## Solution Strategy
A single-machine CLI orchestrates a staged pipeline (sync -> download ->
process -> import) with deterministic naming and metadata embedding. Persistent
local state enables idempotent runs and resumability. The solution intentionally
leans on stable external tools (yt-dlp, AtomicParsley) rather than custom
implementations.

C4 diagrams are intentionally omitted at this stage because the system is a
single-process CLI with a small component surface; revisit if the architecture
expands beyond a local pipeline.

## Cross-Cutting Concepts
- Security:
  - No secrets are required; inputs are local files.
  - Avoid executing untrusted input and sanitize filenames.
- Observability:
  - Human-readable logs with per-video outcomes and run summaries.
- Error handling:
  - Failures are isolated per item where possible and surfaced via exit status.
- Configuration:
  - `subscriptions.txt` is the primary input; optional config files capture
    skip rules and limits.
- Logging / audit:
  - Logs are suitable for cron usage and can be captured to a file by the user.

## Deployment View
- Environments:
  - Local workstation or NAS where Plex scans the output directory.
  - CI environment for linting and unit tests.
- Runtime assumptions:
  - POSIX shell environment with `yt-dlp` and `AtomicParsley` installed.
  - Network access for downloads and sufficient disk capacity.

## Risks & Technical Debt
- Known risks:
  - Upstream changes in YouTube or yt-dlp behavior.
  - Tool availability/version drift for yt-dlp and AtomicParsley.
  - Title sanitization and naming collisions.
  - Timezone consistency when ordering by publish date.
- Deferred decisions:
  - Final configuration schema and validation rules.
  - Exact log format and machine-readable summary outputs.
  - Concurrency model for processing/import stages.
