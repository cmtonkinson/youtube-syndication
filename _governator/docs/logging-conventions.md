# Logging and Run Summary Conventions

This document defines the required logging format and run summary outputs to
meet ASR-5 operational transparency.

## Log Line Format
All log lines are single-line, space-delimited `key=value` pairs (logfmt) with
the following required fields in this exact order:

```
ts=<rfc3339_utc> level=<LEVEL> event=<EVENT> run_id=<RUN_ID> stage=<STAGE> msg="<text>"
```

### Field Rules
- `ts`: RFC3339 UTC timestamp (e.g., `2026-01-08T21:24:52Z`).
- `level`: One of `DEBUG`, `INFO`, `WARN`, `ERROR`.
- `event`: Short, stable event name (see standard events below).
- `run_id`: Stable identifier for the run (e.g., `20260108T212452Z`).
- `stage`: One of `init`, `sync`, `download`, `process`, `import`, `finalize`.
- `msg`: Human-readable message. If it contains spaces, it MUST be quoted.

Optional fields may follow in `key=value` form and MUST be appended after the
required fields. If a value contains spaces, it MUST be quoted.

### Severity Level Semantics
- `DEBUG`: Diagnostic details, disabled by default.
- `INFO`: Normal pipeline progress.
- `WARN`: Non-fatal issues; run continues.
- `ERROR`: Item or run failure.

### Stream Routing
- `DEBUG` and `INFO` go to stdout.
- `WARN` and `ERROR` go to stderr.

## Standard Events
### `event=run_start`
Required fields: `stage=init`.
Optional fields: `subscriptions=<count>`, `config_path=<path>`.

### `event=video_outcome`
Required fields: `stage=<stage>`, `outcome=<success|skipped|failed>`,
`video_id=<id>`, `title="<title>"`.
Optional fields: `channel="<name>"`, `reason="<why>"`, `error="<message>"`.

### `event=run_summary`
Required fields: `stage=finalize`, `duration_s=<seconds>`,
`total=<count>`, `success=<count>`, `skipped=<count>`, `failed=<count>`,
`exit_code=<code>`.
Optional fields: `warnings=<count>`.

The summary line is emitted once per run and MUST appear even when failures
occur (best effort if the run aborts early).

## Run Summary Outputs
- A single `event=run_summary` log line is emitted to stdout.
- The same summary line is written to `./run-summary.logfmt` in the current
  working directory to provide a machine-readable artifact.

## Exit Status Rules
- `0`: Run completed with zero `outcome=failed` items.
- `2`: Run completed with one or more `outcome=failed` items (partial failure).
- `1`: Run aborted before completion due to a fatal error (preflight failure,
  corrupted state, or unrecoverable tool error).

Skipped items do not affect the exit status.
