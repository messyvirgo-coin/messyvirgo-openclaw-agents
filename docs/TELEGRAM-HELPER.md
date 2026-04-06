# Telegram setup

Wire a Telegram bot to OpenClaw for pack agents. Requires Telegram support enabled in your OpenClaw deployment.

## Bot token

In Telegram, open [@BotFather](https://t.me/BotFather), send `/newbot`, and finish the prompts. Copy the bot token BotFather sends and keep it private—you will pass it as `TELEGRAM_BOT_TOKEN`.

## Register channel and bind an agent

Set `BOT_NAME` and `BOT_ACCOUNT` to match the bot you created (display name and `@username` without `@`). Agent ids match `agents/*/` in this repo. To use the legacy agent instead of the default, comment the first `export` and uncomment the second.

```bash
export TELEGRAM_BOT_TOKEN='your-token-here'

# Uncomment the agent you want to register
# export AGENT_ID='mv-core-screener' BOT_NAME='MESSY Token Screener' BOT_ACCOUNT='mv_token_screener_bot'
# export AGENT_ID='mv-t1-mngr' BOT_NAME='MV Team 1 Manager' BOT_ACCOUNT='mv_t1_mngr_bot'

openclaw channels add --channel telegram --account "$BOT_ACCOUNT" --name "$BOT_NAME" --token "$TELEGRAM_BOT_TOKEN"
openclaw agents bind --agent "$AGENT_ID" --bind telegram
```

See [OpenClaw CLI: `channels`](https://github.com/openclaw/openclaw/blob/main/docs/cli/channels.md) and `openclaw channels add --help` for flags.

## Pairing

When a user first messages the bot, list pending codes and approve the right one (`--notify` pings the chat):

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE> --notify
```
