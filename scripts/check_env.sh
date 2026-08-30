#!/usr/bin/env bash
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"

printf '# Environment preflight\n\n'
printf -- '- OS kernel: %s\n' "$(uname -a)"
if [[ -r /etc/os-release ]]; then
  os_name="$(awk -F= '$1 == "PRETTY_NAME" {gsub(/^\"|\"$/, "", $2); print $2}' /etc/os-release)"
  printf -- '- OS distribution: %s\n' "${os_name:-unknown}"
fi

if probe="$(mktemp "${repo_dir}/meta-analysis-v2-write-probe.XXXXXX" 2>/dev/null)"; then
  rm -f "${probe}"
  printf -- '- Repository writable: YES\n'
else
  printf -- '- Repository writable: NO\n'
fi

if command -v R >/dev/null 2>&1 && command -v Rscript >/dev/null 2>&1; then
  printf -- '- R executable: %s\n' "$(command -v R)"
  R --version | sed -n '1,2p'
  exec Rscript "${script_dir}/check_env.R" "--output=${repo_dir}/ENV_REPORT.md"
fi

printf -- '- R executable: NOT FOUND\n'
printf -- '- Rscript executable: NOT FOUND\n'
printf -- '- Package API inspection: BLOCKED (R is unavailable)\n'
printf -- '- Package installation: BLOCKED (R is unavailable)\n'
printf '\nV2_VERIFIED=NO\nBranch: C\n'
exit 3
