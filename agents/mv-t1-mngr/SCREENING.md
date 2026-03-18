# Screening Run Configuration (Prototype)

This file is the orchestration source for the client-side screening workflow. The execution skill reads it, resolves template/profile refs via MCP, runs `screen_fund_tokens` for each executable run, and writes `SCREEN_RESULT_<timestamp>.json` and `.md`.

## Fund

- `fund_id` is not stored in this file. It must be supplied explicitly by the caller, user, or surrounding workflow before screening starts.
- If `fund_id` is missing or ambiguous, do not run screening. Stop and ask which fund to use.

## Runs (order matters)

Execute the following runs in order. Use only **template** or **profile** ids that exist in `get_fund_screening_context` or `mv://screening-templates`. Do not invent ids.

### Run 1: Momentum Combo

- **Ref:** `template:momentum_combo_v1`
- **Scope:** `universe`
- **Condition:** None (always run).
- Resolve the template, build the flat payload from `request`, call `screen_fund_tokens(fund_id, scope="universe", ...)`.

### Run 2: Social Conviction

- **Ref:** `template:social_conviction_v1`
- **Scope:** `universe`
- **Condition:** None (always run).
- Resolve the template, build the flat payload from `request`, call `screen_fund_tokens(fund_id, scope="universe", ...)`.

## No-Do Rules

- If a run is **conditional** and the condition depends on input that is **not provided** (e.g. "when risk_on" but no macro/regime data), **skip** that run with status `skipped_missing_input` and set `reason` to state what is missing (e.g. "Condition requires risk_on; not provided. Do not invent."). **Never** invent values for missing inputs.
- If `fund_id` has not been explicitly clarified before execution, refuse to run. Do not auto-select the first accessible fund.
- If a template or profile id is not found, record the run as `failed_validation` with a reason; do not substitute or guess.
- Use only existing MCP tools and resources; do not call or reference non-existent endpoints or ids.

## Snapshot date

- Omit `snapshot_date` to use the latest available DD snapshot, or set one explicit date (YYYY-MM-DD) and use it for all runs so results are comparable.

## Output

- Write `SCREEN_RESULT_<timestamp>.json` and `SCREEN_RESULT_<timestamp>.md` at repo root, conforming to `SCREEN_RESULT.schema.json`.
- Each candidate must include `candidate_reason` and `source_run_ids`; include identity fields and optional `indicator_snapshot` from the screening response.
