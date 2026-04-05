---
name: mv-screening-configuration
description: Use when inspecting or changing a Messy Virgo fund sleeve's screening context, including custom queries, workflow steps, or instructions.
---

# Screening Configuration

## Overview

This skill is context-first. **Sleeve screening context** (`fund_sleeves.meta.screening`) is canonical and includes `custom_queries`, an ordered `workflow` (`template` / `query` steps), and freeform `instructions`.

## When to Use

- The user wants to inspect the current screening setup for one fund **sleeve**.
- The user wants to change what future screening runs will do for that sleeve.
- The user wants to add, update, or remove a saved custom query for one sleeve.
- The user wants to pull one sleeve's workflow into a local file, edit it, and push it back.

## Prerequisites

- The exact `fund_id` and **`sleeve_id`** must be explicit before doing sleeve-specific configuration work. Use `list_fund_sleeves(fund_id)` when the sleeve id is unknown.
- Do not guess the fund or sleeve from a name, nickname, prior example, or fallback lookup.

## Core Workflow

1. Read the current state first with `get_sleeve_screening_context(fund_id, sleeve_id)`.
2. Decide whether the change affects `custom_queries`, `workflow.steps`, `instructions`, or all three.
3. When saving, send a **full replace** payload through `replace_sleeve_screening_context`: `request.custom_queries`, `request.workflow`, and `request.instructions` are all required.
4. Re-read with `get_sleeve_screening_context` to confirm the saved context matches what was intended.

## Quick Reference

| Task | Action |
| ------ | ---------- |
| Inspect current setup | Call `get_sleeve_screening_context(fund_id, sleeve_id)` first. This returns templates, `custom_queries`, `workflow`, and `instructions`. |
| Inspect template library | Use `mv://screening-templates` or `mv://screening-templates/{template_id}`. Templates are curated and read-only. |
| Inspect screening catalog | Indicator catalog: **`mv://token-dd/indicator-catalog`**. For screening-filtered KPI/score definitions: **`mv://token-dd/screening/kpis`** and **`mv://token-dd/screening/scores`**. Unfiltered KPI/score lists: **`mv://token-dd/kpis`** and **`mv://token-dd/scores`**. |
| Test a custom query | Read `mv://token-dd/indicator-catalog`, then call `screen_sleeve_tokens` with flat args: `fund_id`, **`sleeve_id`**, `scope`, optional `snapshot_date`, `filters`, `order_by`, `fields`, and `limit`. Set `limit` to the user-specified top-N or **20** if not specified; **never use more than 20** for a custom query. If using **`mcporter call`** from a shell, use **named** parameters and **single-quoted** JSON for `filters` / `fields` (see `mv-screening-execution` → **mcporter CLI**). |
| Save context | Choose a descriptive `query_id` such as `high-momentum-liquid`. In `custom_queries`, use `query_id` as the identifier field, not `id`. For `workflow.steps`, `kind: "query"` steps must reference that same `query_id` in `step.id`. Build the nested `request` payload with `custom_queries`, `workflow`, and `instructions`, then call `replace_sleeve_screening_context`. Keep authored `request.limit` at or below **20**. If the tool returns an error, report it verbatim and fix the payload shape rather than inventing fallback ids or selectors. |

## mcporter Safety

Use this section when invoking `replace_sleeve_screening_context` through `mcporter call` in a shell.

- Prefer a full `--args` JSON payload for this tool. It has a nested `request` object, and flat positional/flag mixes are easy to misparse.
- The top-level payload must include `fund_id`, `sleeve_id`, and `request`.
- `request` must include `custom_queries`, `workflow`, and `instructions`.
- Each saved custom query uses `query_id`, not `id`.
- Each `workflow.steps` entry for `kind: "query"` must use the corresponding `query_id` in `id`.

```bash
mcporter call messy-virgo-funds.replace_sleeve_screening_context --args '{
  "fund_id": "mvf-example",
  "sleeve_id": "mvs-example-1",
  "request": {
    "custom_queries": [
      {
        "query_id": "high-momentum-liquid",
        "name": "High momentum liquid",
        "description": "Universe screen for strong performance names",
        "request": {
          "filters": [
            {"field": "score_performance_final", "op": "gte", "value": 65}
          ],
          "order_by": "-score_performance_final",
          "fields": ["score_performance_final", "score_social_final"],
          "limit": 20
        }
      }
    ],
    "workflow": {
      "version": 1,
      "steps": [
        {"kind": "template", "id": "momentum_combo_v1"},
        {"kind": "query", "id": "high-momentum-liquid"}
      ]
    },
    "instructions": "Run the template first, then the custom momentum screen."
  }
}'
```

## Common Mistakes

- Trying to configure a sleeve before the exact `fund_id` and `sleeve_id` are explicit.
- Saving a draft query without persisting the full context through `replace_sleeve_screening_context`.
- Using `limit` above **20** on a custom query (platform may cap or warn; keep the authored request at or below 20).
- Updating `custom_queries` without updating `workflow` references (or vice versa).
- Using `id` inside `custom_queries` instead of `query_id`.
- Forgetting that `replace_sleeve_screening_context` expects a nested `request` object.
- Mixing positionals with `--request` or other flags in `mcporter` and getting misleading validation errors. Prefer one full `--args` payload.
- Inventing `template:<id>` or `query:<id>` references instead of resolving real ids.
- Retrying validation failures with made-up selector names or operators.

`mv-screening-execution` runs the canonical sleeve context and persists immutable screen runs. This skill changes future behavior by editing the sleeve context.
