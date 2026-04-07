# Operations

This document covers pack operations for OpenClaw installations.
If you install through `messyvirgo-openclaw-client`, use `docs/CLIENT-INSTALL.md` for Docker path notes and restarts.

## Paths

Install/update/remove use the same layout as `messyvirgo-openclaw-client` / OpenClaw defaults:

- Config/state (host): `OPENCLAW_CONFIG_DIR` or `~/.openclaw`
- Agent workspace root (host): `OPENCLAW_WORKSPACES_DIR` or `~/.openclaw/workspaces`

Set those variables before running the scripts, or put them in this repo’s `.env` (loaded automatically).

Generated pack fragments use the same home-relative contract as OpenClaw config (`~/.openclaw/...`). In particular, shared skills are rendered to `~/.openclaw/packs/messyvirgo-openclaw-agents/shared/skills` in `skills.load.extraDirs`, so native and Docker-backed gateways resolve the same path shape without per-target script flags.

### Migration from older plain OpenClaw installs

Current defaults already use `~/.openclaw/workspaces`. If you previously used
`~/OpenClawWorkspaces`, set `OPENCLAW_WORKSPACES_DIR` explicitly while migrating
or move those directories into `~/.openclaw/workspaces`.

### Migration from `~/.openclaw-secure`

Older docs used a separate host config directory for Docker. The client now defaults host config to `~/.openclaw`. Either move your tree to `~/.openclaw` or set `OPENCLAW_CONFIG_DIR` to your existing directory before running install/update.

## Recommended env setup

The pack scripts auto-load `.env` from the repo root. Set it up once and then
run `install.sh` / `update.sh` without repeating exports in every command.

```bash
cp .env.example .env
# edit .env and set real values
```

Required values:

- `MESSY_VIRGO_MCP_URL`
- `MESSY_VIRGO_API_KEY`

These values are rendered into managed `mcporter.json` during install/update.
Do not rely on dashboard-only edits for these credentials.

If you do not want a repo-local `.env`, you can still export the variables in
your current shell before running the scripts.

## Install, update, remove

Install the core bundle (recommended for new installs):

```bash
./scripts/install.sh --bundle mv-core
```

Update the core bundle:

```bash
./scripts/update.sh --bundle mv-core
```

Legacy Team 1 bundle (`mv-t1-mngr` only): use `--bundle mv-t1` in the same commands instead of `mv-core`.

Install or update everything in the pack:

```bash
./scripts/install.sh
./scripts/update.sh
```

Remove the core bundle but keep shared pack assets:

```bash
./scripts/remove.sh --bundle mv-core
```

Remove the legacy Team 1 bundle the same way with `--bundle mv-t1`.

Remove all pack-managed files but keep stateful workspace files:

```bash
./scripts/remove.sh
```

Remove pack-managed files and also purge stateful workspace files:

```bash
./scripts/remove.sh --purge-state
```

If you use the Messy Virgo client Docker deployment, restart it after install or update so config/runtime changes are picked up. See `docs/CLIENT-INSTALL.md`.

## What install/update changes

- Shared runtime config and shared skills are replaced by the pack.
- The rendered agent list comes from `agents/registry.json` and selected bundles.
- Template workspace files are refreshed from `agents/<agent-id>/`.
- Stateful workspace files are preserved unless you explicitly purge state.

In this pack, older client installs may still have files that are no longer
shipped. `update.sh` does not automatically delete those stale files.

## Clean roll-out after pack changes

Use this flow when the pack removed agents, removed skills, or stopped shipping some workspace files.

1. Update the bundle:

```bash
./scripts/update.sh --bundle mv-core
```

(If you still use the legacy Team 1 bundle, run the same command with `--bundle mv-t1`.)

1. Remove retired agent workspaces:

```bash
rm -rf ~/.openclaw/workspaces/mv-t1-coder \
  ~/.openclaw/workspaces/mv-t1-planner \
  ~/.openclaw/workspaces/mv-t1-researcher \
  ~/.openclaw/workspaces/mv-t1-funds
```

1. Remove stale files from remaining agent workspaces if they still exist:

```bash
rm -f ~/.openclaw/workspaces/mv-core-screener/TOOLS.md \
  ~/.openclaw/workspaces/mv-t1-mngr/TOOLS.md \
  ~/.openclaw/workspaces/mv-t1-mngr/MEMORY.md
```

1. If you use the client repo Docker deployment, restart it. See `docs/CLIENT-INSTALL.md`.

If you use custom workspace paths, run the same cleanup inside
`$OPENCLAW_WORKSPACES_DIR`.

### Full reinstall

If you want to fully reset the surviving agent to the current pack templates:

```bash
./scripts/remove.sh --bundle mv-core --purge-state
./scripts/install.sh --bundle mv-core
```

Then remove stale workspaces/files as shown above and restart the Docker deployment if applicable.

## Post-install model assignment

After install/update, assign the model for each managed agent in the OpenClaw
dashboard Agent settings.

If an agent has no explicit model configured, it falls back to the runtime
default model of the target instance.

## Telegram Setup

For channel registration, binding, and pairing, follow the client-specific guide if you use `messyvirgo-openclaw-client`, or use your local OpenClaw CLI directly in a plain installation.
