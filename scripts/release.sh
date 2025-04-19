#!/bin/bash
set -e

# Script to handle the Git commit and tagging part of a release.
# Takes one argument: the bump type (major, minor, patch).

BUMP_TYPE="$1"

if [[ -z "$BUMP_TYPE" ]]; then
  echo "Error: Bump type (major, minor, patch) argument is required." >&2
  exit 1
fi

echo "Running Python release script for $BUMP_TYPE bump..."
# Capture stdout (the version) and handle potential errors from the python script
NEW_VERSION=$(uv run python scripts/release.py "$BUMP_TYPE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "Error: Python release script failed." >&2
    echo "$NEW_VERSION" >&2 # Print potential error message from python script
    exit $EXIT_CODE
elif [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Failed to get valid new version from release script. Output: $NEW_VERSION" >&2
    exit 1
fi

echo "Staging release files for v$NEW_VERSION..."
git add pyproject.toml CHANGELOG.md

echo "Committing release v$NEW_VERSION..."
# Allow commit hook to run
git commit -m "[ops] Release v$NEW_VERSION"
COMMIT_EXIT_CODE=$?
if [ $COMMIT_EXIT_CODE -ne 0 ]; then
    echo "Commit failed, check hooks or conflicts." >&2
    # Attempt to reset staged files if commit failed
    git reset HEAD pyproject.toml CHANGELOG.md > /dev/null 2>&1
    exit $COMMIT_EXIT_CODE
fi

echo "Tagging release v$NEW_VERSION..."
git tag "v$NEW_VERSION"
TAG_EXIT_CODE=$?
if [ $TAG_EXIT_CODE -ne 0 ]; then
    echo "Tag creation failed." >&2
    # Attempt to delete the failed commit if tag failed
    git reset --hard HEAD~1 > /dev/null 2>&1
    exit $TAG_EXIT_CODE
fi

echo "Release v$NEW_VERSION prepared. Run 'make push-tags' to publish."
