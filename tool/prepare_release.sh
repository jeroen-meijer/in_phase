#!/usr/bin/env sh
# Prepare a release PR: changelog (per CLAUDE.md), pubspec + Constants version, format, commit, gh pr.
# Usage: ./tool/prepare_release.sh <x.y.z>
# Requires: git, gh, dart, awk; run from repo root (script cds to repo root).
#
# Opens a PR labeled "release". Squash-merge to main triggers publish; the workflow
# publishes to pub.dev, creates a GitHub release, and tags the merge commit after success.

set -eu

# Resolve repository root and run from it.
ROOT="$(CDPATH='' cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Release-managed file paths
CHANGELOG_PATH="CHANGELOG.md"
PUBSPEC_PATH="pubspec.yaml"
CONSTANTS_PATH="lib/src/misc/constants.dart"
CHANGELOG_REWRITE_SCRIPT="$ROOT/tool/rewrite_changelog_for_release.sh"
RELEASE_LABEL="release"

# Read and validate the required release version argument.
if [ "$#" -ne 1 ]; then
  echo "usage: $0 <x.y.z>" >&2
  exit 2
fi
VERSION="$1"

echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
  echo "error: version must be semver x.y.z (e.g. 1.3.0)" >&2
  exit 2
}

git fetch origin main --tags

if git ls-remote --exit-code --tags origin "refs/tags/${VERSION}" >/dev/null 2>&1; then
  echo "error: tag ${VERSION} already exists on origin." >&2
  exit 1
fi

if gh release view "$VERSION" >/dev/null 2>&1; then
  echo "error: GitHub release ${VERSION} already exists." >&2
  exit 1
fi

if ! gh label list --json name --jq '.[].name' | grep -qx "$RELEASE_LABEL"; then
  echo "error: GitHub label \"${RELEASE_LABEL}\" not found. Create it in the repo first." >&2
  exit 1
fi

# Create a dedicated release branch.
BRANCH="chore/release-${VERSION}"
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "error: branch ${BRANCH} already exists." >&2
  exit 1
fi

git checkout -b "$BRANCH"

# Rewrite changelog headings for the new release section.
"$CHANGELOG_REWRITE_SCRIPT" "$VERSION" \
  "$ROOT/$CHANGELOG_PATH" "$ROOT/$CHANGELOG_PATH"

# Update package version in pubspec.
sed "s/^version: .*/version: ${VERSION}/" "$PUBSPEC_PATH" > "${PUBSPEC_PATH}.tmp"
mv "${PUBSPEC_PATH}.tmp" "$PUBSPEC_PATH"

# Update runtime version constant.
sed -E "s/(static const version = ')[^']+(')/\\1${VERSION}\\2/" \
  "$CONSTANTS_PATH" > "${CONSTANTS_PATH}.tmp"
mv "${CONSTANTS_PATH}.tmp" "$CONSTANTS_PATH"

# Format touched Dart files.
dart format "$CONSTANTS_PATH"

# Run analyzer as a final release-prep gate.
if ! dart analyze --fatal-infos --fatal-warnings . >/dev/null; then
  echo "error: dart analyze failed; fix issues and retry." >&2
  exit 1
fi

# Commit release-prep file updates.
git add "$CHANGELOG_PATH" "$PUBSPEC_PATH" "$CONSTANTS_PATH"
git commit -m "chore: prepare release ${VERSION}"

# Push branch and open a release PR.
git push -u origin "$BRANCH"

gh pr create \
  --title "chore: release ${VERSION}" \
  --label "$RELEASE_LABEL" \
  --body "Prepare release **${VERSION}**: changelog section, \`pubspec.yaml\` version, and \`Constants.version\`.

Merge with **squash** after CI passes. Merging this PR (with the \`${RELEASE_LABEL}\` label) publishes to pub.dev, creates a GitHub release, and tags \`main\` with \`${VERSION}\`.
"

echo "Created branch ${BRANCH} and opened a release PR (label: ${RELEASE_LABEL})."
