# Environment Report

Generated: 2026-08-30 04:14:47 UTC

V2_VERIFIED=YES

## Runtime

- OS: sysname=Linux; release=6.12.94+; version=#1 SMP PREEMPT_DYNAMIC Fri Aug 28 16:08:20 UTC 2026; nodename=cursor; machine=x86_64; login=unknown; user=ubuntu; effective_user=ubuntu
- R executable: /usr/lib/R/bin/R
- R version: R version 4.3.3 (2024-02-29)
- Repository writable: YES
- R library paths: /home/ubuntu/R/x86_64-pc-linux-gnu-library/4.3; /usr/local/lib/R/site-library; /usr/lib/R/site-library; /usr/lib/R/library
- Writable R library available: YES
- Package installation attempted: NO (installation requires explicit user consent).

## Required packages

- `meta`: 8.5.0
- `metafor`: 5.0.1
- `netmeta`: 3.6.1

## `meta` API evidence

- `metacont()` has `method.random.ci`: TRUE
- `metacont()` has `hakn`: FALSE
- Installed help/source evidence:
  - method.random.ci = gs("method.random.ci"),
  - adhoc.hakn.ci = gs("adhoc.hakn.ci"),
  - adhoc.hakn.pi = gs("adhoc.hakn.pi"),
  - adhoc.hakn,
  - method.random.ci: A character string indicating which method is used to
  - adhoc.hakn.ci: A character string indicating whether an _ad hoc_
  - adhoc.hakn.pi: A character string indicating whether an _ad hoc_
  - adhoc.hakn: Deprecated argument (replaced by 'adhoc.hakn.ci').

## `netmeta` API evidence

- `netrank()` has `method`: TRUE
- `forest.netmeta` registered: TRUE
- `forest.netrank` registered: FALSE
- Installed help mentions P-score: TRUE
- Installed help mentions SUCRA: TRUE

## Gate decision

- Branch: A
- Independent retest on 2026-08-30: `scripts/check_env.sh` then `tests/run_all.sh` completed with 10/10 R tests PASS, 0 FAIL, 0 BLOCKED. `V2_VERIFIED=YES`.
- Static Python suite (`python3 tests/static_tests.py`) also completed with 0 FAIL when run separately after the R suite.

## Independent runtime fixes required for YES

The uploaded V2 tree failed `test_prevalence.R` and `test_nma_api.R` until the following API/schema mismatches were fixed:

- Prevalence: current `meta` defaults PLOGIT to GLMM, which rejects `method.tau = "REML"`. Main analysis now requests `method = "Inverse"` so the documented REML/HK PLOGIT path can run.
- Network validation: `year` was required for every mode. The data dictionary only requires year for pairwise/prevalence; network templates do not have that column.
- Network engine: `pairwise()` now lives in `meta`, and `netmeta::netmeta()` accepts `method.random.ci` of `classic`/`t-dist`, not `HK`.
