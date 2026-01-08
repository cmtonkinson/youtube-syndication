# Project: YouTube Syndication
A CLI tool to automatically curate YouTube content for consumption through Plex.

## Overview
### Input:
- a configuration file called `subscriptions.txt` containing a list of YouTube identifiers (on per line)
- each identifier will refer to a creator channel or playlist

### Output:
- a managed directory of content called `youtube` which contains post-processed content for native Plex consumption

## Plex Expectations
Plex will be configured to read the `youtube` directory as "TV" content. For example:

```
youtube/
  DoshDoshington/
    DoshDoshington - S01E09 - How hard is it to beat SPACE EXPLORATION The 300 Hour Factorio Mod.mp4
    DoshDoshington - S01E11 - How Hard is it to Beat SPACE EXPLORATION The Second Coming.mp4
    DoshDoshington - S01E14 - How Hard is it to Beat Space Exploration The Final Frontier.mp4
  DocJade/
    DocJade - S01E12 - Krastorio First Steps - EP 1.mp4
```

**Directory/file rules:**
- All videos should be mp4
- All thumbnails should be jpg
- Every subscription should be presented as a single season, with no season directories
- The directory name should match the channel/playlist name
- The video filenames should match the pattern `<channel/playlist name> - S01EXX - <title>.mp4`
- Video title, description, artist, and thumbnail should be embedded into the mp4 metadata
- "episode" numbers should be derived from publication date, in chronological order
    - e.g. the first video published should be S01E01, the second video published should be S01E02, etc.

## Workflow
1. Sync - figure out which videos need to be downloaded
2. Download - download the videos
3. Process - extract metadata from the downloaded videos and embed it into the mp4
4. Import - rename & move the videos where Plex can see them

## Notes:
- downloading should use the `yt-dlp` tool
- embedding should use the `AtomicParsley` tool
- metadata may be kept locally in JSON format
- shorts and livestreams should be skipped by default, if possible
- videos over a configurable length or size should be skipped
- videos matching a configurable title pattern should be skipped
- downloading should be serialized
- processing & importing may be parallelized
- "source" copies of the videos may not be kept; only the "destination" copies should be kept
- use bash for this project; try to avoid depending on other languages (e.g. ruby, python, etc)
- one main executable entrypoint called `yts.sh`; you may create/use subcommands if helpful
- testability is a priority, but tests should not block on long downloads
- you may keep a handful of small (file size) videos locally for testing
- create a proper README.md for the project
- create a CI pipeline for the project using GitHub Actions and run each of the following in a separate job:
    - linting
    - unit tests
