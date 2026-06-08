---
title: Data Export Guard
type: chore
status: completed
date: 2026-06-08
---

# Data Export Guard

## Summary

Expand the documentation-only repository guard for likely Ads API and GNIP
risks by ignoring private data-export directories, local environment loader
files, and secret folders, then scanning for bearer-style API token material.

## Requirements

- R1. Local environment loader files and secret directories must be ignored.
- R2. Private, raw, cached, and exported data directories must be ignored until
  the repository defines safe publishable fixtures.
- R3. The baseline guard must reject tracked private-data paths.
- R4. The baseline guard must scan for common Ads API, GNIP, and bearer-token
  assignment patterns.
- R5. README, CHANGES, and the plan docs must document the expanded guard.

## Verification

- `scripts/check-baseline.sh`
- `git diff --check`
