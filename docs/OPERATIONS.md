# Pack operations

Install, update, and remove Messy Virgo pack files into an existing OpenClaw layout.

## Paths and `.env`

- **Config / state:** `OPENCLAW_CONFIG_DIR` or `~/.openclaw`
- **Agent workspaces:** `OPENCLAW_WORKSPACES_DIR` or `~/.openclaw/workspaces`

Set these in the environment or in a repo-root `.env` (the scripts source `.env` automatically). See [`.env.example`](../.env.example).

Agents use the Messy Virgo HTTP API via the **`mv`** CLI; install and auth are covered in the [README](../README.md).

## Install

```bash
./scripts/install.sh --bundle mv-core
```

Install every agent in [`agents/registry.json`](../agents/registry.json) (same as the full pack):

```bash
./scripts/install.sh
```

**`--sync`** — Overwrite pack-managed files that already exist but differ (shared generated config, non-stateful templates). Stateful workspace files (`USER.md`, `MEMORY.md`, `IDENTITY.md`, `HEARTBEAT.md`) are still only copied if missing. Example:

```bash
./scripts/install.sh --bundle mv-core --sync
```

Without `--sync`, existing files that differ from the pack are left as-is (first-time copy only for those paths).

## Update

Update is install with `--sync`:

```bash
./scripts/update.sh --bundle mv-core
```

All agents:

```bash
./scripts/update.sh
```

## Remove

Remove bundle-managed config entries and workspace templates; **stateful** workspace files are kept unless you opt in.

```bash
./scripts/remove.sh --bundle mv-core
```

Remove everything the pack manages (still preserves stateful workspace files by default):

```bash
./scripts/remove.sh
```

Also delete stateful workspace files (`USER.md`, `MEMORY.md`, etc.):

```bash
./scripts/remove.sh --purge-state
```

## What the scripts change

- **Shared:** generated pack include (e.g. `skills.load.extraDirs` for pack skills) and copied `skills/` under the pack’s shared directory.
- **Per bundle:** generated agent list and copied templates from `agents/<id>/` into each workspace (stateful files preserved as above).

After install or update, restart your OpenClaw gateway if it does not pick up config changes automatically.
