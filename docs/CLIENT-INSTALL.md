# Client Install

Use this guide if you install the pack through `messyvirgo-openclaw-client`.

The client repo handles the OpenClaw deployment itself. This pack only supplies agents, skills, runtime fragments, and bundle selection.

## Prerequisites

- A configured `messyvirgo-openclaw-client` checkout
- `MESSY_VIRGO_MCP_URL`
- `MESSY_VIRGO_API_KEY`

Client `openclaw-secure/scripts/setup.sh` defaults `OPENCLAW_CONFIG_DIR` to `~/.openclaw` (override in the client repo `.env`). Host agent workspaces stay under `~/OpenClawWorkspaces` by default. The gateway container sees config at `/home/node/.openclaw`, so this pack’s `.env` should include:

```bash
OPENCLAW_RUNTIME_CONFIG_DIR=/home/node/.openclaw
```

(or export it before running the scripts). Files are still written on the host under `OPENCLAW_CONFIG_DIR`; that variable only affects paths embedded in generated pack fragments (for example shared skills).

## Install

```bash
cp .env.example .env
# edit .env: MCP keys, OPENCLAW_RUNTIME_CONFIG_DIR for Docker as above
./scripts/install.sh --bundle mv-core
```

If you prefer, you can also source the client repo `.env` or export the variables in your shell before running install/update.

## Update

```bash
./scripts/update.sh --bundle mv-core
```

## Remove

```bash
./scripts/remove.sh --bundle mv-core
```

## Restart

After install or update, restart the secure deployment so runtime files are reloaded:

```bash
cd ../messyvirgo-openclaw-client
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
```
