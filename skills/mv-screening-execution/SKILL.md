---
name: mv-screening-execution
description: |
  Run the client-side screening workflow: load SCREENING.md, resolve template/profile refs,
  call screen_fund_tokens for each executable run (or mark skipped when input is missing),
  aggregate results, and write SCREEN_RESULT_<timestamp>.json and .md. Use only after the
  target fund_id is explicitly clarified. Enforces hard no-do: never invent missing inputs.
metadata:
  author: messy-virgo-platform
  version: "1.0"
---

# Screening Execution (Client-Side Prototype)

## When to Use This Skill

- A scheduled or manual screening run is triggered.
- The goal is to execute the instructions in `SCREENING.md` and produce deterministic result artifacts.
- You must **not** invent values for missing inputs (e.g. regime, risk_on); instead record runs as skipped with a clear reason.

## Inputs and Boundaries

- **Orchestration file:** Root-level `SCREENING.md` in the workspace. Read it first.
- **Mandatory runtime input:** `fund_id` must already be explicitly clarified by the user, caller, or surrounding workflow before this skill runs. If `fund_id` is missing or ambiguous, stop and ask for clarification. Do **not** auto-select a fund.
- **No process inputs** are passed to the run today (e.g. no macro/regime payload). If `SCREENING.md` refers to conditions that require such input, treat them as unavailable and **skip** those runs with status `skipped_missing_input` and a reason like "Condition requires risk_on; not provided. Do not invent."
- **Only use existing MCP tools and resources.** Do not invent endpoints, template ids, or profile ids. If a template or profile id in `SCREENING.md` is not found, record that run as `failed_validation` or skip with reason.

## MCP Surface Used

| What | Purpose |
|------|---------|
| `list_accessible_funds` | Optional discovery helper when the user asks which fund ids are available. Never use it to auto-select a fund for execution. |
| `get_fund_screening_context` (tool or `mv://funds/{fund_id}/screening-context`) | Template library + persisted fund screening policy (profiles) |
| `mv://screening-templates` | MCP resource with all enabled templates (alternative to context) |
| `mv://screening-templates/{template_id}` | MCP resource for one template by id |
| `mv://token-dd/indicator-catalog` | Canonical selectors/operators when building or validating requests |
| `screen_fund_tokens` | Execute one screen; pass **flat** args: `fund_id`, `scope`, `snapshot_date`, `filters`, `order_by`, `fields`, `limit` |

## Execution Flow

1. **Load** root-level `SCREENING.md`. Parse fund, ordered runs, and any conditions.
2. **Require a clarified fund_id** from the caller, user, or surrounding workflow before doing any screening work. If it is missing, stop and ask for it. Do **not** infer it from `SCREENING.md` and do **not** auto-pick the first accessible fund.
3. **Load context:** `get_fund_screening_context(fund_id)` (or resource `mv://funds/{fund_id}/screening-context`) for templates and `screening_policy.profiles`.
4. **Evaluate each run** from `SCREENING.md` in order:
   - If the run is conditional and the condition depends on **unavailable input** (e.g. "when risk_on" but no macro/regime data): set status `skipped_missing_input`, set `reason` to state what is missing and that you do not invent. Do **not** assume or invent values.
   - If the run references `template:<id>`: resolve the template from context or by fetching the MCP resource `mv://screening-templates/{id}`. If not found, record `failed_validation` with reason.
   - If the run references `profile:<id>`: resolve from `screening_policy.profiles`. If not found, record `failed_validation` with reason.
   - If the run is unconditional and the template/profile is resolved: build the flat payload from the template's or profile's `request` (merge in `snapshot_date` if specified in SCREENING.md), call `screen_fund_tokens(fund_id, scope=..., **request)`, record status `executed` and `result_count`.
5. **Aggregate:** Collect all rows from runs with status `executed`. Deduplicate by `token_id`; keep `source_run_ids` (e.g. template or profile ids that returned this token).
6. **Candidate reason:** For each candidate, set `candidate_reason` to a short, explicit reason why this token is a candidate (e.g. based on which screens included it and the indicator values). This is a required field; do not leave it empty.
7. **Write artifacts:**
   - **JSON:** `SCREEN_RESULT_<timestamp>.json` at repo root. Use ISO timestamp (e.g. `20260318T121500Z`). Schema: root-level `SCREEN_RESULT.schema.json`. Required top-level keys: `schema_version` (`screen-result-v1`), `fund_id`, `generated_at_utc`, `runs`, `candidates`. Each run: `run_id`, `status`, and when executed: `scope`, `result_count`; when skipped/failed: `reason`. Each candidate: `token_id`, `symbol`, `candidate_reason`, `source_run_ids`, plus optional `coingecko_id`, `name`, `chain`, `contract_address`, `indicator_snapshot`.
   - **Markdown:** `SCREEN_RESULT_<timestamp>.md` at repo root. Same timestamp as JSON. Include: title (e.g. "Screening Result"), `fund_id`, `generated_at_utc`, a table of runs (run_id, status, scope or reason, result_count), then a table of candidates (symbol, name, token_id, candidate_reason, source_run_ids; optional indicator columns if useful).

## Hard No-Do Rules

- **Never invent** values for missing inputs (e.g. regime, risk_on, macro flags). If a condition in `SCREENING.md` requires such input and it is not provided, **skip** the run with `skipped_missing_input` and state in `reason` that the input was not provided and you do not invent.
- **Never auto-select** a fund. If `fund_id` is not already explicit, stop and ask which fund to use.
- **Never call** non-existent tools or resources. Only use the MCP tools and resources listed above.
- **Never fabricate** template or profile ids. Use only ids that appear in `get_fund_screening_context` or in fetched MCP resources such as `mv://screening-templates`.
- **Never treat** `mv://...` resource URIs as MCP server names or tool names. Fetch them as resources from the same funds MCP surface.
- **Never summarize** a concrete tool/resource failure as "unknown error" when exact observed error text is available.
- **Never change** the artifact schema. Output must conform to `SCREEN_RESULT.schema.json` (schema_version, runs, candidates structure, status enum).

## Failure Reporting

- When a tool or resource call fails, record the exact failing tool or resource name and the exact observed error text when available.
- If exact transport or stderr details are not available, say so plainly instead of speculating about hidden CLI or bridge internals.
- Prefer specific reasons such as `failed_validation` for invalid request inputs and `failed_error` for runtime/API/resource failures.

## Result Artifact Contract

- **Run status enum:** `executed` | `skipped_missing_input` | `skipped_condition_false` | `failed_validation` | `failed_error`
- **Candidate fields:** At minimum `token_id`, `symbol`, `candidate_reason`, `source_run_ids`. Add identity and `indicator_snapshot` when available from the screening response.

## Optional: LATEST Symlink

If useful for downstream steps, you may write `SCREEN_RESULT_LATEST.json` and `SCREEN_RESULT_LATEST.md` as copies of the timestamped files for the run just completed. Not required for the prototype.
