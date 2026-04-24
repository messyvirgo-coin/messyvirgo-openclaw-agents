# Token Screening Memory

- Canonical screening workflow lives in `fund_sleeves.meta.screening`.
- Canonical screening aggregation workflow lives in `fund_sleeves.meta.screening_aggregation`.
- Screening is the bridge between universe-level due-diligence indicators and
  later candidate-vs-holdings analysis for fund decisions.
- Canonical screening context contains `custom_queries`, `workflow`, and `instructions`.
- Canonical screening aggregation context contains `enabled`, `policy`, and `instructions`.
- Configuration-only work may execute `mv screening screen` for validation, but must not execute `mv screening runs create` unless the user explicitly requests persisted run creation.
- Templates are shared and read-only.
- Screening context responses do not embed template definitions; load templates from screening template commands.
- KPI and score catalogs are foundational screening references; use them alongside templates and field catalog when authoring or interpreting screening queries.
- Daily batch screening produces the KPI and score surfaces that sleeve
  screening queries read from.
- Sleeves screen within their bound token universe, which narrows the working
  set from the full token market to a smaller candidate pool.
- Custom queries are sleeve-scoped and referenced by `query_id`.
- Sleeve screening rows include `selected_rank` from `token_universe_current_members`.
- `create_fund_screen_run` persists candidates by `token_id`.
- `create_fund_screen_run` requires explicit `run_date` and stores one persisted sleeve/day run.
- Screening execution is successful only when `create_fund_screen_run` returns a `screen_run_id`.
- When aggregation is enabled, the standard screening workflow persists the raw run first and then rebuilds the same-sleeve aggregate run for the same as-of date.
- Stored raw runs: `mv screening runs list|get`. Aggregate runs: `mv screening aggregation runs list|get|latest`. Indicators: `mv screening indicators get`.
- Candidates come from executed screening runs for the sleeve universe.
- Unresolved `template:<id>` and `query:<id>` references are `failed_validation`.
- User-facing text uses symbol, otherwise name, otherwise contract address.
- User-facing text never includes internal `token_id` values.
