---
name: mv-context-narratives
description: Use when ranking Messy Virgo crypto narratives, drilling into one narrative by id or exact label, comparing narrative momentum against TOTAL3ES, BTC, or ETH, resolving which Messy narratives a master-catalog token belongs to, or retrieving a historical narratives snapshot with as-of dates.
---

# Context Narratives

## Overview

`mv context narratives` is read-only. Use `list` for ranked narrative momentum and `get` for one narrative detail. The CLI intentionally returns a normalized ranking/detail view, not the raw API payload.

Use **mv-context-macros** for macro regime snapshots or macro KPI/score catalogs.

If the question is token-centric, resolve the token first with `mv tokens get` or `mv tokens resolve`, then inspect `narratives[]`.

## Commands

```bash
mv context narratives list [--as-of YYYY-MM-DD] [--include-stable] --json
mv context narratives get <narrative_id_or_exact_label> [--as-of YYYY-MM-DD] --json
mv tokens get --token-id <id> --json
mv tokens get --chain <chain> --contract-address <address> --json
mv tokens resolve --token-ids 1,2,3 --json
mv tokens resolve --pair base:0x... --json
```

Run `mv context narratives --help` or command help when unsure.

## Rules

- `list` ranks narratives and excludes stable narratives unless `--include-stable` is set.
- `get` accepts canonical `narrative_id` or exact case-insensitive label. It does not do fuzzy matching.
- Historical calls resolve the latest snapshot on or before `--as-of`.
- `list.rows[]` includes `rank`, narrative identity, `is_stable`, current market cap/volume, `change_pct_by_window`, and flattened `relative_pp_by_baseline`.
- Window keys are strings: `"15"`, `"30"`, `"60"`. Detail output also includes horizon `"0"` inside each baseline series.
- `list.relative_pp_by_baseline.TOTAL3ES` is the primary ranking signal. `TOTAL3ES` is the CLI-facing name for the API baseline `altcap_ex_stables`.
- `relative_pp_by_baseline` is anchored outperformance in percentage points, not price return.
- `null` means unavailable history; never coerce it to zero.
- `mv tokens get` is flag-only. Do not expect a bare `233` after the command; oclif treats extra words as subcommand names, which produces `command tokens:get:<word> not found`.

## Common Mistakes

- Using partial labels such as `"AI"` instead of an exact label or id.
- Treating `change_pct_by_window["60"]` as the ranking signal.
- Forgetting stable narratives are excluded by default.
- Assuming raw API fields such as `synced_at`, `baselines`, or `narratives[]` appear in CLI output.
- Mixing narrative momentum with macro context.
- Guessing token narratives from symbol alone when a canonical `token_id` is already available.
