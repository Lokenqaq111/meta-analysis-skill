# Test Log

Environment branch: C (Python/shell fallback; R-dependent tests are BLOCKED).

| Test | Status | Key output |
|---|---|---|
| `cycle1_structure` | PASS | Core V2 files exist. |
| `empty_template_header_only` | PASS | continuous_empty.csv has no data rows. |
| `continuous_schema` | PASS | Expanded continuous schema is present. |
| `empty_cell_stops` | PASS | Blank required numeric cell is detected before analysis. |
| `unique_study_count` | PASS | Six rows are counted as three independent studies. |
| `direction_flip` | PASS | Opposite direction changes effect sign only. |
| `md_xlim` | PASS | Calculated limits (-6.2, 68.2) cover MD estimates and CIs. |
| `no_fixed_xlim` | PASS | No fixed SMD-scale xlim remains in the engine. |
| `no_deprecated_hakn` | PASS | The engine uses method.random.ci and does not call hakn=TRUE. |
| `k_gates_in_code` | PASS | Central diagnostic gates use independent-study count at k=3/10. |
| `egger_routing` | PASS | Small-study test selection is routed by effect measure. |
| `md_example_scale` | PASS | MD example differences are [20.0, 35.0, 50.0] metres. |
| `prevalence_schema` | PASS | Prevalence is an independent single-proportion schema. |
| `prevalence_boundary_fixture` | PASS | Synthetic prevalence fixture contains 0% and 100% studies. |
| `nma_api_static` | PASS | NMA uses a netmeta forest path and exact dynamic P-score/SUCRA file naming. |
| `nma_limits_static` | PASS | NMA requests connectivity restriction, netheat, and netsplit when available. |
| `multiarm_shared_control` | PASS | Shared-control fixture is detected and validator contains an explicit stop. |
| `manual_certainty_only` | PASS | JBI/GRADE sections are manual placeholders. |
| `configurable_outdir` | PASS | CLI defaults to configurable ./output/<topic>. |
| `no_hardcoded_mcid_in_instructions` | PASS | No universal MCID examples remain in SKILL.md/README.md. |
| `lean_skill_router` | PASS | SKILL.md routes to repository scripts/references and embeds no full model template. |
| `installation_docs` | PASS | README documents the real Claude and Cursor clone paths. |
| `changelog_v2` | PASS | CHANGELOG records V2 scope, exclusions, and corrected V1 maturity wording. |
| `nonabsolute_model_wording` | PASS | Random effects are documented as a configurable default, not a discipline law. |
| `no_fixed_desktop_path` | PASS | No fixed Desktop output path remains. |
| `r_delimiter_sanity` | PASS | Balanced R delimiters in all scripts/tests. |
| `no_silent_install_call` | PASS | No executable R script calls install.packages(). |
| `reproducible_output_contract` | PASS | CLI records log, parameters, rerun script, session info, and report. |
| `validation_cli` | PASS | validate.R exposes a standalone nonzero-exit CLI. |
| `synthetic_example_labels` | PASS | Every gold-standard fixture uses an Example* study ID. |
| `continuous_smd_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `continuous_md_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `binary_rr_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `diagnostic_plot_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `prevalence_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `nma_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `meta_api_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
| `netmeta_api_runtime` | BLOCKED | Rscript is unavailable (environment branch C). |
