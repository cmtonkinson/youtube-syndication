# Wardley Map

## User Need
Keep a Plex library synchronized with selected YouTube sources and consistent
metadata.

## Value Chain
| Component | Purpose | Evolution Stage | Build / Buy / Reuse | Rationale |
|----------|---------|-----------------|---------------------|-----------|
| subscriptions.txt + filters | Express user intent | Custom | Build | Project-specific input format and rules. |
| Sync orchestration | Decide what to fetch/process | Custom | Build | Differentiates via idempotent behavior. |
| Download engine (yt-dlp) | Fetch media and metadata | Commodity | Reuse | Mature external tool with broad support. |
| Metadata embedding (AtomicParsley) | Write tags/thumbnails | Product | Reuse | Established utility for mp4 tagging. |
| Plex layout rules | Ensure media is discoverable | Custom | Build | Specific to Plex TV expectations. |
| Local filesystem storage | Persist media and state | Commodity | Reuse | Standard OS capability. |

## Strategic Notes
- Where we deliberately avoid differentiation: download and metadata tooling.
- Where we must invest: deterministic naming, idempotent sync, and filtering.
