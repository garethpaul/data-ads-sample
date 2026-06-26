#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
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
FINE_GRAINED_GITHUB_PLAN="$ROOT_DIR/docs/plans/2026-06-15-fine-grained-github-value-scan.md"
AWS_SESSION_KEY_PLAN="$ROOT_DIR/docs/plans/2026-06-16-aws-session-access-key-scan.md"
GITLAB_TOKEN_PLAN="$ROOT_DIR/docs/plans/2026-06-16-gitlab-pat-value-scan.md"
GOOGLE_API_KEY_PLAN="$ROOT_DIR/docs/plans/2026-06-17-google-api-key-value-scan.md"
INDEX_HARDENING_PLAN="$ROOT_DIR/docs/plans/2026-06-19-git-index-readiness-hardening.md"
MAKEFILE="$ROOT_DIR/Makefile"
SCANNER_TEST="$ROOT_DIR/tests/check-baseline.sh"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

escape_index_paths() {
  rule=$1
  index_file=$(mktemp "${TMPDIR:-/tmp}/data-ads-index.XXXXXX")
  if ! git -C "$ROOT_DIR" ls-files -z --stage >"$index_file"; then
    rm -f "$index_file"
    printf '%s\n' "Git index metadata scan failed safely." >&2
    return 1
  fi
  status=0
  INDEX_PATH_RULE=$rule perl -0ne '
      s/\0\z//;
      die "Malformed Git index record\n"
        unless /\A([0-9]+) ([0-9a-f]+) ([0-3])\t(.*)\z/s;
      ($mode, $stage, $path) = ($1, $3, $4);
      $classification_path = $path;
      if (utf8::decode($classification_path)) {
        $classification_path =~ s/\s+\z//;
      } else {
        $classification_path = $path;
        $classification_path =~ s/[ \t\r\n\f\x0B]+\z//;
      }
      $runtime_path = $classification_path;
      $runtime_path =~ tr/A-Z/a-z/;
      $rule = $ENV{"INDEX_PATH_RULE"};
      $matches =
        ($rule eq "unmerged" && $stage ne "0") ||
        ($rule eq "symlink" && $mode eq "120000") ||
        ($rule eq "gitlink" && $mode eq "160000") ||
        ($rule eq "executable" && $mode eq "100755" &&
          $path ne "scripts/check-baseline.sh" &&
          $path ne "tests/check-baseline.sh") ||
        ($rule eq "runtime" &&
          $path ne "scripts/check-baseline.sh" &&
          $path ne "tests/check-baseline.sh" &&
          $runtime_path =~ /\.(?:cjs|mjs|js|jsx|ts|tsx|py|rb|php|java|kt|kts|swift|go|rs|cs|sh|bash|zsh|ksh)\z/) ||
        ($rule eq "manifest" && $path =~ m{(?:\A|/)(?:package\.json|package-lock\.json|requirements.*\.txt|pyproject\.toml|setup\.py|build\.gradle|pom\.xml|go\.mod|Cargo\.toml)\z}) ||
        ($rule eq "sensitive" &&
          $path !~ m{(?:\A|/)\.env\.example\z} &&
          $path ne "docs/credential-handling-policy.md" &&
          $path ne "docs/plans/2026-06-09-credential-placeholder-policy.md" &&
          $path ne "docs/plans/2026-06-12-checkout-credential-boundary.md" &&
          $path =~ m{(?:\A|/)(?:\.env(?:\.|\z)|.*\.(?:pem|key)\z|.*(?:secret|credential|token).*|secrets/|data/(?:private|raw|cache|exports)/|.*\.(?:sqlite|db)\z)}i);
      next unless $matches;
      $path =~ s/\\/\\\\/g;
      $path =~ s/([^[:print:]])/sprintf("\\x{%02X}", ord($1))/ge;
      print "$path\n";
    ' "$index_file" || status=$?
  rm -f "$index_file"
  return "$status"
}

git_grep_index_files() {
  pattern=$1
  shift
  output_file=$(mktemp "${TMPDIR:-/tmp}/data-ads-grep.XXXXXX")
  escaped_file=$(mktemp "${TMPDIR:-/tmp}/data-ads-grep-paths.XXXXXX")
  status=0
  git -C "$ROOT_DIR" grep --cached -a -l -z "$@" -e "$pattern" -- . \
    ':(exclude)scripts/check-baseline.sh' >"$output_file" || status=$?
  if [ "$status" -gt 1 ]; then
    rm -f "$output_file" "$escaped_file"
    printf '%s\n' "Git index content scan failed safely." >&2
    return "$status"
  fi
  if ! perl -0ne '
      s/\0\z//;
      next if $_ eq "";
      s/\\/\\\\/g;
      s/([^[:print:]])/sprintf("\\x{%02X}", ord($1))/ge;
      print "$_\n";
    ' "$output_file" >"$escaped_file"; then
    rm -f "$output_file" "$escaped_file"
    printf '%s\n' "Git index path rendering failed safely." >&2
    return 1
  fi
  cat "$escaped_file"
  rm -f "$output_file" "$escaped_file"
}

checkout_credentials_are_scoped() {
  awk -v checkout='actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10' '
    function indentation(line, copy) {
      copy = line
      sub(/[^ ].*$/, "", copy)
      return length(copy)
    }
    function finish_checkout() {
      if (!in_checkout) return
      if (with_count != 1 || credential_count != 1 || credential_false != 1) invalid = 1
      in_checkout = 0
    }
    {
      sub(/\r$/, "")
      if (index($0, "\t") != 0) invalid = 1
      indent = indentation($0)
      if (in_scalar) {
        if ($0 ~ /^[ ]*$/ || indent > scalar_indent) next
        in_scalar = 0
      }
      if ($0 ~ /^[ ]*[A-Za-z0-9_-]+:[ ]*[|>][-+0-9]*([ ]*#.*)?$/) {
        scalar_indent = indent
        in_scalar = 1
        next
      }
      if (in_checkout && $0 !~ /^[ ]*$/ && indent <= step_indent) finish_checkout()
      if ($0 ~ "^[ ]*uses:[ ]*" checkout "([ ]*#.*)?$") {
        finish_checkout()
        checkout_count++
        in_checkout = 1
        key_indent = indent
        step_indent = indent - 2
        with_count = 0
        credential_count = 0
        credential_false = 0
        in_with = 0
        next
      }
      if (!in_checkout) next
      if (indent == key_indent && $0 ~ /^[ ]*with:[ ]*$/) {
        with_count++
        in_with = 1
        next
      }
      if (indent <= key_indent) in_with = 0
      if (in_with && indent == key_indent + 2 &&
          $0 ~ /^[ ]*persist-credentials:[ ]*/) {
        credential_count++
        if ($0 ~ /^[ ]*persist-credentials:[ ]*false([ ]*#.*)?$/) credential_false++
      }
    }
    END {
      finish_checkout()
      exit !(checkout_count == 1 && invalid == 0)
    }
  ' "$CI_WORKFLOW"
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
  "docs/plans/2026-06-15-fine-grained-github-value-scan.md" \
  "docs/plans/2026-06-16-aws-session-access-key-scan.md" \
  "docs/plans/2026-06-16-gitlab-pat-value-scan.md" \
  "docs/plans/2026-06-17-google-api-key-value-scan.md" \
  "docs/plans/2026-06-19-git-index-readiness-hardening.md" \
  "scripts/check-baseline.sh" \
  "tests/check-baseline.sh"; do
  require_file "$path"
done

workflow_count=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) | wc -l | tr -d ' ')
if [ "$workflow_count" -ne 1 ] || ! checkout_credentials_are_scoped; then
  printf '%s\n' "GitHub Actions checkout must set persist-credentials to false in its own with mapping." >&2
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

if [ "$(grep -Ec '^[a-z_]+_files=\$\(git_grep_index_files' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 4 ] ||
  grep -Eq 'git -C "\$ROOT_DIR" grep .* -n' "$ROOT_DIR/scripts/check-baseline.sh"; then
  printf '%s\n' "Readiness content scans must use the Git index and report filenames instead of matched values." >&2
  exit 1
fi

for ignored in ".env" ".env.*" ".envrc" "!.env.example" "*.local" "*.pem" "*.key" "secrets/" "data/private/" "data/raw/" "data/cache/" "data/exports/" "*.sqlite" "*.db"; do
  if ! grep -Fq "$ignored" "$ROOT_DIR/.gitignore"; then
    printf '%s\n' ".gitignore must include $ignored" >&2
    exit 1
  fi
done

unmerged_entries=$(escape_index_paths unmerged)
if [ -n "$unmerged_entries" ]; then
  printf '%s\n%s\n' "Unmerged Git index entries are not allowed:" "$unmerged_entries" >&2
  exit 1
fi

tracked_sensitive=$(escape_index_paths sensitive)
if [ -n "$tracked_sensitive" ]; then
  printf '%s\n%s\n' "Potential credential or private-data files are tracked:" "$tracked_sensitive" >&2
  exit 1
fi

tracked_symlinks=$(escape_index_paths symlink)
if [ -n "$tracked_symlinks" ]; then
  printf '%s\n%s\n' "Tracked symbolic links are not allowed:" "$tracked_symlinks" >&2
  exit 1
fi

tracked_gitlinks=$(escape_index_paths gitlink)
if [ -n "$tracked_gitlinks" ]; then
  printf '%s\n%s\n' "Tracked Git submodules are not allowed:" "$tracked_gitlinks" >&2
  exit 1
fi

tracked_executables=$(escape_index_paths executable)
if [ -n "$tracked_executables" ]; then
  printf '%s\n%s\n' \
    "Tracked executable files require an explicit readiness allowlist:" \
    "$tracked_executables" >&2
  exit 1
fi

if [ "$(grep -Fc '$rule eq "executable" && $mode eq "100755"' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 2 ] ||
  [ "$(grep -Fc '$path ne "scripts/check-baseline.sh" &&' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 3 ] ||
  [ "$(grep -Fc '$path ne "tests/check-baseline.sh"' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 3 ]; then
  printf '%s\n' "Tracked executable and runtime guards must keep the exact two-script allowlist." >&2
  exit 1
fi

tracked_runtime_sources=$(escape_index_paths runtime)
if [ -n "$tracked_runtime_sources" ]; then
  printf '%s\n%s\n' \
    "Tracked runtime source files require a complete implementation transition:" \
    "$tracked_runtime_sources" >&2
  exit 1
fi

binary_files=$(git_grep_index_files '\x00' -P)
if [ -n "$binary_files" ]; then
  printf '%s\n%s\n' "Tracked binary or NUL-containing files are not allowed:" "$binary_files" >&2
  exit 1
fi

secret_files=$(git_grep_index_files \
  '(^|[^A-Za-z0-9])(AKIA|ASIA)[0-9A-Z]{16}([^A-Za-z0-9]|$)|(^|[^A-Za-z0-9_])(gh[pousr]_[A-Za-z0-9_]{30,}|github_pat_[A-Za-z0-9_]{30,})([^A-Za-z0-9_]|$)|(^|[^A-Za-z0-9_-])glpat-[A-Za-z0-9_-]{20,}([^A-Za-z0-9_-]|$)|(^|[^A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}([^A-Za-z0-9_-]|$)|-----BEGIN ([A-Z ]+)?PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]+' \
  -E)
if [ -n "$secret_files" ]; then
	printf '%s\n%s\n' "Potential secret material detected in:" "$secret_files" >&2
	exit 1
fi

api_secret_files=$(git_grep_index_files \
  'bearer[[:space:]]+[A-Za-z0-9._-]{20,}|(twitter|gnip|ads)[A-Za-z0-9_ -]{0,32}(secret|token|key)[A-Za-z0-9_ -]{0,16}[:=][[:space:]]*[A-Za-z0-9_./+=-]{20,}' \
  -E -i)
if [ -n "$api_secret_files" ]; then
	printf '%s\n%s\n' "Potential Ads API, GNIP, or bearer token material detected in:" "$api_secret_files" >&2
	exit 1
fi

account_context_files=$(git_grep_index_files \
  "(ads[_ -]?)?(account|customer)[_ -]?id[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[0-9]{5,}" \
  -E -i)
if [ -n "$account_context_files" ]; then
	printf '%s\n%s\n' "Potential populated Ads account context detected in:" "$account_context_files" >&2
	exit 1
fi

runtime_manifests=$(escape_index_paths manifest)
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
  ! grep -Fq "assert_index_content_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_index_content_accepted" "$SCANNER_TEST" ||
  ! grep -Fq "assert_binary_index_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_unmerged_index_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_newline_runtime_path_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_checkout_boundary_scoped" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_git_index_failure_rejected ' "$SCANNER_TEST")" -ne 2 ] ||
  ! grep -Fq "assert_tracked_symlink_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_tracked_gitlink_rejected" "$SCANNER_TEST" ||
  ! grep -Fq "assert_unapproved_executable_rejected" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_unapproved_executable_rejected$' "$SCANNER_TEST")" -ne 1 ] ||
  ! grep -Fq '*"$fixture_content"*|*"$fixture_object"*)' "$SCANNER_TEST" ||
  ! grep -Fq "assert_tracked_runtime_source_rejected" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_tracked_runtime_source_rejected ' "$SCANNER_TEST")" -ne 2 ] ||
  ! grep -Fq "assert_shell_runtime_sources_rejected" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_shell_runtime_sources_rejected$' "$SCANNER_TEST")" -ne 1 ] ||
  ! grep -Fq "assert_invalid_utf8_shell_path_rejected" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_invalid_utf8_shell_path_rejected$' "$SCANNER_TEST")" -ne 1 ] ||
  ! grep -Fq "assert_unicode_confusable_extensions_accepted" "$SCANNER_TEST" ||
  [ "$(grep -c '^assert_unicode_confusable_extensions_accepted$' "$SCANNER_TEST")" -ne 1 ] ||
  [ "$(grep -c '^assert_tracked_gitlink_rejected$' "$SCANNER_TEST")" -ne 1 ] ||
  ! grep -Fq "scanner output exposed the object ID" "$SCANNER_TEST" ||
  ! grep -Fq "Potential secret material detected in:" "$SCANNER_TEST" ||
  ! grep -Fq "Potential Ads API, GNIP, or bearer token material detected in:" "$SCANNER_TEST" ||
  ! grep -Fq "Potential populated Ads account context detected in:" "$SCANNER_TEST"; then
  printf '%s\n' "Scanner regression tests must cover rejection and redacted diagnostics." >&2
  exit 1
fi

for index_contract in \
  'git -C "$ROOT_DIR" ls-files -z --stage' \
  'git -C "$ROOT_DIR" grep --cached -a -l -z' \
  'Git index metadata scan failed safely.' \
  'Git index content scan failed safely.' \
  'Tracked binary or NUL-containing files are not allowed:' \
  'Unmerged Git index entries are not allowed:' \
  'checkout_credentials_are_scoped'; do
  if ! grep -Fq "$index_contract" "$ROOT_DIR/scripts/check-baseline.sh"; then
    printf '%s\n' "Readiness scanner must preserve Git-index hardening: $index_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc -- "--glob '!docs/plans/**'" "$ROOT_DIR/scripts/check-baseline.sh")" -ne 1 ] || \
  ! grep -Fq 'fixture_path=${4:-mutation.txt}' "$SCANNER_TEST" || \
  ! grep -Fq 'docs/plans/mutation-one.md' "$SCANNER_TEST" || \
  ! grep -Fq 'docs/plans/mutation-two.md' "$SCANNER_TEST" || \
  ! grep -Fq 'docs/plans/mutation-three.md' "$SCANNER_TEST"; then
  printf '%s\n' "Readiness scans must cover credential and account values in plan documents." >&2
  exit 1
fi

if ! grep -Fq 'github_pat_[A-Za-z0-9_]{30,}' "$ROOT_DIR/scripts/check-baseline.sh" || \
  ! grep -Fq "fine_grained_token='github_pat_'" "$SCANNER_TEST" || \
  [ "$(grep -Ec '^[[:space:]]*"fine-grained GitHub token"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  [ "$(grep -Ec '^[[:space:]]*"fine-grained GitHub token in plan"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  ! grep -Fq 'docs/plans/mutation-four.md' "$SCANNER_TEST"; then
  printf '%s\n' "Readiness scans must cover fine-grained GitHub tokens in ordinary files and plans." >&2
  exit 1
fi

if ! grep -Fq '(AKIA|ASIA)[0-9A-Z]{16}' "$ROOT_DIR/scripts/check-baseline.sh" || \
  ! grep -Fq "aws_session_key='ASIA'" "$SCANNER_TEST" || \
  [ "$(grep -Ec '^[[:space:]]*"AWS session access key"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  [ "$(grep -Ec '^[[:space:]]*"AWS session access key in plan"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  ! grep -Fq 'docs/plans/mutation-five.md' "$SCANNER_TEST"; then
  printf '%s\n' "Readiness scans must cover AWS session access keys in ordinary files and plans." >&2
  exit 1
fi

if [ "$(grep -Fc 'glpat-[A-Za-z0-9_-]{20,}' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 2 ] || \
  ! grep -Fq "gitlab_token='glpat-'" "$SCANNER_TEST" || \
  [ "$(grep -Ec '^[[:space:]]*"GitLab personal access token"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  [ "$(grep -Ec '^[[:space:]]*"GitLab personal access token in plan"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  ! grep -Fq 'docs/plans/mutation-six.md' "$SCANNER_TEST"; then
  printf '%s\n' "Readiness scans must cover GitLab personal access tokens in ordinary files and plans." >&2
  exit 1
fi

if [ "$(grep -Fc 'AIza[0-9A-Za-z_-]{35}' "$ROOT_DIR/scripts/check-baseline.sh")" -ne 2 ] || \
  ! grep -Fq "google_api_key='AIza'" "$SCANNER_TEST" || \
  [ "$(grep -Ec '^[[:space:]]*"Google API key"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  [ "$(grep -Ec '^[[:space:]]*"Google API key in plan"[[:space:]]*\\$' "$SCANNER_TEST")" -ne 1 ] || \
  ! grep -Fq 'docs/plans/mutation-seven.md' "$SCANNER_TEST"; then
  printf '%s\n' "Readiness scans must cover Google API keys in ordinary files and plans." >&2
  exit 1
fi

scanner_rejection_helper=$(awk '
  /^assert_rejected_without_value\(\)/ { capture = 1 }
  capture && /^assert_tracked_symlink_rejected\(\)/ { exit }
  capture { print }
' "$SCANNER_TEST")
if ! printf '%s\n' "$scanner_rejection_helper" | grep -Fq '*"$fixture_content"*)'; then
  printf '%s\n' "Scanner regression helper must reject diagnostics that reproduce matched values." >&2
  exit 1
fi

if ! grep -Fq "Generic secret scans include modern fine-grained GitHub token values" "$README" || \
  ! grep -Fq "Fine-grained GitHub token values are covered by filename-redacted generic" "$SECURITY" || \
  ! grep -Fq "Scan ordinary tracked files and engineering plans for fine-grained GitHub token values" "$VISION" || \
  ! grep -Fq "Extended filename-redacted generic secret scanning to fine-grained GitHub token values" "$CHANGES"; then
  printf '%s\n' "Repository guidance must document fine-grained GitHub token scanning." >&2
  exit 1
fi

if ! grep -Fq "Generic secret scans cover temporary AWS session access keys" "$README" || \
  ! grep -Fq "Temporary AWS session access-key identifiers are covered by filename-redacted generic" "$SECURITY" || \
  ! grep -Fq "Scan ordinary tracked files and engineering plans for temporary AWS session access keys" "$VISION" || \
  ! grep -Fq "Extended filename-redacted generic secret scanning to temporary AWS session access keys" "$CHANGES" || \
  ! grep -Fq "Temporary AWS session access-key identifiers are secret material" "$CREDENTIAL_POLICY"; then
  printf '%s\n' "Repository guidance must document temporary AWS session access-key scanning." >&2
  exit 1
fi

if ! grep -Fq "Generic secret scans cover GitLab personal access token values" "$README" || \
  ! grep -Fq "GitLab personal access token values are covered by filename-redacted generic" "$SECURITY" || \
  ! grep -Fq "Scan ordinary tracked files and engineering plans for GitLab personal access token values" "$VISION" || \
  ! grep -Fq "Extended filename-redacted generic secret scanning to GitLab personal access token values" "$CHANGES" || \
  ! grep -Fq "GitLab personal access tokens are secret material" "$CREDENTIAL_POLICY"; then
  printf '%s\n' "Repository guidance must document GitLab personal access token scanning." >&2
  exit 1
fi

if ! grep -Fq 'Generic secret scans cover Google API key values beginning with `AIza`' "$README" || \
  ! grep -Fq 'Google API key values beginning with `AIza` are covered by filename-redacted' "$SECURITY" || \
  ! grep -Fq 'Scan ordinary tracked files and engineering plans for `AIza` Google API key values' "$VISION" || \
  ! grep -Fq 'Extended filename-redacted generic secret scanning to `AIza` Google API key values' "$CHANGES" || \
  ! grep -Fq 'Google API keys, including values beginning with `AIza`, are secret material' "$CREDENTIAL_POLICY"; then
  printf '%s\n' "Repository guidance must document Google API key scanning." >&2
  exit 1
fi

if [ ! -f "$GOOGLE_API_KEY_PLAN" ] || \
  ! grep -Fq "## Status: Completed" "$GOOGLE_API_KEY_PLAN" || \
  ! grep -Fq "make check" "$GOOGLE_API_KEY_PLAN" || \
  ! grep -Fq "hostile mutations were rejected" "$GOOGLE_API_KEY_PLAN" || \
  ! grep -Fq "187d98a28376b7f92986570b5136c7d38a8e7ac1" "$GOOGLE_API_KEY_PLAN" || \
  ! grep -Fq "27663133191" "$GOOGLE_API_KEY_PLAN" || \
  ! grep -Fq "27663136570" "$GOOGLE_API_KEY_PLAN" || \
  ! grep -Fq "does not claim comprehensive" "$GOOGLE_API_KEY_PLAN"; then
  printf '%s\n' "Google API key scan plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$INDEX_HARDENING_PLAN" ] || \
  ! grep -Fq "## Status: Completed" "$INDEX_HARDENING_PLAN" || \
  ! grep -Fq "make check" "$INDEX_HARDENING_PLAN" || \
  ! grep -Fq "staged Git index" "$INDEX_HARDENING_PLAN" || \
  ! grep -Fq "does not claim comprehensive" "$INDEX_HARDENING_PLAN"; then
  printf '%s\n' "Git-index readiness hardening plan must record completed verification and limitations." >&2
  exit 1
fi

if [ ! -f "$GITLAB_TOKEN_PLAN" ] || \
  ! grep -Fq "## Status: Completed" "$GITLAB_TOKEN_PLAN" || \
  ! grep -Fq "make check" "$GITLAB_TOKEN_PLAN" || \
  ! grep -Fq "hostile mutations were rejected" "$GITLAB_TOKEN_PLAN" || \
  ! grep -Fq "does not claim comprehensive" "$GITLAB_TOKEN_PLAN"; then
  printf '%s\n' "GitLab personal access token scan plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$AWS_SESSION_KEY_PLAN" ] || \
  ! grep -Fq "## Status: Completed" "$AWS_SESSION_KEY_PLAN" || \
  ! grep -Fq "make check" "$AWS_SESSION_KEY_PLAN" || \
  ! grep -Fq "hostile mutations were rejected" "$AWS_SESSION_KEY_PLAN" || \
  ! grep -Fq "does not claim comprehensive" "$AWS_SESSION_KEY_PLAN"; then
  printf '%s\n' "AWS session access-key scan plan must record completed verification." >&2
  exit 1
fi

if [ ! -f "$FINE_GRAINED_GITHUB_PLAN" ] || \
  ! grep -Fq "status: completed" "$FINE_GRAINED_GITHUB_PLAN" || \
  ! grep -Fq "## Status: Completed" "$FINE_GRAINED_GITHUB_PLAN" || \
  ! grep -Fq "make check" "$FINE_GRAINED_GITHUB_PLAN" || \
  ! grep -Fq "hostile mutations were rejected" "$FINE_GRAINED_GITHUB_PLAN"; then
  printf '%s\n' "Fine-grained GitHub token scan plan must record completed verification." >&2
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

if grep -Fq 'Add a minimal local verification command' "$ROOT_DIR/VISION.md"; then
  printf '%s\n' 'VISION.md must not retain the completed local verification gate as future work.' >&2
  exit 1
fi

for local_verification_contract in \
  'Keep the existing `make check` readiness command as the minimal local verification gate' \
  'Status: Completed' \
  'repository-root and external-directory `make check`'; do
  if ! grep -Fq "$local_verification_contract" \
    "$ROOT_DIR/docs/plans/2026-06-25-local-verification-roadmap-closure.md"; then
    printf '%s\n' "Local verification closure must keep contract: $local_verification_contract" >&2
    exit 1
  fi
done

printf '%s\n' "Data Ads Sample readiness baseline checks passed."
