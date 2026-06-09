---
title: Readiness Make Wrapper
type: chore
status: completed
date: 2026-06-08
---

# Readiness Make Wrapper

## Summary

Expose the documentation-only repository readiness guard through the conventional
`make check` entry point while preserving the underlying shell script.

## Requirements

- R1. `make check` runs `scripts/check-baseline.sh`.
- R2. The baseline requires the Makefile wrapper.
- R3. README documents both the wrapper and the direct guard command.
- R4. CHANGES records the verification wrapper.
- R5. No runtime manifest is added before a real Ads API/GNIP sample exists.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
