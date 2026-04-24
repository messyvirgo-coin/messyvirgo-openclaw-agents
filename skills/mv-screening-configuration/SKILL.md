---
name: mv-screening-configuration
description: Use when inspecting or replacing saved Messy Virgo sleeve screening context, aggregation context, custom queries, workflow steps, or fixing context validation and workflow reference errors.
---

# Screening Configuration

## Overview

This skill edits future sleeve screening behavior. It does not persist a sleeve/day screening result.

There are two sibling contexts:

- Single-day screening context: `custom_queries`, `workflow`, `instructions`, `warnings`.
- Aggregate screening context: `enabled`, optional `policy`, `instructions`, `warnings`.

Use **mv-screening-execution** for running, persisting, rebuilding, or inspecting saved runs.

## Hard Boundary

You may run `mv screening screen` to validate changed single-day query logic against real results. Do not run `mv screening runs create` or `mv screening aggregation rebuild` during configuration work unless the user explicitly changes the task from configuration to execution.

## Commands

```bash
mv screening context get <fund_id> <sleeve_id> --json
mv screening context replace <fund_id> <sleeve_id> --file <context.json> --json
mv screening aggregation get <fund_id> <sleeve_id> --json
mv screening aggregation replace <fund_id> <sleeve_id> --file <aggregation-context.json> --json
mv screening templates list --json
mv screening templates get <template_id> --json
mv screening catalog --json
mv screening screen <fund_id> <sleeve_id> --file <request.json> --json
```

Inspect `--example` and `--schema` before drafting replace or validation payloads.

## Workflow

1. Require explicit `fund_id`; if `sleeve_id` is unknown, run `mv funds sleeves list <fund_id> --json`.
2. Load the saved context before editing it.
3. Load templates/catalog/KPI/score definitions only when needed; do not invent ids, fields, or operators.
4. Validate changed single-day requests with `mv screening screen`; validation does not save a run.
5. Replace the full relevant context file, not just the changed fragment.
6. Read the context back and compare the persisted state.

## Payload Rules

- `screening context replace` takes top-level `custom_queries`, `workflow`, and `instructions`.
- `screening aggregation replace` takes top-level `enabled`, optional `policy`, and `instructions`.
- `custom_queries[].query_id` is the identifier. Do not use `id`.
- `workflow.steps[]` uses `kind: "template" | "query"` and plain `id`.
- For custom-query steps, `workflow.steps[].id` must equal a saved `custom_queries[].query_id`.
- `custom_queries[].request` is the nested screen request object. Do not wrap the full save payload in `request`.
- Keep authored custom-query `request.limit` at or below `20`.

## Common Mistakes

- Saving a partial context instead of a full replacement payload.
- Updating `custom_queries` without updating `workflow.steps`, or the reverse.
- Treating `mv screening screen` as persistence.
- Mixing single-day context keys into aggregation context payloads.
- Following validation with run creation during configuration work.
