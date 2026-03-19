---
name: mv-screening-execution
description: Use when running the configured screening workflow for one Messy Virgo (MV / MESSY)fund and producing deterministic screening result artifacts from `SCREENING.md`.
---

# Screening Execution

## Overview

This skill executes the workflow already defined in `agent-workflows/screening/SCREENING.md`. It resolves workflow references against the read-only template library and the fund's saved custom queries, runs valid screens, and writes result artifacts without inventing missing inputs.

## When to Use

- A scheduled or manual screening run is triggered.
- The user wants to run the configured screening workflow end-to-end from `agent-workflows/screening/SCREENING.md`.

## Prerequisites

- The exact `fund_id` must be explicit before execution starts.
- Do not guess the fund from a name, nickname, prior example, or "first accessible" fallback.
- The runtime workspace must already exist. If `agent-workflows/screening/SCREENING.md` or required directories are missing, stop and tell the user to run `mv-agent-setup` first.

## Quick Reference

| Task | Action |
| ------ | --------- |
| Load baseline | Read `agent-workflows/screening/SCREENING.md`. |
| Load fund context | Call `get_fund_screening_context(fund_id)` or read `mv://funds/{fund_id}/screening-context` for templates and saved custom queries. |
| Resolve run references | `template:<id>` resolves from the template library. `query:<id>` resolves from the fund's `custom_queries`. Missing ids must produce `failed_validation`. |
| Handle conditions | If a run depends on unavailable input such as `risk_on`, mark it `skipped_missing_input`. Do not invent values. |
| Execute one run | Call `screen_fund_tokens` with flat args: `fund_id`, `scope`, optional `snapshot_date`, `filters`, `order_by`, `fields`, `limit`. |
| Aggregate results | Combine executed runs, dedupe by `token_id`, keep `source_run_ids`, and write a short non-empty `candidate_reason` for each candidate. |
| Write artifacts | Write both `agent-workflows/screening/results/SCREEN_RESULT_<timestamp>.json` and `.md`. The bundled `SCREEN_RESULT.schema.json` is the source of truth for the JSON contract. |

## Result Artifact Contract

- **Run status enum:** `executed` | `skipped_missing_input` | `skipped_condition_false` | `failed_validation` | `failed_error`
- **Candidate minimum:** `token_id`, `symbol`, `candidate_reason`, `source_run_ids`
- **Output files:** one JSON artifact and one Markdown artifact per run timestamp

## Common Mistakes

- Guessing the fund instead of requiring an explicit `fund_id`.
- Treating missing runtime files as a signal to bootstrap. Setup belongs to `mv-agent-setup`, not here.
- Inventing values for missing conditional inputs instead of marking the run `skipped_missing_input`.
- Inventing `template:<id>` or `query:<id>` references instead of resolving real ids.
- Changing the artifact contract instead of conforming to the bundled schema.
