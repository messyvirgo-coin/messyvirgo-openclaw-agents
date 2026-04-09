---
name: mv-screening-configuration
description: Use when inspecting or replacing a Messy Virgo sleeve screening context (custom queries, workflow steps, instructions), when context replace validation fails, or when workflow step ids drift from custom_queries.query_id.
---

# Screening Configuration

## Overview

`screening context get` is the editable source of truth. Saving is always a full replace.

Out of scope: immutable screen runs (`runs create`) — use **mv-screening-execution**.

## Discover

```bash
mv screening context --help
mv screening templates --help
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
4. Draft and test any new request: `mv screening screen <fund_id> <sleeve_id> --scope <holdings|universe> --file <request.json> --json`
5. `mv screening context replace <fund_id> <sleeve_id> --file <context.json> --json`
6. `mv screening context get <fund_id> <sleeve_id> --json` — confirm the persisted state.

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
- Inventing template ids, query ids, fields, operators, or wrapper objects after a validation failure — fix the payload from the actual error.

`mv-screening-execution` runs the saved workflow and persists immutable screen runs. This skill changes future behavior by editing the saved sleeve context.
