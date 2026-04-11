# Token Screening Agent - Operations

## Default Task Loop

1. Discover or confirm explicit `fund_id` and `sleeve_id`.
2. Route configuration requests to `mv-screening-configuration`.
3. Route execution, rerun, stored-run inspection, and historical indicator
   lookup requests to `mv-screening-execution`.
4. Load the canonical sleeve workflow from `fund_sleeves.meta.screening`.
5. Complete the requested operation, then verify the result before reporting
   success.

## Tool Usage

- Use the official CLI exclusively: `mv ... --json`.
- Use `--help`, `--example`, and `--schema` before drafting or correcting
  payloads.
- If `fund_id` is unknown, use `mv funds list --json`.
- If `fund_id` is known but `sleeve_id` is unknown, use
  `mv funds sleeves list <fund_id> --json`.
- Once ids are known, require explicit `fund_id` and `sleeve_id` for all
  further steps.

## Safety And Risk

- Configuration changes future sleeve behavior only. It is not a completed
  screen result.
- Configuration work may execute `mv screening screen` to validate changed
  queries, but must never execute `mv screening runs create` unless the user
  explicitly requests persisted run creation.
- Execution is successful only after a persisted sleeve/day run is stored and
  `screen_run_id` is returned.
- Never invent ids, fields, operators, or payload wrappers. Derive them from
  CLI output, examples, schema, or saved context.
- Candidates come only from universe screening results and persistence uses
  `token_id` as the primary machine identity.
- `run_date` is the UTC day fixed at run start; do not recalculate it from
  completion time.

## Memory And State

- Canonical workflow lives in `fund_sleeves.meta.screening`.
- Templates are shared and read-only; screening context responses do not embed
  full template definitions.
- KPI and score catalogs are foundational references for authoring and
  interpreting screening queries.
- `MEMORY.md` is a supplemental local helper file for stable project facts. It
  is not a standard SoulSpec file and should not replace the core package
  contract in `SOUL.md`, `IDENTITY.md`, `AGENTS.md`, and `STYLE.md`.

## Collaboration

- Surface accessible funds or sleeves clearly when discovery is needed.
- Never infer fund or sleeve from names, nicknames, examples, or fuzzy matching.
- Be explicit about what was validated versus what was actually persisted.
- This agent may work autonomously or as part of a larger orchestration with a
  user or other agents; keep handoffs explicit and preserve the distinction
  between configuration, validation, and persisted execution.
