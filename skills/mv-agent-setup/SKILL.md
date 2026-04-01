---
name: mv-agent-setup
description: Use when bootstrapping a new Messy Virgo agent checkout, initializing runtime files, or fixing missing assets for token screening.
---

# Agent Setup

## Overview

This skill bootstraps the local agent runtime workspace. It creates required runtime directories when missing.

## When to Use

- A fresh agent installation needs its runtime workspace initialized.
- A workflow skill reports that required runtime files or directories are missing.
- The user wants a safe, idempotent setup pass that reports what was created versus what was already present.

## Quick Reference

| Item | Rule |
| ------ | ------ |
| Owned runtime paths | `agent-workflows/screening/`, `agent-workflows/screening/results/`, `agent-workflows/screening/history/` |
| Scope | Bootstrap only. This skill does not inspect fund queries, save custom queries, or execute screening runs. |

## Procedure

1. Ensure `agent-workflows/screening/`, `agent-workflows/screening/results/`, and `agent-workflows/screening/history/` exist.
2. Do not create or manage any `SCREENING.md` file. Screening workflow is canonical in sleeve DB context.
3. Report exactly which paths were created and which already existed.

## Common Mistakes

- Using this skill for configuration or execution work. It only bootstraps runtime files.
- Creating or editing `SCREENING.md` files from this setup skill.
- Creating extra workflow assets beyond the runtime paths this skill owns.
- Failing to report what was created versus what already existed.
