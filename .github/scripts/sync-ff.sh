#!/usr/bin/env bash
# Fast-forwards the mirror's main to $1 and pushes. Re-checks the target so an
# approval granted hours ago cannot silently apply to a newer revision.
set -euo pipefail

target="$1"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/AnoshanJ/echo-core.git}"

git remote add upstream "$UPSTREAM_URL" 2>/dev/null || git remote set-url upstream "$UPSTREAM_URL"
git fetch --no-tags upstream main

now=$(git rev-parse upstream/main)
if [ "$now" != "$target" ]; then
  echo "::error::upstream moved since this run was planned (${target:0:12} -> ${now:0:12}); re-run so the decision covers the current revision"
  exit 1
fi

git merge --ff-only "$target"
git push origin main
echo "fast-forwarded main to ${target:0:12}"
