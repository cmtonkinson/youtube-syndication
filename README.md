# YouTube Syndication (yts.sh)

A bash-based CLI pipeline that curates YouTube content into a Plex-friendly
library layout.

## Requirements

- Bash (macOS/Linux)
- `yt-dlp` (listing, downloading, metadata extraction)
- `AtomicParsley` (metadata embedding; required by preflight checks)
- Standard Unix tools: `awk`, `sed`, `sort`, `mktemp`, `grep`
- Lint/test tooling: none defined yet in this repository.

## Setup

1. Install dependencies (`yt-dlp`, `AtomicParsley`).
2. Create `subscriptions.txt` in the repository root.
3. (Optional) Create `yts.conf` alongside `subscriptions.txt` (or set
   `YTS_CONFIG` to point elsewhere).

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
- Blank lines and lines starting with `#` are ignored.

Example:
```
https://www.youtube.com/@DoshDoshington
https://www.youtube.com/playlist?list=PLxyz123
```

### yts.conf (optional)

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
- The file is optional; defaults apply when it is missing.
- Relative paths are resolved from the directory containing `yts.conf`.
- `LIBRARY_DIR`, `STAGING_DIR`, and `STATE_DIR` must be distinct writable
  directories.

## Usage

Run the full pipeline (sync -> download -> process -> import):
```
./yts.sh
```

Show help:
```
./yts.sh --help
```

Run with an alternate config file:
```
YTS_CONFIG=/path/to/yts.conf ./yts.sh
```

Stage behavior:
- `sync`: lists each subscription with `yt-dlp`, applies skip filters, writes
  JSON state and metadata cache files under `STATE_DIR`.
- `download`: downloads pending items into `STAGING_DIR/<subscription>/` using
  `yt-dlp` and updates state with file paths.
- `process`: ensures `.info.json` metadata exists (fetches if missing) and
  embeds title/artist/description/artwork into the mp4 with `AtomicParsley`.
- `import`: moves processed mp4/jpg files into the Plex library layout under
  `LIBRARY_DIR`, naming files as `Name - S01E## - Title`.

## Skip Filters (sync stage)

These filters are configured via `yts.conf` and applied during `sync`:
- Shorts: skipped when `SKIP_SHORTS=true` (shorts are <= 60s)
- Livestreams: skipped when `SKIP_LIVESTREAMS=true`
- Size limit: `MAX_SIZE_MB` (MiB), `0` disables
- Duration limit: `MAX_DURATION_MIN` (minutes), `0` disables
- Title pattern: `TITLE_SKIP_REGEX` (bash ERE), empty disables

## Output Layout

### State (sync output)

Sync writes one JSON state file per subscription plus a metadata cache. The
file name is a slugged version of the subscription string (non-alphanumeric
characters become `_`):
```
state/
  <subscription>.json
  <subscription>.metadata.json
```

### Staging (download/process output)

Downloads are written under `STAGING_DIR` (default `./staging`):
```
staging/
  <subscription>/
    <video_id>.mp4
    <video_id>.jpg
    <video_id>.info.json
```

### Plex Library (target layout)

Videos are placed in `LIBRARY_DIR` (default `./youtube`) using Plex TV naming
rules:
```
youtube/
  ChannelName/
    ChannelName - S01E01 - Video Title.mp4
    ChannelName - S01E01 - Video Title.jpg
```

Rules:
- One folder per subscription (channel/playlist name).
- All videos are `.mp4` and thumbnails are `.jpg`.
- Episode numbers are chronological by publish date (S01E01, S01E02, ...).
