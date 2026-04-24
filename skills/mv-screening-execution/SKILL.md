---
name: mv-screening-execution
description: "Use when handling Messy Virgo Funds / MVF screening requests for mvf-* funds or mvs-* sleeves: last/latest screen run, only sleeve, top N token candidates, shortlist candidates, run/rerun screening, persist sleeve/day runs, rebuild aggregates, or inspect run/indicator details."
---

# Screening Execution

## Overview

This skill runs or inspects screening outcomes. It never edits saved screening context; use **mv-screening-configuration** for context changes.

Run/rerun tasks persist one single-day sleeve run with `mv screening runs create`. If aggregation is enabled, rebuild the same-sleeve aggregate run after persistence. Inspect-only tasks such as "last screen run" or "top 3 candidates" use list/get commands and create no rows.

## Commands

```bash
mv funds sleeves list <fund_id> --json
mv screening context get <fund_id> <sleeve_id> --json
mv screening snapshot get <fund_id> <sleeve_id> --json
mv screening templates get <template_id> --json
mv screening screen <fund_id> <sleeve_id> --file <request.json> --json
mv screening runs create <fund_id> --file <payload.json> --json
mv screening runs list <fund_id> [--sleeve-id <sleeve_id>] --json
mv screening runs get <fund_id> <screen_run_id> --json
mv screening aggregation get <fund_id> <sleeve_id> --json
mv screening aggregation rebuild <fund_id> <sleeve_id> --as-of-date <run_date> --json
mv screening aggregation runs list <fund_id> [--sleeve-id <sleeve_id>] --json
mv screening aggregation runs latest <fund_id> <sleeve_id> --json
mv screening indicators get <fund_id> --snapshot-date <YYYY-MM-DD> --chain <chain> --contract-address <address> --json
```

## Inspect Workflow

Use this workflow for requests that ask for existing results, latest/last screen runs, top N candidates, shortlist candidates, or candidate details without asking to run/rerun screening.

1. Require explicit `fund_id`.
2. If `sleeve_id` is unknown, run `mv funds sleeves list <fund_id> --json`.
3. If exactly one sleeve is returned, use it without asking. If multiple sleeves are returned and the prompt does not identify one, ask which sleeve to inspect.
4. List persisted runs with `mv screening runs list <fund_id> --sleeve-id <sleeve_id> --json`.
5. Select the latest run from the list response. If ordering is unclear, sort by `run_date` then `screened_at` descending.
6. If the selected run lacks full `candidates[]`, fetch it with `mv screening runs get <fund_id> <screen_run_id> --json`.
7. Return candidates sorted by persisted `rank`; for "top N" requests, return only the first N.
8. Do not call `mv screening screen`, `mv screening runs create`, or aggregation rebuild commands during inspect-only work.

## Run Workflow

1. Require explicit `fund_id`; if `sleeve_id` is unknown, run `mv funds sleeves list <fund_id> --json`.
2. Set `run_date` once at run start using the UTC date; do not recalculate it at completion time.
3. Load `mv screening context get`; resolve template steps from `mv screening templates get <id> --json` or a loaded template list, and query steps from matching `custom_queries[].query_id`.
4. Inspect `screen --example|--schema` and `runs create --example|--schema` before drafting payload files.
5. Check readiness with `mv screening snapshot get`; `SNAPSHOT_NOT_READY` is not an empty-result success.
6. Execute valid steps with `mv screening screen`; capture returned `snapshot_date`, `coverage`, and `universe_run`.
7. Build ranked candidates with clear `candidate_reason` text and evidence from returned rows.
8. Create the single-day run; success requires a returned `screen_run_id`.
9. If `mv screening aggregation get` returns `enabled: true`, run aggregation rebuild for the same `run_date`.
10. Report single-day and aggregate outcomes separately; aggregate failure does not invalidate a saved single-day run.

## Persistence Rules

- Run payload needs `sleeve_id`, `run_date`, `process_narrative`, JSON-shaped `execution_trace`, `run_catalog`, and candidates with `token_id`, `rank`, `candidate_reason`.
- Persist the screen response `snapshot_date`; do not substitute `screened_at`.
- Candidate ranks must be unique and within `1..10`.
- `candidate_reason` should name 1-3 indicators with scores, use full names, and avoid raw `token_id` in prose.
- Empty-result runs should include `coverage`/`universe_run` evidence to distinguish missing indicator rows from filters removing all rows.
- Do not invent an aggregate policy at execution time; use the saved aggregation context.

## Common Mistakes

- Reporting execution success before `runs create` returns `screen_run_id`.
- Recomputing `run_date` after a long run crosses UTC midnight.
- Looking for a nonexistent custom-query get command instead of using `custom_queries[]`.
- Persisting `chain` or `contract_address` where the run payload expects `token_id`.
- Forgetting aggregate rebuild after a successful single-day run when aggregation is enabled.
- Querying the database directly for run history instead of using CLI list/get commands.
- Inferring narrative backdrop for a candidate from symbol alone when the persisted screening row already includes `token_id` - use that `token_id` with `mv tokens get` / `mv tokens resolve` instead of guessing from the ticker.

`mv-screening-configuration` changes what future runs execute; this skill records one completed sleeve/day run and can optionally inspect run/indicator history.
