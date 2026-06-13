---
title: Tracked Executable Mode Guard
type: security
status: completed
date: 2026-06-13
---

# Tracked Executable Mode Guard

## Status: Completed

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

## Work Completed

- Added a Git-index mode guard that allows executable mode only for the source
  and regression readiness scanners.
- Added an isolated extensionless executable fixture with path-only diagnostic,
  content-redaction, and object-ID-redaction assertions.
- Synchronized repository documentation and completed-plan contracts.

## Verification Completed

- `tests/check-baseline.sh`, `make check`, and the absolute-path Make invocation
  from `/tmp` passed.
- `sh -n` passed for both changed shell scripts, and `git diff --check` passed.
- Eight isolated hostile mutations were rejected across mode matching,
  allowlist widening, diagnostic redaction, fixture presence, documentation,
  plan status, and verification evidence.
- No runtime manifest, implementation, dependency, credential, private data,
  submodule, symlink, or generated artifact was added.
