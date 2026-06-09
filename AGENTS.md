# AGENTS.md

## Repository purpose

`garethpaul/data-ads-sample` is a public sample, documentation, or utility project. Simple Data Ads Sample for Ads API + GNIP.

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets

## Development commands

- Install dependencies: no repository-specific install command is documented.
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: no dominant source language detected.

## Testing guidance

- No dedicated test files were detected; treat `make check` as the minimum baseline.
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- No required secret or credential file was identified in the repository scan.
- Future Ads API or GNIP credentials must stay in environment variables or local untracked configuration such as `.env`, which is ignored by this repository.
- Use `.env.example` only for empty placeholder names, and keep real values in ignored local files or external secret stores. See `docs/credential-handling-policy.md` before adding code that reads credentials.
- Ads account/customer identifiers are local context values; keep `ADS_ACCOUNT_ID` and `ADS_CUSTOMER_ID` empty in `.env.example` and populate them only in ignored local configuration.
- Keep private, raw, cached, and exported Ads/GNIP data under ignored local directories until the project defines safe publishable fixtures.
- Future fixture data must follow `docs/data-fixture-policy.md` before it is committed.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
