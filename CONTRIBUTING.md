# Contributing to messyvirgo-openclaw-agents

Thanks for your interest in contributing to Messy Virgo.

This repository is the source of truth for Messy Virgo agent packs (agent workspace templates, skills, config fragments, and install/update/remove scripts for OpenClaw targets).

Contributions are welcome, but please note:

- This repo is public and open to PRs, but not every PR will be merged.
- Maintainers keep final say on scope, design, and what gets shipped.
- Support is best-effort only (see [SUPPORT.md](./SUPPORT.md)).

## Ground rules

- Be respectful: follow the [Code of Conduct](./CODE_OF_CONDUCT.md).
- Keep it public-safe: do not include secrets, tokens, personal data, private links, or confidential information.
- Keep PRs focused: one change-set per PR when possible.
- Keep changes auditable: explain what changed, why, and how you verified it.

## What kinds of contributions we welcome

- Bug fixes and improvements in `scripts/`
- Documentation improvements in `README.md` and `docs/`
- Agent/runtime quality improvements under `agents/`, `runtime/`, `skills/`, and `bundles/`
- Safer defaults and better operator ergonomics that do not break existing flows

## Contribution boundaries (important)

- This repo owns Messy Virgo pack assets and pack-management logic.
- It is not the upstream OpenClaw project.
  - Upstream OpenClaw issues/feature requests should generally go to OpenClaw.
- Maintainers may decline changes that increase maintenance burden, reduce safety, or expand scope without clear value.

## Pull request checklist

- Explain intent: what problem does this solve?
- Add or update docs if user workflow changes.
- Include reproducible verification steps (commands and expected outcomes).
- Double-check that you did not commit `.env`, tokens, credentials, or private paths.

## Maintainers

- `@messy-michael`
- `@MessyFranco`
