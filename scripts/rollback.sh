#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -L var/prod/current ]; then
  echo "Cannot rollback: no current production environment exists yet."
  echo "Run scripts/deploy.sh v1 first, then deploy another version before rollback."
  exit 1
fi

# shellcheck disable=SC1091
source var/prod/shared/env

CURRENT="$(basename "$(readlink var/prod/current)")"
if [ "$CURRENT" = "blue" ]; then
  PREVIOUS="green"
  PREVIOUS_PORT="$GREEN_PORT"
else
  PREVIOUS="blue"
  PREVIOUS_PORT="$BLUE_PORT"
fi

PID_FILE="var/prod/$PREVIOUS/app.pid"
if [ ! -f "$PID_FILE" ] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Cannot rollback: previous environment '$PREVIOUS' is not running."
  echo "Rollback only works after both blue and green have been deployed at least once."
  exit 1
fi

ln -sfn "$PREVIOUS" var/prod/current
echo "$PREVIOUS_PORT" > var/prod/current_port
echo "Rolled back from $CURRENT to $PREVIOUS."
echo "Production now points to http://127.0.0.1:$PREVIOUS_PORT"
