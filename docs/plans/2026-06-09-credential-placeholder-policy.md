# Credential Placeholder Policy

Status: Completed
Date: 2026-06-09

## Goal

Document safe local credential handling before any Ads API or GNIP runtime code
is added.

## Changes

- Added an empty `.env.example` with the expected Ads API and GNIP placeholder
  names.
- Added `docs/credential-handling-policy.md` for allowed credential sources,
  tracked placeholder rules, redacted logging expectations, and future guard
  updates.
- Extended the readiness baseline to require the placeholder file, credential
  policy, and documentation links.
- Updated README, SECURITY, VISION, and CHANGES with the credential policy
  contract.

## Verification

- `sh -n scripts/check-baseline.sh`
- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
