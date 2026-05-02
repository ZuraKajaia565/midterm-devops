#!/usr/bin/env bash
set -euo pipefail

python -m py_compile app/*.py tests/*.py

if grep -RIn '[[:blank:]]$' app tests scripts .github README.md; then
  echo "Trailing whitespace found"
  exit 1
fi

echo "Lint passed"
