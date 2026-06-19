---
title: Tracked Runtime Source Guard
type: fix
date: 2026-06-13
status: completed
---

# Tracked Runtime Source Guard

## Summary

Reject tracked application source files while the Ads/GNIP sample remains a
documentation-only readiness repository without a runtime manifest or
executable sample contract.

## Problem Frame

The readiness scanner rejects runtime manifests, but a contributor can still
commit orphan `.py`, `.js`, `.ts`, Java, Go, Ruby, or similar source files while
the README continues to state that no implementation exists. Such files have no
declared runtime, dependency lock, lint/test gate, setup instructions, or
credential boundary and can bypass the transition requirements intended for
the first real sample.

## Requirements

- R1. The scanner must inspect tracked index paths and reject common application
  source extensions while the repository is documentation-only.
- R2. Existing repository shell verification infrastructure must remain allowed.
- R3. Diagnostics must list only rejected paths and must not print source
  contents, blob IDs, or credential-like values.
- R4. The regression harness must prove representative Python and JavaScript
  files are rejected with filename-only diagnostics.
- R5. Existing clean, secret, account-context, symlink, gitlink, and manifest
  scanner behavior must remain unchanged.
- R6. README, security, vision, changes, tests, and the static baseline must
  enforce the no-orphan-source transition contract and completed plan through
  `make check`.

## Key Technical Decisions

- **Inspect the Git index:** Use `git ls-files` so the guard describes content
  proposed for the repository, not ignored local credentials or caches.
- **Match application source extensions:** Cover common JavaScript/TypeScript,
  Python, Ruby, PHP, Java/Kotlin, Swift, Go, Rust, and C# source paths while
  leaving the existing shell readiness scripts intact.
- **Fail before content scans:** Reject source paths immediately after symlink
  and gitlink shape checks, before secret and account-content inspection.
- **Keep the transition explicit:** The first implementation must deliberately
  update the README, plan, manifest/toolchain, tests, and this guard together.

## Implementation Units

### U1. Reject Tracked Runtime Source Paths

- **Files:** `scripts/check-baseline.sh`
- **Goal:** Detect indexed application source extensions and emit path-only
  diagnostics before repository content scans.
- **Covers:** R1, R2, R3, R5

### U2. Add Redaction Regression Coverage

- **Files:** `tests/check-baseline.sh`
- **Goal:** Add isolated tracked Python and JavaScript fixtures and prove both
  rejection and absence of fixture content in scanner output.
- **Covers:** R3, R4, R5

### U3. Record The Documentation-Only Boundary

- **Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`
- **Goal:** Explain that orphan source files are rejected until a complete,
  reviewable runtime transition is introduced.
- **Covers:** R6

## Verification

- Run `tests/check-baseline.sh`, `make check`, and the absolute-path
  `make check` wrapper from `/tmp`.
- Run shell syntax, whitespace, exact-path, and secret scans.
- Apply isolated hostile mutations for removed extension matching, shell-script
  overreach, content disclosure, omitted Python/JavaScript fixtures, scanner
  invocation drift, documentation drift, and incomplete plan status; each
  mutation must fail.
- Confirm no runtime manifest, dependency, API implementation, submodule,
  credential, or private data is added by this change.

## Verification Results

- `tests/check-baseline.sh`, repository `make check`, and the absolute-path
  `make check` wrapper from `/tmp` passed the clean repository plus generic
  secret, bearer-token, account-context, symlink, gitlink, Python, and
  JavaScript rejection cases.
- Python and JavaScript runtime-source diagnostics contained only tracked paths
  and did not reproduce fixture contents.
- Plan-aware review found no actionable findings; the check remains scoped to
  tracked application source extensions and leaves shell verification
  infrastructure allowed.
- Shell syntax, whitespace, exact-path, and explicit secret scans passed.
- Eight isolated hostile mutations covering extension matching, shell-script
  overreach, content disclosure, both runtime fixtures, invocation contracts,
  documentation drift, and completed-plan status were rejected.
- No runtime manifest, dependency, Ads API/GNIP implementation, submodule,
  credential, private fixture, or generated artifact was added.

## Prioritized Follow-Ups

1. Choose the sample language and runtime before adding implementation files.
2. Introduce the smallest runnable Ads/GNIP flow with locked dependencies,
   credential-safe configuration, fixture provenance, and executable tests.

## Risks

- Extension matching is intentionally conservative and may require an explicit
  guard update when the real sample is introduced; that friction prevents an
  incomplete runtime transition from landing silently.
- Source embedded as documentation examples remains allowed because the guard
  inspects tracked file paths rather than prose content.
