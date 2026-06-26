## Data Ads Sample Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

Data Ads Sample is currently a documentation-only public repository reserved
for a simple Ads API plus GNIP sample.

The authoritative project context today is the GitHub description:
"Simple Data Ads Sample for Ads API + GNIP." No runnable implementation is
checked in yet.

The goal is to keep the repository ready for a focused, credential-safe API
sample rather than accumulate unverified scaffolding.

The current focus is:

Priority:

- Keep tracked executable modes limited to approved readiness scripts
- Establish basic project direction before adding code
- Keep root verification gates aligned with the documentation-only baseline
- Keep readiness tool prerequisites explicit before the source guard runs
- Keep the credential and fixture-safety baseline running in GitHub Actions
  without persisting the checkout credential
- Keep any future Ads API and GNIP credentials out of git
- Keep the credential placeholder contract explicit before code exists
- Keep account context placeholders empty until runnable code defines them
- Keep readiness failures redacted to affected filenames and reject populated
  account or customer ID assignments
- Scan the staged Git index, reject ambiguous or binary index states, and keep
  checkout credential policy attached to the checkout step
- Scan tracked engineering plans for credential and account values
- Scan ordinary tracked files and engineering plans for fine-grained GitHub token values
- Scan ordinary tracked files and engineering plans for temporary AWS session access keys
- Scan ordinary tracked files and engineering plans for GitLab personal access token values
- Scan ordinary tracked files and engineering plans for `AIza` Google API key values
- Keep orphan runtime source files out until the first implementation includes
  its complete runtime, verification, setup, and security contract
- Document setup, required accounts, and sample data as soon as code exists
- Prefer a small runnable example over a broad client wrapper

Next priorities:

- Keep README, setup notes, and verification commands aligned with the current repository state
- Define the sample language, runtime, and supported API flow
- Keep the existing `make check` readiness command as the minimal local
  verification gate until a runtime implementation adds its own tests
- Include fixture data that is safe to publish
- Require fixture provenance before future sample data is committed
- Use the fixture provenance template for future sample data reviews

Contribution rules:

- One PR = one focused setup, API flow, or documentation topic.
- Do not add generated credentials, tokens, or private customer data.
- Keep private raw exports and caches out of git unless they are replaced with
  explicit safe fixtures.
- Keep tracked symlinks out of the repository so credential and fixture checks
  remain bounded to reviewed files.
- Keep tracked Git submodules and gitlinks out of the documentation-only
  repository so external content cannot bypass readiness review.
- Require safe fixture provenance before committing sample Ads/GNIP data.
- Keep fixture provenance records with the fixture change by using
  `docs/fixture-provenance-template.md` or equivalent plan fields.
- Keep the first implementation small enough to review in one pass.
- Document external account requirements explicitly.

## Security And Privacy

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Advertising and social data APIs can expose tokens, account identifiers,
campaign data, and user-derived data. Future code must keep credentials in
environment variables or local config and use only publishable sample data.

## What We Will Not Merge (For Now)

- Committed API credentials, tokens, exports, or private datasets
- Broad SDK wrappers before a minimal sample exists
- Data ingestion code without setup and privacy notes
- Generated project scaffolding with no runnable example

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
