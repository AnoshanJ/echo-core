#!/usr/bin/env bash
# Proves the core serves base functionality and nothing more.
set -euo pipefail

cd "$(dirname "$0")"

MODE=binary
[[ "${1:-}" == "--docker" ]] && MODE=docker

PORT=8081
BASE="http://127.0.0.1:${PORT}"
VERSION="v-test-1.2.3"
COMMIT="deadbeef"
IMAGE=echo-core:verify
PID=""
CID=""

declare -a RESULTS=()
FAILED=0

cleanup() {
  [[ -n "$PID" ]] && kill "$PID" 2>/dev/null || true
  [[ -n "$CID" ]] && docker rm -f "$CID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    RESULTS+=("PASS|${name}|${actual}")
  else
    RESULTS+=("FAIL|${name}|expected [${expected}] got [${actual}]")
    FAILED=1
  fi
}

wait_ready() {
  for _ in $(seq 1 50); do
    curl -fsS "${BASE}/healthz" >/dev/null 2>&1 && return 0
    sleep 0.2
  done
  echo "server never became ready" >&2
  exit 1
}

status_of() { curl -s -o /dev/null -w '%{http_code}' "$1"; }
field_of() {
  curl -fsS "$1" | python3 -c '
import json, sys
d = json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d = d[int(k)] if isinstance(d, list) else d[k]
print(d)
' "$2"
}

if [[ "$MODE" == binary ]]; then
  (cd backend && go build \
    -ldflags "-X github.com/AnoshanJ/echo-core/backend/app.Version=${VERSION} -X github.com/AnoshanJ/echo-core/backend/app.Commit=${COMMIT}" \
    -o ../bin/echo-core .)
  ./bin/echo-core -addr ":${PORT}" &
  PID=$!
else
  docker build --build-arg "VERSION=${VERSION}" --build-arg "COMMIT=${COMMIT}" -t "$IMAGE" ./backend
  CID=$(docker run -d -p "${PORT}:8080" "$IMAGE")
fi
wait_ready

check "healthz returns 200"              "200"        "$(status_of "${BASE}/healthz")"
check "echo reflects the message"        "hello"      "$(field_of "${BASE}/api/v1/echo?msg=hello" "msg")"
check "echo reports source=core"         "core"       "$(field_of "${BASE}/api/v1/echo?msg=hello" "source")"
check "ldflags version is injected"      "${VERSION}" "$(field_of "${BASE}/api/v1/version" "version")"
check "ldflags commit is injected"       "${COMMIT}"  "$(field_of "${BASE}/api/v1/version" "commit")"
check "core is its own main module"      "(main module)" "$(field_of "${BASE}/api/v1/version" "core_module.version")"
check "echo carries feature markers"      "public-feat1" "$(field_of "${BASE}/api/v1/echo?msg=hello" "features.0")"
check "no wrapper route (/reverse 404)"  "404"        "$(status_of "${BASE}/api/v1/reverse?msg=hello")"

echo
printf '%-34s %s\n' "CHECK (${MODE})" "RESULT"
printf '%-34s %s\n' "----------------------------------" "------"
for row in "${RESULTS[@]}"; do
  IFS='|' read -r verdict name detail <<<"$row"
  printf '%-34s %-5s %s\n' "$name" "$verdict" "$detail"
done
echo

if [[ "$FAILED" -ne 0 ]]; then
  echo "VERIFY FAILED"
  exit 1
fi
echo "VERIFY OK (${MODE})"
