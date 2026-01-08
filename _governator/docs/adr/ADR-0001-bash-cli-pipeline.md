# ADR-0001: Bash CLI Pipeline

## Status
Accepted

## Context
The project is required to deliver a single CLI entrypoint and avoid depending
on other languages. The solution must orchestrate a multi-stage pipeline
(sync, download, process, import) while remaining easy to run on typical
workstations and NAS devices.

Alternatives considered:
- Python or Go CLI for richer parsing and concurrency.
- Makefile-based orchestration with mixed shell scripts.

## Decision
Adopt a bash-first CLI architecture with a single `yts.sh` entrypoint that
orchestrates the pipeline stages.

## Consequences

Positive:
- Aligns with explicit project constraints and minimizes dependencies.
- Simple installation and execution on standard Unix environments.

Negative:
- Complex parsing and data handling are harder in bash.
- Concurrency and structured logging are more limited.

Tradeoffs accepted:
- Rely on external tools and small JSON state files instead of a richer
  internal runtime.

## Notes

- Date: 2026-01-08
- Related ASRs: ASR-2, ASR-4, ASR-5
- Related Tasks: _governator/task-assigned/000-architecture-bootstrap-architect.md
