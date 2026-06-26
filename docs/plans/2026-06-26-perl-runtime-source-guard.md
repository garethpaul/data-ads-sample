# Perl Runtime Source Guard

status: completed

## Problem

The documentation-only readiness scanner rejected many common runtime source
extensions but allowed tracked Perl scripts and modules. A contributor could
therefore stage `.pl` or `.pm` implementation files without adding the runtime,
locked dependencies, tests, setup, and credential boundary required for the
first real Ads/GNIP sample.

## Decision

Add `.pl` and `.pm` to the existing exact staged-index runtime extension
classifier. Preserve the two readiness shell allowlist paths, filename-only
diagnostics, trailing-whitespace handling, and all content scans.

## Verification

- Both Perl fixtures failed first because the scanner accepted `client.pl`.
- The scanner now rejects Perl scripts and modules without exposing source
  content or blob IDs.
- Repository and external-directory `make check` passed, including the isolated
  readiness scanner regression suite and documentation-only build contract.
- Two isolated hostile mutations removing `.pl` or `.pm` classification were
  rejected, and shell syntax plus `git diff --check` passed.
- Hosted verification and exact-head review remain required before merge.
