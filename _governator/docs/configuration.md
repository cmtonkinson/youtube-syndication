# Configuration Schema (Filters and Paths)

This document defines the local configuration inputs used to control skip
filters and filesystem paths. It is intentionally bash-friendly and does not
require any non-standard tooling.

## Configuration Files

### subscriptions.txt (required)
- Location: user-managed file; typically in the working directory.
- Format: one YouTube identifier per line (channel or playlist).

### yts.conf (optional)
- Location: same directory as `subscriptions.txt` by default.
- Override: `YTS_CONFIG` environment variable may point to an alternate file.
- If the file is missing, defaults apply for all settings.

## File Format Rules (yts.conf)
- ASCII, line-based `KEY=VALUE` pairs.
- Blank lines are ignored.
- Comments start with `#` as the first non-space character.
- Keys are uppercase snake case.
- Values are single-line strings; quote with `"` if spaces are needed.
- No shell expansion or command execution is permitted when parsing.
- Unknown keys are rejected as configuration errors.

## Schema

| Key | Type | Default | Purpose |
| --- | ---- | ------- | ------- |
| `SKIP_SHORTS` | boolean | `true` | Skip shorts by default; set `false` to include them. |
| `SKIP_LIVESTREAMS` | boolean | `true` | Skip livestreams by default; set `false` to include them. |
| `MAX_SIZE_MB` | integer | `0` | Skip videos larger than this size (in MiB). `0` disables. |
| `MAX_DURATION_MIN` | integer | `0` | Skip videos longer than this duration (in minutes). `0` disables. |
| `TITLE_SKIP_REGEX` | string | empty | Skip videos whose title matches the regex. Empty disables. |
| `LIBRARY_DIR` | path | `./youtube` | Plex library root containing per-subscription folders. |
| `STAGING_DIR` | path | `./staging` | Temporary workspace for downloads and processing. |
| `STATE_DIR` | path | `./state` | Root for JSON state and metadata caches. |

## Validation Rules

### Booleans
- Accepted values (case-insensitive): `true`, `false`, `1`, `0`, `yes`, `no`.
- Empty values are treated as missing and fall back to defaults.

### Size and duration limits
- Must be non-negative integers.
- `0` disables the respective filter.
- When set, any video with a larger size or longer duration is skipped.

### Title pattern
- `TITLE_SKIP_REGEX` uses a Bash ERE-compatible pattern.
- Invalid regex syntax is a configuration error.

### Paths
- Relative paths are resolved from the directory containing `yts.conf`.
- Paths must be writable and refer to directories (created if missing).
- `LIBRARY_DIR`, `STAGING_DIR`, and `STATE_DIR` must be distinct.

## Example yts.conf

```ini
# Skip rules
SKIP_SHORTS=true
SKIP_LIVESTREAMS=true
MAX_SIZE_MB=2048
MAX_DURATION_MIN=90
TITLE_SKIP_REGEX="(trailer|teaser)"

# Paths
LIBRARY_DIR=./youtube
STAGING_DIR=./staging
STATE_DIR=./state
```
