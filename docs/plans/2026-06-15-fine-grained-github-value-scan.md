---
title: Fine-Grained GitHub Token Scan
status: completed
date: 2026-06-15
---

# Fine-Grained GitHub Token Scan

## Problem

The readiness scanner rejects classic GitHub token prefixes such as `ghp_`, but
does not recognize the modern fine-grained personal access token prefix
`github_pat_`. A live fine-grained token can therefore be tracked in ordinary
documentation or an engineering plan without triggering the generic secret
boundary.

## Priority

1. Detect the currently issued `github_pat_` token shape in every file already
   covered by the generic secret scan.
2. Prove ordinary tracked files and `docs/plans/` both reject the token without
   reproducing its value in diagnostics.
3. Preserve existing Ads/GNIP, account-context, tracked-shape, runtime-source,
   and documentation-only repository contracts.

## Requirements

- Extend the existing generic secret expression with a bounded
  `github_pat_`-prefixed token shape.
- Keep scanner output limited to filenames and the existing generic diagnostic
  category.
- Add isolated regression fixtures for an ordinary tracked file and a tracked
  engineering plan.
- Assemble synthetic token values at runtime so the repository test source does
  not itself contain a scanner match.
- Synchronize credential guidance and completed plan evidence.
- Add no dependencies, runtime manifests, source applications, or workflow
  changes.

## Implementation Units

### Generic scanner pattern

Files:

- `scripts/check-baseline.sh`

Add the fine-grained prefix to the existing filename-only generic secret scan.
Do not create a second scanner or expose matching content.

### Regression fixtures

Files:

- `tests/check-baseline.sh`

Use the existing isolated temporary Git repository helper to verify ordinary and
plan-file rejection plus value-redacted diagnostics.

### Contracts and guidance

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Require the scanner source pattern, both fixture calls, completed plan evidence,
and maintained credential guidance.

## Verification Plan

- Demonstrate the current scanner accepts an isolated synthetic
  `github_pat_` token before implementation.
- Run `sh -n` for both shell scripts, focused scanner regressions, repository-root
  `make check`, and the complete gate from `/tmp` through the absolute Makefile.
- Run hostile mutations removing the source pattern, ordinary-file fixture,
  plan-file fixture, redaction assertion, guidance, and completed status.
- Audit the exact diff, file modes, artifacts, dependencies/workflows, whitespace,
  conflict markers, and added credential-shaped values.
- Record exact local/upstream, pull-request, hosted-check, and security-alert
  evidence after pushing.

## Scope Boundaries

- Do not broaden into arbitrary high-entropy detection or claim comprehensive
  secret scanning.
- Do not print token values or matching lines.
- Do not change Ads/GNIP or account-ID expressions.
- Do not add runtime code, package manifests, dependencies, or permissions.

## Status: Completed

## Work Completed

- Extended the existing filename-only generic secret expression with the
  fine-grained GitHub token prefix and bounded value shape.
- Added isolated ordinary-file and engineering-plan fixtures assembled at
  runtime so the test source remains scanner-safe.
- Strengthened the shared regression helper contract so diagnostics that echo a
  matched value cannot silently return.
- Synchronized maintained credential guidance without adding dependencies,
  runtime code, manifests, or workflow changes.

## Verification Completed

- An isolated pre-fix tracked fixture proved the scanner accepted a synthetic
  fine-grained GitHub token before implementation.
- `sh -n` passed for both shell scripts, and the full readiness scanner
  regression suite passed after implementation.
- Six isolated hostile mutations were rejected for scanner-pattern removal,
  ordinary-fixture removal, plan-fixture removal, redaction weakening, and
  guidance weakening, plus completed-status rollback.
- Root/external gates, final audits, and hosted exact-head state are recorded by
  the shipping evidence for this branch.
