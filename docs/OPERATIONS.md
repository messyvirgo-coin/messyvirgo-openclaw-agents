# Operations

This document covers pack operations for OpenClaw installations.
If you install through `messyvirgo-openclaw-client`, use `docs/CLIENT-INSTALL.md` for the client-specific path.

## Targets

- `secure`: openclaw-secure (Docker) deployment
  - config: `~/.openclaw-secure`
  - workspaces: `~/OpenClawWorkspaces`
- `raw`: openclaw-raw (native) deployment
  - config: `~/.openclaw`
  - workspaces: `~/OpenClawWorkspaces`

If you use custom locations, set `OPENCLAW_CONFIG_DIR` and/or
`OPENCLAW_WORKSPACES_DIR` before running the scripts.

### Migration from older plain OpenClaw installs

If pack files were previously written under `~/.openclaw/workspaces`, you can
preserve that layout by
setting `OPENCLAW_WORKSPACES_DIR=$HOME/.openclaw/workspaces` before future
install/update runs. Otherwise, new installs use `~/OpenClawWorkspaces` to
match the messyvirgo-openclaw-client native defaults.

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

## Secure workflow

Install the core bundle (recommended for new installs):

```bash
./scripts/install.sh --target secure --bundle mv-core
```

Update the core bundle:

```bash
./scripts/update.sh --target secure --bundle mv-core
```

Legacy Team 1 bundle (`mv-t1-mngr` only): use `--bundle mv-t1` in the same commands instead of `mv-core`.

Install or update everything in the pack:

```bash
./scripts/install.sh --target secure
./scripts/update.sh --target secure
```

Remove the core bundle but keep shared pack assets:

```bash
./scripts/remove.sh --target secure --bundle mv-core
```

Remove the legacy Team 1 bundle the same way with `--bundle mv-t1`.

Remove all pack-managed files but keep stateful workspace files:

```bash
./scripts/remove.sh --target secure
```

Remove pack-managed files and also purge stateful workspace files:

```bash
./scripts/remove.sh --target secure --purge-state
```

If you manage a secure client deployment, restart it after install or update so config/runtime changes are picked up. See `docs/CLIENT-INSTALL.md`.

## Raw workflow

Install the core bundle:

```bash
./scripts/install.sh --target raw --bundle mv-core
```

Update the core bundle:

```bash
./scripts/update.sh --target raw --bundle mv-core
```

Legacy Team 1 bundle: use `--bundle mv-t1` in the same commands.

Install or update everything in the pack:

```bash
./scripts/install.sh --target raw
./scripts/update.sh --target raw
```

Remove the core bundle:

```bash
./scripts/remove.sh --target raw --bundle mv-core
```

Remove all pack-managed files:

```bash
./scripts/remove.sh --target raw
```

## What install/update changes

- Shared runtime config and shared skills are replaced by the pack.
- The rendered agent list comes from `agents/registry.json` and selected bundles.
- Template workspace files are refreshed from `agents/<agent-id>/`.
- Stateful workspace files are preserved unless you explicitly purge state.

In this pack, older client installs may still have files that are no longer
shipped. `update.sh` does not automatically delete those stale files.

## Clean Roll-out After Pack Changes

Use this flow when the pack removed agents, removed skills, or stopped shipping some workspace files.

### Secure

1. Update the bundle:

```bash
./scripts/update.sh --target secure --bundle mv-core
```

(If you still use the legacy Team 1 bundle, run the same command with `--bundle mv-t1`.)

1. Remove retired agent workspaces:

```bash
rm -rf ~/OpenClawWorkspaces/mv-t1-coder \
  ~/OpenClawWorkspaces/mv-t1-planner \
  ~/OpenClawWorkspaces/mv-t1-researcher \
  ~/OpenClawWorkspaces/mv-t1-funds
```

1. Remove stale files from remaining agent workspaces if they still exist:

```bash
rm -f ~/OpenClawWorkspaces/mv-core-screener/TOOLS.md \
  ~/OpenClawWorkspaces/mv-t1-mngr/TOOLS.md \
  ~/OpenClawWorkspaces/mv-t1-mngr/MEMORY.md
```

1. Restart the secure deployment if you use the client repo. See `docs/CLIENT-INSTALL.md`.

### Raw

1. Update the bundle:

```bash
./scripts/update.sh --target raw --bundle mv-core
```

(If you still use the legacy Team 1 bundle, use `--bundle mv-t1`.)

1. Remove retired agent workspaces:

```bash
rm -rf ~/OpenClawWorkspaces/mv-t1-coder \
  ~/OpenClawWorkspaces/mv-t1-planner \
  ~/OpenClawWorkspaces/mv-t1-researcher \
  ~/OpenClawWorkspaces/mv-t1-funds
```

1. Remove stale files from remaining agent workspaces if they still exist:

```bash
rm -f ~/OpenClawWorkspaces/mv-core-screener/TOOLS.md \
  ~/OpenClawWorkspaces/mv-t1-mngr/TOOLS.md \
  ~/OpenClawWorkspaces/mv-t1-mngr/MEMORY.md
```

If you use custom workspace paths, run the same cleanup inside
`$OPENCLAW_WORKSPACES_DIR`.

### Full reinstall

If you want to fully reset the surviving agent to the current pack templates:

```bash
./scripts/remove.sh --target secure --bundle mv-core --purge-state
./scripts/install.sh --target secure --bundle mv-core
```

Then remove stale workspaces/files as shown above and restart the secure deployment.

## Post-install model assignment

After install/update, assign the model for each managed agent in the OpenClaw
dashboard Agent settings.

If an agent has no explicit model configured, it falls back to the runtime
default model of the target instance.

## Telegram Setup

For channel registration, binding, and pairing, follow the client-specific guide if you use `messyvirgo-openclaw-client`, or use your local OpenClaw CLI directly in a plain installation.
