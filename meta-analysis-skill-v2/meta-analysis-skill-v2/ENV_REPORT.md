V2_VERIFIED=NO

# Environment Report

Generated: 2026-08-29 UTC

## Gate decision

- Branch: **C**
- R is unavailable in the current runtime. All V2 files will still be implemented.
- Package-dependent analysis tests must be marked `BLOCKED`; no claim of a runtime-verified analysis pipeline is permitted.

## Runtime

- OS: Ubuntu 24.04.3 LTS, Linux 6.18.35, x86_64
- Repository writable: YES (a temporary probe file was created and removed successfully)
- R executable: NOT FOUND
- Rscript executable: NOT FOUND
- `R --version`: BLOCKED because R is not installed

## Required R packages

| Package | Installed | Version |
|---|---:|---|
| `meta` | BLOCKED | R unavailable |
| `metafor` | BLOCKED | R unavailable |
| `netmeta` | BLOCKED | R unavailable |

## Installed-package API evidence

- `meta`: BLOCKED. The installed help/source cannot be inspected because R is unavailable. V2 code must avoid `hakn = TRUE`; `scripts/check_env.R` will verify `method.random.ci` and record installed help evidence when rerun in an R environment.
- `netmeta`: BLOCKED. Runtime registration of `forest.netmeta`, absence/presence of `forest.netrank`, and `netrank()` support for P-score/SUCRA cannot be verified here. `scripts/check_env.R` contains those runtime checks.
- External reviews are not treated as runtime evidence in this report.

## Write and installation capability

- File writes in the repository: YES
- R package installation: NO in this environment because R is unavailable
- Installation attempted: NO
- No package installation was performed or requested silently.

## Verification command for an R environment

After installing R, run the following from the repository root. The first command rewrites this report with actual installed-package versions and API evidence; the second runs the complete test suite.

```bash
scripts/check_env.sh
tests/run_all.sh
```

If packages are missing, review the rewritten report and obtain user approval before running:

```r
install.packages(c("meta", "metafor", "netmeta"))
```
