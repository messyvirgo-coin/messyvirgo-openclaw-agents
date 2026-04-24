---
name: mv-context-macros
description: Use when reading current or historical Messy Virgo macro context snapshots, checking macro regime score and indicator state, or resolving macro KPI and macro score ids from the live catalog.
---

# Context Macros

## Overview

`mv context macros` is read-only. Use it for daily macro backdrop snapshots and the live macro KPI/score catalogs. It is not for screening, narratives, or spreadsheet-style macros.

Use `--json` whenever another agent, script, or persisted artifact will consume the output.

## Commands

```bash
mv context macros get [--as-of YYYY-MM-DD] --json
mv context macros kpis list [--lens-key macros] --json
mv context macros kpis get <kpi_id> --json
mv context macros scores list [--lens-key macros] --json
mv context macros scores get <score_id> --json
```

Run `mv context macros --help` or nested topic help when unsure.

## Rules

- `get` returns the latest snapshot on or before `--as-of`; without `--as-of`, it returns the latest available snapshot.
- Too-early history returns `MACROS_CONTEXT_NOT_FOUND`, not an empty success.
- Snapshot output includes `snapshot_date`, `synced_at`, `macro_score`, EMA fields, optional `macro_regime_label`, and `indicator_values`.
- `macro_score` projects `indicator_values["macro_score_final"]`.
- `macro_regime_label` projects `indicator_values["macro_score_final__interpretation_label"]`.
- `indicator_values` contains stable `macro_kpi_*`, `macro_score_*`, and facet keys such as `__score`, `__previous`, `__delta_pct`, `__ema_3d`, and `__interpretation_label`.
- KPI and score ids are live catalog data. If the exact id is unknown, list first, then get the exact id.

## Common Mistakes

- Treating `snapshot_date` as the requested date instead of the resolved available date.
- Inventing KPI or score ids from human labels.
- Assuming every KPI has every facet; some only expose `__score`.
- Using `--as-of` on catalog commands; it applies only to `context macros get`.
- Confusing top-level `macro_score` with individual pillar or KPI scores in `indicator_values`.
