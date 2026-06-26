# Changes

## 2026-06-26

- Rejected orphan Perl runtime files (`.pl` and `.pm`) while the repository
  remains documentation-only, with filename-redacted script and module
  regressions and a durable documentation contract.
- Repository and external-directory `make check`, shell syntax, diff checks,
  and two isolated extension-removal mutations passed.
- Exact-head readiness runs `28250272153` and `28250274757` passed in 39 and
  41 seconds; CodeQL run `28250273410` passed Actions analysis.
- Codex review was blocked by repeated OpenAI API HTTP 401 failures; immutable
  exact-head manual review found no actionable findings.

## 2026-06-25

- Closed the stale roadmap item for adding local verification: `make check`
  already runs lint/readiness scanning, the isolated hostile regression suite,
  and the documentation-only build contract from any working directory.
- Revalidated exact shell runtime-path classification, including invalid UTF-8
  and trailing ASCII whitespace cases, with the full readiness suite and an
  independent Codex review.

## 2026-06-19

- Moved readiness content and path checks to the staged Git index, with
  fail-closed metadata/content errors and escaped unusual filenames.
- Rejected unmerged and NUL-containing index entries, prevented working-tree
  edits from hiding staged credentials, and reduced embedded-key false
  positives with explicit token boundaries.
- Scoped the credential-free checkout contract to the pinned checkout step and
  added hostile regressions for index divergence, binary content, malformed
  index state, Unicode boundaries, newline paths, and Git command failures.

## 2026-06-17

- Extended filename-redacted generic secret scanning to `AIza` Google API key values.

## 2026-06-16

- Extended filename-redacted generic secret scanning to GitLab personal access token values.
- Extended filename-redacted generic secret scanning to temporary AWS session access keys.

## 2026-06-15

- Extended credential and account-value scans to tracked engineering plans and
  added filename-redacted plan fixture regressions.
- Extended filename-redacted generic secret scanning to fine-grained GitHub token values.

## 2026-06-13

- Rejected unapproved tracked executable files while preserving the two
  readiness scanner entry points.
- Rejected tracked runtime source files while the repository remains
  documentation-only, with filename-redacted Python and JavaScript regressions.
- Rejected tracked Git submodules and raw gitlinks before readiness content
  scans, with a network-free redaction regression for indexed object IDs.

## 2026-06-12

- Stopped the hosted readiness checkout from persisting its credential and
  added an exact contract for the sole workflow and checkout step.
- Added isolated mutation tests for generic secret, Ads/GNIP bearer-token, and
  populated account-context scanner findings.
- Asserted that scanner failures report affected filenames without reproducing
  the complete matched value, and wired the suite into `make test`.
- Rejected tracked symbolic links before content scans and added an isolated
  regression proving diagnostics expose only the link path, not its target.

## 2026-06-10

- Redacted credential scanner failures to filenames and added populated Ads
  account/customer identifier detection without echoing matched values.
- Rooted Make readiness targets to the repository and refreshed the checkout
  action annotation.
- Added a pinned, read-only GitHub Actions workflow that runs the existing
  `make check` credential, fixture, and repository readiness baseline.
- Made the workflow and completed CI plan part of the checked repository
  contract without introducing a runtime or package manager.
- Pinned the hosted runner to Ubuntu 24.04 and installed ripgrep explicitly so
  credential and manifest scans cannot be skipped by runner image changes.

## 2026-06-09

- Added empty Ads account context placeholders and documented that real account
  or customer IDs stay in ignored local configuration.
- Added an explicit ripgrep readiness prerequisite before source guard scans.
- Added a credential placeholder policy and empty `.env.example` for future Ads
  API/GNIP runtime work.
- Added root `make lint`, `make test`, `make build`, and `make check` gates
  around the documentation-only readiness baseline.
- Added a reusable fixture provenance template for future Ads API/GNIP sample
  data reviews.
- Added a fixture provenance checklist requirement for future Ads API/GNIP
  sample data.
- Added a safe fixture policy for future Ads API/GNIP sample data and wired it
  into the readiness guard.

## 2026-06-08

- Added `make check` as the conventional wrapper for the readiness baseline.
- Added a repository readiness baseline for the currently documentation-only Ads API + GNIP sample.
- Added `.gitignore` coverage for local credentials, private exports, generated logs, caches, and dependency directories.
- Added `scripts/check-baseline.sh` so maintainers can verify that future code additions update the README, plan, and credential-safety contract.
- Expanded the readiness guard for local environment loader files, private data
  directories, and Ads API/GNIP bearer-token patterns.
