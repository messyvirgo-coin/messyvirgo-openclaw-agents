---
name: mv-agent-setup
description: Use when bootstrapping a new Messy Virgo agent checkout, initializing runtime files, or fixing missing assets for token screening.
---

# Agent Setup

## Overview

This skill bootstraps the local agent runtime workspace. It creates the required directories and files from the bundled default when they are missing.

## When to Use

- A fresh agent installation needs its runtime workspace initialized.
- A workflow skill reports that required runtime files or directories are missing.
- The user wants a safe, idempotent setup pass that reports what was created versus what was already present.

## Quick Reference

| Item | Rule |
| ------ | ------ |
| Owned runtime paths | `agent-workflows/screening/`, `agent-workflows/screening/results/`, `agent-workflows/screening/history/`, `agent-workflows/screening/SCREENING.md` |
| Bundled default file | `SCREENING.default.md` |
| Overwrite behavior | If `agent-workflows/screening/SCREENING.md` already exists, leave it unchanged unless the user explicitly asks to reset or overwrite it. |
| Scope | Bootstrap only. This skill does not inspect fund queries, save custom queries, or execute screening runs. |

## Procedure

1. Ensure `agent-workflows/screening/`, `agent-workflows/screening/results/`, and `agent-workflows/screening/history/` exist.
2. If `agent-workflows/screening/SCREENING.md` does not exist, create it from the bundled `SCREENING.default.md`.
3. If the runtime file already exists, leave it intact unless the user explicitly asks to reset it.
4. Report exactly which paths were created, which already existed, and whether `SCREENING.md` was created or left unchanged.

## Common Mistakes

- Using this skill for configuration or execution work. It only bootstraps runtime files.
- Overwriting an existing `SCREENING.md` without an explicit user request.
- Creating extra workflow assets beyond the runtime paths this skill owns.
- Failing to report what was created versus what already existed.
