---
title: Repository Readiness Baseline
type: fix
status: completed
date: 2026-06-08
---

# Repository Readiness Baseline

## Summary

Prepare the documentation-only Ads API + GNIP sample repository for future implementation by
adding credential-safe ignore rules, a repeatable source guard, and maintenance
notes that make the current no-runtime state explicit.

## Problem Frame

The repository is currently reserved for a simple Data Ads sample but has no
source files, dependency manifests, runnable sample, or automated verification.
Because the future project will likely involve advertising API credentials and
data exports, the safest useful baseline is to prevent accidental commits of
local secrets or private data and require future code additions to update the
verification contract.

## Requirements

- R1. Local credentials, private exports, generated logs, and common caches must
  be ignored.
- R2. No credential-like or private data files should be tracked in the current
  documentation-only baseline.
- R3. Adding a runtime manifest must fail the baseline until the README, plan,
  and guard are updated for the real sample.
- R4. README, changelog, and plan docs must document how to verify the current
  repository state.

## Implementation Units

### U1. Credential-Safe Ignore Rules

- **Goal:** Make future local setup less likely to leak secrets or private data.
- **Files:** `.gitignore`
- **Verification:** `scripts/check-baseline.sh`

### U2. Readiness Guard

- **Goal:** Provide a lightweight command that validates the no-runtime baseline.
- **Files:** `scripts/check-baseline.sh`
- **Verification:** `scripts/check-baseline.sh`, `git diff --check`

### U3. Maintenance Documentation

- **Goal:** Document the repository state and future update obligation.
- **Files:** `README.md`, `CHANGES.md`, this plan
- **Verification:** `scripts/check-baseline.sh`

## Risks & Dependencies

- This pass intentionally does not create a sample implementation.
- Future code should replace the no-runtime manifest check with real build,
  lint, test, and fixture-data checks.
- Runtime documentation must explain required Ads API/GNIP accounts and keep all
  credentials in environment variables or untracked local configuration.
