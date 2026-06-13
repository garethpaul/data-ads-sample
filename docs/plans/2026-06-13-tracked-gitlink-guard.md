---
title: Tracked Gitlink Guard
type: security
status: completed
date: 2026-06-13
---

# Tracked Gitlink Guard

## Summary

Reject tracked Git submodules and raw gitlinks in this documentation-only
repository so readiness scans cannot silently omit externally supplied content.

## Requirements

- R1. Reject every index entry with Git mode `160000` before content scans.
- R2. Report only the tracked path, without printing the object ID or reading
  external repository content.
- R3. Add an isolated, network-free regression that creates a gitlink index
  entry and proves rejection and diagnostic redaction.
- R4. Preserve the existing symlink, credential, account-context, manifest,
  and no-runtime boundaries.
- R5. Document the repository-tree rule in README, SECURITY, VISION, and
  CHANGES.
- R6. Add no runtime manifest, Ads API implementation, submodule, or project
  dependency.

## Verification

Completed on 2026-06-13:

- `make check` passed the readiness scanner, isolated regression harness, and
  documentation-only build contract.
- `make -f /absolute/path/to/Makefile check` passed from `/tmp`.
- Ten hostile mutations were rejected across index-mode behavior, diagnostics,
  harness invocation, object-ID redaction, documentation, required-plan
  presence, and completed-plan evidence.
- `sh -n scripts/check-baseline.sh`, `sh -n tests/check-baseline.sh`,
  `git diff --check`, focused diff review, and a changed-line secret-pattern
  scan passed.
- No runtime manifest, Ads API/GNIP implementation, submodule, credential, or
  project dependency was added.

## Non-Goals

- Following or inspecting submodule content.
- Allowlisting selected gitlinks.
- Adding runnable Ads API or GNIP code.
