---
title: Readiness Make Gates
type: tooling
status: completed
date: 2026-06-09
---

# Readiness Make Gates

## Summary

Expose standard root verification targets while the repository remains a
documentation-only Ads API/GNIP sample placeholder.

## Requirements

- R1. Add `make lint`, `make test`, `make build`, `make verify`, and keep
  `make check`.
- R2. Keep every gate tied to `scripts/check-baseline.sh` until runnable code
  and a real build/test toolchain exist.
- R3. Make test/build output explicitly state that no runtime tests or build
  artifacts are configured yet.
- R4. Document the gate behavior in README, CHANGES, VISION, and this plan.
- R5. Do not add runtime manifests, dependencies, credentials, or sample data in
  this pass.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
