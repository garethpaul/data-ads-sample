# Git-Index Readiness Hardening

## Status: Completed

## Context

The readiness scanner read mutable working-tree files while its path and mode
checks parsed line-oriented Git-index output. A staged credential could be
hidden by replacing the working-tree file with safe content after `git add`.
Newline-bearing paths, unmerged stages, and binary/NUL content also made the
prospective commit boundary ambiguous. Separately, the workflow contract only
counted `persist-credentials: false` text anywhere in the file instead of
requiring it under the pinned checkout step.

## Objective

Make the staged Git index the authoritative readiness boundary, fail closed on
ambiguous metadata or content scans, preserve filename-only diagnostics, and
scope checkout credential policy to the action step that owns it.

## Work Completed

- Parse `git ls-files -z --stage` records and escape unusual filenames before
  diagnostics.
- Scan staged blobs with `git grep --cached`, checked exit statuses, and
  filename-only NUL-delimited output.
- Reject unmerged stages and NUL-containing tracked content before credential
  matching.
- Add standalone token boundaries to reduce embedded-identifier false
  positives while preserving Unicode-delimited detection.
- Validate the sole pinned checkout step and its own `with` mapping.
- Add hostile tests for staged/working-tree divergence, binary content,
  unmerged stages, newline paths, Unicode boundaries, decoy workflow text, and
  Git metadata/content command failures.

## Verification Completed

- Observed the new staged-secret regression fail against the prior scanner.
- `sh -n scripts/check-baseline.sh` and `sh -n tests/check-baseline.sh` passed.
- The expanded focused regression suite passed.
- Repository-root and external-directory `make check` passed.
- Isolated hostile mutations of each new boundary were rejected.

## Limitations

This focused scanner does not claim comprehensive secret detection. It does
not decode archives, base64 or other transformed values, arbitrary non-NUL
encodings, split credentials, or custom provider prefixes, and it does not
validate whether a matching value is active. Provider-side secret scanning and
credential rotation remain necessary defenses.
