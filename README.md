# YouTube Syndication (yts.sh)

A bash-based CLI pipeline that curates YouTube content into a Plex-friendly
library layout.

## Requirements

- Bash (macOS/Linux)
- `yt-dlp` (downloads video + thumbnails)
- `AtomicParsley` (metadata embedding; required by preflight checks)
- Lint/test tooling: none defined yet in this repository.

## Setup

1. Install dependencies (`yt-dlp`, `AtomicParsley`).
2. Create `subscriptions.txt` in the repository root.
3. (Optional) Create `yts.conf` alongside `subscriptions.txt`.

## Development

Lint scripts with:
```
./scripts/lint.sh
```

Run unit tests with:
```
./scripts/test.sh
```

Notes:
- Linting requires `shellcheck` (install via `brew install shellcheck` or
  `apt-get install shellcheck`).

## Configuration

### subscriptions.txt (required)

- Location: repository root (same directory as `yts.sh`).
- Format: one YouTube identifier per line (channel or playlist).

Example:
```
https://www.youtube.com/@DoshDoshington
https://www.youtube.com/playlist?list=PLxyz123
```

### yts.conf (optional, schema documented)

Configuration is defined in `_governator/docs/configuration.md`. The schema is
bash-friendly `KEY=VALUE` pairs with defaults:

```
# Skip rules
SKIP_SHORTS=true
SKIP_LIVESTREAMS=true
MAX_SIZE_MB=0
MAX_DURATION_MIN=0
TITLE_SKIP_REGEX=""

# Paths
LIBRARY_DIR=./youtube
STAGING_DIR=./staging
STATE_DIR=./state
```

Notes:
- The config file format and defaults are documented, but parsing is not wired
  into `yts.sh` yet. The current script only reads `STATE_DIR`/`STAGING_DIR`
  from environment variables.
- When filtering is implemented, skip defaults are:
  shorts/livestreams skipped, size/duration limits disabled (`0`), and an empty
  title regex disables the filter.

## Usage

Run the full pipeline:
```
./yts.sh
```

Show help:
```
./yts.sh --help
```

Current stage behavior:
- `sync`: placeholder (no-op)
- `download`: implemented; pulls videos listed in state files
- `process`: placeholder (no-op)
- `import`: placeholder (no-op)

The download stage expects JSON state files in `STATE_DIR` (default `./state`).
Each file represents a subscription and contains per-video records. If the
state directory or files are missing, downloads are skipped.

## Skip Filters (planned)

These filters are configured via `yts.conf` and will be applied by the `sync`
stage once implemented:
- Shorts: skipped by default (`SKIP_SHORTS=true`)
- Livestreams: skipped by default (`SKIP_LIVESTREAMS=true`)
- Size limit: `MAX_SIZE_MB` (MiB), `0` disables
- Duration limit: `MAX_DURATION_MIN` (minutes), `0` disables
- Title pattern: `TITLE_SKIP_REGEX` (bash ERE), empty disables

## Output Layout

### Staging (current download output)

Downloads are written under `STAGING_DIR` (default `./staging`):
```
staging/
  <subscription>/
    <video_id>.mp4
    <video_id>.jpg
```

### Plex Library (target layout)

When `import` is implemented, videos will be placed in `LIBRARY_DIR` (default
`./youtube`) using Plex TV naming rules:
```
youtube/
  ChannelName/
    ChannelName - S01E01 - Video Title.mp4
```

Rules:
- One folder per subscription (channel/playlist name).
- All videos are `.mp4` and thumbnails are `.jpg`.
- Episode numbers are chronological by publish date (S01E01, S01E02, ...).
