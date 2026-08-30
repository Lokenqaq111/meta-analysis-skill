#!/usr/bin/env bash
set -u

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

if command -v Rscript >/dev/null 2>&1; then
  exec Rscript tests/run_all.R
fi

exec python3 tests/static_tests.py

