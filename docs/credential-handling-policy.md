# Credential Handling Policy

This repository is public and currently has no runnable Ads API or GNIP client.
Future implementations must keep all real credentials in local, ignored
configuration.

## Allowed Credential Sources

- Environment variables loaded by the developer's shell or local process
  manager.
- A local `.env` file copied from `.env.example`; `.env` remains ignored.
- CI or deployment secrets configured outside git.

Temporary AWS session access-key identifiers are secret material and must stay
in ignored local or external secret stores even when their lifetime is short.
GitLab personal access tokens are secret material and must stay in ignored
local or external secret stores.
Google API keys, including values beginning with `AIza`, are secret material
and must stay in ignored local or external secret stores.

## Tracked Placeholders

`.env.example` is tracked only to document names that future code may read:

- `ADS_API_KEY`
- `ADS_API_SECRET`
- `ADS_ACCESS_TOKEN`
- `ADS_ACCESS_TOKEN_SECRET`
- `ADS_ACCOUNT_ID`
- `ADS_CUSTOMER_ID`
- `GNIP_BEARER_TOKEN`

The placeholder file must keep values empty. Account and customer identifiers
are local context values, not publishable sample data. If the first runnable
sample needs different names, update `.env.example`, this policy, the README,
and `scripts/check-baseline.sh` in the same change.

## Logging And Redaction

Future code must not print authorization headers, credentials, bearer tokens,
cookies, account IDs, customer IDs, or raw private exports. Error output should
name the missing variable or setup step without echoing configured values.
Repository readiness scans follow the same rule: findings identify affected
files without printing the matched credential or account-context value.
The scanner evaluates staged Git-index content because that is the prospective
commit boundary. It rejects unmerged and NUL-containing entries rather than
silently relying on a mutable working-tree copy or text-decoding heuristic.

The scanner is a focused readiness backstop, not comprehensive secret
detection. It does not decode archives, base64 or other transformed values,
arbitrary non-NUL encodings, split credentials, or provider-specific custom
prefixes, and it does not validate whether a matching credential is active.
Use provider-side secret scanning and rotate any value that may have escaped.

## Verification Updates

When runnable code is added, extend `scripts/check-baseline.sh` with checks for
the real install command, local verification command, fixture policy, and
credential documentation.
