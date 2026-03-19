---
name: mv-screening-configuration
description: |
  Configure Messy Virgo (MV / MESSY) fund-specific screening workflows: inspect available templates and saved screening
  policy, test custom screening queries, persist reusable profiles, and update the configured
  workflow so future runs use the intended templates or profiles.
metadata:
  author: messy-virgo-platform
  version: "1.4"
---

# Screening Configuration

## When to Use This Skill

- The screening runtime workspace already exists, or the user can run `mv-agent-setup` first to initialize it.
- The user wants to **inspect** available screening templates or the fund's saved screening policy.
- The user wants to **test** a custom screening query (ad hoc filters/order/fields) before saving it.
- The user wants to **save** a custom query as a fund profile so it can be referenced in `agent-workflows/screening/SCREENING.md` as `profile:<id>`.
- The user wants to **edit** `agent-workflows/screening/SCREENING.md` (add/remove runs, change template or profile refs, or update workflow-specific instructions).
- The exact `fund_id` is already clear from context, or the agent can ask the user to provide it before proceeding.

## Fund Identification

- This skill always operates on one specific fund at a time.
- If the exact `fund_id` is not 100% clear from the user request or established execution context, stop and ask the user for the exact `fund_id`.
- Do not guess the fund from a name, nickname, prior example, or "first accessible" fallback when performing configuration changes.
- Do not inspect policy, test queries, save profiles, or report configuration results for any fund until the target `fund_id` is explicit.

## MCP Surface Used

| What | Purpose |
| ------ | ---------- |
| `get_fund_screening_context(fund_id)` | Get template library + current fund `screening_policy` (profiles, default_profile_ids) |
| `mv://screening-templates` | List all enabled templates |
| `mv://screening-templates/{template_id}` | Get one template by id (for copying or reference) |
| `mv://token-dd/indicator-catalog` | Valid selectors, operators, and constraints for building requests |
| `screen_fund_tokens` | **Test** a query: pass flat args (`fund_id`, `scope`, `snapshot_date`, `filters`, `order_by`, `fields`, `limit`). Use to validate a custom request before saving. |
| `save_fund_screening_context(fund_id, request)` | Persist fund screening policy. **Payload is nested:** `request.screening_policy` must contain `profiles` (list of `FundScreenProfile`) and optionally `default_profile_ids`. |

## Inspecting Templates and Policy

1. Call `get_fund_screening_context(fund_id)` to get:
   - `templates`: list of `ScreeningQueryTemplate` (id, name, description, request, enabled).
   - `screening_policy`: `profiles` (fund-scoped saved profiles), `default_profile_ids`, `updated_at`, `warnings`.
2. Or read resource `mv://screening-templates` for the full template list, and `mv://funds/{fund_id}/screening-context` for the same combined context.

## Testing a Custom Query

1. Read `mv://token-dd/indicator-catalog` to ensure selectors and operators are valid.
2. Build a **flat** payload: `fund_id`, `scope` (`universe` or `holdings`), optional `snapshot_date`, `filters`, `order_by`, `fields`, `limit`.
3. Call `screen_fund_tokens` with that payload. If the API returns a validation error, adjust the request (e.g. fix selector names, use allowed operators) and retry. Do not invent selectors or operators.
4. Use the response to confirm the query returns the expected columns and row count before saving as a profile.

## Saving a Custom Profile

1. **Build the profile:** Create a `FundScreenProfile` with `profile_id` (e.g. `custom_momentum_001`), `name`, optional `description`, `request` (same shape as a template's `request`: `filters`, `order_by`, `fields`, `limit`; optional `snapshot_date`). Set `source_template_id` if derived from a template, `enabled=True`, optional `is_default`, `priority`.
2. **Load current policy:** Call `get_fund_screening_context(fund_id)`. Take `screening_policy` and add or update the new profile in `profiles`. Optionally add the profile's `profile_id` to `default_profile_ids` (respect `max_defaults` from context if present).
3. **Save:** Call `save_fund_screening_context(fund_id, request=FundScreeningContextSaveRequest(screening_policy=updated_policy))`. The MCP tool expects **nested** payload: `request` with a key `screening_policy` containing the full `FundScreeningPolicy` (profiles, default_profile_ids, etc.). Do not pass a flat screening_policy at top level.
4. **Verify the save:** Immediately call `get_fund_screening_context(fund_id)` again and confirm the saved profile is present in `screening_policy.profiles` with the expected `profile_id` and request data. The task is not complete if the profile was only proposed and not persisted.
5. After saving, the user or execution skill can reference this profile in `agent-workflows/screening/SCREENING.md` as `profile:custom_momentum_001`.

## Editing SCREENING.md

- **Location:** `agent-workflows/screening/SCREENING.md` in the workspace.
- **Prerequisite runtime state:** Expect `agent-workflows/screening/`, `agent-workflows/screening/results/`, `agent-workflows/screening/history/`, and `agent-workflows/screening/SCREENING.md` to already exist. If they do not, stop and tell the user to run `mv-agent-setup` first.
- **Structure:** Keep it minimal and configuration-focused: ordered runs, each referencing either `template:<id>` or `profile:<id>`, plus an optional `Additional Instructions` section for workflow-specific guidance.
- **Write-through behavior:** If the workflow should change, the agent must edit and save `agent-workflows/screening/SCREENING.md`; it is not enough to describe the desired edit without persisting it.
- **Backup before overwrite:** If `agent-workflows/screening/SCREENING.md` already exists and its contents will change, first save a UTC timestamped backup copy at `agent-workflows/screening/history/SCREENING_<timestamp>.md`.
- **Verify the write:** After saving `agent-workflows/screening/SCREENING.md`, re-read the file and confirm the expected runs and instructions are present.
- **After adding a profile:** Update `agent-workflows/screening/SCREENING.md` to add a run that references `profile:<profile_id>` if the user wants that profile to run in the default or conditional flow.
- **Do not invent** template or profile ids in `agent-workflows/screening/SCREENING.md`. Only reference ids that exist in the template library or in the fund's `screening_policy.profiles`.

## Persistence Requirements

- Persist profile changes via `save_fund_screening_context`; do not stop at a draft profile object.
- Persist workflow changes by writing `agent-workflows/screening/SCREENING.md`; do not stop at a suggested diff.
- Treat both the profile save and the workflow file write as required side effects when the user asked for them.
- Report back with what was saved and how it was verified.

## Boundaries

- **No new backend.** All configuration is either read/write via existing MCP tools or local file edits to `agent-workflows/screening/SCREENING.md`.
- **Keep policy in the skill:** General rules such as missing-input handling and no-do constraints belong in the skill, not in the workflow file.
- **Fund certainty is required:** If the target `fund_id` is not explicit, ask the user and do not continue.
- **No bootstrap in configuration:** Runtime workspace bootstrap belongs to `mv-agent-setup`, not this skill.
- **Validation:** The API validates saved policies (e.g. selector names, limit bounds). On validation errors, report the error and do not retry with invented values.
- **Nested save payload:** `save_fund_screening_context` expects `request: { screening_policy: { profiles: [...], default_profile_ids: [...], ... } }`, not a flat list of profiles.
- **Backups:** Create `SCREENING.md` backups only when the file already exists and its contents are actually changing.
- **Production-ready wording:** Do not describe this skill or workflow as a prototype in user-facing output.

## Relation to Execution Skill

- **mv-agent-setup** initializes the local screening runtime workspace before configuration or execution begins.
- **mv-screening-execution** uses `agent-workflows/screening/SCREENING.md` and the same MCP surface to **run** screening and write result artifacts.
- **mv-screening-configuration** uses the same MCP surface to **change** what will run (templates, profiles, `agent-workflows/screening/SCREENING.md`) and to test queries before saving.
