# CLAUDE.md — Digital Payments Thesis Rebuild

This file is read by Claude Code on every session. It tells you the project
context, conventions, and the rules you must follow when working on this
codebase. Read it in full before taking any action.

---

## 1. Project overview

**Author:** Hari Dharshini K.S.
**Context:** Rebuild and extension of my undergraduate thesis
("Determinants of Digital Payments in India — A state-level analysis",
Shiv Nadar University, May 2024) using updated data and improved methods.

**Goal:** Produce a working-paper-quality document suitable as a writing
sample for finance, consulting, and policy research roles.

**Structure of the final paper:**
- **Part I** — Determinants of Early-Stage Digital Payment Adoption
  (2017-18 to 2020-21), rebuilt from clean data with improved methods.
- **Part II** — UPI at Scale: State-Level Retail Adoption (2023-24 to
  2025-26), new analysis with richer variables.
- **Part III** — Comparative discussion: what changed between the two
  periods and what that implies for policy.

**Not in scope:** structural models, firm-level analysis, cross-country
comparisons. Keep scope tight.

---

## 2. What I already know and what you do NOT need to re-derive

I have thought through the research design. Do not re-litigate these
choices unless I explicitly ask:

- The paper is structured as Part I + Part II + Part III (Option C).
- Part I uses the Indiastat composite series (BHIM + IMPS + RuPay POS +
  UPI + USSD); Part II uses pure UPI data from NPCI via Indiastat.
- The two parts are intentionally NOT chained into a single panel, because
  the dependent variables are definitionally different. Do not suggest
  chaining them.
- Stata is not available. Analysis is in R.
- The "PHCs per sq km has a negative effect" finding in the original
  thesis is a confounded result driven by rurality. The rebuild adds
  urbanization controls to correct this. Do not restate the original
  interpretation as if it were correct.
- The original thesis used causal language for associational results.
  The rebuild uses disciplined associational language everywhere except
  in the optional DiD section. Do not slip back into causal language.

---

## 3. Tools and environment

- **Language:** R (not Python, not Stata).
- **IDE:** VS Code with the Claude Code extension.
- **Version control:** Git. Commit after every meaningful unit of work.
- **Key R packages:** `renv` (environment lockfile), `fixest` (regressions
  and fixed effects), `modelsummary` (tables), `tidyverse` (data wrangling),
  `readxl` (Excel ingestion), `janitor` (name cleaning), `fwildclusterboot`
  (wild cluster bootstrap), `did` (Callaway-Sant'Anna DiD, if used).
- **Output format:** LaTeX for tables, PDF for the final paper.

Before writing any R code, check that the relevant package is listed
above. If you need a new package, add it to this CLAUDE.md in the same
commit as the script that uses it.

---

## 4. Project directory structure

```
digital-payments-thesis/
├── CLAUDE.md              # this file
├── README.md              # one-paragraph project description + how to run
├── .gitignore             # ignore data/raw/, output/, .Rhistory, .RData
├── data/
│   ├── raw/               # untouched source files, NEVER edit
│   │   ├── indiastat/
│   │   ├── rbi_handbook/
│   │   ├── plfs/
│   │   ├── trai/
│   │   ├── pmjdy/
│   │   └── meity/
│   ├── interim/           # cleaned single-source files (CSV)
│   └── processed/         # final panels (CSV, parquet if large)
├── lookups/
│   └── state_names.csv    # canonical state-name reconciliation table
├── scripts/
│   ├── 01_ingest/         # one script per source, reads raw, writes interim
│   ├── 02_clean/          # variable-level cleaning (rarely needed)
│   ├── 03_build/          # panel construction from interim files
│   ├── 04_analyze/        # regression scripts, one per table in paper
│   └── 05_tables_figures/ # generates final LaTeX tables and figures
├── output/
│   ├── tables/            # LaTeX output from modelsummary
│   ├── figures/           # PDF / PNG figures
│   └── diagnostics/       # sanity-check plots, not for the paper
└── paper/
    ├── main.tex
    ├── sections/
    └── refs.bib
```

**Rules:**
- Never write to `data/raw/`. If source files need correction, document the
  correction in the ingestion script, not by editing the raw file.
- Scripts in a numbered folder may only read from lower-numbered folders
  and `data/interim/` or `data/processed/`. An `04_analyze/` script should
  not read from `data/raw/`.
- Every script starts with a comment block: purpose, inputs, outputs.

---

## 5. The state-name reconciliation rule

This is the single most important data discipline rule in the project.
Every Indian data source spells state names differently. Silent mismatches
here are the most common source of data corruption in panel work.

**The canonical file is `lookups/state_names.csv`.** It has these columns:
- `state_canonical` — the name we use throughout the project (UTF-8, no
  trailing whitespace, title case, ampersand spelled as "and")
- `state_code` — two-letter code (e.g., "MH" for Maharashtra)
- `variants` — pipe-separated list of every spelling we've encountered
  (e.g., `Orissa|ODISHA|Odisha |odisha`)
- `include_in_analysis` — logical, TRUE or FALSE
- `notes` — free text, especially for Telangana/AP split and J&K
  reorganization handling

**Every ingestion script must join through this table before writing to
`data/interim/`.** If a script encounters a state name not in the
`variants` column, it must FAIL LOUDLY — do not silently drop rows and do
not fuzzy-match without logging. Add the new variant to the lookup table
and re-run.

---

## 6. Handling geographic boundary changes

India's state boundaries changed during our sample period. Handle these
explicitly, not implicitly.

**Telangana (bifurcated from Andhra Pradesh, June 2014):**
Our sample starts in 2017-18, so both states exist separately throughout.
No special handling required for Part I or Part II. Document this in the
data section of the paper.

**Jammu & Kashmir (reorganized October 2019 into J&K UT and Ladakh UT):**
- For Part I (2017-18 to 2020-21): treat J&K as a single unit throughout.
  Combine Ladakh and J&K figures for 2020-21 if sources report them
  separately. Document in a footnote.
- For Part II (2023-24 onwards): treat J&K and Ladakh as separate units
  if sources report them separately. Otherwise, combine and document.

**Union Territories:** the original thesis used 30 units (28 states +
2 UTs — confirm which in the raw data). Maintain that convention for
Part I for direct comparability. For Part II, reassess based on UPI data
availability and document the decision.

Whenever a boundary issue arises, STOP and ask me. Do not make the call
silently.

---

## 7. Data architecture: the three series problem

The dependent variable in Part I and the dependent variable in Part II
are NOT the same thing. This is a deliberate design choice. Never chain
them into a single panel without asking me first.

**Series 1 (Part I):** Indiastat "State-wise Number of Digital Payment
Transactions through BHIM App, IMPS, RuPay on POS, UPI and USSD",
years 2017-18, 2019-20, 2020-21. Units: number of transactions.
Five-rail composite. This is the original thesis's dependent variable.

**Series 2 (optional for Part I robustness):** Indiastat "State-wise
Volume and Value of Digital Transactions (Financial and Non-Financial)",
years 2018-19 to 2022-23. MeitY DigiDhan-sourced. DEFINITIONALLY
DIFFERENT from Series 1 — includes AePS, NACH, internet banking, and
non-financial transactions. Use only as a robustness check, with an
explicit structural-break control.

**Series 3 (Part II):** Indiastat / NPCI state-wise UPI volume and value,
monthly from September 2023 onwards. Pure UPI. This is the Part II
dependent variable. When available, the P2M (person-to-merchant) subset
is preferred over total UPI, because it isolates retail adoption from
institutional transfers.

In the paper, describe each series precisely every time it's introduced.
Do not refer to "digital payments" without qualifying which series.

---

## 8. Econometric conventions

These conventions are non-negotiable. Every regression in this project
must follow them.

**Standard errors:**
- ALWAYS cluster at the state level. No exceptions.
- For every main specification, report wild cluster bootstrap p-values
  alongside cluster-robust p-values. 30 clusters is on the edge for
  asymptotic inference.
- Use `fixest::feols(..., cluster = ~state)` for clustering.
- Use `fwildclusterboot::boottest()` for wild bootstrap.

**Fixed effects:**
- Part I baseline: state and year FE. Syntax: `| state + year`.
- Part II baseline: state and month FE. Consider state + year-month or
  state × quarter as robustness.
- NEVER report a specification without state FE unless explicitly
  comparing to pooled OLS as a diagnostic.

**Dependent variable transformation:**
- Baseline is log(per-capita transactions). Per-capita normalization
  uses state population from the MoHFW projection report, consistent
  source across years.
- PPML (Poisson pseudo-maximum likelihood) is the primary robustness
  alternative. Uses raw per-capita counts, not logs. Handles zeros.
  Syntax: `fixest::fepois(..., cluster = ~state)`.
- Report log-OLS and PPML side by side for every main table.

**Language discipline:**
- For fixed-effects results: "associated with", "correlated with",
  "is positively/negatively related to". NEVER "causes", "drives",
  "leads to", "impact of X on Y".
- For the optional DiD section: "effect of", "treatment effect" are
  permitted, but only within that section.
- Never cite R² as evidence for a coefficient-level claim. R² in FE
  models is dominated by the fixed effects themselves.

**Robustness section minimum:**
Every main table requires a robustness section in the appendix covering:
(a) PPML alongside log-OLS, (b) wild cluster bootstrap SEs,
(c) leave-one-state-out (drop Maharashtra, rerun), (d) alternative FE
structure.

---

## 9. The PHC correction (Part I)

The original thesis reported a large significant negative coefficient on
"PHCs per sq km" and interpreted it as "healthcare infrastructure
suppresses digital payments". This is almost certainly a spurious result
driven by the denominator: PHCs are allocated per-population, but the
denominator is square kilometers. Sparse, remote states (Arunachal,
Mizoram, Sikkim) have high PHCs/km² because their land area includes huge
uninhabited regions. High PHCs/km² is a proxy for rurality.

**In the rebuild:**
- Add `share_urban` and `population_density` (or `log_population_density`)
  as controls in every development-indicator regression.
- Report the PHC coefficient with and without these controls.
- In the paper text, describe this as a correction of the original
  interpretation. Do not hide the change. The honesty is a strength.

---

## 10. When to stop and ask me

ASK ME before:
- Making any decision about how to combine or reconcile differently-defined
  series.
- Dropping observations for any reason other than the explicit inclusion
  rule in `lookups/state_names.csv`.
- Changing the baseline specification (state + year FE, clustered SEs,
  log dependent variable).
- Adding or removing a variable from the main analysis.
- Any imputation of missing values.
- Writing results language that describes a finding.
- Any geographic boundary decision (J&K, Ladakh, UT inclusion).
- Installing a new R package not listed in section 3.

DO NOT ask me before:
- Fixing a syntax error in a script I wrote.
- Running an existing script that's already been reviewed.
- Producing a diagnostic plot (time series, histogram, scatter) for my
  review.
- Writing a new ingestion script for a source already on the inventory.
- Refactoring for readability without changing behavior.

---

## 11. Memory across sessions

At the end of each session, update `README.md` with a dated "last status"
entry: what was completed, what's next, any open decisions. Do not update
CLAUDE.md itself — it encodes durable project rules, not session state.

If you find yourself repeatedly re-explaining something to me in
conversation, that something probably belongs in CLAUDE.md. Flag it, I'll
decide whether to promote it into this file.

---

## 12. Timeline and current phase

Overall timeline: 12-16 weekends.

| Phase | Description | Weekends | Status |
|-------|-------------|----------|--------|
| 0 | Project setup | 1 | in progress |
| 1 | Data inventory and pulls | 2-3 | not started |
| 2 | Data cleaning and panel construction | 2-3 | not started |
| 3 | Part I re-estimation | 1-2 | not started |
| 4 | Part II design and estimation | 2-3 | not started |
| 5 | Part III comparative section | 1 | not started |
| 6 | Writing and polish | 3-4 | not started |

**Current phase:** 0 — setup. Update this table as phases complete.

---

## 13. Writing conventions for the paper

- Length target: 40-50 pages including references and appendix.
- Format: LaTeX, single-column, 11pt serif body, standard economics
  working-paper style.
- Citations: author-year, not numbered.
- Tables: generated by `modelsummary::modelsummary(..., output = "latex")`.
  Never hand-typeset a regression table.
- Figures: generated by `ggplot2`, saved as PDF, included via
  `\includegraphics`. Never screenshot.
- Every coefficient discussed in the text must include its economic
  magnitude, not just its significance level. "A 10 percentage point
  increase in literacy is associated with a 7% increase in per-capita
  digital transactions" — not "literacy is significant at 1%".

---

*Last updated: 2026-04-23. Phase 0 scaffold commit — added `renv` to the
package list in §3. Update this footer line whenever substantive rules
change, and note the change in the git commit.*
