#!/usr/bin/env sh
set -eu

exp=${1:-main}
curr=$(git rev-parse --abbrev-ref HEAD)
printf "⏳ verifying branch '%s'..." "$exp"
if [ "$curr" = "$exp" ]; then
  printf "✔ branch '%s' OK    \n" "$curr"
else
  printf "❌ branch '%s' (expected '%s')\n" "$curr" "$exp" >&2
  exit 1
fi
exit 0
