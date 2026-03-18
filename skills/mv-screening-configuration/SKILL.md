---
name: mv-screening-configuration
description: |
  Configure the client-side screening workflow: inspect the template library, test custom queries
  via screen_fund_tokens, save reusable profiles to the fund's screening policy, and edit
  SCREENING.md. Use only after the target fund_id is explicitly clarified.
metadata:
  author: messy-virgo-platform
  version: "1.0"
---

# Screening Configuration (Client-Side Prototype)

## When to Use This Skill

- The user wants to **inspect** available screening templates or the fund's saved screening policy.
- The user wants to **test** a custom screening query (ad hoc filters/order/fields) before saving it.
- The user wants to **save** a custom query as a fund profile so it can be referenced in `SCREENING.md` as `profile:<id>`.
- The user wants to **edit** root-level `SCREENING.md` (add/remove runs, change template or profile refs, adjust conditions or no-do rules).
- The target `fund_id` is already explicit. If it is not, stop and ask which fund to configure.

## MCP Surface Used

| What | Purpose |
|------|----------|
| `list_accessible_funds` | Optional discovery helper when the user explicitly asks which fund ids are available. Never use it to auto-select a fund. |
| `get_fund_screening_context(fund_id)` | Get template library + current fund `screening_policy` (profiles, default_profile_ids) |
| `mv://screening-templates` | MCP resource listing all enabled templates |
| `mv://screening-templates/{template_id}` | MCP resource for one template by id |
| `mv://token-dd/indicator-catalog` | Valid selectors, operators, and constraints for building requests |
| `screen_fund_tokens` | **Test** a query: pass flat args (`fund_id`, `scope`, `snapshot_date`, `filters`, `order_by`, `fields`, `limit`). Use to validate a custom request before saving. |
| `save_fund_screening_context(fund_id, request)` | Persist fund screening policy. **Payload is nested:** `request.screening_policy` must contain `profiles` (list of `FundScreenProfile`) and optionally `default_profile_ids`. |

## Required Fund Context

- `fund_id` is mandatory for inspect, test, and save operations in this skill.
- If `fund_id` is missing or ambiguous, stop and ask for clarification before reading or changing fund-scoped screening state.
- `list_accessible_funds` may help the user discover valid ids, but it must not be used to pick a fund on the agent's behalf.

## Inspecting Templates and Policy

1. Call `get_fund_screening_context(fund_id)` to get:
   - `templates`: list of `ScreeningQueryTemplate` (id, name, description, request, enabled).
   - `screening_policy`: `profiles` (fund-scoped saved profiles), `default_profile_ids`, `updated_at`, `warnings`.
2. Or fetch MCP resource `mv://screening-templates` for the full template list, and `mv://funds/{fund_id}/screening-context` for the same combined context.

## Testing a Custom Query

1. Read `mv://token-dd/indicator-catalog` to ensure selectors and operators are valid.
2. Build a **flat** payload: `fund_id`, `scope` (`universe` or `holdings`), optional `snapshot_date`, `filters`, `order_by`, `fields`, `limit`.
3. Call `screen_fund_tokens` with that payload. If the API returns a validation error, adjust the request (e.g. fix selector names, use allowed operators) and retry. Do not invent selectors or operators.
4. Use the response to confirm the query returns the expected columns and row count before saving as a profile.

## Saving a Custom Profile

1. **Build the profile:** Create a `FundScreenProfile` with `profile_id` (e.g. `custom_momentum_001`), `name`, optional `description`, `request` (same shape as a template's `request`: `filters`, `order_by`, `fields`, `limit`; optional `snapshot_date`). Set `source_template_id` if derived from a template, `enabled=True`, optional `is_default`, `priority`.
2. **Load current policy:** Call `get_fund_screening_context(fund_id)`. Take `screening_policy` and add or update the new profile in `profiles`. Optionally add the profile's `profile_id` to `default_profile_ids` (respect `max_defaults` from context if present).
3. **Save:** Call `save_fund_screening_context(fund_id, request=FundScreeningContextSaveRequest(screening_policy=updated_policy))`. The MCP tool expects **nested** payload: `request` with a key `screening_policy` containing the full `FundScreeningPolicy` (profiles, default_profile_ids, etc.). Do not pass a flat screening_policy at top level.
4. After saving, the user or execution skill can reference this profile in `SCREENING.md` as `profile:custom_momentum_001`.

## Editing SCREENING.md

- **Location:** Root-level `SCREENING.md` in the workspace.
- **Structure:** Keep a light, consistent format: note that `fund_id` must be supplied externally before execution, then list ordered runs, each run referencing either `template:<id>` or `profile:<id>`, optional conditions, and explicit no-do rules (e.g. "If risk_on is required and not provided, skip; do not invent.").
- **After adding a profile:** Update `SCREENING.md` to add a run that references `profile:<profile_id>` if the user wants that profile to run in the default or conditional flow.
- **Do not invent** template or profile ids in `SCREENING.md`. Only reference ids that exist in the template library or in the fund's `screening_policy.profiles`.

## Boundaries

- **No new backend.** All configuration is either read/write via existing MCP tools or local file edits to `SCREENING.md`.
- **Validation:** The API validates saved policies (e.g. selector names, limit bounds). On validation errors, report the error and do not retry with invented values.
- **Nested save payload:** `save_fund_screening_context` expects `request: { screening_policy: { profiles: [...], default_profile_ids: [...], ... } }`, not a flat list of profiles.
- **Resource access:** Treat `mv://...` values as MCP resource URIs, not as tool names or server ids.
- **Error reporting:** When a tool or resource call fails, report the exact failing tool/resource and observed error text when available. Do not summarize a concrete failure as "unknown error."

## Relation to Execution Skill

- **mv-screening-execution** uses `SCREENING.md` and the same MCP surface to **run** screening and write result artifacts.
- **mv-screening-configuration** uses the same MCP surface to **change** what will run (templates, profiles, `SCREENING.md`) and to test queries before saving.
