#!/usr/bin/env sh
# Prepare a release PR: changelog (per CLAUDE.md), pubspec + Constants version, format, commit, gh pr.
# Usage: ./tool/prepare_release.sh <x.y.z>
# Requires: git, gh, dart, awk; run from repo root (script cds to repo root).

set -eu

ROOT="$(CDPATH='' cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <x.y.z>" >&2
  exit 2
fi
VERSION="$1"

echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
  echo "error: version must be semver x.y.z (e.g. 1.3.0)" >&2
  exit 2
}

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "error: working tree is not clean; commit or stash first." >&2
  exit 1
fi

if ! head -1 docs/CHANGELOG.md | grep -q '^## Upcoming$'; then
  echo "error: docs/CHANGELOG.md must start with ## Upcoming" >&2
  exit 1
fi

BRANCH="chore/release-${VERSION}"
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  echo "error: branch ${BRANCH} already exists." >&2
  exit 1
fi

git checkout -b "$BRANCH"

"$ROOT/tool/rewrite_changelog_for_release.sh" "$VERSION" \
  "$ROOT/docs/CHANGELOG.md" "$ROOT/docs/CHANGELOG.md"

sed "s/^version: .*/version: ${VERSION}/" pubspec.yaml > pubspec.yaml.tmp
mv pubspec.yaml.tmp pubspec.yaml

sed -E "s/(static const version = ')[^']+(')/\\1${VERSION}\\2/" \
  lib/src/misc/constants.dart > lib/src/misc/constants.dart.tmp
mv lib/src/misc/constants.dart.tmp lib/src/misc/constants.dart

dart format docs/CHANGELOG.md pubspec.yaml lib/src/misc/constants.dart

if ! dart analyze --fatal-infos --fatal-warnings . >/dev/null; then
  echo "error: dart analyze failed; fix issues and retry." >&2
  exit 1
fi

git add docs/CHANGELOG.md pubspec.yaml lib/src/misc/constants.dart
git commit -m "chore: prepare release ${VERSION}"

git push -u origin "$BRANCH"

gh pr create \
  --title "chore: release ${VERSION}" \
  --body "Prepare release **${VERSION}**: changelog section, \`pubspec.yaml\` version, and \`Constants.version\`.

Merge after review; tag and publish separately when ready."

echo "Created branch ${BRANCH} and opened a PR."
