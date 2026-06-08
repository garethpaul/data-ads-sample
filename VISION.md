## Data Ads Sample Vision

Data Ads Sample is currently a documentation-only public repository reserved
for a simple Ads API plus GNIP sample.

The authoritative project context today is the GitHub description:
"Simple Data Ads Sample for Ads API + GNIP." No runnable implementation is
checked in yet.

The goal is to keep the repository ready for a focused, credential-safe API
sample rather than accumulate unverified scaffolding.

The current focus is:

Priority:

- Establish basic project direction before adding code
- Keep any future Ads API and GNIP credentials out of git
- Document setup, required accounts, and sample data as soon as code exists
- Prefer a small runnable example over a broad client wrapper

Next priorities:

- Keep README, setup notes, and verification commands aligned with the current repository state
- Define the sample language, runtime, and supported API flow
- Add a minimal local verification command
- Include fixture data that is safe to publish

Contribution rules:

- One PR = one focused setup, API flow, or documentation topic.
- Do not add generated credentials, tokens, or private customer data.
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
