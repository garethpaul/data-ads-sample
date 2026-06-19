#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
REAL_GIT=$(command -v git)
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/data-ads-baseline-tests.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

case_number=0

copy_repository_files() {
  git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard |
    while IFS= read -r path; do
      source_path="$ROOT_DIR/$path"
      if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
        continue
      fi

      mkdir -p "$CASE_DIR/$(dirname -- "$path")"
      cp -pP "$source_path" "$CASE_DIR/$path"
    done
}

prepare_case() {
  case_number=$((case_number + 1))
  CASE_DIR="$TMP_ROOT/case-$case_number"
  mkdir "$CASE_DIR"
  copy_repository_files
  git -C "$CASE_DIR" init -q
  git -C "$CASE_DIR" add .
}

assert_rejected_without_value() {
  label=$1
  fixture_content=$2
  expected_message=$3
  fixture_path=${4:-mutation.txt}

  prepare_case
  mkdir -p "$CASE_DIR/$(dirname -- "$fixture_path")"
  printf '%s\n' "$fixture_content" >"$CASE_DIR/$fixture_path"
  git -C "$CASE_DIR" add "$fixture_path"

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "$label: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"$expected_message"*"$fixture_path"*) ;;
    *)
      printf '%s\n%s\n' "$label: expected diagnostic and fixture filename" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$fixture_content"*)
      printf '%s\n' "$label: scanner output exposed the matched value" >&2
      exit 1
      ;;
  esac
}

assert_index_content_rejected() {
  label=$1
  fixture_content=$2
  expected_message=$3
  fixture_path=${4:-mutation.txt}
  working_tree_content=${5:-safe working tree content}

  prepare_case
  mkdir -p "$CASE_DIR/$(dirname -- "$fixture_path")"
  printf '%s\n' "$fixture_content" >"$CASE_DIR/$fixture_path"
  git -C "$CASE_DIR" add "$fixture_path"
  printf '%s\n' "$working_tree_content" >"$CASE_DIR/$fixture_path"

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "$label: expected staged-content rejection" >&2
    exit 1
  fi

  case $output in
    *"$expected_message"*"$fixture_path"*) ;;
    *)
      printf '%s\n%s\n' "$label: expected diagnostic and fixture filename" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$fixture_content"*|*"$working_tree_content"*)
      printf '%s\n' "$label: scanner output exposed file content" >&2
      exit 1
      ;;
  esac
}

assert_index_content_accepted() {
  label=$1
  staged_content=$2
  working_tree_content=${3:-$staged_content}

  prepare_case
  printf '%s\n' "$staged_content" >"$CASE_DIR/mutation.txt"
  git -C "$CASE_DIR" add mutation.txt
  printf '%s\n' "$working_tree_content" >"$CASE_DIR/mutation.txt"

  if ! output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n%s\n' "$label: expected scanner acceptance" "$output" >&2
    exit 1
  fi
}

assert_binary_index_rejected() {
  prepare_case
  fixture_path='encoded-payload.bin'
  fixture_secret='ghp_'
  fixture_secret="${fixture_secret}012345678901234567890123456789"
  printf '\000%s\000' "$fixture_secret" >"$CASE_DIR/$fixture_path"
  git -C "$CASE_DIR" add "$fixture_path"
  printf '%s\n' 'safe working tree content' >"$CASE_DIR/$fixture_path"

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "binary index content: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"Tracked binary or NUL-containing files are not allowed:"*"$fixture_path"*) ;;
    *)
      printf '%s\n%s\n' "binary index content: expected redacted binary diagnostic" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$fixture_secret"*)
      printf '%s\n' "binary index content: scanner output exposed matched content" >&2
      exit 1
      ;;
  esac
}

assert_unmerged_index_rejected() {
  prepare_case
  fixture_path='conflicted-input.txt'
  base_object=$(printf '%s' 'base' | git -C "$CASE_DIR" hash-object -w --stdin)
  ours_object=$(printf '%s' 'ours' | git -C "$CASE_DIR" hash-object -w --stdin)
  theirs_object=$(printf '%s' 'theirs' | git -C "$CASE_DIR" hash-object -w --stdin)
  git -C "$CASE_DIR" update-index --force-remove "$fixture_path"
  printf '100644 %s 1\t%s\n100644 %s 2\t%s\n100644 %s 3\t%s\n' \
    "$base_object" "$fixture_path" \
    "$ours_object" "$fixture_path" \
    "$theirs_object" "$fixture_path" |
    git -C "$CASE_DIR" update-index --index-info

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "unmerged index: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"Unmerged Git index entries are not allowed:"*"$fixture_path"*) ;;
    *)
      printf '%s\n%s\n' "unmerged index: expected controlled diagnostic" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$base_object"*|*"$ours_object"*|*"$theirs_object"*)
      printf '%s\n' "unmerged index: scanner output exposed object IDs" >&2
      exit 1
      ;;
  esac
}

assert_newline_runtime_path_rejected() {
  prepare_case
  fixture_path=$(printf 'sample\nclient.py')
  printf '%s\n' "print('private account workflow')" >"$CASE_DIR/$fixture_path"
  git -C "$CASE_DIR" add "$fixture_path"

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "newline runtime path: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"Tracked runtime source files require a complete implementation transition:"*'sample\x{0A}client.py'*) ;;
    *)
      printf '%s\n%s\n' "newline runtime path: expected escaped filename diagnostic" "$output" >&2
      exit 1
      ;;
  esac
}

assert_checkout_boundary_scoped() {
  prepare_case
  perl -0pi -e 's/persist-credentials: false/persist-credentials: true/' \
    "$CASE_DIR/.github/workflows/check.yml"
  cat >>"$CASE_DIR/.github/workflows/check.yml" <<'EOF'

      - name: Credential boundary decoy
        if: ${{ false }}
        run: |
          persist-credentials: false
EOF
  git -C "$CASE_DIR" add .github/workflows/check.yml

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "checkout boundary: expected structural rejection" >&2
    exit 1
  fi

  case $output in
    *"GitHub Actions checkout must set persist-credentials to false in its own with mapping."*) ;;
    *)
      printf '%s\n%s\n' "checkout boundary: expected controlled diagnostic" "$output" >&2
      exit 1
      ;;
  esac

  prepare_case
  perl -0pi -e \
    's#actions/checkout\@df4cb1c069e1874edd31b4311f1884172cec0e10#actions/checkout\@v6#' \
    "$CASE_DIR/.github/workflows/check.yml"
  cat >>"$CASE_DIR/.github/workflows/check.yml" <<'EOF'

      - name: Checkout contract decoy
        run: |
          uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10
          with:
            persist-credentials: false
EOF
  git -C "$CASE_DIR" add .github/workflows/check.yml

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "checkout boundary: expected block-scalar decoy rejection" >&2
    exit 1
  fi

  case $output in
    *"GitHub Actions checkout must set persist-credentials to false in its own with mapping."*) ;;
    *)
      printf '%s\n%s\n' "checkout boundary: expected block-scalar diagnostic" "$output" >&2
      exit 1
      ;;
  esac
}

assert_git_index_failure_rejected() {
  label=$1
  failure_mode=$2
  expected_message=$3

  prepare_case
  mkdir -p "$CASE_DIR/failing-bin"
  cat >"$CASE_DIR/failing-bin/git" <<EOF
#!/usr/bin/env sh
case "\$*" in
  *"$failure_mode"*) exit 2 ;;
esac
exec "$REAL_GIT" "\$@"
EOF
  chmod 755 "$CASE_DIR/failing-bin/git"

  if output=$(PATH="$CASE_DIR/failing-bin:$PATH" \
      "$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "$label: expected fail-closed Git diagnostic" >&2
    exit 1
  fi

  case $output in
    *"$expected_message"*) ;;
    *)
      printf '%s\n%s\n' "$label: expected controlled Git failure diagnostic" "$output" >&2
      exit 1
      ;;
  esac
}

assert_tracked_symlink_rejected() {
  prepare_case
  link_target='../outside/private-credential.txt'
  ln -s "$link_target" "$CASE_DIR/linked-input"
  git -C "$CASE_DIR" add linked-input

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "tracked symlink: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"Tracked symbolic links are not allowed:"*"linked-input"*) ;;
    *)
      printf '%s\n%s\n' "tracked symlink: expected diagnostic and link filename" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$link_target"*)
      printf '%s\n' "tracked symlink: scanner output exposed the link target" >&2
      exit 1
      ;;
  esac
}

assert_tracked_gitlink_rejected() {
  prepare_case
  gitlink_object=$(printf '%s' 'external repository object' |
    git -C "$CASE_DIR" hash-object -w --stdin)
  git -C "$CASE_DIR" update-index --add \
    --cacheinfo "160000,$gitlink_object,external-sample"

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "tracked gitlink: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"Tracked Git submodules are not allowed:"*"external-sample"*) ;;
    *)
      printf '%s\n%s\n' "tracked gitlink: expected diagnostic and indexed path" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$gitlink_object"*)
      printf '%s\n' "tracked gitlink: scanner output exposed the object ID" >&2
      exit 1
      ;;
  esac
}

assert_unapproved_executable_rejected() {
  prepare_case
  fixture_content='run private Ads workflow'
  printf '%s\n' "$fixture_content" >"$CASE_DIR/launch-sample"
  chmod 755 "$CASE_DIR/launch-sample"
  git -C "$CASE_DIR" add launch-sample
  fixture_object=$(git -C "$CASE_DIR" rev-parse :launch-sample)

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "tracked executable: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"Tracked executable files require an explicit readiness allowlist:"*"launch-sample"*) ;;
    *)
      printf '%s\n%s\n' "tracked executable: expected diagnostic and indexed path" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$fixture_content"*|*"$fixture_object"*)
      printf '%s\n' "tracked executable: scanner output exposed content or object ID" >&2
      exit 1
      ;;
  esac
}

assert_tracked_runtime_source_rejected() {
  fixture_path=$1
  fixture_content=$2

  prepare_case
  mkdir -p "$CASE_DIR/$(dirname -- "$fixture_path")"
  printf '%s\n' "$fixture_content" >"$CASE_DIR/$fixture_path"
  git -C "$CASE_DIR" add "$fixture_path"

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "$fixture_path: expected runtime source rejection" >&2
    exit 1
  fi

  case $output in
    *"Tracked runtime source files require a complete implementation transition:"*"$fixture_path"*) ;;
    *)
      printf '%s\n%s\n' "$fixture_path: expected diagnostic and fixture filename" "$output" >&2
      exit 1
      ;;
  esac

  case $output in
    *"$fixture_content"*)
      printf '%s\n' "$fixture_path: scanner output exposed source content" >&2
      exit 1
      ;;
  esac
}

prepare_case
"$CASE_DIR/scripts/check-baseline.sh" >/dev/null

generic_secret='ghp_'
generic_secret="${generic_secret}012345678901234567890123456789"
assert_rejected_without_value \
  "generic secret" \
  "$generic_secret" \
  "Potential secret material detected in:"
assert_rejected_without_value \
  "generic secret in plan" \
  "$generic_secret" \
  "Potential secret material detected in:" \
  "docs/plans/mutation-one.md"

fine_grained_token='github_pat_'
fine_grained_token="${fine_grained_token}abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
assert_rejected_without_value \
  "fine-grained GitHub token" \
  "$fine_grained_token" \
  "Potential secret material detected in:"
assert_rejected_without_value \
  "fine-grained GitHub token in plan" \
  "$fine_grained_token" \
  "Potential secret material detected in:" \
  "docs/plans/mutation-four.md"

aws_session_key='ASIA'
aws_session_key="${aws_session_key}0123456789ABCDEF"
assert_rejected_without_value \
  "AWS session access key" \
  "$aws_session_key" \
  "Potential secret material detected in:"
assert_rejected_without_value \
  "AWS session access key in plan" \
  "$aws_session_key" \
  "Potential secret material detected in:" \
  "docs/plans/mutation-five.md"

aws_static_key='AKIA'
aws_static_key="${aws_static_key}0123456789ABCDEF"
assert_rejected_without_value \
  "AWS static access key" \
  "$aws_static_key" \
  "Potential secret material detected in:"

gitlab_token='glpat-'
gitlab_token="${gitlab_token}abcdefghijklmnopqrstuvwxyz"
assert_rejected_without_value \
  "GitLab personal access token" \
  "$gitlab_token" \
  "Potential secret material detected in:"
assert_rejected_without_value \
  "GitLab personal access token in plan" \
  "$gitlab_token" \
  "Potential secret material detected in:" \
  "docs/plans/mutation-six.md"

google_api_key='AIza'
google_api_key="${google_api_key}0123456789abcdefghijklmnopqrstuvwxy"
assert_rejected_without_value \
  "Google API key" \
  "$google_api_key" \
  "Potential secret material detected in:"
assert_rejected_without_value \
  "Google API key in plan" \
  "$google_api_key" \
  "Potential secret material detected in:" \
  "docs/plans/mutation-seven.md"

assert_index_content_rejected \
  "staged GitHub token hidden by working tree" \
  "$generic_secret" \
  "Potential secret material detected in:"
assert_index_content_rejected \
  "Unicode-delimited staged GitHub token" \
  "é${generic_secret}é" \
  "Potential secret material detected in:"
assert_index_content_accepted \
  "unstaged GitHub token is outside the commit boundary" \
  "safe staged content" \
  "$generic_secret"
assert_index_content_accepted \
  "embedded Google-like identifier is not a standalone key" \
  "prefix${google_api_key}suffix"

bearer_token='bearer '
bearer_token="${bearer_token}abcdefghijklmnopqrstuvwxyz123456"
assert_rejected_without_value \
  "Ads bearer token" \
  "$bearer_token" \
  "Potential Ads API, GNIP, or bearer token material detected in:"
assert_rejected_without_value \
  "Ads bearer token in plan" \
  "$bearer_token" \
  "Potential Ads API, GNIP, or bearer token material detected in:" \
  "docs/plans/mutation-two.md"

account_context='ADS_ACCOUNT_ID='
account_context="${account_context}123456789"
assert_rejected_without_value \
  "Ads account context" \
  "$account_context" \
  "Potential populated Ads account context detected in:"
assert_rejected_without_value \
  "Ads account context in plan" \
  "$account_context" \
  "Potential populated Ads account context detected in:" \
  "docs/plans/mutation-three.md"

assert_tracked_symlink_rejected
assert_tracked_gitlink_rejected
assert_unapproved_executable_rejected
assert_tracked_runtime_source_rejected "sample/client.py" "print('private account workflow')"
assert_tracked_runtime_source_rejected "sample/client.js" "throw new Error('private token workflow')"
assert_binary_index_rejected
assert_unmerged_index_rejected
assert_newline_runtime_path_rejected
assert_checkout_boundary_scoped
assert_git_index_failure_rejected \
  "Git index metadata failure" \
  "ls-files -z --stage" \
  "Git index metadata scan failed safely."
assert_git_index_failure_rejected \
  "Git index content failure" \
  "grep --cached" \
  "Git index content scan failed safely."

printf '%s\n' "Readiness scanner regression tests passed."
