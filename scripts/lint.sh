#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"${PYTHON_BIN:-python3}" -m py_compile app/*.py tests/*.py

if grep -RIn '[[:blank:]]$' app tests scripts .github README.md; then
  echo "Trailing whitespace found"
  exit 1
fi

echo "Lint passed"
