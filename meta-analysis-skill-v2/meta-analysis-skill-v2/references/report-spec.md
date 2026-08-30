# Report Specification

`report.md` uses this fixed section order.

## 1. Statistical interpretation

Include effect/prevalence estimates, 95% CI, prediction interval when available, `tau^2`, `I^2`, Q and p-value, `k_studies`, row/effect counts, total N when available, small-study test or exact skip reason, and generated subgroup outputs.

NMA reports relative-effect output paths, connectivity, reference treatment, inconsistency status, and the exact ranking metric instead of inventing a single pooled network effect.

## 2. Clinical interpretation

Use the user-supplied population and MCID source. If no MCID source is supplied, write `MCID not provided — no clinical threshold applied`. Prevalence reports state that MCID is not applicable to pooled prevalence.

## 3. Writing suggestions

Provide short Results and Discussion starting points. End with a caveat to verify every number against `data/summary.txt` and adapt wording to the protocol.

## 4. Methods caveats

Carry validation warnings and analysis notes into the report, including small-k, direction, change/final, multi-arm, boundary-event, model-target, and NMA validity cautions.

## 5. Certainty placeholders

- Comparative pairwise/NMA: manual RoB/GRADE table with blank judgement cells.
- Prevalence: manual JBI prevalence checklist with Yes/No/Unclear and source fields.

V2 does not calculate GRADE, CINeMA, JBI scores, or PRISMA flow diagrams.

