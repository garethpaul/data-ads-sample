# AWS Session Access Key Readiness Scan

## Status: Planned

## Context

The documentation-only readiness scanner rejects long-lived AWS access keys
with the `AKIA` prefix, but a temporary STS access key using the `ASIA` prefix
passes the same repository scan. Temporary credentials are still secret
material and can be committed in ordinary files or engineering plans.

## Objectives

- Reject AWS temporary session access-key identifiers with the same exact
  length and uppercase-alphanumeric boundary used for long-lived keys.
- Preserve filename-only diagnostics so matched credential values are never
  printed by the scanner or regression suite.
- Cover both ordinary tracked content and `docs/plans/*.md` content.
- Preserve all repository-shape, Ads credential, account-context, GitHub token,
  and ignored-local-data contracts.

## Scope

- Extend `scripts/check-baseline.sh` without adding dependencies or broad
  entropy heuristics.
- Add isolated regressions to `tests/check-baseline.sh`.
- Update the credential policy, maintained repository guidance, and changes.

## Verification

- `sh -n scripts/check-baseline.sh tests/check-baseline.sh`
- Repository-root and external-directory `make check`
- Isolated hostile mutations removing the temporary-key prefix, weakening the
  ordinary-file or plan-file fixture, exposing matched values, weakening
  guidance, and reverting completed plan status
- `git diff --check`
- Generated artifact and sensitive-value audits

This is a prefix-specific readiness boundary. It does not claim comprehensive
secret detection or replace provider-side secret scanning and revocation.
