# Skills

Each skill is a subdirectory under this directory with at least `SKILL.md`.

- **Shared:** `skills/<skill-name>/` — available to any agent; the runtime loads all of these.
- **Scoped to one agent:** `skills/<agent-id>/<skill-name>/` — same load path; only that agent’s docs (e.g. AGENTS.md) reference the skill, so in practice only that agent uses it.
