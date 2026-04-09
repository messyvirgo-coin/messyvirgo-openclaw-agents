---
name: mv-screening-execution
description: Use when running or rerunning a Messy Virgo sleeve token screen for one fund, sleeve, and screen date, or when runs create rejects execution_trace, candidate ranks, candidate_reason, or token_id identity.
---

# Screening Execution

## Overview

`screening context get` is the source of truth for the workflow. Persist one immutable run with `screening runs create` before reporting success.

Out of scope: editing saved queries, workflow, or sleeve instructions — use **mv-screening-configuration**.

- `kind: "template"` steps resolve from `mv screening templates get <id> --json` or a prior `mv screening templates list --json` result.
- `kind: "query"` steps resolve from `custom_queries[]` already returned by `screening context get`. There is no separate query-get command.

## Required Inputs

- Require explicit `fund_id`, `sleeve_id`, and target screen day.
- If `sleeve_id` is unknown, run `mv funds sleeves list <fund_id> --json`.
- Carry the target day as `snapshot_date` in each step request JSON and in the persistence payload.

## Discover

```bash
mv screening --help
mv screening runs --help
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
4. Execute each valid step: `mv screening screen <fund_id> <sleeve_id> --scope <holdings|universe> --file <request.json> --json`
5. Record `ref`, `scope`, `status`, `intent`, and `resolved_request`. Missing refs → `failed_validation`; missing runtime inputs → `skipped_missing_input`; command errors → `failed_error`.
6. Build candidates only from executed `scope: universe` rows. Exclude `membership_source: "fund_position"` and `"both"`. Never promote holdings-only rows.
7. `mv screening runs create <fund_id> --file <payload.json> --json` — success requires a returned `screen_run_id`.
8. Confirm if needed: `mv screening runs get <fund_id> <screen_run_id> --json`

## Persistence Rules

- Payload needs `sleeve_id`, `process_narrative`, structured `execution_trace`, `run_catalog`, and candidate rows with `token_id`, `rank`, and `candidate_reason`.
- `execution_trace` must be JSON-shaped (dict or list, not plain text).
- Candidate ranks must be unique and contiguous in `1..10`.
- `candidate_reason`: name the 1–3 most relevant DD indicators with actual scores, explain why they matter for this sleeve, state why the token is worth follow-up. Use full indicator names (`Relative Strength` not `RS`). Never put a raw `token_id` in user-facing prose.
- If create fails because a candidate is already a current holding: remove only the rejected candidates, re-rank from `1`, update `process_narrative`, and retry once.
- For other transient failures: retry the same payload once, then report the error.

## Common Mistakes

- Looking for a nonexistent query-get command instead of using `custom_queries[]` from context.
- Writing malformed JSON files for `screen` or `runs create`.
- Using `chain` or `contract_address` as machine identity when persistence expects `token_id`.
- Reporting success before `runs create` returns a `screen_run_id`.
- Dropping all candidates after one partial validation failure — strip the invalid rows, re-rank, and persist the remainder.

`mv-screening-configuration` changes what future runs execute; this skill records one completed run.
