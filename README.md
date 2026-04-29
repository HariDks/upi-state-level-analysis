# Digital Payments Thesis — Rebuild

State-level analysis of digital payment adoption in India, rebuilding and
extending the undergraduate thesis "Determinants of Digital Payments in
India" (Shiv Nadar University, May 2024). The paper has three parts:
(I) determinants of early-stage adoption, 2017-18 to 2020-21, rebuilt from
clean data with improved methods; (II) UPI at scale, 2023-24 to 2025-26,
new state-level analysis; (III) comparative discussion of what changed.
Author: Hari Dharshini K.S.

See [CLAUDE.md](CLAUDE.md) for project rules, conventions, and data
discipline. Read it before contributing.

## How to run

Requirements: R ≥ 4.3, `renv`, a working LaTeX install for the paper.

```bash
# Clone, then restore the R environment
cd digital-payments-thesis
Rscript -e 'renv::restore()'

# Scripts run in order (01 → 05). Each writes to data/interim,
# data/processed, or output/ — never to data/raw/.
Rscript scripts/01_ingest/<source>.R
Rscript scripts/03_build/<panel>.R
Rscript scripts/04_analyze/<table>.R
```

Raw source files live in `data/raw/` and are not versioned. Pull each
source per the inventory in Phase 1 before running ingestion scripts.

## Status log

Append-only. Newest entries at the top. Update at the end of each session.

### 2026-04-26 — Spec overhaul, first regression run, data audit
- §7a written into CLAUDE.md: narrowed from the 2024 thesis's 9-control
  kitchen-sink to a theoretically-anchored 6-variable spec (PHCs/sq km,
  share_urban, log pop density, log literacy, log NSDP, log internet
  penetration). Same set in Part I and Part II for Part III
  coefficient-on-coefficient comparability.
- Read user's original thesis materials (Final Variables xlsx, Regressions
  doc, full thesis text). Original spec was already panel + state/year FE
  — methodology rebuild is alignment, not wholesale change.
- TRAI legacy LSA boundaries discovered — pre-2023 TRAI YPI reports
  combine post-split states (AP+Telangana, Bihar+Jharkhand, etc.);
  internet penetration is therefore omitted from Part I (one explicit
  data-availability caveat).
- Built Part I panel (60 obs), ran two specs (puzzle vs §9 correction).
  Initial run produced surprising literacy = -1.314*** which triggered
  full data-quality audit.
- AUDIT FINDINGS: South 2019-20 Indiastat literacy file was rural-only
  scope (every other regional file rural+urban combined) — manufactured
  fake +5pp within-state literacy "jump" for 7 South India states.
  After user re-pulled the correct rural+urban-combined file, literacy
  point estimate barely changed but SE inflated 5× — what looked
  significant was spurious precision from upstream data corruption.
  DNHDD literacy aggregation also fixed (simple mean → population-
  weighted using Census 2011 weights).
- Final clean Part I result: nothing significant. Within-R² ≈ 0.01.
  This IS the rebuild's contribution — exposing that the 2024 thesis's
  headline findings depended on data-quality issues that vanish once
  corrected.
- Defensive parser change: `indiastat_literacy.R` now scans titles for
  "Rural Areas" / "Urban Areas" scope qualifiers and skips with loud
  warning rather than silently including.
- Day 1 log written: `learning day 1.md` (16 sections).

### 2026-04-24 — First Phase 1 pulls landed
- 8 files pulled via `curl` / WebFetch against public URLs, ~55 MB total,
  distributed across six `data/raw/<source>/` subfolders. Provenance (URL,
  date pulled, size, caveats) logged in per-folder `_MANIFEST.txt` files
  and an index at `data/raw/_MANIFEST.txt`.
- Landed: MoHFW Population Projections 2019 (PDF); RHS 2020-21 (PDF, via
  archive.org mirror); PLFS AR 2022-23 (PDF) + PLFS 2023-24 press note;
  TRAI YPI 2023-24 (PDF); Census 2011 Rural-Urban Distribution (PDF) +
  state-wise area table (XLS); PMJDY live state-wise snapshot as of
  2026-04-15 (CSV, all 36 states/UTs captured via WebFetch).
- Hard blockers flagged and handed off to user:
  * Indiastat Series 1 and Series 3 — paid-portal login, nothing to do.
    NPCI's own public stats don't expose state-level monthly UPI;
    Dataful (the free Indiastat tier) also paywalls it.
  * RBI Handbook XLSX tables — rbidocs.rbi.org.in uses Imperva/TSPD
    bot protection (JS challenge). Browser works fine; curl cannot pass.
    Four specific table URLs flagged for manual download.
  * RHS 2017-18 and 2019-20 — `main.mohfw.gov.in` and `hmis.mohfw.gov.in`
    unreachable from this network; URLs recorded for browser retry.
- Methodological footnote to eventually include in the paper: per Dataful
  commentary on NPCI data, ~27% of UPI volume in FY 2024-25 is
  "unclassified" at the state level (routing / app-aggregation /
  institutional flow limits). This is a real measurement issue for Part
  II's state-level DV.

### 2026-04-23 — Phase 1 planning complete; scaffolds landed
- `renv::install()` populated the lockfile with 117 binary packages
  against R 4.5.3 (tidyverse + readxl + janitor as the Phase-1 toolset).
- `scripts/01_ingest/_utils_state_names.R` written: exposes
  `reconcile_states()`, which joins input state names through
  `lookups/state_names.csv` and fails loud with a listed error if any
  name is unrecognized. Five self-tests at the bottom, all passing.
- `scripts/01_ingest/README.md` written: per-source inventory covering
  11 sources, anchored vs. proposed split, and all seven open questions
  answered and recorded in the Resolved section.
- CLAUDE.md §4 directory tree updated — added `data/raw/mohfw/` and
  `data/raw/census/`, created both folders locally.
- Nine ingestion scaffolds landed (`indiastat_series1`, `indiastat_upi`,
  `rbi_handbook`, `plfs`, `trai`, `pmjdy`, `mohfw_population`,
  `mohfw_rhs`, `census_urbanization`). Each: standard header contract;
  fails loud with a "pull X, save to Y" error when raw files are
  missing; includes a commented template the user uncomments and fills
  in once the file is inspected.
- Key design decisions recorded: Part II UT coverage = include all UTs
  with non-zero UPI + Part III robustness on 30-unit overlap; TRAI
  Metro LSAs aggregate into parent states with teledensity recomputed
  not averaged; PMJDY uses one consistent source across all FY-end
  snapshots (MoF reports preferred, Wayback fallback — never mixed);
  UPI DV (P2M vs. total) chosen once at panel-build time, not per cell.

### 2026-04-23 — Phase 0 scaffold
- Repo moved out of iCloud to `~/projects/digital-payments-thesis` to avoid
  iCloud sync corrupting `.git/`.
- Directory tree from CLAUDE.md §4 created.
- `.gitignore`, `README.md`, and this status log added.
- `lookups/state_names.csv` seeded with 30-unit Part I panel (28 states +
  J&K as single unit + Puducherry) as confirmed from original thesis FE
  table (90 obs = 30 × 3 years, Andhra Pradesh is the omitted FE
  reference). Delhi was NOT in the original panel — flagged for
  reconsideration in Phase 1.
- Other UTs (Delhi, Chandigarh, A&N, Lakshadweep, merged DNHDD, Ladakh)
  included in the lookup but noted as outside Part I original sample.
- `renv` initialized (bare) and added to CLAUDE.md §3 package list.

Next: first Phase 1 pulls. Suggested order — Indiastat Series 1 (Part I
DV) and MoHFW population projections (per-capita denominator); these two
together unblock the first Part I regression run.
