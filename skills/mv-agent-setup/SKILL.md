---
name: mv-agent-setup
description: |
  Setup or update the Messy Virgo (MV / MESSY) funds management agent configuration.
  Use to bootstrap a fresh or updated installation, new agent checkout, 
  or when a Messy Virgo (mv-prefix) skill reports missing components or configuration.
metadata:
  author: messy-virgo-platform
  version: "1.0"
---

# Agent Setup

## When to Use This Skill

- A fresh agent installation needs its runtime workspace initialized.
- A workflow skill reports that required runtime files or directories are missing.
- The user wants to bootstrap local workflow scaffolding before configuring or executing it.
- The user wants a safe, idempotent setup pass that reports what was created versus what was already present.

## Purpose

- This skill owns one-time runtime bootstrap for agent-local workflow files.
- It is generic by role, but today it initializes the screening workspace only.
- It prepares local files and directories so workflow-specific skills can assume the runtime workspace already exists.

## Runtime Assets Owned Today

- `agent-workflows/screening/`
- `agent-workflows/screening/results/`
- `agent-workflows/screening/history/`
- `agent-workflows/screening/SCREENING.md`
- `SCREENING.default.md` bundled with this skill as the starter template for the runtime workflow file

## Setup Flow

1. Confirm which supported workflow workspace should be initialized. Today that means screening.
2. Ensure `agent-workflows/screening/`, `agent-workflows/screening/results/`, and `agent-workflows/screening/history/` exist.
3. If `agent-workflows/screening/SCREENING.md` does not exist, create it from this skill's bundled `SCREENING.default.md`.
4. If the runtime file already exists, leave it unchanged unless the user explicitly asks to reset or overwrite it.
5. Report exactly which paths were created, which already existed, and whether the runtime workflow file was created or left intact.

## Boundaries

- **Bootstrap only:** This skill prepares runtime workspace files and directories. It does not inspect fund policy, save profiles, or execute screening runs.
- **Idempotent behavior:** Re-running setup must be safe. Existing directories remain in place and existing runtime files are not overwritten by default.
- **No silent reset:** Do not replace an existing `agent-workflows/screening/SCREENING.md` with the default template unless the user explicitly asks for that reset.
- **No invented assets:** Create only the runtime assets defined above. Do not add extra workflow files, result artifacts, or policy content that the bundled default does not define.
- **Local workspace only:** This skill performs local file bootstrap only. It does not call screening MCP tools or modify fund state in the backend.

## Relation To Other Skills

- **mv-agent-setup** prepares the runtime workspace so other workflow skills can operate safely.
- **mv-screening-configuration** assumes the screening runtime workspace already exists and changes what will run in future executions.
- **mv-screening-execution** assumes the screening runtime workspace already exists and performs deterministic screening runs.
