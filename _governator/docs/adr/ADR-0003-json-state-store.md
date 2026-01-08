# ADR-0003: File-Based JSON State Store

## Status
Accepted

## Context
The system must support idempotent, resumable runs and avoid re-downloading or
reprocessing videos. The project prefers bash and minimal dependencies.

Alternatives considered:
- No state (recompute on every run).
- SQLite database for state and metadata.

## Decision
Use a file-based JSON state store (per subscription and/or per run) to record
video identifiers, publish dates, and processing status.

## Consequences

Positive:
- Simple to manage in bash and easy to inspect or back up.
- Supports deterministic idempotent behavior.

Negative:
- Requires careful handling to avoid partial writes or corruption.
- Limited query capabilities compared to a database.

Tradeoffs accepted:
- Prefer simplicity and portability over richer querying.

## Notes

- Date: 2026-01-08
- Related ASRs: ASR-2, ASR-4, ASR-5
- Related Tasks: _governator/task-assigned/000-architecture-bootstrap-architect.md
