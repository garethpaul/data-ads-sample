# Changes

## 2026-06-08

- Added a repository readiness baseline for the currently documentation-only Ads API + GNIP sample.
- Added `.gitignore` coverage for local credentials, private exports, generated logs, caches, and dependency directories.
- Added `scripts/check-baseline.sh` so maintainers can verify that future code additions update the README, plan, and credential-safety contract.
- Expanded the readiness guard for local environment loader files, private data
  directories, and Ads API/GNIP bearer-token patterns.
