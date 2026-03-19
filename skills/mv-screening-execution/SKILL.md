---
name: mv-screening-execution
description: |
  Execute configured Messy Virgo (MV / MESSY) fund screening workflows and write screening result artifacts. Use when a
  scheduled or manual screening run should be performed for a specific fund or execution context.
metadata:
  author: messy-virgo-platform
  version: "1.4"
---

# Screening Execution

## When to Use This Skill

- A scheduled or manual screening run is triggered.
- The screening runtime workspace has already been initialized by `mv-agent-setup`.
- The user wants to run the configured screening workflow end-to-end from `agent-workflows/screening/SCREENING.md`.
- The exact `fund_id` is already clear from context, or the agent can ask the user to provide it before proceeding.
- You must **not** invent values for missing inputs (e.g. regime, risk_on); instead record runs as skipped with a clear reason.

## Fund Identification

- This skill always executes against one specific fund at a time.
- If the exact `fund_id` is not 100% clear from the user request or established execution context, stop and ask the user for the exact `fund_id`.
- Do not guess the fund from a name, nickname, prior example, or "first accessible" fallback.
- Do not execute screening runs, load fund screening context, or write screening result artifacts for any fund until the target `fund_id` is explicit.

## Inputs and Boundaries

- **Runtime workflow file:** `agent-workflows/screening/SCREENING.md`
- **Bundled schema:** `SCREEN_RESULT.schema.json` bundled with this skill
- **Required runtime directories:** `agent-workflows/screening/`, `agent-workflows/screening/results/`, and `agent-workflows/screening/history/`
- **No bootstrap in execution:** If the runtime workflow file or required directories are missing, stop and tell the user to run `mv-agent-setup` first. Do not create them here.
- **Orchestration file:** Read `agent-workflows/screening/SCREENING.md` only after confirming the runtime workspace already exists.
- **No process inputs** are passed to the run today (e.g. no macro/regime payload). If `agent-workflows/screening/SCREENING.md` refers to conditions that require such input, treat them as unavailable and **skip** those runs with status `skipped_missing_input` and a reason like "Condition requires risk_on; not provided. Do not invent."
- **Only use existing MCP tools and resources.** Do not invent endpoints, template ids, or profile ids. If a template or profile id in `agent-workflows/screening/SCREENING.md` is not found, record that run as `failed_validation` or skip with reason.

## MCP Surface Used

| What | Purpose |
| ------ | --------- |
| `list_accessible_funds` | Inspect accessible funds after the user has clarified which exact `fund_id` to use |
| `get_fund_screening_context` (tool or `mv://funds/{fund_id}/screening-context`) | Template library + persisted fund screening policy (profiles) |
| `mv://screening-templates` | All enabled templates (alternative to context) |
| `mv://screening-templates/{template_id}` | Single template by id |
| `mv://token-dd/indicator-catalog` | Canonical selectors/operators when building or validating requests |
| `screen_fund_tokens` | Execute one screen; pass **flat** args: `fund_id`, `scope`, `snapshot_date`, `filters`, `order_by`, `fields`, `limit` |

## Execution Flow

1. **Check runtime workspace:** Confirm `agent-workflows/screening/`, `agent-workflows/screening/results/`, `agent-workflows/screening/history/`, and `agent-workflows/screening/SCREENING.md` already exist. If any are missing, stop and tell the user to run `mv-agent-setup` first.
2. **Load** `agent-workflows/screening/SCREENING.md`. Parse ordered runs and any workflow-specific additional instructions.
3. **Confirm fund_id** from execution context. If it is not explicit, ask the user for the exact `fund_id` and stop. Use `list_accessible_funds` only as a supporting lookup after the user has clarified which fund they mean.
4. **Load context:** `get_fund_screening_context(fund_id)` (or resource `mv://funds/{fund_id}/screening-context`) for templates and `screening_policy.profiles`.
5. **Evaluate each run** from `agent-workflows/screening/SCREENING.md` in order:
   - If the run is conditional and the condition depends on **unavailable input** (e.g. "when risk_on" but no macro/regime data): set status `skipped_missing_input`, set `reason` to state what is missing and that you do not invent. Do **not** assume or invent values.
   - If the run references `template:<id>`: resolve the template from context or `mv://screening-templates/{id}`. If not found, record `failed_validation` with reason.
   - If the run references `profile:<id>`: resolve from `screening_policy.profiles`. If not found, record `failed_validation` with reason.
   - If the run is unconditional and the template/profile is resolved: build the flat payload from the template's or profile's `request` (merge in `snapshot_date` if specified in `agent-workflows/screening/SCREENING.md`), call `screen_fund_tokens(fund_id, scope=..., **request)`, record status `executed` and `result_count`.
6. **Aggregate:** Collect all rows from runs with status `executed`. Deduplicate by `token_id`; keep `source_run_ids` (e.g. template or profile ids that returned this token).
7. **Candidate reason:** For each candidate, set `candidate_reason` to a short, explicit reason why this token is a candidate (e.g. based on which screens included it and the indicator values). This is a required field; do not leave it empty.
8. **Write artifacts:**
   - **JSON:** `agent-workflows/screening/results/SCREEN_RESULT_<timestamp>.json`. Use ISO timestamp (e.g. `20260318T121500Z`). Schema: the bundled `SCREEN_RESULT.schema.json` in this skill directory. Required top-level keys: `schema_version` (`screen-result-v1`), `fund_id`, `generated_at_utc`, `runs`, `candidates`. Each run: `run_id`, `status`, and when executed: `scope`, `result_count`; when skipped/failed: `reason`. Each candidate: `token_id`, `symbol`, `candidate_reason`, `source_run_ids`, plus optional `coingecko_id`, `name`, `chain`, `contract_address`, `indicator_snapshot`.
   - **Markdown:** `agent-workflows/screening/results/SCREEN_RESULT_<timestamp>.md`. Same timestamp as JSON. Include: title (e.g. "Screening Result"), `fund_id`, `generated_at_utc`, a table of runs (run_id, status, scope or reason, result_count), then a table of candidates (symbol, name, token_id, candidate_reason, source_run_ids; optional indicator columns if useful).

## Hard No-Do Rules

- **Never invent** values for missing inputs (e.g. regime, risk_on, macro flags). If a condition in `agent-workflows/screening/SCREENING.md` requires such input and it is not provided, **skip** the run with `skipped_missing_input` and state in `reason` that the input was not provided and you do not invent.
- **Never guess** the target `fund_id` or silently choose a fallback fund.
- **Never create or bootstrap** missing runtime screening files or directories from the execution skill. If they are missing, stop and tell the user to run `mv-agent-setup` first.
- **Never call** non-existent tools or resources. Only use the MCP tools and resources listed above.
- **Never fabricate** template or profile ids. Use only ids that appear in `get_fund_screening_context` or `mv://screening-templates`.
- **Never change** the artifact schema. Output must conform to the bundled `SCREEN_RESULT.schema.json` in this skill directory (schema_version, runs, candidates structure, status enum).

## Result Artifact Contract

- **Run status enum:** `executed` | `skipped_missing_input` | `skipped_condition_false` | `failed_validation` | `failed_error`
- **Candidate fields:** At minimum `token_id`, `symbol`, `candidate_reason`, `source_run_ids`. Add identity and `indicator_snapshot` when available from the screening response.
- **Setup dependency:** Runtime workspace creation belongs to `mv-agent-setup`; this skill only reads from it.
