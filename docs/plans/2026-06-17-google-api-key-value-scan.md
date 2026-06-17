# Google API Key Value Scan

## Status: Completed

## Context

The documentation-only readiness scanner rejects several common credential
formats, but a tracked Google API key beginning with `AIza` currently passes.
That shape is relevant to future advertising API integrations and conflicts
with the repository policy that real credentials remain outside git.

## Objective

Extend the filename-redacted generic secret scan to reject Google API key
values in all tracked repository content, including engineering plans, without
printing the matched value.

## Scope

- Add the Google API key prefix and exact value shape to
  `scripts/check-baseline.sh`.
- Add ordinary-file and engineering-plan regressions to
  `tests/check-baseline.sh` using synthetic values assembled at runtime.
- Add source, fixture, documentation, and completed-plan contracts to the
  baseline checker.
- Update `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, and
  `docs/credential-handling-policy.md`.

## Constraints

- Diagnostics identify affected filenames only and never echo matched values.
- Existing GitHub, GitLab, AWS, Slack, private-key, Ads bearer-token, and
  account-context detection remains unchanged.
- The change does not add runtime source, dependencies, manifests, or a claim
  of comprehensive secret detection.
- The pull request remains stacked on PR #9 and retains base-first ordering.

## Validation

- Run `sh -n` for both shell scripts.
- Run the focused scanner regression suite and repository-root plus
  external-directory `make check`.
- Reject isolated mutations that remove the runtime pattern, either regression
  case, filename-only redaction, maintained guidance, or completed-plan
  evidence.
- Audit the exact diff, generated artifacts, file modes, conflict markers,
  sensitive additions, and upstream alignment.

## Runtime Boundary

No runnable Ads client exists in this repository. Verification covers the
tracked-content readiness boundary only and does not claim comprehensive
secret scanning or provider-side credential validation.

## Verification Results

- `sh -n scripts/check-baseline.sh` and `sh -n tests/check-baseline.sh` passed.
- The scanner regression suite passed with ordinary-file and engineering-plan
  Google API key fixtures while keeping diagnostics filename-only.
- Six isolated hostile mutations were rejected: the runtime pattern, each
  regression case, the redaction helper, maintained guidance, and completed
  plan status.
- Repository-root and external-directory `make check` passed the complete
  documentation-readiness baseline.
- Exact implementation head `187d98a28376b7f92986570b5136c7d38a8e7ac1`
  passed readiness on push run `27663133191` and pull-request run
  `27663136570`.
- This focused pattern extension does not claim comprehensive secret scanning.
