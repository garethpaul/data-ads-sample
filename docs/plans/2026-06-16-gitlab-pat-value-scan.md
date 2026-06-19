# GitLab Personal Access Token Scan

## Status: Completed

## Context

The documentation-only readiness scanner rejects several common credential
formats, including GitHub and AWS access tokens, but it does not recognize
GitLab personal access tokens beginning with `glpat-`. A tracked token in an
ordinary file or engineering plan therefore passes the current baseline even
though the repository policy forbids committed credentials.

## Objective

Extend the filename-redacted generic secret scan to reject GitLab personal
access token values in all tracked repository content, including
`docs/plans`, without printing the matched token.

## Scope

- Add the GitLab PAT prefix and minimum value shape to the generic secret
  expression in `scripts/check-baseline.sh`.
- Add ordinary-file and engineering-plan regression cases to
  `tests/check-baseline.sh`.
- Add self-protecting source, fixture, documentation, and completed-plan
  contracts to the baseline checker.
- Update `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, and
  `docs/credential-handling-policy.md`.

## Constraints

- Diagnostics identify affected filenames only and never echo matched values.
- Existing GitHub, AWS, Slack, private-key, Ads bearer-token, and account
  context detection remains unchanged.
- The change does not add runtime source, dependencies, manifests, or a claim
  of comprehensive secret detection.
- The pull request remains stacked on PR #8 and retains base-first ordering.

## Verification

- Run `sh -n` for both shell scripts.
- Run the focused scanner regression suite and repository-root plus
  external-directory `make check`.
- Reject hostile mutations that remove the pattern, either regression case,
  filename-only redaction, maintained guidance, or completed-plan evidence.
- Audit the exact diff, generated artifacts, file modes, conflict markers,
  sensitive additions, and upstream alignment.

## Runtime Boundary

No runnable Ads client exists in this repository. Verification covers the
tracked-content readiness boundary only and does not claim comprehensive
secret scanning or provider-side token validation.

## Verification Results

- `sh -n scripts/check-baseline.sh` and `sh -n tests/check-baseline.sh` passed.
- The scanner regression suite passed with ordinary-file and engineering-plan
  GitLab PAT fixtures while keeping diagnostics filename-only.
- Six isolated hostile mutations were rejected: the runtime pattern, each
  regression case, the redaction helper, maintained guidance, and completed
  plan status.
- Repository-root and external-directory `make check` passed the complete
  documentation-readiness baseline.
- This focused pattern extension does not claim comprehensive secret scanning.
