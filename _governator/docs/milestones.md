# Project Milestones
> This document defines the **delivery phases (milestones)** of the project.
> Each milestone represents a **demo-able system state** with explicit intent,
> scope, and exit criteria.  
>
> Milestones exist to preserve sequencing rationale, prevent scope drift,
> and provide clear review gates.

## Milestone Map
| ID | Name | Outcome (One-liner) |
|----|------|---------------------|
| m1 | Functional pipeline | `yts.sh` produces Plex-ready media with idempotent sync, filtering, and metadata. |
| m2 | Operational readiness | Tests, CI, and documentation make the system reviewable and usable. |

> Notes:
> - Use as few milestones as necessary.
> - Small or trivial projects may have just a single "Delivery" milestone.

## Milestone m1 — Functional pipeline

### Outcome
A working CLI pipeline that syncs subscriptions and produces Plex-ready media
with correct naming, ordering, metadata, and idempotent behavior.

### Why This Milestone Exists
Retires the core risk that the staged pipeline (sync, download, process, import)
can run end-to-end using the required external tools while preserving Plex
compatibility and idempotency.

### In Scope
- `yts.sh` entrypoint and pipeline orchestration
- Configuration inputs (`subscriptions.txt` plus documented config file)
- Preflight checks for required tools
- JSON state store for idempotent and resumable runs
- Sync stage with filters and publish-date ordering
- Serialized downloads via `yt-dlp`
- Metadata embedding via `AtomicParsley`
- Import, naming, and cleanup into the `youtube/` library
- Per-item logging and run summary with correct exit status

### Out of Scope
- Automated test suite and fixtures
- CI pipeline setup
- README and user documentation

### Acceptance / Exit Criteria
The milestone is considered complete when:
- [ ] A full run produces Plex-ready mp4/jpg output with correct naming and
      embedded metadata
- [ ] Re-running with no new videos produces no duplicate files
- [ ] Shorts and livestreams are skipped by default
- [ ] Downloads are serialized and processing/import respects constraints
- [ ] Logs include per-item outcomes and a final summary

### Dependencies & Assumptions
- `yt-dlp` and `AtomicParsley` are installed and available on PATH
- User provides a valid `subscriptions.txt`
- Network access is available for metadata and downloads

### Notes / Constraints
- Bash-based implementation only
- Output must be mp4 and jpg only
- Only destination copies are retained after import

## Milestone m2 — Operational readiness

### Outcome
A documented and testable system with CI checks that validate correctness
without long downloads.

### Why This Milestone Exists
Ensures the project is reviewable, maintainable, and safe to run regularly by
providing tests, automation, and clear usage documentation.

### In Scope
- Unit tests with small fixtures (no full downloads)
- CI pipeline with separate linting and unit test jobs
- README documenting setup, dependencies, configuration, and usage

### Out of Scope
- New core features beyond the pipeline defined in m1
- Deployment or distribution automation beyond CI

### Acceptance / Exit Criteria
The milestone is considered complete when:
- [ ] Tests run locally in under 5 minutes and avoid full downloads
- [ ] CI runs linting and unit tests in separate jobs
- [ ] README covers installation, configuration, and command usage

### Dependencies & Assumptions
- Milestone m1 is complete
- CI environment can install required tools for linting/tests

### Notes / Constraints
- Tests must not require network downloads of full-length videos

## Milestone Sequencing Rationale
Core pipeline functionality (m1) must exist before tests, CI, and documentation
(m2) can be accurately authored and validated.
