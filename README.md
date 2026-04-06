# Messy Virgo OpenClaw Agents Pack

This repository publishes Messy Virgo OpenClaw agents, skills, runtime fragments, and pack install scripts.

It is meant for people who already have an OpenClaw installation and want to add our agents to it. You do not need the Messy Virgo client repo to use this pack.

It owns:

- shared skills loaded for the whole OpenClaw instance
- runtime fragments and the `mcporter.json` template
- reusable agent workspace templates and metadata
- bundle selectors for installing a subset of agents
- install, update, and remove scripts for `raw` and `secure` targets

It does not own:

- the upstream OpenClaw source fork
- the Messy Virgo client repo
- Docker hardening or other secure deployment wrapper concerns
- the legacy `messyvirgo-skills` repo

## Quick Start

For a plain OpenClaw installation, export the MCP variables and install the core bundle:

```bash
export MESSY_VIRGO_MCP_URL="https://api.messyvirgo.com/mcp"
export MESSY_VIRGO_API_KEY="your-api-key"
./scripts/install.sh --target raw --bundle mv-core
```

Use `--target secure` if you are installing into a secure Docker-based OpenClaw deployment instead of a plain native one.

If you want every managed agent in the pack, omit `--bundle`.

## Bundles

- `mv-core`: recommended bundle for new installs
- `mv-t1`: legacy bundle kept for compatibility and scheduled for removal

## If You Use the Messy Virgo Client

If you use `messyvirgo-openclaw-client`, follow [`docs/CLIENT-INSTALL.md`](./docs/CLIENT-INSTALL.md) for the client-specific install path and deployment notes.

## Source Layout

- `agents/`: source of truth for the agent registry and workspace templates
- `bundles/`: bundle selectors that choose which agents get installed
- `skills/`: shared skills loaded instance-wide
- `runtime/`: runtime fragments and the `mcporter.json` template
- `docs/OPERATIONS.md`: pack operations, cleanup, and channel setup

## Notes

- Agent models are assigned in OpenClaw after install.
- MCP runtime credentials come from environment variables.
- For Telegram and other channel setup, see `docs/OPERATIONS.md`.

## Public Repo Safety

Do not post secrets, tokens, private links, personal data, or confidential information in issues or pull requests.

If you suspect a vulnerability or accidental disclosure, report privately to `contact@messyvirgo.com` instead of opening a public security issue.

## License

Apache-2.0. See [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Security

See [SECURITY.md](./SECURITY.md).

## Support

See [SUPPORT.md](./SUPPORT.md).
