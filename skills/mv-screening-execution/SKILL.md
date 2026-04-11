---
name: mv-screening-execution
description: Use when running or rerunning a Messy Virgo sleeve token screen for one fund and sleeve, when persisting a sleeve/day screening run with run_date, or when inspecting stored runs or historical indicator details.
---

# Screening Execution

## Overview

`screening context get` is the source of truth for the workflow. Persist one sleeve/day run row with `screening runs create` before reporting success.

Out of scope: editing saved queries, workflow, or sleeve instructions — use **mv-screening-configuration**.

- `kind: "template"` steps resolve from `mv screening templates get <id> --json` or a prior `mv screening templates list --json` result.
- `kind: "query"` steps resolve from `custom_queries[]` already returned by `screening context get`. There is no separate query-get command.

## Required Inputs

- Require explicit `fund_id` and `sleeve_id`.
- If `sleeve_id` is unknown, run `mv funds sleeves list <fund_id> --json`.
- Set `run_date` once at run start using UTC date and keep it fixed through the run.
- Do not invent a historical `snapshot_date` for ordinary "screen now" flows.
- If you need explicit freshness visibility before screening, call:
  - `mv screening snapshot get <fund_id> <sleeve_id> --json`

## Discover

```bash
mv screening --help
mv screening runs --help
mv screening templates --help
mv screening screen --example
mv screening screen --schema
mv screening runs create --example
mv screening runs create --schema
```

## Workflow

1. `mv screening context get <fund_id> <sleeve_id> --json`
2. Resolve each workflow step from that response:
   - template step → `mv screening templates get <id> --json` or an already-loaded template list
   - query step → matching `custom_queries[].query_id`
3. Before drafting payloads, inspect the contracts:
   - `mv screening screen --example`
   - `mv screening screen --schema`
   - `mv screening runs create --example`
   - `mv screening runs create --schema`
4. Freshness check before each step:
   - `mv screening snapshot get <fund_id> <sleeve_id> --json`
5. Execute each valid step: `mv screening screen <fund_id> <sleeve_id> --file <request.json> --json`
   - If request JSON omits `snapshot_date`, screening targets today's UTC date.
   - Readiness is based on completed `token_universe_runs` for the sleeve universe/date.
   - If today's snapshot is not ready, API returns `SNAPSHOT_NOT_READY` (409); do not treat that as an empty-result success.
   - Completed runs may still produce partial row coverage when some tokens fail; this does not invalidate screening.
   - Capture the `snapshot_date` returned by each screen response.
   - Also capture `universe_run` and `coverage` from the screen response. When `results` is empty, use these fields to distinguish "no joined indicator rows" (`indicator_rows_joined=0`) vs "filters removed all rows" (`rows_after_filters=0` with `indicator_rows_joined>0`), and reference the counters in narrative/meta.
6. Record `ref`, `status`, `intent`, and `resolved_request`. Missing refs → `failed_validation`; missing runtime inputs → `skipped_missing_input`; command errors → `failed_error`.
7. Build candidates from executed screening rows using ranked evidence and clear `candidate_reason` text.
8. Build run payload with explicit `run_date` (UTC day from run start), `snapshot_date`, and shortlist candidates.
9. `mv screening runs create <fund_id> --file <payload.json> --json` — success requires a returned `screen_run_id`.
10. Confirm if needed:

- latest persisted row: `mv screening runs get <fund_id> <screen_run_id> --json`
- history listing (complementary): `mv screening runs list <fund_id> --sleeve-id <sleeve_id> --json`
- historical indicator lookup (complementary): `mv screening indicators get <fund_id> --snapshot-date <YYYY-MM-DD> --chain <chain> --contract-address <address> --json`

## Persistence Rules

- Payload needs `sleeve_id`, `run_date`, `process_narrative`, structured `execution_trace`, `run_catalog`, and candidate rows with `token_id`, `rank`, and `candidate_reason`.
- `run_date` is the UTC day fixed at run start (business key with `sleeve_id`); do not recalculate at completion time.
- Persist the resolved screen response `snapshot_date` in the run payload; do not substitute `screened_at`.
- For empty-result runs, include the screen response `coverage`/`universe_run` evidence in `process_narrative` and/or payload `meta` so users can see whether data was unavailable or filtered out.
- `execution_trace` must be JSON-shaped (dict or list, not plain text).
- Candidate ranks must be unique and within `1..10`.
- `candidate_reason`: name the 1–3 most relevant DD indicators with actual scores, explain why they matter for this sleeve, state why the token is worth follow-up. Use full indicator names (`Relative Strength` not `RS`). Never put a raw `token_id` in user-facing prose.
- For transient failures: retry the same payload once, then report the error.

## Common Mistakes

- Looking for a nonexistent query-get command instead of using `custom_queries[]` from context.
- Writing malformed JSON files for `screen` or `runs create`.
- Omitting `run_date` or setting it from finish time instead of run-start UTC day.
- Using `chain` or `contract_address` as machine identity when persistence expects `token_id`.
- Reporting success before `runs create` returns a `screen_run_id`.
- Dropping all candidates after one partial validation failure — strip the invalid rows, re-rank, and persist the remainder.

`mv-screening-configuration` changes what future runs execute; this skill records one completed sleeve/day run and can optionally inspect run/indicator history.
