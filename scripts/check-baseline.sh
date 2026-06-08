#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT_DIR/README.md"
VISION="$ROOT_DIR/VISION.md"
SECURITY="$ROOT_DIR/SECURITY.md"
PLAN="$ROOT_DIR/docs/plans/2026-06-08-repository-readiness-baseline.md"
CHANGES="$ROOT_DIR/CHANGES.md"

require_file() {
  path=$1
  if [ ! -f "$ROOT_DIR/$path" ]; then
    printf '%s\n' "Required file is missing: $path" >&2
    exit 1
  fi
}

for path in \
  ".gitignore" \
  "CHANGES.md" \
  "README.md" \
  "SECURITY.md" \
  "VISION.md" \
  "docs/readme-overview.svg" \
  "docs/plans/2026-06-08-repository-readiness-baseline.md" \
  "scripts/check-baseline.sh"; do
  require_file "$path"
done

for ignored in ".env" ".env.*" "!.env.example" "*.local" "*.pem" "*.key" "data/private/" "data/exports/" "*.sqlite" "*.db"; do
  if ! grep -Fq "$ignored" "$ROOT_DIR/.gitignore"; then
    printf '%s\n' ".gitignore must include $ignored" >&2
    exit 1
  fi
done

tracked_sensitive=$(git -C "$ROOT_DIR" ls-files | grep -Ei '(^|/)(\.env(\.|$)|.*\.(pem|key)|.*(secret|credential|token).*|data/(private|exports)/|.*\.(sqlite|db)$)' || true)
if [ -n "$tracked_sensitive" ]; then
  printf '%s\n%s\n' "Potential credential or private-data files are tracked:" "$tracked_sensitive" >&2
  exit 1
fi

secret_content=$(rg -n --hidden \
  --glob '!**/.git/**' \
  --glob '!docs/plans/**' \
  --glob '!scripts/check-baseline.sh' \
  'AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z ]+)?PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]+|gh[pousr]_[A-Za-z0-9_]{30,}' \
  "$ROOT_DIR" || true)
if [ -n "$secret_content" ]; then
  printf '%s\n%s\n' "Potential secret material detected:" "$secret_content" >&2
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

if ! grep -Fq "credentials out of git" "$VISION"; then
  printf '%s\n' "VISION.md must keep future credentials out of git." >&2
  exit 1
fi

if ! grep -Fq "documentation-only" "$VISION"; then
  printf '%s\n' "VISION.md must describe the current documentation-only repository state." >&2
  exit 1
fi

if ! grep -Fq "No primary dependency manifest was detected" "$SECURITY"; then
  printf '%s\n' "SECURITY.md must describe the current no-dependency baseline." >&2
  exit 1
fi

if ! grep -Fq "repository readiness baseline" "$CHANGES"; then
  printf '%s\n' "CHANGES.md must record the repository readiness baseline." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PLAN"; then
  printf '%s\n' "Plan must be marked completed." >&2
  exit 1
fi

printf '%s\n' "Data Ads Sample readiness baseline checks passed."
