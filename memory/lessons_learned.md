# Lessons Learned - Context Trauma Purge

## 🛠️ Infrastructure & API
- **YouTube API/Transcripts:** Attempting large-scale transcript fetching (Gsheets/Batch) often fails due to token limits or IP rate-limiting. 
- **Resolution:** Moved to `qmd` for local hybrid search of indexed local docs. For YT, fetch selectively via `video-frames` or use a specialized sub-agent (research-swarm) with chunking.
- **Status:** Resolved Feb 2026. Do not re-attempt 50+ batch fetches in main context.

## 🦎 Orchestration Patterns
- **Complexity-Based Routing:** (Feb 2026) Moving away from keyword triggers to L1/L2/L3 triage. Improved reliability of special-purpose agents like Sonnet for TDD building.
- **Model Drift:** Standardized the fleet names between `AGENTS.md` and `TASK_ROUTING.md`.

## 🏗️ QS Automation (Engineering)
- **Data SDL:** Confirmed SDL (Standard Data Layout) as the mandatory foundation for all Excel tools to prevent "Magic Cell" logic failures.
- **VBA Matching:** Standardized on `Scripting.Dictionary` for 1000+ row datasets.

## Evolver loop death (2026-03-20) — SUPERSEDED
- **Status:** EVOLVER REMOVED from workspace on 2026-03-21 per Henry's request.
- This entry is kept for historical reference only.
- No further evolver monitoring needed.
