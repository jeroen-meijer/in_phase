#!/usr/bin/env sh
# Sanity checks before publish (see .github/workflows/publish.yml).
#
# PR merge path (env from Actions):
#   RELEASE_EVENT=pull_request
#   RELEASE_MERGED=true
#   RELEASE_PR_LABELS=release,...
#   RELEASE_HEAD_REF=chore/release-1.2.3
#   RELEASE_SHA=<merge commit>

set -eu

ROOT="$(CDPATH='' cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

semver_ok() {
  printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
}

pubspec_version() {
  awk '/^version: / { print $2; exit }' pubspec.yaml
}

constants_version() {
  sed -n "s/.*static const version = '\([^']*\)'.*/\1/p" lib/src/misc/constants.dart | head -n 1
}

changelog_has_version() {
  ver="$1"
  awk -v v="$ver" '
    $0 == "## " v { found = 1; exit }
    END { exit !found }
  ' CHANGELOG.md
}

remote_tag_sha() {
  ver="$1"
  git ls-remote --tags origin "refs/tags/${ver}" 2>/dev/null | awk '{print $1}' | head -1
}

short_sha() {
  printf '%.7s' "$1"
}

EVENT="${RELEASE_EVENT:-}"
SHA="${RELEASE_SHA:-}"

case "$EVENT" in
  pull_request)
    if [ "${RELEASE_MERGED:-}" != "true" ]; then
      echo "error: pull request was closed without merge" >&2
      exit 1
    fi
    case_labels="${RELEASE_PR_LABELS:-}"
    if ! printf '%s' "$case_labels" | tr ',' '\n' | grep -qx 'release'; then
      echo "error: merged PR must have the release label" >&2
      exit 1
    fi
    HEAD_REF="${RELEASE_HEAD_REF:-}"
    case "$HEAD_REF" in
      chore/release-*)
        BRANCH_VERSION="${HEAD_REF#chore/release-}"
        ;;
      *)
        echo "error: release PR branch must be chore/release-x.y.z (got: $HEAD_REF)" >&2
        exit 1
        ;;
    esac
    if ! semver_ok "$BRANCH_VERSION"; then
      echo "error: invalid version in branch name: $BRANCH_VERSION" >&2
      exit 1
    fi
    VERSION="$BRANCH_VERSION"
    if [ -z "$SHA" ]; then
      echo "error: RELEASE_SHA (merge commit) is required" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: unsupported RELEASE_EVENT: $EVENT (expected pull_request)" >&2
    exit 1
    ;;
esac

git fetch origin main --tags

if ! git merge-base --is-ancestor "$SHA" origin/main; then
  echo "error: commit $SHA is not on origin/main" >&2
  exit 1
fi

git checkout --force "$SHA"

PUBSPEC="$(pubspec_version)"
if [ "$PUBSPEC" != "$VERSION" ]; then
  echo "error: pubspec.yaml version ($PUBSPEC) does not match release version ($VERSION)" >&2
  exit 1
fi

CONSTANTS="$(constants_version)"
if [ "$CONSTANTS" != "$VERSION" ]; then
  echo "error: Constants.version ($CONSTANTS) does not match release version ($VERSION)" >&2
  exit 1
fi

if ! changelog_has_version "$VERSION"; then
  echo "error: CHANGELOG.md has no ## $VERSION section" >&2
  exit 1
fi

EXISTING_TAG_SHA="$(remote_tag_sha "$VERSION" || true)"
if [ -n "$EXISTING_TAG_SHA" ]; then
  if [ "$EXISTING_TAG_SHA" != "$SHA" ]; then
    echo "error: tag $VERSION already points to $(short_sha "$EXISTING_TAG_SHA"), expected $(short_sha "$SHA")" >&2
    exit 1
  fi
  echo "note: tag $VERSION already exists at this commit (retry-safe)"
fi

if gh release view "$VERSION" >/dev/null 2>&1; then
  echo "error: GitHub release $VERSION already exists; remove it before retrying this publish if needed" >&2
  exit 1
fi

echo "version=$VERSION" >> "${GITHUB_OUTPUT:-/dev/stdout}"
echo "sha=$SHA" >> "${GITHUB_OUTPUT:-/dev/stdout}"
echo "tag=$VERSION" >> "${GITHUB_OUTPUT:-/dev/stdout}"
echo "ok: release $VERSION at $(short_sha "$SHA")"
