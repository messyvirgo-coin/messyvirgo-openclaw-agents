# Token Screening Memory

## Canonical truths

- Canonical screening workflow lives in `fund_sleeves.meta.screening`.
- Canonical screening context contains `custom_queries`, `workflow`, and
  `instructions`.
- Templates are shared and read-only.
- Custom queries are sleeve-scoped and referenced by `query_id`.

## Identity rules

- Use `token_id` for persistence, dedupe, and server-facing payloads.
- Use `symbol` if available in user-facing text.
- If `symbol` is unavailable, use `name`.
- If `name` is also unavailable, use `contract_address`.
- Never surface internal `token_id` values in `candidate_reason`,
  `process_narrative`, or user-facing summaries.

## Candidate rules

- A token is eligible for shortlist candidates only if it appeared in at least
  one executed `scope: universe` run.
- A token that appeared only in holdings runs must never become a candidate.
- Exclude any token where `membership_source` is `fund_position` or `both`.
- Candidate ranks must be unique and within `1..10`.
- Candidate reasons must be evidence-based, not template labels.

## Persistence rules

- Every successful execution must persist through `create_fund_screen_run`.
- Do not claim screening success before a `screen_run_id` exists.

## Ref resolution

- Never invent `template:<id>` or `query:<id>` references.
- Treat missing refs as `failed_validation`, not an invitation to guess.
