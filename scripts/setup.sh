#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PYTHON_BIN="${PYTHON_BIN:-python3}"

"$PYTHON_BIN" --version
mkdir -p var/prod/blue var/prod/green var/prod/shared var/logs
chmod +x scripts/*.sh

cat > var/prod/shared/env <<ENV
HOST=127.0.0.1
BLUE_PORT=8101
GREEN_PORT=8102
PYTHON_BIN=$PYTHON_BIN
ENV

echo "Created local production folders:"
echo "  $ROOT_DIR/var/prod/blue"
echo "  $ROOT_DIR/var/prod/green"
echo "  $ROOT_DIR/var/prod/shared/env"
echo "  $ROOT_DIR/var/logs"
echo "Environment prepared successfully."
