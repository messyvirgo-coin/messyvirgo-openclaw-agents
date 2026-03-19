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

- Define and enforce the runtime bootstrap contract (which assets exist, where they live, and how they are initialized).
- Guarantee idempotent setup behavior and explicit reporting of what was created versus already present.

## Runtime Assets Owned Today

- `agent-workflows/screening/`
- `agent-workflows/screening/results/`
- `agent-workflows/screening/history/`
- `agent-workflows/screening/SCREENING.md`

## Bundled template files in the skill's directory

- `SCREENING.default.md`

## Setup Flow

Execute all steps defined below. Even if a step should fail, proceed to the next one and always end with the 'Final Step'

### Step 1: Setup Token Screening

1. Ensure `agent-workflows/screening/`, `agent-workflows/screening/results/`, and `agent-workflows/screening/history/` exist.
2. If `agent-workflows/screening/SCREENING.md` does not exist, create it from this skill's bundled `SCREENING.default.md`.
3. If the runtime file already exists, leave it unchanged unless the user explicitly asks to reset or overwrite it.

### Final Step

1. Report exactly which paths were created, which already existed, and whether the runtime workflow file was created or left intact.
  
## Boundaries

- **Bootstrap only:** This skill prepares runtime workspace files and directories. It does not inspect fund policy, save profiles, or execute screening runs.
- **Idempotent behavior:** Re-running setup must be safe. Existing directories remain in place and existing runtime files are not overwritten by default.
- **No silent reset:** Do not replace an existing runtime files with a template unless the user explicitly asks for that reset.
- **No invented assets:** Create only the runtime assets defined above. Do not add extra workflow files, result artifacts, or policy content that the bundled default does not define.
