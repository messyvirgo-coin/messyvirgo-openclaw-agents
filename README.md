# Messy Virgo OpenClaw Agents Pack

This repository publishes Messy Virgo OpenClaw agents, skills, and pack install scripts.

It is meant for people who already have an OpenClaw installation and want to add our agents to it.

It owns:

- shared skills loaded for the whole OpenClaw instance (via generated shared pack config)
- reusable agent workspace templates and metadata
- bundle selectors for installing a subset of agents
- install, update, and remove scripts

## Quick Start

Install the core bundle into your OpenClaw config and workspaces:

```bash
./scripts/install.sh --bundle mv-core
```

Paths default to `~/.openclaw` (config/state) and `~/.openclaw/workspaces` (agent workspaces), overridable with `OPENCLAW_CONFIG_DIR` and `OPENCLAW_WORKSPACES_DIR`. Generated `skills.load.extraDirs` is rendered as `~/.openclaw/packs/messyvirgo-openclaw-agents/shared/skills`.

If you want every managed agent in the pack, omit `--bundle`.

### Messy Virgo CLI

Agents call the Messy Virgo HTTP API through the **`mv`** command-line tool (package `@messyvirgo/cli`). Install is separate from this pack.

**Install** (pick one):

```bash
npx @messyvirgo/cli --help
```

```bash
npm install -g @messyvirgo/cli
mv --help
```

**Auth** (API key format `mvk_...`): set `MV_API_URL` and `MV_API_KEY`, or persist with `mv config set api-url …` and `mv config set api-key …`. Quick check: `mv funds list --json`.

## Bundles

- `mv-core`: the supported bundle (core screener agent)

## Source Layout

- `agents/`: source of truth for the agent registry and workspace templates
- `bundles/`: bundle selectors that choose which agents get installed
- `skills/`: shared skills loaded instance-wide
- `docs/OPERATIONS.md`: install, update, and remove

## Notes

- Assign suitable Agent models in OpenClaw after install.
- For Telegram setup, see [`docs/TELEGRAM-HELPER.md`](./docs/TELEGRAM-HELPER.md).

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Security

See [SECURITY.md](./SECURITY.md).

## Support

See [SUPPORT.md](./SUPPORT.md).

## Disclaimer

⚠️ This is experimental software for educational and research purposes only. Trading involves significant risk of loss. If you decide to use any of this software in a trading context, you do this 100% at your own risk. Trade with capital you can afford to lose. Past performance does not guarantee future results. This software is not financial advice. The authors are not responsible for any financial losses resulting from the use of this software.
