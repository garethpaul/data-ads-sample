#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
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

printf '%s\n' "Readiness scanner regression tests passed."
