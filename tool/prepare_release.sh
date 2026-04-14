#!/usr/bin/env sh
# Prepare a release PR: changelog (per CLAUDE.md), pubspec + Constants version, format, commit, gh pr.
# Usage: ./tool/prepare_release.sh <x.y.z>
# Requires: git, gh, dart, awk; run from repo root (script cds to repo root).

set -eu

# Resolve repository root and run from it.
ROOT="$(CDPATH='' cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Release-managed file paths
CHANGELOG_PATH="CHANGELOG.md"
PUBSPEC_PATH="pubspec.yaml"
CONSTANTS_PATH="lib/src/misc/constants.dart"
CHANGELOG_REWRITE_SCRIPT="$ROOT/tool/rewrite_changelog_for_release.sh"

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

# Block when release-managed files already have local edits.
if [ -n "$(git status --porcelain -- "$CHANGELOG_PATH" "$PUBSPEC_PATH" "$CONSTANTS_PATH" 2>/dev/null)" ]; then
  echo "error: release-managed files have local changes; commit or stash:" >&2
  echo "  - $CHANGELOG_PATH" >&2
  echo "  - $PUBSPEC_PATH" >&2
  echo "  - $CONSTANTS_PATH" >&2
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
  --body "Prepare release **${VERSION}**: changelog section, \`pubspec.yaml\` version, and \`Constants.version\`.

Merge after review; tag and publish separately when ready."

echo "Created branch ${BRANCH} and opened a PR."
