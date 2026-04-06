# Client Install

Use this guide if you install the pack through `messyvirgo-openclaw-client`.

The client repo handles the OpenClaw deployment itself. This pack only supplies agents, skills, runtime fragments, and bundle selection.

## Prerequisites

- A configured `messyvirgo-openclaw-client` checkout
- `MESSY_VIRGO_MCP_URL`
- `MESSY_VIRGO_API_KEY`

## Install

```bash
cp .env.example .env
# edit .env and set real values
./scripts/install.sh --target secure --bundle mv-core
```

If you prefer, you can also source the client repo `.env` or export the variables in your shell before running install/update.

## Update

```bash
./scripts/update.sh --target secure --bundle mv-core
```

## Remove

```bash
./scripts/remove.sh --target secure --bundle mv-core
```

## Restart

After install or update, restart the secure deployment so runtime files are reloaded:

```bash
cd ../messyvirgo-openclaw-client
./openclaw-secure/scripts/down.sh
./openclaw-secure/scripts/up.sh
```

## Telegram Setup

If you use the client repo for channel setup, bind the core screener agent by default:

```bash
openclaw channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN"
openclaw agents bind --agent mv-core-screener --bind telegram
openclaw pairing list --channel telegram
openclaw pairing approve telegram <CODE> --notify
```

If you still run the legacy bundle, bind `mv-t1-mngr` instead.
