# Readiness Ripgrep Prerequisite

Status: Completed
Date: 2026-06-09

## Goal

Fail the readiness guard with a clear prerequisite message when `ripgrep` is not
installed, instead of letting the first source scan fail ambiguously.

## Changes

- Added an explicit `rg` availability check before secret and manifest scans.
- Documented the readiness tool prerequisite in the README, changelog, and
  vision.
- Extended the baseline guard with this completed plan.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
