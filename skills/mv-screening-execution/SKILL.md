---
name: mv-screening-execution
description: Use when running or rerunning a configured token screen for a specific Messy Virgo fund sleeve on a specific screen date.
---

# Screening Execution

## Overview

Run one sleeve's configured screening workflow for one day using canonical context from `fund_sleeves.meta.screening`. Require explicit ids, execute each workflow step, build a universe-only shortlist of up to ten candidates, and persist one immutable run with `create_fund_screen_run`.

Missing inputs, unresolved references, and validation failures must be reported explicitly. Do not guess fund ids, sleeve ids, conditional values, or template/query ids.

## When to Use

- A scheduled or manual screening run is triggered for one fund sleeve and one date.
- The user wants to run or rerun that sleeve's configured token screen.
- The user wants the results persisted as one immutable screening run with shortlist and narrative.

## When Not to Use

- Editing templates or saved screening context belongs to `mv-screening-configuration`.
- Generic template/query inspection without execution does not need this skill.

## Required Inputs

- Require explicit `fund_id`, `sleeve_id`, and target screen day before sleeve-specific work starts.
- If `sleeve_id` is unknown, call `list_fund_sleeves(fund_id)`.
- Do not infer a fund or sleeve from names, nicknames, examples, or "first accessible" fallbacks.

## Core Workflow

1. Load sleeve context with `get_sleeve_screening_context(fund_id, sleeve_id)`.
2. Resolve each `template:<id>` and `query:<id>` from the canonical context. Missing refs become `failed_validation`.
3. Execute each valid step with `screen_sleeve_tokens`, recording `ref`, `scope`, status, intent, and resolved request. Missing runtime inputs become `skipped_missing_input`. Tool errors become `failed_error`, then continue to the remaining runs.
4. Aggregate candidates only from executed `scope: universe` runs. Dedupe by `token_id`, carry forward identity fields from the screen row, assign unique `rank` values `1..10`, and write evidence-based `candidate_reason` text.
5. Persist with `create_fund_screen_run` using `process_narrative`, structured `execution_trace`, `run_catalog`, and up to ten candidates.
6. **Persistence gate:** the workflow MUST NOT report success until `create_fund_screen_run` returns a `screen_run_id`. Never skip persistence.
7. **If persistence fails:**
   - **Already a fund position:** The API rejects the whole request if any candidate `token_id` is a current fund beta holding. **Do not** respond with an empty shortlist. Remove only the rejected `token_id`(s) from `candidates`, assign contiguous `rank` values from 1, and update `process_narrative` (and `run_catalog` / `execution_trace` when needed) to note which symbols were excluded as existing positions—use symbol, name, or contract address in prose, never internal ids. Call `create_fund_screen_run` again with the corrected payload.
   - **Other failures (transient / 5xx / tool):** Retry the **same** payload once. If it still fails, report the error.

## Shortlist Rules

- A token is eligible for `candidates` only if it appeared in at least one executed `scope: universe` run.
- Universe-scope `screen_sleeve_tokens` results include `membership_source` and `selected_rank` on each row. Exclude any token where `membership_source` is `fund_position` or `both`. These are current holdings and must not appear as new candidates. The API will also reject them server-side.
- Holdings-only tokens (tokens that only appeared in `scope: holdings` runs) never belong in `candidates`, even if they screened well.
- For persistence, keep the token's `token_id` from `screen_sleeve_tokens` as the machine identity. Keep `chain`, `contract_address`, `symbol`, and `name` from the screen row for traceability and narrative generation when available.
- `candidate_reason` must use simple words and answer three things: what stood out in the data, why that matters for this sleeve, and why the token is worth further evaluation now. Use full indicator names, not abbreviations or field slugs (`Social Momentum` not `social mom`, `Relative Strength` not `RS`, `Performance Score` not `perf_final`). Mention actual scores in parentheses for evidence.
- When referring to a token in `candidate_reason` or `process_narrative`, always use the token symbol if available, otherwise the token name, otherwise the contract address. NEVER mention an internal `token_id` or other database id in user-facing text.
- Use the data as evidence, not as the whole explanation: mention the 1-3 most relevant DD indicators, scores, filter outcomes, or rank drivers from the `screen_sleeve_tokens` row, then interpret them in plain language.
- Tie the reasoning to the sleeve's intent when possible. For example: momentum sleeve, quality sleeve, defensive sleeve, or a custom instruction from the saved context.
- Keep `candidate_reason` concise: usually 1-3 sentences, specific, and human-readable.
- `process_narrative` must explain how the shortlist was built: run order, skips, merges, cuts, and why this final set survived.
- `run_catalog` is the audit trail of what ran: include `ref`, `scope`, `status`, `intent`, and `resolved_request`.

Reasoning example:

```text
Bad:  VEE top perf/RS leader (67.67/85.78) + social mom 65 = breakout momentum play worth DD.
Bad:  Top from momentum_combo_v1: perf_final=70.02, social_momentum=57.65
Good: Strong momentum candidate: Relative Strength is very high (85.78) and Performance Score is solid (67.67), with Social Momentum adding conviction (65). Worth deeper diligence as a breakout momentum name for this sleeve.
```

## Result Contract

- `create_fund_screen_run` persists one immutable API run plus related candidates.
- API/MCP candidate payloads require `token_id`, `rank`, and `candidate_reason`. Keep `chain` and `contract_address` when available for traceability, but do not use them instead of `token_id`.
- Local artifacts following `SCREEN_RESULT.schema.json` also require `source_run_ids` per candidate.
- Run status enum: `executed` | `skipped_missing_input` | `skipped_condition_false` | `failed_validation` | `failed_error`
- Run scope enum: `universe` | `holdings`

## Common Mistakes

- Passing plain text for `execution_trace` and hitting validation because the API expects dict/list-shaped JSON.
- Writing `candidate_reason` as a score dump or query label instead of an interpreted recommendation in simple language.
- Guessing `fund_id`, `sleeve_id`, missing conditional inputs, or unresolved `template:<id>` / `query:<id>` refs.
- Promoting holdings-only tokens into shortlist candidates.
- Sending duplicate or missing `rank` values, omitting `token_id` from the persistence payload, or using `chain` / `contract_address` as the machine identity when the API expects `token_id`. Never surface a `token_id` in a narrative summary.
- Completing the workflow without calling `create_fund_screen_run`. Persistence is mandatory.
- Dropping every candidate after a partial validation failure (e.g. one holding mixed with valid universe names). Strip invalid rows, re-rank, and persist the remainder.
