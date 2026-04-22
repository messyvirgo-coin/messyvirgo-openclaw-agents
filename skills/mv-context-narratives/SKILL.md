---
name: mv-context-narratives
description: Use when ranking Messy Virgo crypto narratives, drilling into one narrative by id or exact label, comparing narrative momentum against TOTAL3ES, BTC, or ETH, or retrieving a historical narratives snapshot with as-of dates.
---

# Context Narratives

## Overview

`mv context narratives` is a read-only CLI over the point-in-time narratives trend snapshot. Use `list` for ranking and `get` for one narrative detail. The CLI is a projection of `/api/v1/context/narratives/trend`, not the raw API payload, so interpret the CLI fields exactly as documented here.

Out of scope: macro regime snapshots, KPI/score catalogs, or macroeconomics context. Use **mv-context-macros** for those.

## Quick Choice

- Strongest or weakest narratives now or on a date: `list`
- One narrative deep-dive across baselines and horizons: `get`
- Need stable narratives included in ranking: `list --include-stable`
- Need historical point-in-time output: add `--as-of YYYY-MM-DD`
- Passing output to code or another agent: use `--json`

## Discover

```bash
mv context --help
mv context narratives --help
mv context narratives list --help
mv context narratives get --help
```

## Commands

- `mv context narratives list --json`
  Ranked `rows[]` view. Stable narratives are excluded by default.
- `mv context narratives list --include-stable --json`
  Same ranking view, but includes `is_stable: true` rows.
- `mv context narratives list --as-of 2026-04-10 --json`
  Resolves the latest snapshot on or before the requested date.
- `mv context narratives get ai-agents --json`
- `mv context narratives get "AI Agents" --json`
  `get` accepts canonical `narrative_id` or exact case-insensitive label.
- `mv context narratives get ai-agents --as-of 2026-04-10 --json`
  One narrative detail for a historical snapshot.

Commands already return structured output by default. Use `--json` when you want the machine-readable contract made explicit.

## CLI Contract

- `list` returns:
  - `snapshot_date`
  - `effective_anchor_date`
  - `included_stable`
  - `rows[]` with `rank`, `narrative_id`, `narrative_label`, `is_stable`, `current_market_cap`, `current_volume_24h`, `change_pct_by_window`, and `relative_pp_by_baseline`
- `list.change_pct_by_window` always uses string keys `"15"`, `"30"`, and `"60"`.
- `list.relative_pp_by_baseline` is flattened to one scalar per baseline: `TOTAL3ES`, `BTC`, `ETH`. These are the `0d` endpoint values used for ranking.
- `get` returns:
  - `snapshot_date`
  - `effective_anchor_date`
  - `anchor_days`
  - narrative identity and current fields
  - `change_pct_by_window` with `"15"`, `"30"`, `"60"`
  - `relative_pp_by_baseline` where each baseline contains the horizon series `"60"`, `"30"`, `"15"`, `"0"`

## How To Interpret

- `change_pct_by_window` is absolute market-cap percentage change vs N days ago.
- `relative_pp_by_baseline` is anchored relative momentum in percentage points, not price return and not the same metric as `change_pct_by_window`.
- In `list`, ranking is by `relative_pp_by_baseline.TOTAL3ES` descending, then `change_pct_by_window["60"]` descending, then `narrative_id` ascending.
- In `get`, horizon `"0"` is cumulative outperformance or underperformance from the anchor through `snapshot_date`.
- In `get`, horizon `"60"` is the anchor point. It is often `0`, but it can be `null` when sparse history prevents a shared anchor row.
- `effective_anchor_date` is the actual anchor used after walking forward when full 60-day history is unavailable. If it moves forward, some `"60"` values may be `null`.
- `null` means unavailable history. Never coerce it to zero.

## API Boundary

- The raw API payload includes `synced_at`, `windows_days`, `horizons_days`, `baselines`, and `narratives[]`.
- The CLI intentionally normalizes that payload into a ranking view (`list`) and a detail view (`get`).
- The API baseline id `altcap_ex_stables` becomes user-facing `TOTAL3ES` in CLI output.
- Do not assume raw API fields appear in CLI output.

## Common Mistakes

- Mixing `mv context narratives` with `mv context macros`.
- Using partial or fuzzy labels such as `"AI"` instead of a canonical id or exact label. Those fail with `NARRATIVE_NOT_FOUND`.
- Forgetting that `list` excludes stable narratives by default.
- Treating `change_pct_by_window["60"]` as the main ranking signal instead of `relative_pp_by_baseline.TOTAL3ES`.
- Treating `null` as flat performance instead of missing data.
- Treating the output as editorial prose instead of quantitative snapshot data.
