---
title: Fixture Provenance Checklist
type: privacy
status: completed
date: 2026-06-09
---

# Fixture Provenance Checklist

## Summary

Extend the safe fixture policy so future Ads API and GNIP sample data must
include provenance details before it can be committed.

## Requirements

- R1. Fixture policy must require a source or generation method.
- R2. Fixture policy must require license or permission notes.
- R3. Fixture policy must require a PII review before public commit.
- R4. Fixture policy must require a size rationale for any committed fixture.
- R5. README, SECURITY, CHANGES, and the readiness guard must mention the
  fixture provenance checklist.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
