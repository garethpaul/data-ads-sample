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

  prepare_case
  printf '%s\n' "$fixture_content" >"$CASE_DIR/mutation.txt"
  git -C "$CASE_DIR" add mutation.txt

  if output=$("$CASE_DIR/scripts/check-baseline.sh" 2>&1); then
    printf '%s\n' "$label: expected scanner rejection" >&2
    exit 1
  fi

  case $output in
    *"$expected_message"*"mutation.txt"*) ;;
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

prepare_case
"$CASE_DIR/scripts/check-baseline.sh" >/dev/null

generic_secret='ghp_'
generic_secret="${generic_secret}012345678901234567890123456789"
assert_rejected_without_value \
  "generic secret" \
  "$generic_secret" \
  "Potential secret material detected in:"

bearer_token='bearer '
bearer_token="${bearer_token}abcdefghijklmnopqrstuvwxyz123456"
assert_rejected_without_value \
  "Ads bearer token" \
  "$bearer_token" \
  "Potential Ads API, GNIP, or bearer token material detected in:"

account_context='ADS_ACCOUNT_ID='
account_context="${account_context}123456789"
assert_rejected_without_value \
  "Ads account context" \
  "$account_context" \
  "Potential populated Ads account context detected in:"

printf '%s\n' "Readiness scanner regression tests passed."
