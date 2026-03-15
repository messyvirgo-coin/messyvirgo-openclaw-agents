---
name: mv-fund-token-screening
description: |
  Messy Virgo Funds Management skill for fund-scoped token screening.
  Use this when an AI agent needs to discover due diligence indicator fields,
  compose valid screening requests, screen a fund's token universe, and
  optionally compare candidate tokens against the fund's current holdings.
metadata:
  author: messy-virgo-platform
  version: "1.1"
---

# Messy Virgo Funds Management - Fund Token Screening

## Purpose

Use this skill for the screening and compact comparison step in daily fund management:

1. Discover valid due diligence indicator selectors and operators.
2. Build valid ad hoc screening requests.
3. Screen the fund's token universe for candidates.
4. Optionally screen the fund's current holdings with the same or related fields.
5. Hand off a short candidate list for deeper due diligence.

This skill is intentionally narrow. It covers screening and candidate comparison, not deep due diligence, trade execution, or full portfolio management.

## MCP Tools

- `get_due_diligence_indicator_catalog`: returns canonical field names, allowed operators, value types, unsortable fields, and request bounds.
- `screen_token_universe_indicators`: screens the assigned token universe for one fund and returns compact indicator rows for matching candidates.
- `screen_token_holdings_indicators`: screens tokens currently held by one fund and returns compact indicator rows for holdings-side comparison.

## Required Context

- All screening is fund-scoped and requires `fund_id`.
- The token universe is resolved from the fund assignment; the agent does not choose a universe directly.
- Holdings screening covers tokens currently held through active fund positions.
- `snapshot_date` is optional. Omit it to use the latest available DD snapshot on or before today, or provide `YYYY-MM-DD` for an exact historical indicator date.
- The catalog is global metadata and can be called before choosing the exact query shape.

## Use This Skill When

- The goal is to narrow a large token universe into a shortlist.
- The agent wants to compare candidate tokens against current holdings using the same indicator surface.
- The agent needs a low-cost, structured first pass before deeper due diligence.

## Do Not Use This Skill For

- Full narrative due diligence or thesis generation.
- Trade submission or rebalance execution.
- Broad fund monitoring unrelated to token screening.

## Workflow

1. Call `get_due_diligence_indicator_catalog` first.
2. Choose canonical fields from the catalog that fit the current screening idea.
3. Build a small request with `filters`, optional `snapshot_date`, optional `order_by`, explicit `fields`, and a modest `limit`.
4. Call `screen_token_universe_indicators(fund_id, request={...})` to identify candidate tokens.
5. If comparison is useful, call `screen_token_holdings_indicators(fund_id, request={...})` with the same or closely related fields.
6. Compare the compact indicator results and decide which tokens should advance to deeper due diligence.

## Request Authoring Rules

1. Use only catalog fields returned by `get_due_diligence_indicator_catalog`.
2. Use only operators listed in `allowed_operators`.
3. Use one `order_by` field and prefix it with `-` for descending order.
4. Never use `unsortable_fields` in `order_by`.
5. Keep `limit` within the catalog's min/max bounds.
6. Use `snapshot_date` only when you intentionally want an exact historical indicator snapshot.
7. Prefer 1-3 filters and 2-6 projected fields for the first pass.
8. On validation errors, correct the request and retry instead of inventing aliases or unsupported syntax.

## Request Shape

Use this object as the nested `request` argument in screening MCP tool calls:

```json
{
  "snapshot_date": "2026-03-14",
  "filters": [
    {"field": "score_social_social_momentum", "op": "gt", "value": 30},
    {"field": "kpi_performance_rel_return_7d_vs_btc", "op": "gt", "value": 0.05}
  ],
  "order_by": "-score_social_social_momentum",
  "fields": [
    "score_social_social_momentum",
    "kpi_performance_rel_return_7d_vs_btc"
  ],
  "limit": 20
}
```

## Comparison Guidance

- Use the universe screen to find interesting external candidates.
- Use the holdings screen to inspect how current positions score on the same dimensions.
- Favor requests that make side-by-side comparison easy by projecting the same fields across both calls.
- Treat this step as shortlist generation, not the final investment decision.

## Safety Notes

- Do not invent selectors, aliases, or operators.
- Start with small, readable screens and iterate.
- Keep this workflow read-only; downstream trade or rebalance actions belong to separate skills and tools.
