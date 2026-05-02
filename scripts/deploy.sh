#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f var/prod/shared/env ]; then
  scripts/setup.sh
fi

# shellcheck disable=SC1091
source var/prod/shared/env

CURRENT_TARGET=""
if [ -L var/prod/current ]; then
  CURRENT_TARGET="$(basename "$(readlink var/prod/current)")"
fi

if [ "$CURRENT_TARGET" = "blue" ]; then
  NEXT="green"
  NEXT_PORT="$GREEN_PORT"
else
  NEXT="blue"
  NEXT_PORT="$BLUE_PORT"
fi

mkdir -p "var/prod/$NEXT"
APP_VERSION="${1:-$(date +%Y%m%d%H%M%S)}"
PID_FILE="var/prod/$NEXT/app.pid"
LOG_FILE="var/logs/$NEXT.log"

echo "Current active environment: ${CURRENT_TARGET:-none}"
echo "Deploying version $APP_VERSION to inactive environment: $NEXT"
echo "Target URL: http://$HOST:$NEXT_PORT"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Stopping old $NEXT process with PID $(cat "$PID_FILE")"
  kill "$(cat "$PID_FILE")"
fi

APP_VERSION="$APP_VERSION" HOST="$HOST" PORT="$NEXT_PORT" nohup "${PYTHON_BIN:-python3}" -m app.server > "$LOG_FILE" 2>&1 &
echo "$!" > "$PID_FILE"
echo "Started $NEXT process with PID $(cat "$PID_FILE")"
sleep 1

if ! "${PYTHON_BIN:-python3}" - <<PY
import json
import urllib.request

url = "http://$HOST:$NEXT_PORT/health"
with urllib.request.urlopen(url, timeout=5) as response:
    payload = json.loads(response.read())
assert payload["status"] == "ok", payload
print("Health check passed:", payload)
PY
then
  echo "Health check failed. See $LOG_FILE for application logs."
  echo "Production pointer was not switched."
  exit 1
fi

ln -sfn "$NEXT" var/prod/current
echo "$NEXT_PORT" > var/prod/current_port
echo "Production now points to $NEXT."
echo "Deployed version $APP_VERSION on http://$HOST:$NEXT_PORT"
