#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"
VISION="$ROOT_DIR/VISION.md"
SECURITY="$ROOT_DIR/SECURITY.md"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-repository-readiness-baseline.md"
DATA_GUARD_PLAN="$ROOT_DIR/docs/plans/2026-06-08-data-export-guard.md"
MAKE_GATE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-readiness-make-gates.md"
FIXTURE_POLICY="$ROOT_DIR/docs/data-fixture-policy.md"
FIXTURE_TEMPLATE="$ROOT_DIR/docs/fixture-provenance-template.md"
CREDENTIAL_POLICY="$ROOT_DIR/docs/credential-handling-policy.md"
CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-credential-placeholder-policy.md"
ACCOUNT_CONTEXT_PLAN="$ROOT_DIR/docs/plans/2026-06-09-account-context-placeholders.md"
ENV_EXAMPLE="$ROOT_DIR/.env.example"
CHANGES="$ROOT_DIR/CHANGES.md"
CI_WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CI_PLAN="$ROOT_DIR/docs/plans/2026-06-10-ci-baseline.md"
SCANNER_REDACTION_PLAN="$ROOT_DIR/docs/plans/2026-06-10-readiness-scan-redaction.md"
SCANNER_TEST_PLAN="$ROOT_DIR/docs/plans/2026-06-12-001-test-readiness-scanner-regressions-plan.md"
SYMLINK_GUARD_PLAN="$ROOT_DIR/docs/plans/2026-06-12-tracked-symlink-guard.md"
CHECKOUT_CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-12-checkout-credential-boundary.md"
GITLINK_GUARD_PLAN="$ROOT_DIR/docs/plans/2026-06-13-tracked-gitlink-guard.md"
RUNTIME_SOURCE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-tracked-runtime-source-guard.md"
EXECUTABLE_MODE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-tracked-executable-mode-guard.md"
MAKE_ROOT_PROTECTION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-make-root-override-protection.md"
PLAN_CREDENTIAL_SCAN_PLAN="$ROOT_DIR/docs/plans/2026-06-15-plan-sensitive-value-scan.md"
MAKEFILE="$ROOT_DIR/Makefile"
SCANNER_TEST="$ROOT_DIR/tests/check-baseline.sh"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  ".gitignore" \
  ".env.example" \
  ".github/workflows/check.yml" \
  "CHANGES.md" \
  "Makefile" \
  "README.md" \
  "SECURITY.md" \
  "VISION.md" \
  "docs/credential-handling-policy.md" \
  "docs/readme-overview.svg" \
  "docs/data-fixture-policy.md" \
  "docs/fixture-provenance-template.md" \
  "docs/plans/2026-06-08-repository-readiness-baseline.md" \
  "docs/plans/2026-06-08-data-export-guard.md" \
  "docs/plans/2026-06-09-credential-placeholder-policy.md" \
  "docs/plans/2026-06-09-safe-fixture-policy.md" \
  "docs/plans/2026-06-09-fixture-provenance-checklist.md" \
  "docs/plans/2026-06-09-fixture-provenance-template.md" \
  "docs/plans/2026-06-09-readiness-make-gates.md" \
  "docs/plans/2026-06-09-account-context-placeholders.md" \
  "docs/plans/2026-06-10-ci-baseline.md" \
  "docs/plans/2026-06-10-readiness-scan-redaction.md" \
  "docs/plans/2026-06-12-001-test-readiness-scanner-regressions-plan.md" \
  "docs/plans/2026-06-12-tracked-symlink-guard.md" \
  "docs/plans/2026-06-12-checkout-credential-boundary.md" \
  "docs/plans/2026-06-13-tracked-gitlink-guard.md" \
  "docs/plans/2026-06-13-tracked-runtime-source-guard.md" \
  "docs/plans/2026-06-13-tracked-executable-mode-guard.md" \
  "docs/plans/2026-06-14-make-root-override-protection.md" \
  "docs/plans/2026-06-15-plan-sensitive-value-scan.md" \
  "scripts/check-baseline.sh" \
  "tests/check-baseline.sh"; do
  require_file "$path"
done

workflow_count=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) | wc -l | tr -d ' ')
checkout_count=$(grep -Ec '^[[:space:]]*uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10' "$CI_WORKFLOW" || true)
credential_boundary_count=$(grep -Ec '^[[:space:]]*persist-credentials:[[:space:]]*false([[:space:]]|$)' "$CI_WORKFLOW" || true)
if [ "$workflow_count" -ne 1 ] || [ "$checkout_count" -ne 1 ] || [ "$credential_boundary_count" -ne 1 ]; then
  printf '%s\n' "GitHub Actions must keep one workflow with one pinned, credential-free checkout." >&2
  exit 1
fi

for workflow_contract in \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  "permissions:" \
  "contents: read" \
  "workflow_dispatch:" \
  "runs-on: ubuntu-24.04" \
  "timeout-minutes: 5" \
  "sudo apt-get install --yes --no-install-recommends ripgrep" \
  "run: make check"; do
  if ! grep -Fq "$workflow_contract" "$CI_WORKFLOW"; then
    printf '%s\n' "GitHub Actions workflow must keep contract: $workflow_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "Status: Completed" "$CI_PLAN" || ! grep -Fq "make check" "$CI_PLAN"; then
  printf '%s\n' "CI baseline plan must record completed make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$CHECKOUT_CREDENTIAL_PLAN" ||
  ! grep -Fq "make check" "$CHECKOUT_CREDENTIAL_PLAN"; then
  printf '%s\n' "Checkout credential boundary plan must record completed make check verification." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$README" ||
  ! grep -Fq "GitHub Actions" "$VISION" ||
  ! grep -Fq "GitHub Actions" "$SECURITY" ||
  ! grep -Fq "GitHub Actions" "$CHANGES"; then
  printf '%s\n' "Project docs must preserve the hosted readiness baseline." >&2
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  printf '%s\n' "ripgrep (rg) must be installed for readiness secret and manifest scans." >&2
  exit 1
fi

if [ "$(grep -Ec '^[a-z_]+_files=\$\(rg -l --hidden' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 3 ] ||
  grep -Eq '^[a-z_]+_files=\$\(rg -n --hidden' "$ROOT_DIR/scripts/check-baseline.sh"; then
  printf '%s\n' "Readiness content scans must report filenames instead of matched values." >&2
  exit 1
fi

for ignored in ".env" ".env.*" ".envrc" "!.env.example" "*.local" "*.pem" "*.key" "secrets/" "data/private/" "data/raw/" "data/cache/" "data/exports/" "*.sqlite" "*.db"; do
  if ! grep -Fq "$ignored" "$ROOT_DIR/.gitignore"; then
    printf '%s\n' ".gitignore must include $ignored" >&2
    exit 1
  fi
done

tracked_sensitive=$(git -C "$ROOT_DIR" ls-files |
  grep -Ev '(^|/)\.env\.example$|^docs/credential-handling-policy\.md$|^docs/plans/2026-06-09-credential-placeholder-policy\.md$|^docs/plans/2026-06-12-checkout-credential-boundary\.md$' |
  grep -Ei '(^|/)(\.env(\.|$)|.*\.(pem|key)|.*(secret|credential|token).*|secrets/|data/(private|raw|cache|exports)/|.*\.(sqlite|db)$)' || true)
if [ -n "$tracked_sensitive" ]; then
  printf '%s\n%s\n' "Potential credential or private-data files are tracked:" "$tracked_sensitive" >&2
  exit 1
fi

tracked_symlinks=$(git -C "$ROOT_DIR" ls-files -s |
  awk '$1 == "120000" { print substr($0, index($0, "\t") + 1) }')
if [ -n "$tracked_symlinks" ]; then
  printf '%s\n%s\n' "Tracked symbolic links are not allowed:" "$tracked_symlinks" >&2
  exit 1
fi

tracked_gitlinks=$(git -C "$ROOT_DIR" ls-files -s |
  awk '$1 == "160000" { print substr($0, index($0, "\t") + 1) }')
if [ -n "$tracked_gitlinks" ]; then
  printf '%s\n%s\n' "Tracked Git submodules are not allowed:" "$tracked_gitlinks" >&2
  exit 1
fi

tracked_executables=$(git -C "$ROOT_DIR" ls-files -s |
  awk '$1 == "100755" {
    path = substr($0, index($0, "\t") + 1)
    if (path != "scripts/check-baseline.sh" && path != "tests/check-baseline.sh") print path
  }')
if [ -n "$tracked_executables" ]; then
  printf '%s\n%s\n' \
    "Tracked executable files require an explicit readiness allowlist:" \
    "$tracked_executables" >&2
  exit 1
fi

if [ "$(grep -Fc '$1 == "100755"' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 2 ] ||
  [ "$(grep -Fc 'if (path != "scripts/check-baseline.sh" && path != "tests/check-baseline.sh") print path' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 2 ]; then
  printf '%s\n' "Tracked executable guard must keep the exact two-script allowlist." >&2
  exit 1
fi

tracked_runtime_sources=$(git -C "$ROOT_DIR" ls-files |
  grep -Ei '\.(cjs|mjs|js|jsx|ts|tsx|py|rb|php|java|kt|kts|swift|go|rs|cs)$' || true)
if [ -n "$tracked_runtime_sources" ]; then
  printf '%s\n%s\n' \
    "Tracked runtime source files require a complete implementation transition:" \
    "$tracked_runtime_sources" >&2
  exit 1
fi

secret_files=$(rg -l --hidden \
  --glob '!**/.git/**' \
  --glob '!scripts/check-baseline.sh' \
  'AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z ]+)?PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]+|gh[pousr]_[A-Za-z0-9_]{30,}' \
  "$ROOT_DIR" || true)
if [ -n "$secret_files" ]; then
	printf '%s\n%s\n' "Potential secret material detected in:" "$secret_files" >&2
	exit 1
fi

api_secret_files=$(rg -l --hidden -i \
  --glob '!**/.git/**' \
  --glob '!scripts/check-baseline.sh' \
  'bearer[[:space:]]+[A-Za-z0-9._-]{20,}|(twitter|gnip|ads)[A-Za-z0-9_ -]{0,32}(secret|token|key)[A-Za-z0-9_ -]{0,16}[:=][[:space:]]*[A-Za-z0-9_./+=-]{20,}' \
  "$ROOT_DIR" || true)
if [ -n "$api_secret_files" ]; then
	printf '%s\n%s\n' "Potential Ads API, GNIP, or bearer token material detected in:" "$api_secret_files" >&2
	exit 1
fi

account_context_files=$(rg -l --hidden -i \
	--glob '!**/.git/**' \
	--glob '!scripts/check-baseline.sh' \
	"(ads[_ -]?)?(account|customer)[_ -]?id[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[0-9]{5,}" \
	"$ROOT_DIR" || true)
if [ -n "$account_context_files" ]; then
	printf '%s\n%s\n' "Potential populated Ads account context detected in:" "$account_context_files" >&2
	exit 1
fi

runtime_manifests=$(git -C "$ROOT_DIR" ls-files | grep -E '(^|/)(package\.json|package-lock\.json|requirements.*\.txt|pyproject\.toml|setup\.py|build\.gradle|pom\.xml|go\.mod|Cargo\.toml)$' || true)
if [ -n "$runtime_manifests" ]; then
  printf '%s\n%s\n' "Runtime manifests were added; update README, plan, and this guard for the real sample:" "$runtime_manifests" >&2
  exit 1
fi

if ! grep -Fq "scripts/check-baseline.sh" "$README"; then
  printf '%s\n' "README must document the baseline guard." >&2
  exit 1
fi

if ! grep -Fq "scripts/check-baseline.sh" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must run the readiness baseline guard." >&2
  exit 1
fi

if ! grep -Fq 'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' "$MAKEFILE" ||
  [ "$(grep -c '\$(ROOT)scripts/check-baseline.sh' "$MAKEFILE")" -ne 2 ] ||
  [ "$(grep -c '\$(ROOT)tests/check-baseline.sh' "$MAKEFILE")" -ne 1 ]; then
  printf '%s\n' "Make readiness targets must resolve the baseline from the repository root." >&2
  exit 1
fi

if ! grep -Fq "assert_rejected_without_value" "$SCANNER_TEST" ||
  ! grep -Fq "assert_tracked_symlink_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_tracked_gitlink_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_unapproved_executable_rejected" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_unapproved_executable_rejected$' "$SCANNER_TEST")" -ne 1 ] ||
  ! grep -Fq '*"$fixture_content"*|*"$fixture_object"*)' "$SCANNER_TEST" ||
  ! grep -Fq "assert_tracked_runtime_source_rejected" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_tracked_runtime_source_rejected ' "$SCANNER_TEST")" -ne 2 ] ||
  [ "$(grep -c '^assert_tracked_gitlink_rejected$' "$SCANNER_TEST")" -ne 1 ] ||
  ! grep -Fq "scanner output exposed the object ID" "$SCANNER_TEST" ||
  ! grep -Fq "Potential secret material detected in:" "$SCANNER_TEST" ||
  ! grep -Fq "Potential Ads API, GNIP, or bearer token material detected in:" "$SCANNER_TEST" ||
  ! grep -Fq "Potential populated Ads account context detected in:" "$SCANNER_TEST"; then
  printf '%s\n' "Scanner regression tests must cover rejection and redacted diagnostics." >&2
  exit 1
fi

if [ "$(grep -Fc -- "--glob '!docs/plans/**'" "$ROOT_DIR/scripts/check-baseline.sh")" -ne 1 ] || \
  ! grep -Fq 'fixture_path=${4:-mutation.txt}' "$SCANNER_TEST" || \
  ! grep -Fq 'docs/plans/mutation-one.md' "$SCANNER_TEST" || \
  ! grep -Fq 'docs/plans/mutation-two.md' "$SCANNER_TEST" || \
  ! grep -Fq 'docs/plans/mutation-three.md' "$SCANNER_TEST"; then
  printf '%s\n' "Readiness scans must cover credential and account values in plan documents." >&2
  exit 1
fi

if [ ! -f "$PLAN_CREDENTIAL_SCAN_PLAN" ] || \
  ! grep -Fq "status: completed" "$PLAN_CREDENTIAL_SCAN_PLAN" || \
  ! grep -Fq "## Status: Completed" "$PLAN_CREDENTIAL_SCAN_PLAN" || \
  ! grep -Fq "make check" "$PLAN_CREDENTIAL_SCAN_PLAN" || \
  ! grep -Fq "hostile mutations were rejected" "$PLAN_CREDENTIAL_SCAN_PLAN"; then
  printf '%s\n' "Plan credential scan must record completed verification." >&2
  exit 1
fi

if ! grep -Fq "engineering plans are scanned for credential and account values" "$README" || \
  ! grep -Fq "Tracked engineering plans receive the same credential and account-value scans" "$SECURITY" || \
  ! grep -Fq "Scan tracked engineering plans for credential and account values" "$VISION" || \
  ! grep -Fq "Extended credential and account-value scans to tracked engineering plans" "$CHANGES"; then
  printf '%s\n' "Repository guidance must document plan credential scanning." >&2
  exit 1
fi

if ! grep -Fq "unapproved tracked executable files" "$README" ||
  ! grep -Fq "Tracked executable files are allowlisted" "$SECURITY" ||
  ! grep -Fq "Keep tracked executable modes limited" "$VISION" ||
  ! grep -Fq "Rejected unapproved tracked executable files" "$CHANGES"; then
  printf '%s\n' "Project docs must record the tracked executable-mode boundary." >&2
  exit 1
fi

for plan_contract in \
  'status: completed' \
  '## Status: Completed' \
  '## Work Completed' \
  '## Verification Completed' \
  'Eight isolated hostile mutations were rejected'; do
  if ! grep -Fq "$plan_contract" "$EXECUTABLE_MODE_PLAN"; then
    printf '%s\n' "Tracked executable-mode plan must keep completed evidence: $plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "readiness guard rejects orphan runtime source files" "$README" ||
  ! grep -Fq "Tracked application source files are rejected" "$SECURITY" ||
  ! grep -Fq "Keep orphan runtime source files" "$VISION" ||
  ! grep -Fq "Rejected tracked runtime source files" "$CHANGES"; then
  printf '%s\n' "Project docs must record the documentation-only runtime source boundary." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$RUNTIME_SOURCE_PLAN" ||
  ! grep -Fq "Eight isolated hostile mutations" "$RUNTIME_SOURCE_PLAN" ||
  ! grep -Fq "No runtime manifest" "$RUNTIME_SOURCE_PLAN"; then
  printf '%s\n' "Runtime source guard plan must record completed verification and no-runtime scope." >&2
  exit 1
fi

if ! grep -Fq "tracked symlinks and Git submodules" "$README" ||
  ! grep -Fq "Tracked Git submodules and raw gitlinks are rejected" "$SECURITY" ||
  ! grep -Fq "Keep tracked Git submodules and gitlinks" "$VISION" ||
  ! grep -Fq "Rejected tracked Git submodules and raw gitlinks" "$CHANGES"; then
  printf '%s\n' "Project docs must record the tracked gitlink readiness boundary." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$SYMLINK_GUARD_PLAN" ||
  ! grep -Fq "Tracked Symlink Guard" "$SYMLINK_GUARD_PLAN"; then
  printf '%s\n' "Tracked symlink guard plan must remain completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$GITLINK_GUARD_PLAN" ||
  ! grep -Fq "Ten hostile mutations were rejected" "$GITLINK_GUARD_PLAN" ||
  ! grep -Fq 'make -f /absolute/path/to/Makefile check' "$GITLINK_GUARD_PLAN" ||
  ! grep -Fq "No runtime manifest" "$GITLINK_GUARD_PLAN"; then
  printf '%s\n' "Tracked gitlink guard plan must record completed verification and no-runtime scope." >&2
  exit 1
fi

if ! grep -Fq "Readiness Scanner Regression Tests" "$SCANNER_TEST_PLAN" ||
  ! grep -Fq "tests/check-baseline.sh" "$SCANNER_TEST_PLAN"; then
  printf '%s\n' "Scanner regression test plan must document the behavior harness." >&2
  exit 1
fi

if ! grep -Fq "lint:" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must expose a lint gate." >&2
  exit 1
fi

if ! grep -Fq "test:" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must expose a test gate." >&2
  exit 1
fi

if ! grep -Fq "build:" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must expose a build gate." >&2
  exit 1
fi

if ! grep -Fq "verify: lint test build" "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile must expose a combined verify gate." >&2
  exit 1
fi

if ! grep -Fq 'override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' "$MAKEFILE" || \
   ! grep -Fq '$(ROOT)scripts/check-baseline.sh' "$MAKEFILE" || \
   ! grep -Fq '$(ROOT)tests/check-baseline.sh' "$MAKEFILE"; then
  printf '%s\n' "Makefile verification must protect and resolve both scanners from the loaded Makefile." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "## Status: Completed" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq 'make ROOT=/tmp check' "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "four Make gates" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "external working directory" "$MAKE_ROOT_PROTECTION_PLAN" || \
   ! grep -Fq "Four isolated hostile mutations were rejected" "$MAKE_ROOT_PROTECTION_PLAN"; then
  printf '%s\n' "Make root protection plan must record completed hostile-override and external verification." >&2
  exit 1
fi

if ! grep -Fq "make check" "$README"; then
  printf '%s\n' "README must document the make check wrapper." >&2
  exit 1
fi

if ! grep -Fq "make lint" "$README" || ! grep -Fq "make test" "$README" || ! grep -Fq "make build" "$README"; then
  printf '%s\n' "README must document the root lint, test, and build gates." >&2
  exit 1
fi

if ! grep -Fq "private, raw, cached, and exported Ads/GNIP data" "$README"; then
  printf '%s\n' "README must document private data export handling." >&2
  exit 1
fi

if ! grep -Fq "docs/data-fixture-policy.md" "$README"; then
  printf '%s\n' "README must point future fixture work to the fixture policy." >&2
  exit 1
fi

if ! grep -Fq "docs/fixture-provenance-template.md" "$README"; then
  printf '%s\n' "README must point future fixture work to the provenance template." >&2
  exit 1
fi

if ! grep -Fq 'ripgrep (`rg`)' "$README"; then
  printf '%s\n' "README must document the ripgrep readiness prerequisite." >&2
  exit 1
fi

if ! grep -Fq ".env.example" "$README" || ! grep -Fq "docs/credential-handling-policy.md" "$README"; then
  printf '%s\n' "README must document the credential placeholder policy." >&2
  exit 1
fi

if ! grep -Fq "account context placeholders" "$README"; then
  printf '%s\n' "README must document account context placeholders." >&2
  exit 1
fi

if ! grep -Fq "reports filenames without echoing matched values" "$README"; then
	printf '%s\n' "README must document redacted readiness scan output." >&2
	exit 1
fi

if ! grep -Fq "fixture provenance checklist" "$README"; then
  printf '%s\n' "README must mention the fixture provenance checklist." >&2
  exit 1
fi

if ! grep -Fq "## Allowed Fixtures" "$FIXTURE_POLICY"; then
  printf '%s\n' "Fixture policy must define allowed fixture criteria." >&2
  exit 1
fi

if ! grep -Fq "## Disallowed Data" "$FIXTURE_POLICY"; then
  printf '%s\n' "Fixture policy must define disallowed data." >&2
  exit 1
fi

if ! grep -Fq "synthetic" "$FIXTURE_POLICY" || ! grep -Fq "publishable" "$FIXTURE_POLICY"; then
  printf '%s\n' "Fixture policy must require synthetic or publishable data." >&2
  exit 1
fi

if ! grep -Fq "## Provenance Requirements" "$FIXTURE_POLICY"; then
  printf '%s\n' "Fixture policy must define provenance requirements." >&2
  exit 1
fi

if ! grep -Fq "docs/fixture-provenance-template.md" "$FIXTURE_POLICY"; then
  printf '%s\n' "Fixture policy must point to the provenance template." >&2
  exit 1
fi

for provenance in "source or generation method" "license or permission" "PII review" "size rationale"; do
  if ! grep -Fq "$provenance" "$FIXTURE_POLICY"; then
    printf '%s\n' "Fixture policy must require provenance detail: $provenance" >&2
    exit 1
  fi
done

for template_section in "## Fixture Summary" "## Source Or Generation Method" "## License Or Permission" "## PII Review" "## Size Rationale" "## Guard Updates"; do
  if ! grep -Fq "$template_section" "$FIXTURE_TEMPLATE"; then
    printf '%s\n' "Fixture provenance template must include section: $template_section" >&2
    exit 1
  fi
done

for template_detail in "Fixture path" "Intended sample flow" "Redistribution permission" "Reviewer and review date" "Smallest useful fixture size" "scripts/check-baseline.sh"; do
  if ! grep -Fq "$template_detail" "$FIXTURE_TEMPLATE"; then
    printf '%s\n' "Fixture provenance template must include detail: $template_detail" >&2
    exit 1
  fi
done

for credential in "ADS_API_KEY=" "ADS_API_SECRET=" "ADS_ACCESS_TOKEN=" "ADS_ACCESS_TOKEN_SECRET=" "ADS_ACCOUNT_ID=" "ADS_CUSTOMER_ID=" "GNIP_BEARER_TOKEN="; do
  if ! grep -Fxq "$credential" "$ENV_EXAMPLE"; then
    printf '%s\n' ".env.example must include empty placeholder: $credential" >&2
    exit 1
  fi
done

for credential in "ADS_API_KEY" "ADS_API_SECRET" "ADS_ACCESS_TOKEN" "ADS_ACCESS_TOKEN_SECRET" "ADS_ACCOUNT_ID" "ADS_CUSTOMER_ID" "GNIP_BEARER_TOKEN"; do
  if ! grep -Fq "$credential" "$CREDENTIAL_POLICY"; then
    printf '%s\n' "Credential policy must document placeholder: $credential" >&2
    exit 1
  fi
done

if ! grep -Fq "Account and customer identifiers" "$CREDENTIAL_POLICY" ||
  ! grep -Fq "not publishable sample data" "$CREDENTIAL_POLICY"; then
  printf '%s\n' "Credential policy must distinguish account context placeholders from publishable sample data." >&2
  exit 1
fi

for credential_policy_section in "## Allowed Credential Sources" "## Tracked Placeholders" "## Logging And Redaction" "## Verification Updates"; do
  if ! grep -Fq "$credential_policy_section" "$CREDENTIAL_POLICY"; then
    printf '%s\n' "Credential policy must include section: $credential_policy_section" >&2
    exit 1
  fi
done

for credential_policy_detail in ".env.example" "values empty" "authorization headers" "scripts/check-baseline.sh"; do
  if ! grep -Fq "$credential_policy_detail" "$CREDENTIAL_POLICY"; then
    printf '%s\n' "Credential policy must include detail: $credential_policy_detail" >&2
    exit 1
  fi
done

if ! grep -Fq "credentials out of git" "$VISION"; then
  printf '%s\n' "VISION.md must keep future credentials out of git." >&2
  exit 1
fi

if ! grep -Fq "documentation-only" "$VISION"; then
  printf '%s\n' "VISION.md must describe the current documentation-only repository state." >&2
  exit 1
fi

if ! grep -Fq "docs/fixture-provenance-template.md" "$VISION"; then
  printf '%s\n' "VISION.md must point future fixture work to the provenance template." >&2
  exit 1
fi

if ! grep -Fq "credential placeholder contract" "$VISION"; then
  printf '%s\n' "VISION.md must describe the credential placeholder contract." >&2
  exit 1
fi

if ! grep -Fq "account context placeholders" "$VISION"; then
  printf '%s\n' "VISION.md must describe account context placeholders." >&2
  exit 1
fi

if ! grep -Fq "readiness tool prerequisites" "$VISION"; then
  printf '%s\n' "VISION.md must describe readiness tool prerequisites." >&2
  exit 1
fi

if ! grep -Fq "No primary dependency manifest was detected" "$SECURITY"; then
  printf '%s\n' "SECURITY.md must describe the current no-dependency baseline." >&2
  exit 1
fi

if ! grep -Fq "docs/data-fixture-policy.md" "$SECURITY"; then
  printf '%s\n' "SECURITY.md must point fixture changes to the fixture policy." >&2
  exit 1
fi

if ! grep -Fq "docs/fixture-provenance-template.md" "$SECURITY"; then
  printf '%s\n' "SECURITY.md must point fixture changes to the provenance template." >&2
  exit 1
fi

if ! grep -Fq "fixture provenance checklist" "$SECURITY"; then
  printf '%s\n' "SECURITY.md must mention the fixture provenance checklist." >&2
  exit 1
fi

if ! grep -Fq "docs/credential-handling-policy.md" "$SECURITY" || ! grep -Fq ".env.example" "$SECURITY"; then
  printf '%s\n' "SECURITY.md must point credential changes to the credential policy and placeholder file." >&2
  exit 1
fi

if ! grep -Fq "repository readiness baseline" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the repository readiness baseline." >&2
  exit 1
fi

if ! grep -Fq "fixture provenance checklist" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the fixture provenance checklist." >&2
  exit 1
fi

if ! grep -Fq "fixture provenance template" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the fixture provenance template." >&2
  exit 1
fi

if ! grep -Fq "credential placeholder policy" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the credential placeholder policy." >&2
  exit 1
fi

if ! grep -Fq "ripgrep readiness prerequisite" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the ripgrep readiness prerequisite." >&2
  exit 1
fi

if ! grep -Fq "account context placeholders" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the account context placeholders." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN"; then
  printf '%s\n' "Plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$DATA_GUARD_PLAN"; then
  printf '%s\n' "Data guard plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-09-safe-fixture-policy.md"; then
  printf '%s\n' "Safe fixture policy plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-safe-fixture-policy.md"; then
  printf '%s\n' "Safe fixture policy plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-09-fixture-provenance-checklist.md"; then
  printf '%s\n' "Fixture provenance checklist plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fixture-provenance-checklist.md"; then
  printf '%s\n' "Fixture provenance checklist plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$ROOT_DIR/docs/plans/2026-06-09-fixture-provenance-template.md"; then
  printf '%s\n' "Fixture provenance template plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-fixture-provenance-template.md"; then
  printf '%s\n' "Fixture provenance template plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$MAKE_GATE_PLAN"; then
  printf '%s\n' "Readiness make gate plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$MAKE_GATE_PLAN"; then
  printf '%s\n' "Readiness make gate plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$CREDENTIAL_PLAN"; then
  printf '%s\n' "Credential placeholder policy plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$CREDENTIAL_PLAN"; then
  printf '%s\n' "Credential placeholder policy plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ACCOUNT_CONTEXT_PLAN"; then
  printf '%s\n' "Account context placeholder plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ACCOUNT_CONTEXT_PLAN"; then
  printf '%s\n' "Account context placeholder plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$ROOT_DIR/docs/plans/2026-06-09-readiness-ripgrep-prerequisite.md"; then
  printf '%s\n' "Readiness ripgrep prerequisite plan must be marked completed." >&2
  exit 1
fi

if ! grep -Fq "make check" "$ROOT_DIR/docs/plans/2026-06-09-readiness-ripgrep-prerequisite.md"; then
  printf '%s\n' "Readiness ripgrep prerequisite plan must record make check verification." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$SCANNER_REDACTION_PLAN" ||
  ! grep -Fq "make check" "$SCANNER_REDACTION_PLAN"; then
  printf '%s\n' "Readiness scan redaction plan must be completed and record verification." >&2
  exit 1
fi

printf '%s\n' "Data Ads Sample readiness baseline checks passed."
