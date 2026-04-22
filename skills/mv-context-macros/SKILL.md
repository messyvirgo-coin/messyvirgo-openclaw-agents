---
name: mv-context-macros
description: Use when reading current or historical Messy Virgo macro context snapshots, checking macro regime score and indicator state, or resolving macro KPI and macro score ids from the live catalog.
---

# Context Macros

## Overview

`mv context macros` reads the persisted daily macro context snapshot and the live macro KPI and score catalogs. Use `get` for the current or historical macro backdrop. Use `kpis` and `scores` to discover stable ids and read definition metadata.

Out of scope: screening execution, sleeve screening context, or persisted screening runs — use **mv-screening-configuration** or **mv-screening-execution** for screening workflows.

## Quick Choice

- Need the current or historical macro snapshot: `get`
- Need the final score, regime label, or raw indicator map: `get`
- Need KPI ids or KPI metadata: `kpis list` or `kpis get`
- Need score ids or score metadata: `scores list` or `scores get`
- Passing output to code or another agent: use `--json`

## Discover

```bash
mv context --help
mv context macros --help
mv context macros get --help
mv context macros kpis list --help
mv context macros kpis get --help
mv context macros scores list --help
mv context macros scores get --help
mv context macros kpis --help
mv context macros scores --help
```

## Commands

- `mv context macros get --json`
  Reads the latest available macro snapshot.
- `mv context macros get --as-of 2026-04-16 --json`
  Reads the latest snapshot on or before the requested date.
- `mv context macros kpis list --json`
- `mv context macros kpis list --lens-key macros --json`
  Lists KPI definitions. `--lens-key` is optional; `macros` is the normal value here.
- `mv context macros kpis get macro_kpi_global_liquidity --json`
  Returns one KPI definition by exact id.
- `mv context macros scores list --json`
- `mv context macros scores get macro_score_final --json`
  Same pattern for score definitions.

Commands already return structured output by default. Use `--json` when you want the machine-readable contract made explicit.

## Snapshot Contract

- `get` returns:
  - `snapshot_date`
  - `synced_at`
  - `macro_score`
  - `macro_score_ema_3d`
  - `macro_score_ema_7d`
  - `macro_score_ema_30d`
  - optional `macro_regime_label`
  - `indicator_values`
- `macro_score` is the curated top-level projection of `indicator_values["macro_score_final"]`.
- `macro_regime_label` is the curated top-level projection of `indicator_values["macro_score_final__interpretation_label"]`.
- `indicator_values` is the full machine-readable field map. It contains:
  - base KPI values keyed by `macro_kpi_*`
  - KPI facets such as `__score`, and for some KPIs also `__previous` and `__delta_pct`
  - score values keyed by `macro_score_*`
  - final-score facets such as `macro_score_final__ema_3d`, `__ema_7d`, `__ema_30d`, and `__interpretation_label`

## Catalog Contract

- `kpis list` returns `{ "definitions": [...] }`.
- `kpis get <kpi_id>` returns one KPI definition object.
- KPI definitions include identity and display fields such as `kpi_id`, `name`, `category`, `unit`, `period`, `direction`, `value_type`, `groups`, plus optional metadata like `thresholds`, `scale`, `related_kpis`, `render_as`, and `tone_rules`.
- `scores list` returns `{ "definitions": [...] }`.
- `scores get <score_id>` returns one score definition object.
- Score definitions include `score_id`, `name`, `category`, `kind`, `weight_default`, and `groups`.
- Treat KPI ids and score ids as live catalog data. Do not invent them.
- If a user asks by human name and the id is unknown, list first and then get the exact id.

## Common Mistakes

- Treating `snapshot_date` as “the requested date” instead of the resolved snapshot on or before `--as-of`.
- Assuming `get --as-of` returns empty success when history is too early. It returns `MACROS_CONTEXT_NOT_FOUND`.
- Assuming every KPI has both `__previous` and `__delta_pct`. Some have only `__score`; some have `__previous` but no `__delta_pct`.
- Confusing top-level `macro_score` with the pillar scores inside `indicator_values`.
- Inventing KPI ids or score ids instead of using the live catalog.
- Using `--as-of` on catalog commands. It only applies to `context macros get`.
- Treating `macro` as spreadsheet macros or command macros instead of macroeconomics context.
- Treating `indicator_values` as arbitrary prose instead of stable machine keys aligned to the macro catalogs.
