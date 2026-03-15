# Messy Virgo OpenClaw Agents Pack

This repository is the source of truth for Messy Virgo OpenClaw runtime assets and agents.

It owns:

- global skill packages loaded for the whole OpenClaw instance
- global runtime config fragments and `mcporter.json` template
- reusable agent workspace templates and metadata
- optional agent bundles for selective deployment
- install/update/remove scripts for both secure-wrapper and plain OpenClaw targets

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

- `skills/`: global skills loaded instance-wide
- `runtime/`: global OpenClaw runtime fragments and `mcporter.json` template
- `agents/`: reusable agent definitions (`registry.json`) and workspace templates
- `bundles/`: optional agent-only deployment selectors

Legacy `profiles/` content is retained only for migration context and is no longer canonical.

## Pack Install

After the client is installed and configured, install this pack from this repo:

```bash
## Option A: wrapper installed on same machine
set -a
source ../messyvirgo-openclaw-client/.env
set +a

## Option B: export directly in current shell
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"

## Install
./scripts/install.sh --target wrapper
```

Install only a selected bundle:

```bash
./scripts/install.sh --target wrapper --bundle mv-t1
```

Restart the wrapper after install/update so runtime files are reloaded:

```bash
cd ../messyvirgo-openclaw-client
./scripts/down.sh
./scripts/up.sh
```

Update managed files in place:

```bash
# load env first (Option A or B above), then:
./scripts/update.sh --target wrapper
```

Update only a selected bundle:

```bash
./scripts/update.sh --target wrapper --bundle mv-t1
```

Remove only pack-managed files:

```bash
./scripts/remove.sh --target wrapper
```

Remove one bundle while keeping shared global assets:

```bash
./scripts/remove.sh --target wrapper --bundle mv-t1
```

Install into a plain OpenClaw deployment:

```bash
./scripts/install.sh --target openclaw
```

## Plain OpenClaw

If you are not using the Messy Virgo wrapper client and instead run plain
OpenClaw directly, use this repo as a pack overlay on top of your existing
OpenClaw instance.

Install into a plain OpenClaw target:

```bash
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/install.sh --target openclaw
```

Update later:

```bash
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/update.sh --target openclaw
```

Remove pack-managed files:

```bash
./scripts/remove.sh --target openclaw
```

Remove one bundle while keeping shared global assets:

```bash
./scripts/remove.sh --target openclaw --bundle mv-t1
```

In plain OpenClaw mode, target paths default to:

- config: `~/.openclaw`
- workspaces: `~/.openclaw/workspaces`

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

## MCP Runtime Values (Funds Agent)

`mv-t1-funds` uses MCP runtime values from environment variables:

- `MESSY_VIRGO_MCP_URL`
- `MESSY_VIRGO_API_KEY`

Set them in your shell (or wrapper `.env`) before running install/update.
These values are rendered into managed `mcporter.json` during pack install/update.
For wrapper installs, this is a single global runtime config at
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
