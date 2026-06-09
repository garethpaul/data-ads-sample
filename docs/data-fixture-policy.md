# Data Fixture Policy

This repository is public and does not currently include runnable Ads API or
GNIP code. Future fixture data must be safe before it is committed.

## Allowed Fixtures

- Synthetic examples that were created for this repository.
- Small excerpts from public documentation or public datasets when their license
  permits redistribution.
- Aggregated or mocked records that cannot identify real accounts, campaigns,
  users, audiences, or customers.
- Minimal files needed by local tests or examples, with provenance documented in
  the same pull request.

## Disallowed Data

- Raw Ads API or GNIP exports from real accounts.
- Account IDs, tokens, customer identifiers, campaign performance exports, user
  handles, direct-message data, or audience lists.
- Cached API responses unless they have been replaced with synthetic or clearly
  publishable equivalents.
- Large datasets that are not required for the smallest runnable sample.

## Review Checklist

- Confirm the fixture is synthetic or publishable.
- Confirm the README explains how the fixture is used.
- Update `scripts/check-baseline.sh` when a new safe fixture directory or file
  type is introduced.
- Keep private, raw, cached, and exported data in ignored local directories.
