---
name: mv-screening-execution
description: Use when running or rerunning a token screen for a specific Messy Virgo (MV / MESSY) fund for a given calendar day, or when a fund screening workflow needs to be executed and its results persisted to the platform.
---

# Screening Execution

## Overview

This skill runs one fund's configured token screening process for a specific day. Read `SCREENING.md` as the recipe, combine it with the fund's screening context, execute each valid run, build a universe-only shortlist of up to ten candidates, persist the daily result to the platform, and write one Markdown summary under `agent-workflows/screening/results/`.

Missing inputs, unresolved references, and validation failures must be reported explicitly. Do not guess values, infer a fund, or invent template/query ids.

## When to Use

- A scheduled or manual screening run is triggered for one fund.
- The user wants to run or rerun that fund's configured token screen.
- The user wants that day's shortlist and persisted screen result for one fund.
- The user wants to process today's screening results and save them to the platform.

## When Not to Use

- Do not use this skill to create the runtime workspace. That belongs to `mv-agent-setup`.
- Do not use this skill to edit `SCREENING.md`, templates, or saved custom queries. That belongs to `mv-screening-configuration`.
- Do not use this skill for generic template/query inspection without executing a screen.

## Prerequisites

- The exact `fund_id` must be explicit before execution starts.
- Do not guess the fund from a name, nickname, prior example, or "first accessible" fallback.
- The runtime workspace must already exist. If `agent-workflows/screening/SCREENING.md` or required directories are missing, stop and tell the user to run `mv-agent-setup` first.

## Core Workflow

1. Require an explicit `fund_id` and target screen day before doing fund-specific work.
2. Read `agent-workflows/screening/SCREENING.md` and load fund screening context for templates and saved custom queries.
3. Resolve each `template:<id>` and `query:<id>` reference, and mark runs with missing inputs or invalid refs instead of inventing fixes.
4. Execute each valid run with `screen_fund_tokens`, recording `scope`, status, and the resolved request. If a run returns `failed_error`, record it with that status and continue to the remaining runs.
5. Aggregate candidates only from executed `scope: universe` runs (see **Candidate eligibility** below), dedupe by `token_id`, assign a unique `rank` (1–10), and write substantive `candidate_reason` text per **Reasoning standards**.
6. Persist the day with `upsert_fund_token_screen`, then write one Markdown summary at `agent-workflows/screening/results/{screen_date}_{fund_id}.md`. The API is the canonical store; the Markdown file is the default operator-facing note.

## Candidate Eligibility

```
Token appeared in at least one executed scope: universe run?
  YES → eligible for candidates (include even if also in holdings runs)
  NO  → never add to candidates or pass to upsert_fund_token_screen
```

Holdings-only tokens must never appear in `candidates` regardless of how strongly they screen.

## Quick Reference

| Task | Action |
| ------ | --------- |
| Load baseline | Read `agent-workflows/screening/SCREENING.md`. |
| Load fund context | Call `get_fund_screening_context(fund_id)` or read `mv://funds/{fund_id}/screening-context` for templates and saved custom queries. |
| Resolve run references | `template:<id>` resolves from the template library. `query:<id>` resolves from the fund's `custom_queries`. Missing ids must produce `failed_validation`. |
| Handle conditions | If a run depends on unavailable input such as `risk_on`, mark it `skipped_missing_input`. Do not invent values. |
| Execute one run | Call `screen_fund_tokens` with flat args: `fund_id`, `scope`, optional `snapshot_date`, `filters`, `order_by`, `fields`, `limit`. Record each run in `runs` with `scope` set to `universe` or `holdings`. On `failed_error`, record status and continue. |
| Aggregate candidates | From executed `scope: universe` runs only: dedupe by `token_id`, assign `rank` 1–N (≤10, **unique per fund per day**), keep `source_run_ids`, and write **`candidate_reason`** as in **Reasoning standards**. |
| Persist the day | Call `upsert_fund_token_screen` with `screen_date` (`YYYY-MM-DD`), **`process_narrative`** (selection story, not a copy of `run_catalog`), `execution_trace`, `run_catalog`, and **at most ten** candidates with `token_id`, `rank`, and `candidate_reason`. Overwrites any prior save that day. |
| Write local summary | Write **exactly one** Markdown file at `agent-workflows/screening/results/{screen_date}_{fund_id}.md` unless the user explicitly asks not to. Do not create a paired JSON file. The API remains the source of truth. |

## Reasoning Standards

**`candidate_reason` (each shortlist token)**

Must justify the row in **data terms**, not artifact terms. Cite **concrete DD indicators, scores, or filter outcomes** from the `screen_fund_tokens` **results** for that token (field names and values or clear bands/ranks). **Do not** use only "from template X" / "matched query Y"—those refs belong in `source_run_ids` and `run_catalog`; readers need **what** in the numbers drove inclusion.

**`process_narrative` (whole day / whole workflow)**

Describe the **selection process**: sequence of runs, how hits were merged or cut to the shortlist (up to ten), branches and skips, what each universe run contributed, and brief honest notes on other tools (macro, web) if used. **Do not** replace this with a list of query ids—`run_catalog` already records *what* ran. Narrative answers *how we chose* and *why this set*.

**`run_catalog`**

Per-run: ref + `scope` + intent + resolved request. The **intent** line should say what the screen was **trying to surface** (e.g. "high final performance score, liquid names"); detailed thresholds live in `resolved_request`.

## Result Artifact Contract

**Two output targets with different fields:**

| Field | API (`upsert_fund_token_screen` candidates) | Local schema (`SCREEN_RESULT.schema.json`) |
|-------|-------------------------------------------|--------------------------------------------|
| `token_id` | ✅ required | ✅ required |
| `rank` | ✅ required (1–10, unique) | optional |
| `candidate_reason` | ✅ required | ✅ required |
| `symbol` | — not sent | ✅ required |
| `source_run_ids` | — not sent | ✅ required |
| `indicator_snapshot` | — not sent | optional |

Local schema reference: [`SCREEN_RESULT.schema.json`](SCREEN_RESULT.schema.json).

**Run status enum:** `executed` | `skipped_missing_input` | `skipped_condition_false` | `failed_validation` | `failed_error`

**Run `scope` (required):** `universe` | `holdings` for every run entry.

**Platform persistence:** `upsert_fund_token_screen` / `get_fund_token_screen` (canonical store; max ten candidates per fund per day).

**Local output:** single Markdown file `agent-workflows/screening/results/{screen_date}_{fund_id}.md`; do not also write a JSON file.

## Common Mistakes

- Guessing the fund instead of requiring an explicit `fund_id`.
- Treating missing runtime files as a signal to bootstrap. Setup belongs to `mv-agent-setup`, not here.
- Inventing values for missing conditional inputs instead of marking the run `skipped_missing_input`.
- Inventing `template:<id>` or `query:<id>` references instead of resolving real ids.
- Putting holdings-screen tokens into `candidates` or into `upsert_fund_token_screen` when they were **only** surfaced via `scope: holdings`.
- Omitting `rank` from candidates sent to `upsert_fund_token_screen`, or sending two candidates with the same rank.
- Sending `symbol` or `source_run_ids` in the API payload — those fields are for the local schema artifact, not the API.
- Stopping execution when one run returns `failed_error`; continue remaining runs and record all statuses.
- Changing the artifact contract instead of conforming to the bundled schema.
- Sending more than ten candidates to `upsert_fund_token_screen`.
- Skipping the default Markdown summary, writing multiple local result files, or using a different filename than `{screen_date}_{fund_id}.md`.
- Vague **`candidate_reason`** text that only names a template/query without indicator/score substance.
- Treating **`process_narrative`** as a duplicate of **`run_catalog`** (ids and requests only)—it must explain **how** the shortlist was produced.
- Treating `SCREENING.md` as the source of truth for results instead of the input recipe.
