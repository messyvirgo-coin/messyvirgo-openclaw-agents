# Messy Virgo OpenClaw Agents Pack

This repository is the source of truth for Messy Virgo agent packs.

It owns:

- team-scoped agent workspace templates (for example `mv-t1-*`)
- active skills used by those agents
- pack-managed OpenClaw config fragments
- install/update/remove scripts for both secure-wrapper and plain OpenClaw targets

It does not own:

- the upstream OpenClaw source fork
- secure deployment wrapper concerns (Docker hardening, image build wrappers)
- the legacy `messyvirgo-skills` repo (left unchanged for now)

## Quick Start

Install team profile `mv-t1` into a secure-wrapper deployment:

```bash
./scripts/install.sh --target wrapper --profile mv-t1
```

Install into a plain OpenClaw deployment:

```bash
./scripts/install.sh --target openclaw --profile mv-t1
```

Update managed files in place:

```bash
./scripts/update.sh --target wrapper --profile mv-t1
```

Remove only pack-managed files:

```bash
./scripts/remove.sh --target wrapper --profile mv-t1
```

Configure Telegram and bind to a profile agent:

```bash
./scripts/setup-agent-channel.sh --target wrapper --agent mv-t1-mngr --channel telegram
```
