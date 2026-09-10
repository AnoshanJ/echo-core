#!/usr/bin/env bash
# Proves the core UI renders standalone and carries no cloud functionality.
set -euo pipefail

cd "$(dirname "$0")/frontend"

MODE=source
[[ "${1:-}" == "--docker" ]] && MODE=docker

PNPM="${PNPM:-corepack pnpm}"
PORT=8181
BASE="http://127.0.0.1:${PORT}"
IMAGE=echo-core-ui:verify
CID=""

declare -a RESULTS=()
FAILED=0

cleanup() {
  [[ -n "$CID" ]] && docker rm -f "$CID" >/dev/null 2>&1 || true
  return 0
}
trap cleanup EXIT

record() { RESULTS+=("$1|$2|$3"); [[ "$1" == FAIL ]] && FAILED=1; return 0; }

has() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    record PASS "$name" "$needle"
  else
    record FAIL "$name" "expected to contain [${needle}]"
  fi
}

lacks() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    record FAIL "$name" "unexpectedly contains [${needle}]"
  else
    record PASS "$name" "absent"
  fi
}

$PNPM install --frozen-lockfile >/dev/null
$PNPM build >/dev/null
$PNPM build:demo >/dev/null

[[ -f dist/index.js && -f dist/index.d.ts ]] \
  && record PASS "lib builds js + types" "dist/index.js, dist/index.d.ts" \
  || record FAIL "lib builds js + types" "missing dist artifact"

ROOT=$(node verify/render.mjs "/?msg=hello")
MISS=$(node verify/render.mjs "/reverse?msg=hello")

has   "core renders standalone"  "echo-core-ui"            "$ROOT"
has   "core echo unmodified"     "source:core"             "$ROOT"
has   "core echoes the message"  "msg:hello"               "$ROOT"
has   "public-ui-feat1 present"  "public-ui-feat1"         "$ROOT"
lacks "no cloud marker"          "private-ui-feat-1"       "$ROOT"
lacks "no cloud panel injected"  "cloud-banner"            "$ROOT"
has   "cloud route absent"       "not-found"               "$MISS"

BUNDLE=$(cat demo-dist/assets/*.js)
has   "bundle carries core marker" "public-ui-feat1"   "$BUNDLE"
lacks "bundle has no cloud marker" "private-ui-feat-1" "$BUNDLE"

# The real repo ships a stale -ldflags path that silently never injects, so
# assert the value is a real commit rather than the placeholder.
COMMIT=$(sed -n 's/.*core:[^+]*+\([0-9a-f]\{40\}\).*/\1/p' <<<"$ROOT")
if [[ -n "$COMMIT" ]]; then
  record PASS "CORE_BUILD commit injected" "$COMMIT"
else
  record FAIL "CORE_BUILD commit injected" "placeholder or missing"
fi

if [[ "$MODE" == docker ]]; then
  docker build --build-arg "CORE_COMMIT=$(git rev-parse HEAD)" -t "$IMAGE" . >/dev/null
  CID=$(docker run -d -p "${PORT}:8080" "$IMAGE")
  for _ in $(seq 1 50); do
    curl -fsS "$BASE/" >/dev/null 2>&1 && break
    sleep 0.2
  done
  code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/")
  [[ "$code" == 200 ]] \
    && record PASS "image serves the app" "200" \
    || record FAIL "image serves the app" "got $code"

  asset=$(curl -fsS "$BASE/" | sed -n 's/.*src="\([^"]*\.js\)".*/\1/p' | head -1)
  served=$(curl -fsS "${BASE}${asset}")
  has   "served bundle carries core marker" "public-ui-feat1"   "$served"
  lacks "served bundle has no cloud marker" "private-ui-feat-1" "$served"
fi

echo
printf '%-36s %s\n' "CHECK (${MODE})" "RESULT"
printf '%-36s %s\n' "------------------------------------" "------"
for row in "${RESULTS[@]}"; do
  IFS='|' read -r verdict name detail <<<"$row"
  printf '%-36s %-5s %s\n' "$name" "$verdict" "$detail"
done
echo

if [[ "$FAILED" -ne 0 ]]; then
  echo "VERIFY FAILED"
  exit 1
fi
echo "VERIFY OK"
