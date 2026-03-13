# Operations

## Targets

- `wrapper`: secure-wrapper deployment defaults (`~/.openclaw-secure`, `~/OpenClawWorkspaces`)
- `openclaw`: plain OpenClaw defaults (`~/.openclaw`, `~/.openclaw/workspaces`)

## Commands

Install:

```bash
set -a
source ../messyvirgo-openclaw-client/.env
set +a
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/install.sh --target wrapper --profile mv-t1
```

Restart wrapper services after install/update so runtime files are reloaded:

```bash
cd ../messyvirgo-openclaw-client
./scripts/down.sh
./scripts/up.sh
```

Update:

```bash
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/update.sh --target wrapper --profile mv-t1
```

Remove (preserve state):

```bash
./scripts/remove.sh --target wrapper
```

Remove including stateful files:

```bash
./scripts/remove.sh --target wrapper --purge-state
```

## Post-Install: Per-Agent Model Assignment

After install/update, assign the model for each `mv-t1-*` agent in the
OpenClaw dashboard Agent settings.

If an agent has no explicit model configured, it falls back to the runtime
default model of the target instance.

## MCP Runtime Values (Funds Agent)

The funds MCP runtime is sourced from:

- `MESSY_VIRGO_MCP_URL`
- `MESSY_VIRGO_API_KEY`

Set these values before install/update (shell exports or wrapper `.env`).
Pack scripts render them into managed `mcporter.json`.

Do not rely on dashboard-only edits for these runtime credentials.

## Telegram Setup via OpenClaw CLI

Add Telegram account and bind it to `mv-t1-mngr`:

```bash
export TELEGRAM_BOT_TOKEN="your-bot-token"
../messyvirgo-openclaw-client/scripts/cli.sh channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN"
../messyvirgo-openclaw-client/scripts/cli.sh agents bind --agent mv-t1-mngr --bind telegram
```

If CLI access is blocked by local `pairing required`, approve device pairing:

```bash
../messyvirgo-openclaw-client/scripts/cli.sh devices list
../messyvirgo-openclaw-client/scripts/cli.sh devices approve <REQUEST_ID>
```

Complete Telegram DM pairing:

```bash
# Send /start or "hi" to your bot in Telegram first
../messyvirgo-openclaw-client/scripts/cli.sh pairing list --channel telegram
../messyvirgo-openclaw-client/scripts/cli.sh pairing approve telegram <CODE> --notify
```

Verify:

```bash
../messyvirgo-openclaw-client/scripts/cli.sh agents bindings
../messyvirgo-openclaw-client/scripts/cli.sh agent --agent mv-t1-mngr --message "State your name in one sentence."
```
