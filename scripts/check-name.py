#!/usr/bin/env python3
import re
import sys
import os
import subprocess

BRANCH_RE = re.compile(r'^(feat|fix|refactor|ops|docs)/')
COMMIT_RE = re.compile(r'^(feat|fix|refactor|ops|docs)\[')
is_invalid = False

# Helper function to run shell commands silently and return output
def run_cmd(cmd):
    return subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True).stdout.strip()

def record_failure(check_type, value):
  """Prints an error message and sets the global invalid flag."""
  global is_invalid
  print(f'[POLICY] Invalid {check_type}: {value.splitlines()[0]}', file=sys.stderr)
  is_invalid = True

script_args = sys.argv[1:]
check_branch = '-b' in script_args or '--check-branch' in script_args
check_commit = '-c' in script_args or '--check-commit' in script_args
check_push   = '-p' in script_args or '--check-push' in script_args

project_root = run_cmd('git rev-parse --show-toplevel')
if not project_root:
  print("[POLICY] Error: Not a git repository?", file=sys.stderr)
  sys.exit(1)

# Determine commit message file path, defaulting if checking commit
commit_msg_file = None
if '--commit-msg-file' in script_args:
  try:
    commit_msg_file = script_args[script_args.index('--commit-msg-file') + 1]
  except IndexError:
    print("[POLICY] Error: --commit-msg-file flag requires an argument.", file=sys.stderr)
    is_invalid = True
elif check_commit:
  commit_msg_file = os.path.join(project_root, '.git', 'COMMIT_EDITMSG')

# Get current branch and check if it's protected
current_branch = run_cmd('git rev-parse --abbrev-ref HEAD')
is_protected_branch = current_branch in ('main', 'dev', 'HEAD')

# 1. Check Branch Name (if checking branch or push, and not protected)
if (check_branch or check_push) and not is_protected_branch:
  if not BRANCH_RE.match(current_branch):
    record_failure('branch name', current_branch)

# 2. Check Commit Message (if checking commit)
if check_commit:
  if commit_msg_file and os.path.exists(commit_msg_file):
    try:
      with open(commit_msg_file, 'r', encoding='utf-8') as f:
        commit_msg = f.read().strip()
      # Only fail if the message is not empty and doesn't match the pattern
      if commit_msg and not COMMIT_RE.match(commit_msg):
        record_failure('commit message format', commit_msg)
    except Exception as e:
      print(f"[POLICY] Error reading {commit_msg_file}: {e}", file=sys.stderr)
      is_invalid = True
  # Silently skip if file missing (e.g. interactive rebase) or path not determined

# 3. Check Pre-push Commit Format (if checking push, and not protected)
if check_push and not is_protected_branch:
  # Determine commit range (try upstream, fallback to HEAD~1)
  upstream_ref = run_cmd("git rev-parse --abbrev-ref --symbolic-full-name '@{u}'") or 'HEAD~1'
  # Get log of commit messages in the range
  commit_log = run_cmd(f"git log {upstream_ref}..HEAD --pretty=%B")
  # Validate each non-empty commit message
  for i, commit_text in enumerate([msg for msg in commit_log.split('\n\n\n') if msg.strip()]):
    if not COMMIT_RE.match(commit_text):
      record_failure(f'pushed commit #{i+1} format', commit_text)

if is_invalid:
  print('[POLICY] Failed', file=sys.stderr)
  sys.exit(1)
sys.exit(0)
