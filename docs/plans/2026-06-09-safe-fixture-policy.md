---
title: Safe Fixture Policy
type: privacy
status: completed
date: 2026-06-09
---

# Safe Fixture Policy

## Summary

Define what future Ads API and GNIP fixture data may be committed to this public
documentation-only repository.

## Requirements

- R1. The repository must document allowed fixture criteria.
- R2. The repository must document disallowed private Ads/GNIP data.
- R3. README must point future sample work to the fixture policy.
- R4. The readiness guard must require the policy and its key sections.
- R5. No runnable implementation or runtime manifest is added in this pass.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
