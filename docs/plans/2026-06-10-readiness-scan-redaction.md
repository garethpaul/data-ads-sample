---
title: Readiness Scan Redaction
type: security
status: completed
date: 2026-06-10
---

# Readiness Scan Redaction

## Summary

Keep the credential readiness guard from reproducing matched secrets in local
or hosted logs, and enforce the documented rule that Ads account and customer
identifiers remain empty in tracked content.

## Work Completed

- Changed generic and Ads-specific secret scans from matching-line output to
  filename-only findings.
- Added detection for populated account or customer ID assignments while
  keeping empty `.env.example` placeholders valid.
- Kept plans and the scanner source excluded so documented test patterns do not
  create false positives.
- Rooted all Make readiness targets to the repository for out-of-tree use.
- Updated README, credential policy, SECURITY, VISION, and CHANGES with the
  redacted output and account-context contract.
- Extended the executable baseline to require this completed plan and the
  rooted Make wrapper.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check`
- Synthetic mutation checks for a GitHub token, Ads bearer token, populated
  account ID, matching-line output, unrooted Make target, and incomplete plan
- Confirmed scanner failures contain the synthetic filename but not its value
- `sh -n scripts/check-baseline.sh`
- `git diff --check`

No real credential, account identifier, customer data, or Ads export was used.
