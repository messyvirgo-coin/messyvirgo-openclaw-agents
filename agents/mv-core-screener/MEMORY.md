# Token Screening Memory

- Canonical screening workflow lives in `fund_sleeves.meta.screening`.
- Canonical screening context contains `custom_queries`, `workflow`, and `instructions`.
- Templates are shared and read-only.
- Screening context responses do not embed template definitions; load templates from screening template commands.
- Custom queries are sleeve-scoped and referenced by `query_id`.
- Universe `screen_sleeve_tokens` rows include `membership_source` and `selected_rank`.
- `create_fund_screen_run` persists candidates by `token_id`.
- `create_fund_screen_run` rejects the whole request if any candidate `token_id` is already a fund beta position.
- Screening execution is successful only when `create_fund_screen_run` returns a `screen_run_id`.
- Candidates may only come from executed `scope: universe` runs.
- Tokens with `membership_source` `fund_position` or `both` are not candidates.
- Unresolved `template:<id>` and `query:<id>` references are `failed_validation`.
- User-facing text uses symbol, otherwise name, otherwise contract address.
- User-facing text never includes internal `token_id` values.
