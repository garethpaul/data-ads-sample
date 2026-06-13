---
title: Tracked Executable Mode Guard
type: security
status: planned
date: 2026-06-13
---

# Tracked Executable Mode Guard

## Status: Planned

## Problem Frame

The documentation-only readiness scanner rejects common runtime source
extensions, symlinks, and gitlinks, but an extensionless script or binary can
still be committed with Git mode `100755`. That creates an undeclared runtime
surface without a manifest, dependency boundary, tests, setup, or credential
policy transition.

## Scope Boundaries

- Inspect tracked Git index modes and reject executable regular files outside
  the two approved readiness scripts.
- Preserve executable mode for `scripts/check-baseline.sh` and
  `tests/check-baseline.sh`.
- Emit only rejected tracked paths, never blob IDs or file contents.
- Do not add a runtime, dependency manifest, Ads/GNIP implementation, or
  credential.

## Requirements

- R1. Any indexed `100755` path other than the two approved scanner scripts must
  fail before content scans.
- R2. The clean repository and approved scanner scripts must continue to pass.
- R3. Regression coverage must reject an extensionless executable fixture and
  prove its content and object ID are absent from diagnostics.
- R4. Static contracts and maintenance documentation must enforce the allowlist
  and completed verification evidence.

## Implementation

- Add a Git-index executable-mode allowlist to `scripts/check-baseline.sh`.
- Add an isolated executable fixture to `tests/check-baseline.sh`.
- Synchronize README, SECURITY, CHANGES, VISION, and this plan.

## Verification

- `tests/check-baseline.sh`
- `make check`
- Absolute-path `make check` from `/tmp`
- Shell syntax and `git diff --check`
- Isolated hostile mutations for mode matching, allowlist widening, content or
  object-ID disclosure, fixture omission, documentation drift, stale plan
  status, and missing verification evidence

## Risks

- Future legitimate tooling must update the allowlist and documentation in the
  same reviewed change rather than silently adding executable surface.
- Git mode checks cover tracked executability, not arbitrary binary content in
  non-executable files; the repository remains documentation-only and may need
  a separate binary-content boundary later.
