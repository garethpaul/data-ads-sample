---
title: Plan Credential Scan
status: in_progress
date: 2026-06-15
---

# Plan Credential Scan

## Problem

The readiness scanner excludes every file under `docs/plans/**` from generic
secret, Ads API token, and populated account-context scans. Current plans do not
require that exemption, so an accidentally pasted credential or account ID in a
tracked engineering plan can bypass the repository gate.

## Requirements

1. Scan tracked plan documents with the existing generic secret, Ads token, and
   account-context patterns.
2. Preserve the intentional exclusion for the scanner implementation itself,
   where the detection patterns are defined.
3. Extend the regression harness to place sensitive fixtures at explicit paths.
4. Prove each sensitive-value class is rejected from `docs/plans` without printing
   the matched value.
5. Keep the repository documentation-only and avoid adding runtime manifests or
   source files.

## Implementation

- Remove the three `docs/plans/**` glob exclusions from
  `scripts/check-baseline.sh`.
- Add an explicit fixture-path argument to `assert_rejected_without_value` and
  cover generic secrets, bearer tokens, and Ads account IDs in plan files.
- Add static contracts and synchronized credential-boundary guidance.

## Verification Plan

- `sh -n scripts/check-baseline.sh tests/check-baseline.sh`
- `make check`
- `make -C /tmp -f <worktree>/Makefile check`
- Isolated hostile mutations for each restored exclusion, missing plan fixtures,
  documentation drift, and stale plan evidence
- Exact diff, generated-artifact, whitespace, conflict-marker, and credential scans

## Status: In Progress

Implementation and verification evidence will be recorded after the gates complete.
