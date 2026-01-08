# Project Epics
> This document defines the project’s **epics**: coherent capabilities that
> collectively realize each milestone.
>
> Epics exist to preserve **intent, scope boundaries, and design decisions**
> while serving as the source of truth for story-level task generation.

## How to Read This Document
- Epics are grouped by **milestone**.
- Every epic maps to **exactly one milestone**.
- Tasks must map to **exactly one epic**.
- Epics should remain stable even if tasks change.

## Milestone m1 — Functional pipeline

### Epic e1 — CLI entrypoint, configuration, and logging
**Goal**  
Provide the single `yts.sh` entrypoint with defined configuration inputs,
preflight checks, and logging conventions so the pipeline can be invoked
consistently.

**Why This Epic Exists**  
Users need a reliable way to run the pipeline and understand outcomes; clear
configuration and logging are prerequisites for safe operation.

**In Scope**
- `yts.sh` entrypoint and invocation model
- Configuration schema and validation rules
- Preflight checks for `yt-dlp` and `AtomicParsley`
- Logging format and run summary conventions

**Out of Scope**
- Sync/download/process/import implementations
- Tests, CI, and documentation

**Key Decisions**
- Bash CLI entrypoint (`ADR-0001`)
- External toolchain dependency (`ADR-0002`)

**Interfaces / Contracts**
- `yts.sh` CLI interface
- `subscriptions.txt` input file
- Config file schema (as documented)
- Log output format

**Risks & Mitigations**
- Risk: Ambiguous config rules lead to inconsistent behavior.
- Mitigation: Document explicit schema and defaults before implementation.

**Definition of Done (Epic-level)**
This epic is complete when:
- Configuration and logging conventions are documented
- The CLI entrypoint enforces those conventions

### Epic e2 — State store and sync planning
**Goal**  
Provide a JSON state store and a sync stage that enumerates videos, applies
filters, and establishes deterministic episode ordering.

**Why This Epic Exists**  
Idempotency and predictable ordering are essential for Plex-compatible output
and resumable runs.

**In Scope**
- JSON state files for per-video status and metadata
- Safe, atomic state writes
- Metadata listing via `yt-dlp` without downloads
- Filter application (shorts/livestreams default skip, size/duration, title)
- Publish-date ordering and episode number assignment

**Out of Scope**
- Download, processing, or import execution

**Key Decisions**
- JSON state store (`ADR-0003`)

**Interfaces / Contracts**
- State file schema and location
- Metadata fields consumed from `yt-dlp`

**Risks & Mitigations**
- Risk: Partial state writes cause duplicates.
- Mitigation: Use atomic write strategy.

**Definition of Done (Epic-level)**
This epic is complete when:
- Sync outputs a deterministic plan without downloading
- State enables idempotent runs and consistent episode numbering

### Epic e3 — Serialized download stage
**Goal**  
Download required videos and thumbnails in a strictly serialized manner.

**Why This Epic Exists**  
Serial downloads reduce complexity and comply with stated constraints.

**In Scope**
- Download staging directory conventions
- Serialized `yt-dlp` downloads for pending items
- State updates for download success/failure

**Out of Scope**
- Metadata embedding or final import

**Key Decisions**
- Use `yt-dlp` as the download engine (`ADR-0002`)

**Interfaces / Contracts**
- Downloaded file locations referenced by later stages

**Risks & Mitigations**
- Risk: Large queues take too long.
- Mitigation: Keep processing/import parallelization available later.

**Definition of Done (Epic-level)**
This epic is complete when:
- Downloads run serially and update state for each item

### Epic e4 — Metadata embedding
**Goal**  
Embed titles, descriptions, artist/channel, and thumbnails into mp4 files.

**Why This Epic Exists**  
Plex requires embedded metadata to display content correctly.

**In Scope**
- Metadata extraction from `yt-dlp` outputs
- `AtomicParsley` tagging and thumbnail embedding
- Processed output files ready for import

**Out of Scope**
- Final naming and directory layout

**Key Decisions**
- Use `AtomicParsley` for mp4 metadata (`ADR-0002`)

**Interfaces / Contracts**
- Processed mp4 outputs consumed by the import stage

**Risks & Mitigations**
- Risk: Metadata fields are missing or malformed.
- Mitigation: Log per-item failures and preserve state.

**Definition of Done (Epic-level)**
This epic is complete when:
- Processed mp4 files contain required metadata and thumbnails

### Epic e5 — Plex import and cleanup
**Goal**  
Rename and move processed videos into the Plex-compatible `youtube/` layout and
remove source artifacts.

**Why This Epic Exists**  
Plex discovery relies on specific naming and directory rules, and storage must
remain single-copy.

**In Scope**
- Directory naming per channel/playlist
- Filename format `<name> - S01EXX - <title>.mp4`
- Cleanup of staging artifacts after successful import
- Collision handling and logging

**Out of Scope**
- Downloading or metadata embedding

**Key Decisions**
- One season per subscription (no season directories)

**Interfaces / Contracts**
- Destination library structure under `youtube/`

**Risks & Mitigations**
- Risk: Naming collisions or unsafe filenames.
- Mitigation: Deterministic sanitization and collision handling rules.

**Definition of Done (Epic-level)**
This epic is complete when:
- Imported media conforms to Plex naming/layout and source copies are removed

## Milestone m2 — Operational readiness

### Epic e6 — Test harness and fixtures
**Goal**  
Provide fast, deterministic tests for core logic without full downloads.

**Why This Epic Exists**  
Testability is an explicit requirement, and CI must run quickly.

**In Scope**
- Unit tests for parsing, filtering, ordering, naming, and state logic
- Small fixtures or mocks that avoid network downloads

**Out of Scope**
- End-to-end downloads of real videos

**Key Decisions**
- Favor minimal bash-compatible testing approaches

**Interfaces / Contracts**
- Test entrypoint(s) and fixtures directory

**Risks & Mitigations**
- Risk: Tests become flaky due to network usage.
- Mitigation: Use local fixtures only.

**Definition of Done (Epic-level)**
This epic is complete when:
- Tests run in under 5 minutes and validate core behaviors

### Epic e7 — CI pipeline
**Goal**  
Run linting and unit tests in CI to validate every change.

**Why This Epic Exists**  
Automated checks enforce baseline quality and regressions are caught early.

**In Scope**
- GitHub Actions workflow
- Separate linting and unit test jobs
- Tool installation required for linting/tests

**Out of Scope**
- Deployment or release automation

**Key Decisions**
- CI targets lint and unit tests as distinct jobs

**Interfaces / Contracts**
- `.github/workflows/*` configuration

**Risks & Mitigations**
- Risk: CI lacks tools used locally.
- Mitigation: Explicitly install required tools in workflow.

**Definition of Done (Epic-level)**
This epic is complete when:
- CI runs lint and unit tests in separate jobs successfully

### Epic e8 — Documentation
**Goal**  
Provide a clear README for installation, configuration, and usage.

**Why This Epic Exists**  
Users need concise instructions to set up dependencies and run the pipeline.

**In Scope**
- README describing setup, dependencies, and usage
- Configuration and skip rule documentation
- Example command usage

**Out of Scope**
- Expanded user guides beyond README

**Key Decisions**
- Keep documentation focused on CLI usage and configuration

**Interfaces / Contracts**
- `README.md`

**Risks & Mitigations**
- Risk: README diverges from actual behavior.
- Mitigation: Document after core pipeline exists.

**Definition of Done (Epic-level)**
This epic is complete when:
- README enables a new user to install and run the tool

## Epic Dependency Notes
- Epic e1 (configuration and logging) must precede e2-e5.
- Epic e2 provides ordering/state inputs for e3-e5.

## Epic Granularity Guidelines
Epics should:
- Represent a **coherent capability**, not a grab-bag of tasks
- Be small enough to reason about in isolation
- Be large enough that splitting them further would reduce clarity

If an epic:
- Spans multiple milestones → split it
- Contains unrelated capabilities → split it
- Collapses to a single trivial story → consider inlining or merging
