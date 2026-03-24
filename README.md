# Messy Virgo OpenClaw Agents Pack

This repository is the source of truth for Messy Virgo OpenClaw runtime assets and agents.

It owns:

- global skill packages loaded for the whole OpenClaw instance
- global runtime config fragments and `mcporter.json` template
- reusable agent workspace templates and metadata
- optional agent bundles for selective deployment
- install/update/remove scripts for both secure (Docker) and raw (native) targets

It does not own:

- the upstream OpenClaw source fork
- secure deployment wrapper concerns (Docker hardening, image build wrappers)
- the legacy `messyvirgo-skills` repo (left unchanged for now)

## Official Install Docs

Use the client repository as the canonical operator guide:

- Linux: [`messyvirgo-openclaw-client/docs/INSTALL-linux.md`](https://github.com/messyvirgo-coin/messyvirgo-openclaw-client/blob/main/docs/INSTALL-linux.md)
- macOS: [`messyvirgo-openclaw-client/docs/INSTALL-macos.md`](https://github.com/messyvirgo-coin/messyvirgo-openclaw-client/blob/main/docs/INSTALL-macos.md)

Those docs cover:

- secure client setup
- `.env` preparation
- device/browser pairing
- optional Messy Virgo agent installation
- Telegram channel registration and pairing

## Source Layout

- `skills/`: skills loaded instance-wide; use subfolders like `skills/mv-t1-mngr/` for agent-specific skills (see `skills/README.md`)
- `runtime/`: global OpenClaw runtime fragments and `mcporter.json` template
- `agents/`: **source of truth** — agent registry (`registry.json`) and workspace templates (e.g. `agents/mv-t1-mngr/*.md` plus optional `soul.json`). Install/update scripts copy these into the target’s workspaces directory; the live workspaces live under `~/OpenClawWorkspaces` (both secure and raw modes), or the path set by `OPENCLAW_WORKSPACES_DIR`.
- `bundles/`: optional agent-only deployment selectors (e.g. `mv-t1` bundle picks which agents from the registry get installed)

## SoulSpec vs OpenClaw Files

This pack aims to stay close to SoulSpec while still working well in OpenClaw.

- SoulSpec-style core agent files in this repo are `soul.json`, `SOUL.md`, `IDENTITY.md`, and `AGENTS.md`.
- `BOOTSTRAP.md` and `USER.md` are kept as OpenClaw-specific workspace files because OpenClaw reads and uses them directly.
- `TOOLS.md` and `MEMORY.md` are not shipped by this pack; operational tool guidance belongs in `AGENTS.md` and task-specific procedures should live in `skills/`.

## Pack Install

After the client is installed and configured, install this pack from this repo. The install and update scripts need `MESSY_VIRGO_MCP_URL` and `MESSY_VIRGO_API_KEY` for the MCP runtime config. You can provide them in any of these ways:

```bash
## Option A: .env in this repo (recommended for local use)
cp .env.example .env
# Edit .env and set real values; do not commit .env

## Option B: client env (when using secure mode)
set -a
source ../messyvirgo-openclaw-client/.env
set +a

## Option C: export in current shell
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"

## Install
./scripts/install.sh --target secure
```

Install only a selected bundle:

```bash
./scripts/install.sh --target secure --bundle mv-t1
```

Restart the secure deployment after install/update so runtime files are reloaded:

```bash
cd ../messyvirgo-openclaw-client
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
```

Update managed files in place:

```bash
# load env first (Option A or B above), then:
./scripts/update.sh --target secure
```

Update only a selected bundle:

```bash
./scripts/update.sh --target secure --bundle mv-t1
```

Remove only pack-managed files:

```bash
./scripts/remove.sh --target secure
```

Remove one bundle while keeping shared global assets:

```bash
./scripts/remove.sh --target secure --bundle mv-t1
```

Install into a plain OpenClaw deployment:

```bash
./scripts/install.sh --target raw
```

## Plain OpenClaw

If you use openclaw-raw (native) or run plain OpenClaw directly, use this repo
as a pack overlay on top of your existing OpenClaw instance.

Install into a plain OpenClaw target:

```bash
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/install.sh --target raw
```

Update later:

```bash
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/update.sh --target raw
```

Remove pack-managed files:

```bash
./scripts/remove.sh --target raw
```

Remove one bundle while keeping shared global assets:

```bash
./scripts/remove.sh --target raw --bundle mv-t1
```

In raw mode, target paths default to:

- config: `~/.openclaw`
- workspaces: `~/OpenClawWorkspaces`

For channels, bindings, and pairing, use the plain OpenClaw CLI directly:

```bash
openclaw channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN"
openclaw agents bind --agent mv-t1-mngr --bind telegram
openclaw pairing list --channel telegram
openclaw pairing approve telegram <CODE> --notify
```

## Post-Install: Assign Models Per Agent

This pack no longer ships provider/model catalog fragments. After install/update, assign the desired model to each managed agent in the OpenClaw dashboard Agent settings.

If you do not assign a model per agent, agents use the runtime default model
configured in the target OpenClaw instance.

## MCP Runtime Values

The pack uses MCP runtime values from environment variables (e.g. for funds MCP used by mv-t1-mngr):

- `MESSY_VIRGO_MCP_URL`
- `MESSY_VIRGO_API_KEY`

Set them in your shell (or the secure deployment `.env`) before running install/update.
These values are rendered into managed `mcporter.json` during pack install/update.
For secure installs, this is a single global runtime config at
`$OPENCLAW_CONFIG_DIR/mcporter.json` (default: `~/.openclaw-secure/mcporter.json`);
per-workspace `config/mcporter.json` files are not required.

Use the dashboard for agent model selection, but keep MCP runtime credentials in
environment variables.

## Notes

- This pack does not force a default agent in the target instance.
- For Telegram registration, bindings, and pairing, follow the official client install docs above.
- More pack-specific operational examples live in `docs/OPERATIONS.md`.

## Public Repo Safety

Do not post secrets, tokens, private links, personal data, or confidential
information in issues or pull requests.

If you suspect a vulnerability or accidental disclosure, report privately to
`contact@messyvirgo.com` (do not open a public security issue).

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Security

See [SECURITY.md](./SECURITY.md).

## Support

See [SUPPORT.md](./SUPPORT.md).
