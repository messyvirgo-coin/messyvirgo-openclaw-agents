# Pull Request

## Context & Purpose

- What is the purpose of this change?
- What problem does it solve or improve?

## What changed

- Summarize the key changes (agents, bundles, runtime, skills, scripts, docs, config fragments, etc.).
- Note any behavior changes for operators/users.

## How to test

- Provide exact commands you ran.
- Include relevant environment details when needed (OS, Docker vs native OpenClaw, relevant `OPENCLAW_*` path overrides).

Example:

```bash
./scripts/install.sh --bundle mv-core
./scripts/update.sh --bundle mv-core
```

## Checklist

- [ ] No secrets/tokens/private paths were committed (especially `.env` or credential-bearing output)
- [ ] Docs updated if user workflow changed
- [ ] Changes are scoped and easy to review
