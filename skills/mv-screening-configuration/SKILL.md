---
name: mv-screening-configuration
description: Use when a user wants to inspect or change how a Messy Virgo (MV / MESSY) fund's screening workflow is configured, which templates or queries run, or what custom queries are saved for a fund.
---

# Screening Configuration

## Overview

This skill is workflow-first. `agent-workflows/screening/SCREENING.md` is the baseline workflow, `api.screening_query_templates` is the read-only template library, and fund context provides the saved custom queries that the workflow may reference.

## When to Use

- The user wants to inspect the current screening setup for one fund.
- The user wants to change what future screening runs will do.
- The user wants to add, update, or remove a saved custom query for one fund.
- The user wants to edit `agent-workflows/screening/SCREENING.md`.

## Prerequisites

- The exact `fund_id` must be explicit before doing fund-specific configuration work.
- Do not guess the fund from a name, nickname, prior example, or fallback lookup.
- The runtime workspace must already exist. If `agent-workflows/screening/SCREENING.md` or its directories are missing, stop and tell the user to run `mv-agent-setup` first.

## Quick Reference

| Task | Action |
| ------ | ---------- |
| Inspect current setup | Read `agent-workflows/screening/SCREENING.md` first, then call `get_fund_screening_context(fund_id)` to compare workflow references with available templates and saved custom queries. |
| Inspect template library | Use `mv://screening-templates` or `mv://screening-templates/{template_id}`. Templates are curated and read-only. |
| Test a custom query | Read `mv://token-dd/indicator-catalog`, then call `screen_fund_tokens` with flat args: `fund_id`, `scope`, optional `snapshot_date`, `filters`, `order_by`, `fields`, and `limit`. Set `limit` to the user-specified top-N or **20** if not specified; **never use more than 20** for a custom query. |
| Save a custom query | Choose a `query_id`: lowercase alphanumeric with hyphens, descriptive of the use case (e.g. `high-momentum-liquid`)—not `query1` or random strings. Build a `FundCustomScreeningQuery` with `request.limit` set to the user-specified top-N (max **20**) or **20** if omitted. Merge into the fund's current `custom_queries`, then call `replace_fund_custom_queries`. If the tool returns an error, report the message verbatim—do not retry with invented selector names or a new `query_id` to bypass validation. After success, call `get_fund_screening_context` (or equivalent) and confirm the saved `query_id` appears in `custom_queries`. |
| Edit workflow | Keep `SCREENING.md` minimal: ordered `template:<id>` and `query:<id>` refs plus optional additional instructions. Read existing content first, back it up before changing it, then verify the saved file. |
| Add a saved query to the workflow | After persisting the query, add `query:<query_id>` to `SCREENING.md` if the user wants it to run. |

## Common Mistakes

- Asking "templates or custom queries?" before reading `SCREENING.md`. Read the workflow first.
- Trying to configure a fund before the exact `fund_id` is explicit.
- Saving a draft query without persisting it through `replace_fund_custom_queries`.
- Using `limit` above **20** on a custom query (platform may cap or warn; keep the authored request at or below 20).
- Editing the workflow in prose only. If the workflow changes, write `SCREENING.md`.
- Inventing `template:<id>` or `query:<id>` references instead of resolving real ids.
- Retrying validation failures with made-up selector names or operators.

`mv-agent-setup` bootstraps the runtime workspace. `mv-screening-execution` runs the workflow already defined in `SCREENING.md`. This skill changes that future behavior by editing the workflow and the fund's saved custom queries.
