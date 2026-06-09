---
title: Fixture Provenance Template
type: privacy
status: completed
date: 2026-06-09
---

# Fixture Provenance Template

## Summary

Add a reusable provenance template so future Ads API and GNIP fixtures have a
consistent review record before sample data is committed.

## Requirements

- R1. Add a template that captures fixture path, intended flow, format, and
  approximate size.
- R2. Require source or generation method, license or permission, PII review,
  and size rationale details.
- R3. Point the fixture policy, README, SECURITY, VISION, and CHANGES to the
  template.
- R4. Extend the readiness guard so the template remains present and complete.
- R5. Do not add runnable Ads API/GNIP code, dependencies, or sample data in
  this pass.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
