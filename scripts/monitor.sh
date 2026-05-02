#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

INTERVAL="${INTERVAL:-5}"
COUNT="${COUNT:-12}"
LOG_FILE="${LOG_FILE:-var/logs/health.log}"
mkdir -p "$(dirname "$LOG_FILE")"

echo "Writing health check results to $LOG_FILE"

for _ in $(seq 1 "$COUNT"); do
  if [ -f var/prod/current_port ]; then
    PORT="$(cat var/prod/current_port)"
  else
    PORT="${PORT:-8000}"
  fi

  if "${PYTHON_BIN:-python3}" - <<PY
import json
import urllib.request

with urllib.request.urlopen("http://127.0.0.1:$PORT/health", timeout=3) as response:
    payload = json.loads(response.read())
assert payload["status"] == "ok"
PY
  then
    echo "$(date -Is) OK http://127.0.0.1:$PORT/health" | tee -a "$LOG_FILE"
  else
    echo "$(date -Is) FAIL http://127.0.0.1:$PORT/health" | tee -a "$LOG_FILE"
  fi
  sleep "$INTERVAL"
done
