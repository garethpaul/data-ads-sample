# Account Context Placeholders

Status: Completed
Date: 2026-06-09

## Goal

Document future Ads account and customer context inputs without committing real
account or customer identifiers to the public repository.

## Changes

- Added empty `ADS_ACCOUNT_ID` and `ADS_CUSTOMER_ID` entries to `.env.example`.
- Updated the credential handling policy to treat account and customer IDs as
  local context values, not publishable sample values.
- Documented the account context placeholder contract in the README, changelog,
  and vision.
- Extended the readiness baseline to require the placeholders and completed
  plan.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
