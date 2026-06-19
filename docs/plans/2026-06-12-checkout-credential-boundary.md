# Checkout Credential Boundary

## Status: Completed

## Context

The hosted readiness job only needs repository contents. Its checkout token
does not need to remain in Git configuration while the documentation and data
safety checks run.

## Objectives

- Disable checkout credential persistence without changing readiness coverage.
- Preserve the immutable action pin, read-only permissions, and Ubuntu 24.04
  baseline.
- Reject duplicate workflows, checkout steps, or boundary declarations.

## Work Completed

- Added `persist-credentials: false` to the pinned checkout step.
- Extended the shell baseline to require exactly one workflow, one pinned
  checkout, and one credential-free checkout declaration.
- Updated the readiness and security documentation.

## Verification

- `make lint`
- `make test`
- `make build`
- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
- Hostile workflow and plan mutations were rejected.

## Remaining Risk

The repository intentionally remains documentation-only; this change does not
add or exercise Ads API or GNIP runtime behavior.
