#!/usr/bin/env bash
# Classifies the mirror against upstream. Writes action/target to GITHUB_OUTPUT.
set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/AnoshanJ/echo-core.git}"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"

git remote add upstream "$UPSTREAM_URL" 2>/dev/null || git remote set-url upstream "$UPSTREAM_URL"
git fetch --no-tags upstream main

mine=$(git rev-parse HEAD)
theirs=$(git rev-parse upstream/main)
base=$(git merge-base HEAD upstream/main)

if [ "$mine" = "$theirs" ]; then
  action=in-sync
  note="Already in sync at \`${mine:0:12}\`."
elif [ "$base" = "$theirs" ]; then
  action=ahead
  note="Mirror is **ahead** of upstream — an undisclosed fix is in flight. Nothing to sync."
elif [ "$base" = "$mine" ]; then
  action=fast-forward
  note="Mirror can fast-forward \`${mine:0:12}\` → \`${theirs:0:12}\`."
else
  action=diverged
  note="Mirror has **diverged** from upstream (base \`${base:0:12}\`). A human must reconcile."
fi

{ echo "action=$action"; echo "target=$theirs"; } >> "$OUT"
{ echo "### sync-upstream: $action"; echo; echo "$note"; } >> "$SUMMARY"
echo "$action: $note"

[ "$action" = diverged ] && exit 1
exit 0
