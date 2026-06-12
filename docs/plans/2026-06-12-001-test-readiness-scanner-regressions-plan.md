---
title: Readiness Scanner Regression Tests
type: test
date: 2026-06-12
---

# Readiness Scanner Regression Tests

## Summary

Add isolated mutation tests for the repository readiness scanner so its
credential and account-context protections are verified as behavior rather
than only asserted by source inspection.

## Problem Frame

`scripts/check-baseline.sh` contains the repository's main security behavior,
but `make test` currently reruns only the passing baseline. Regressions in a
detection pattern or error-message redaction can therefore pass every gate.

## Requirements

- R1. `make test` must run the scanner against an isolated copy of the tracked
  repository without modifying the developer's checkout.
- R2. Tests must prove generic secret, Ads/GNIP bearer-token, and populated
  account-context mutations are rejected.
- R3. Each rejection test must prove the affected filename is reported and
  the matched value is absent from scanner output.
- R4. The existing clean repository baseline and all root verification gates
  must continue to pass in local and hosted environments.
- R5. Project documentation must distinguish scanner regression tests from
  absent application runtime tests.

## Key Technical Decisions

- **Test disposable repository copies:** Each case initializes a temporary git
  repository from tracked and non-ignored candidate files because the scanner
  intentionally reasons about tracked files.
- **Exercise the public scanner entry point:** Tests invoke
  `scripts/check-baseline.sh` instead of duplicating its regular expressions.
- **Use POSIX shell and existing tools:** The harness keeps the repository free
  of a runtime manifest and relies only on shell, git, and ripgrep already used
  by the readiness baseline.
- **Assert redaction directly:** Failure output is checked for the fixture path
  and against the complete synthetic value, covering the security property
  that motivated the scanner's filename-only mode.

## Implementation Units

### U1. Add isolated scanner behavior tests

- **Goal:** Cover the clean baseline and three sensitive-value rejection paths.
- **Files:** `tests/check-baseline.sh`
- **Test scenarios:** Clean copy passes; synthetic generic token, bearer token,
  and account ID fail without echoing their values.
- **Verification:** `sh -n tests/check-baseline.sh` and
  `tests/check-baseline.sh`.

### U2. Wire regression tests into repository gates

- **Goal:** Make the behavior suite the implementation behind `make test` and
  preserve self-checking readiness contracts.
- **Files:** `Makefile`, `scripts/check-baseline.sh`
- **Verification:** `make lint`, `make test`, `make build`, and `make check`.

### U3. Document the tested security contract

- **Goal:** Explain that the repository has scanner tests but still has no Ads
  API or GNIP application runtime.
- **Files:** `README.md`, `CHANGES.md`
- **Verification:** `make check` and `git diff --check`.

## Acceptance Examples

- AE1. Given an unchanged temporary copy, when the test harness runs the
  readiness scanner, then the scanner exits successfully. Covers R1 and R4.
- AE2. Given a tracked file containing a synthetic secret-like value, when the
  scanner rejects it, then output includes the filename but not the value.
  Covers R2 and R3.
- AE3. Given a tracked file containing a populated Ads account ID, when the
  scanner rejects it, then output includes the filename but not the numeric ID.
  Covers R2 and R3.

## Scope Boundaries

- Do not add Ads API or GNIP runtime code, dependencies, or manifests.
- Do not broaden credential patterns beyond what the current scanner claims to
  detect.
- Do not test GitHub Actions syntax independently of the existing scanner
  contract.

## Risks And Mitigations

- Temporary-copy setup could expose ignored local data. Copy only files listed
  by git as tracked or non-ignored candidates before initializing each
  disposable repository.
- Failure assertions could pass for the wrong reason. Require both a nonzero
  exit and the expected scanner diagnostic for each mutation.
- Test fixtures resemble credentials. Keep them synthetic, create them only in
  temporary directories, and remove them through a shell trap.
