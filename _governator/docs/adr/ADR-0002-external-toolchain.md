# ADR-0002: External Toolchain Dependencies

## Status
Accepted

## Context
The project requires reliable download and metadata embedding capabilities for
YouTube videos. Mature tools already exist and are explicitly referenced in the
project constraints.

Alternatives considered:
- Using ffmpeg for metadata embedding.
- Using youtube-dl or a custom downloader.

## Decision
Depend on `yt-dlp` for downloading/metadata extraction and `AtomicParsley` for
embedding metadata and thumbnails into mp4 files, with pre-flight checks to
ensure they are available.

## Consequences

Positive:
- Leverages well-tested tools with broad format support.
- Reduces implementation complexity and risk.

Negative:
- Requires users to install and maintain external tool versions.
- Behavior can change with upstream tool updates.

Tradeoffs accepted:
- Tool upgrades may require occasional compatibility validation.

## Notes

- Date: 2026-01-08
- Related ASRs: ASR-1, ASR-3, ASR-5
- Related Tasks: _governator/task-assigned/000-architecture-bootstrap-architect.md
