# Data Ads CI Baseline

## Status: Completed

## Context

`data-ads-sample` is intentionally documentation-only until a safe, runnable
Ads API example is designed. Its existing `make check` gate protects credential
placeholders, ignored private-data paths, secret-shaped content, and fixture
provenance requirements, but those contracts were not enforced on GitHub.

## Objectives

- Run the readiness and data-safety baseline on every push and pull request.
- Preserve the no-runtime, no-package-manager repository shape.
- Pin third-party action code and keep workflow access read-only.
- Make the hosted workflow part of the checked repository contract.

## Work Completed

- Added `.github/workflows/check.yml` for pushes, pull requests, and manual
  dispatches.
- Pinned the runner to Ubuntu 24.04 and installed ripgrep explicitly before the
  readiness gate.
- Pinned `actions/checkout` to a reviewed commit, limited repository access to
  read-only, and bounded execution with timeout and concurrency cancellation.
- Extended `scripts/check-baseline.sh` to require the workflow and this plan.
- Updated README, VISION, SECURITY, and CHANGES with the hosted readiness gate.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- workflow YAML parse
- `git diff --check`

## Follow-Up

- When runnable code is added, extend CI only after the runtime, credential
  injection boundary, synthetic fixture strategy, and dependency lockfile are
  documented together.
