---
title: Tracked Symlink Guard
type: security
status: completed
date: 2026-06-12
---

# Tracked Symlink Guard

## Summary

Reject tracked symbolic links in the documentation-only repository so readiness
scans cannot be redirected outside the checked-out tree. Add an isolated
regression test that preserves the scanner's filename-only diagnostic policy.

## Problem Frame

The credential scanner uses ripgrep without following symbolic links. A tracked
link with an ordinary filename could therefore resolve to machine-local content
outside the repository while remaining outside the scanner's content boundary.
This repository does not need symlinks, so rejecting them is simpler and safer
than following unknown targets.

## Requirements

- R1. The readiness scanner must reject every tracked symbolic link before
  credential content scans run.
- R2. The rejection must report the tracked link path without printing or
  resolving its target.
- R3. The regression harness must create a tracked symlink in an isolated
  repository and prove the scanner rejects it.
- R4. The regression must prove the diagnostic does not expose the symlink
  target.
- R5. README, SECURITY, VISION, and CHANGES must record the repository-boundary
  rule.
- R6. No runtime manifest, Ads API implementation, or new dependency may be
  added.

## Non-Goals

- Following symlinks during credential scans.
- Evaluating whether individual symlink targets are safe.
- Changing existing secret, bearer-token, or account-context patterns.
- Adding application runtime tests.

## Work Completed

- Added an index-mode check that rejects all tracked symbolic links without
  resolving their targets.
- Added an isolated scanner regression that verifies the link path is reported
  and the target remains absent from output.
- Extended the readiness baseline and project documentation with the bounded
  repository-tree contract.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check`
- `sh -n scripts/check-baseline.sh`
- `sh -n tests/check-baseline.sh`
- Mutation check: removing the tracked-symlink guard must fail the regression
  suite.
- Mutation check: exposing the symlink target must fail the regression suite.
- `git diff --check`
