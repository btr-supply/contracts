"""
SPDX-License-Identifier: MIT
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@/         '@@@@/            /@@@/         '@@@@@@@@
@@@@@@@@/    /@@@    @@@@@@/    /@@@@@@@/    /@@@    @@@@@@@
@@@@@@@/           _@@@@@@/    /@@@@@@@/    /.     _@@@@@@@@
@@@@@@/    /@@@    '@@@@@/    /@@@@@@@/    /@@    @@@@@@@@@@
@@@@@/            ,@@@@@/    /@@@@@@@/    /@@@,    @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@title Release Helper Script - Automates version bumping and changelog generation
@copyright 2025
@notice Python script to increment the project version in uv.toml, update CHANGELOG.md based on commit messages since the
last tag, and clean up local git tags

@dev Requires specific commit message prefixes (e.g., [feat], [fix]) for changelog generation
@author BTR Team
"""

#!/usr/bin/env python
import argparse
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
import toml

# --- Configuration ---
PYPROJECT_PATH = Path("pyproject.toml")
CHANGELOG_PATH = Path("CHANGELOG.md")
COMMIT_PREFIX_MAP = {
    "[feat]": "Features",
    "[fix]": "Fixes",
    "[refac]": "Refactors",
    "[ops]": "Ops",
    "[docs]": "Docs",
}
CHANGELOG_HEADER = """# BTR Contracts Changelog

All changes documented here, based on [Keep a Changelog](https://keepachangelog.com).
See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

NB: [Auto-generated from commits](./scripts/release.py) - DO NOT EDIT.

"""


def run_cmd(command):
  """Helper to run shell commands."""
  try:
    return subprocess.run(command,
                          shell=True,
                          check=True,
                          capture_output=True,
                          text=True).stdout.strip()
  except subprocess.CalledProcessError as e:
    sys.exit(f"Error: {e.stderr}")


def get_current_version():
  """Reads the current version from pyproject.toml."""
  return toml.load(PYPROJECT_PATH)["project"]["version"]


def cleanup_dangling_tags(current_version):
  """Remove local git tags that don't exist on remote."""
  print("🧹 Cleaning up dangling git tags...")
  local_tags = set(re.findall(r"v(\d+\.\d+\.\d+)", run_cmd('git tag -l "v*"')))
  remote_tags = set(
      re.findall(r"refs/tags/v(\d+\.\d+\.\d+)",
                 run_cmd("git ls-remote --tags origin")))
  local_only = local_tags - remote_tags
  if not local_only:
    print("✔️ No dangling tags found")
    return
  print(
      f"🗑️ Removing {len(local_only)} local-only tag(s): {', '.join(sorted(f'v{t}' for t in local_only if t != current_version))}"
  )
  for tag_ver in local_only:
    if tag_ver != current_version:
      run_cmd(f"git tag -d v{tag_ver}")


def calculate_new_version(current, bump_type):
  """Calculates the new version based on bump type or explicit version."""
  major, minor, patch = map(int, current.split("."))
  return {
      "major": f"{major+1}.0.0",
      "minor": f"{major}.{minor+1}.0",
      "patch": f"{major}.{minor}.{patch+1}",
  }[bump_type]


def update_pyproject_toml(new_version):
  """Update version in pyproject.toml."""
  print(f"📦 Updating {PYPROJECT_PATH} to version {new_version}...")
  config = toml.load(PYPROJECT_PATH)
  config["project"]["version"] = new_version
  with open(PYPROJECT_PATH, "w") as f:
    toml.dump(config, f)


def update_changelog(new_version):
  """Update CHANGELOG.md with commit history."""
  print(f"📝 Updating {CHANGELOG_PATH} for version {new_version}...")
  content = CHANGELOG_PATH.read_text() if CHANGELOG_PATH.exists() else ""

  # Strip header up to first version tag
  versions = re.split(r"(?=^## \[\d+\.\d+\.\d+\])", content, flags=re.M)
  cleaned = [v for v in versions if not v.startswith(f"## [{new_version}]")]

  # Get commits since last tag
  last_tag = run_cmd("git describe --tags --abbrev=0 2>/dev/null || echo")
  commits = (run_cmd(f'git log {last_tag}..HEAD --pretty=format:"%s"')
             if last_tag else "")

  # Categorize commits
  changes = {cat: [] for cat in COMMIT_PREFIX_MAP.values()}
  for commit in commits.split("\n"):
    for prefix, cat in COMMIT_PREFIX_MAP.items():
      if commit.lower().startswith(prefix.lower()):
        msg = re.sub(f"^{prefix}\s*", "", commit, flags=re.I).strip()
        if msg:
          changes[cat].append(msg[0].upper() + msg[1:])
        break

  # Build new entry
  entry = [f"## [{new_version}] - {datetime.now().strftime('%Y-%m-%d')}"]
  for cat, msgs in changes.items():
    if msgs:
      entry += [f"\n### {cat}"] + [f"- {m}" for m in sorted(msgs)]

  new_content = "\n".join([CHANGELOG_HEADER, "\n".join(entry), "\n"] +
                          cleaned[1:])
  CHANGELOG_PATH.write_text(new_content)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("bump",
                      choices=["major", "minor", "patch"],
                      default="minor",
                      nargs="?")
  args = parser.parse_args()

  current = get_current_version()
  print(f"📦 Current version: {current}")

  cleanup_dangling_tags(current)

  new_version = calculate_new_version(current, args.bump)

  if new_version == current:
    print(f"Version {current} is already up to date. Exiting.")
    print(new_version)  # Output the version even if unchanged
    sys.exit(0)

  print(f"🔖 Bumping version from {current} to {new_version}")

  update_pyproject_toml(new_version)
  update_changelog(new_version)

  # Optional: post-versioning tasks could go here

  print(f"✔️ Successfully updated version to {new_version}")
  print(new_version)  # Output the new version for potential scripting use


if __name__ == "__main__":
  main()
