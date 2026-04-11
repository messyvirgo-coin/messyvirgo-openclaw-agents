---
name: mv-screening-configuration
description: Use when inspecting or replacing a Messy Virgo sleeve screening context (custom queries, workflow steps, instructions), when context replace validation fails, or when workflow step ids drift from custom_queries.query_id.
---

# Screening Configuration

## Overview

`screening context get` is the editable source of truth for sleeve-owned state. It returns `custom_queries`, `workflow`, `instructions`, and `warnings`; load shared template definitions separately from `mv screening templates ...`. Saving is always a full replace.

Hard boundary: this skill may execute `mv screening screen` to validate changed queries against real results, but it must never execute `mv screening runs create`. Only `runs create` persists a sleeve/day run and can replace the stored row for today's `run_date`.

Out of scope: persisted run creation (`runs create`) and historical run/indicator retrieval (`runs list|get`, `indicators get`) — use **mv-screening-execution** for persisted execution and run-history tasks.

## Discover

```bash
mv screening context --help
mv screening templates --help
mv screening catalog --help
mv screening kpis --help
mv screening scores --help
mv screening context replace --example
mv screening context replace --schema
mv screening screen --example
mv screening screen --schema
```

## Required IDs

- Require explicit `fund_id` and `sleeve_id`.
- If `sleeve_id` is unknown, run `mv funds sleeves list <fund_id> --json`.
- If both ids are already explicit, do not re-derive them.

## Workflow

1. `mv screening context get <fund_id> <sleeve_id> --json`
2. Inspect supporting definitions as needed:
   - `mv screening templates list --json`
   - `mv screening templates get <template_id> --json`
   - `mv screening catalog --json`
   - `mv screening kpis list --json`
   - `mv screening scores list --json`
3. Before drafting JSON files, inspect payload contracts:
   - `mv screening screen --example`
   - `mv screening screen --schema`
   - `mv screening context replace --example`
   - `mv screening context replace --schema`
4. Draft any changed request JSON from the saved context and the `screen --example|--schema` contract.
5. Validate changed query logic against real results with `mv screening screen <fund_id> <sleeve_id> --file <request.json> --json`.
6. `mv screening context replace <fund_id> <sleeve_id> --file <context.json> --json`
7. `mv screening context get <fund_id> <sleeve_id> --json` — confirm the persisted state.

## Payload Rules

- `screening context replace` takes one JSON file with top-level `custom_queries`, `workflow`, and `instructions`.
- `custom_queries[].query_id` is the saved query identifier. Never use `id` there.
- `workflow.steps[]` uses `kind: "template" | "query"` plus raw `id`. For custom-query steps, `step.id` must equal the saved `query_id`.
- `custom_queries[].request` is the nested screen request object. Do not wrap the whole save payload in `request`.
- Keep authored custom-query `request.limit` at or below `20`.

## Common Mistakes

- Saving only the changed query instead of the full context file.
- Updating `custom_queries` without updating `workflow.steps` references (or vice versa).
- Using `id` inside `custom_queries` instead of `query_id`.
- Treating `mv screening screen` validation as a persisted run. Validation does not save or replace the sleeve/day row.
- Following validation with `mv screening runs create` during configuration work.
- Inventing template ids, query ids, fields, operators, or wrapper objects after a validation failure — fix the payload from the actual error.

`mv-screening-execution` runs the saved workflow and persists sleeve/day run rows (`run_date`-scoped with same-day replace). This skill changes future behavior by editing the saved sleeve context.
