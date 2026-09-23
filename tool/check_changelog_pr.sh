#!/usr/bin/env sh
# Verify a PR updates ## Upcoming in CHANGELOG.md.
#
# Upcoming is the draft for the next release: keep it user-facing and
# consolidate unshipped work (edit/merge existing bullets). Do not append a
# "fix feature A" line for something that never shipped.
#
# Usage:
#   ./tool/check_changelog_pr.sh [<base-ref>]
#
# Exempt: branches chore/release-* (prepare_release.sh rewrites Upcoming).

set -eu

ROOT="$(CDPATH='' cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CHANGELOG="CHANGELOG.md"
BASE_REF="${1:-${GITHUB_BASE_REF:-main}}"
case "$BASE_REF" in
  main | master) BASE_REF="origin/$BASE_REF" ;;
esac

BRANCH="${GITHUB_HEAD_REF:-$(git branch --show-current)}"
case "$BRANCH" in
  chore/release-*)
    echo "skip: release branch $BRANCH (changelog rewritten by prepare_release.sh)"
    exit 0
    ;;
esac

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  git fetch origin "${BASE_REF#origin/}" --depth=1 2>/dev/null || git fetch origin main --depth=50
fi

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "error: base ref $BASE_REF not found" >&2
  exit 1
fi

if ! git cat-file -e "$BASE_REF:$CHANGELOG" 2>/dev/null; then
  echo "error: $CHANGELOG missing on $BASE_REF" >&2
  exit 1
fi

extract_upcoming_from_git() {
  git show "$1:$CHANGELOG" | awk '
    BEGIN { in_up = 0 }
    /^## Upcoming$/ { in_up = 1; next }
    in_up && /^## [0-9]+\.[0-9]+\.[0-9]+/ { exit }
    in_up && /^## / { exit }
    in_up && NF { print }
  '
}

extract_upcoming_from_file() {
  awk '
    BEGIN { in_up = 0 }
    /^## Upcoming$/ { in_up = 1; next }
    in_up && /^## [0-9]+\.[0-9]+\.[0-9]+/ { exit }
    in_up && /^## / { exit }
    in_up && NF { print }
  ' "$CHANGELOG"
}

BASE_LINES="$(extract_upcoming_from_git "$BASE_REF" || true)"
HEAD_LINES="$(extract_upcoming_from_file || true)"

if [ -z "$HEAD_LINES" ] && [ -n "$BASE_LINES" ]; then
  echo "error: $CHANGELOG ## Upcoming has no entries on this branch." >&2
  echo "Keep user-facing bullets for unshipped work, or ship a release first." >&2
  exit 1
fi

if [ "$HEAD_LINES" = "$BASE_LINES" ]; then
  echo "error: $CHANGELOG ## Upcoming was not updated in this PR." >&2
  echo "Edit Upcoming for the user-visible change (add, merge, or rewrite bullets)." >&2
  exit 1
fi

BAD="$(printf '%s\n' "$HEAD_LINES" | grep -v '^- ' || true)"
if [ -n "$BAD" ]; then
  echo "error: every Upcoming line must be a bullet starting with \"- \"" >&2
  printf '%s\n' "$BAD" | sed 's/^/  /' >&2
  exit 1
fi

HEAD_COUNT="$(printf '%s\n' "$HEAD_LINES" | wc -l | tr -d ' ')"
echo "ok: ## Upcoming updated ($HEAD_COUNT bullet$( [ "$HEAD_COUNT" = 1 ] && echo '' || echo s ))"
