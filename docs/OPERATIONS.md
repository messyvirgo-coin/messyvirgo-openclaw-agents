# Operations

## Targets

- `wrapper`: secure-wrapper deployment defaults (`~/.openclaw-secure`, `~/OpenClawWorkspaces`)
- `openclaw`: plain OpenClaw defaults (`~/.openclaw`, `~/.openclaw/workspaces`)

## Commands

Install:

```bash
./scripts/install.sh --target wrapper --profile mv-t1
```

Update:

```bash
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

## Channel Setup Helper

Bind Telegram (or another channel) to a pack agent:

```bash
./scripts/setup-agent-channel.sh --target wrapper --agent mv-t1-mngr --channel telegram
```

With an inline token:

```bash
./scripts/setup-agent-channel.sh --target wrapper --agent mv-t1-mngr --channel telegram --token "$TELEGRAM_BOT_TOKEN"
```

For plain OpenClaw installs:

```bash
./scripts/setup-agent-channel.sh --target openclaw --agent mv-t1-mngr --channel telegram --use-env
```
