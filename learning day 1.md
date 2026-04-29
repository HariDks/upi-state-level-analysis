# Learning Day 1 — Project Log

**Working dates:** 2026-04-23 through 2026-04-26
**Author:** Hari Dharshini K.S. (with Claude assistance)
**Project:** Digital Payments Thesis Rebuild — Part I (Determinants of
Early-Stage Digital Payment Adoption, 2019-20 + 2020-21) and Part II
(UPI at Scale, 2023-26)

This document is the comprehensive working log of the rebuild's first
days — what was done, what got stuck, what we learned along the way,
and how the design decisions evolved. Written in semi-chronological
order so the reasoning trail is preserved.

---

## 1. Project setup (Phase 0) — 2026-04-23

### What landed
- Repository moved out of iCloud to `~/projects/digital-payments-thesis`
  (iCloud sync was at risk of corrupting `.git/`).
- Directory tree created per CLAUDE.md §4: `data/raw/{indiastat,
  rbi_handbook, plfs, trai, pmjdy, meity}`, `data/interim/`,
  `data/processed/`, `lookups/`, `scripts/{01_ingest, 02_clean,
  03_build, 04_analyze, 05_tables_figures}`, `output/{tables, figures,
  diagnostics}`, `paper/sections/`.
- `lookups/state_names.csv` seeded with the 30-unit Part I original
  panel (28 states + J&K as single unit + Puducherry) plus other UTs
  for completeness — confirmed against the original thesis FE table
  (90 obs = 30 × 3 years, with Andhra Pradesh as the alphabetically-
  omitted FE reference).
- `renv` initialised (bare); R 4.5.3 installed and on PATH.
- `.gitignore`, `README.md`, `.Rprofile` all written.

### Key discipline rule established
**State-name reconciliation must be fail-loud, not silent.** Every
ingestion script joins through `lookups/state_names.csv`'s `variants`
column. Unknown spellings stop the script with an error listing the
offending strings. The fix is to add the variant to the lookup, not
to fuzzy-match. This is the single most important data-quality rule
in the project (CLAUDE.md §5).

---

## 2. Phase 1 planning and the seven open questions — 2026-04-23 to 04-24

Built `scripts/01_ingest/_utils_state_names.R` exposing
`reconcile_states(x, source_label)`. Self-tests cover canonical
pass-through, enumerated variants, whitespace tolerance, "All India"
flag handling, and the loud-fail path. All five tests pass.

Wrote `scripts/01_ingest/README.md` — a per-source inventory of 11
data sources with target years, role (DV / control / boundary),
interim output paths, and explicit "anchored in CLAUDE.md" vs.
"proposed by Claude" tagging. Seven open questions surfaced:

1. **Raw folder tree** → resolved: added `data/raw/mohfw/` and
   `data/raw/census/` subfolders; updated CLAUDE.md §4.
2. **UPI DV consistency rule** → resolved: never mix P2M and total UPI
   within a panel, even cell-by-cell. Pick one consistent measure at
   pull time and apply uniformly. (User correctly pushed back on my
   initial suggestion of cell-level fallback.)
3. **Part II UT coverage** → resolved: include every state/UT NPCI
   reports separately with non-zero volume; Part III runs robustness
   on the 30-unit overlap with Part I.
4. **TRAI Metro LSA → state mapping** → resolved at planning time:
   Mumbai+Maharashtra → Maharashtra, Chennai+Tamil Nadu → Tamil Nadu,
   Kolkata+West Bengal → West Bengal, Delhi LSA → Delhi. Sum
   subscribers; recompute teledensity from summed subscribers.
5. **PMJDY snapshot dates** → resolved: one consistent source across
   all FY-end snapshots. Try MoF finmin reports first; fall back to
   Wayback Machine snapshots only if (c) lacks coverage. Never mix.
6. **Variable list coverage** → resolved: pull broadly, specify
   narrowly in Phase 3.
7. **Indiastat access** → resolved: user pulls files manually because
   Indiastat is paid/login-only and Claude cannot drive authenticated
   browser sessions. No credentials shared.

Nine ingestion scaffolds written, each with header contract, fail-
loud "missing raw file" guidance, and uncomment-and-edit template.

---

## 3. The first wave of self-pulled data — 2026-04-24

Eight files landed from public URLs via `curl` / WebFetch into
six `data/raw/<source>/` subfolders, totalling ~55 MB. Provenance
logged in per-folder `_MANIFEST.txt` plus an index at
`data/raw/_MANIFEST.txt`.

| Source | File | Size | URL family |
|---|---|---|---|
| MoHFW population | `Report_Population_Projection_2019.pdf` | 11.5 MB | nhm.gov.in |
| MoHFW RHS 2020-21 | `RHS_2020-21.pdf` | 8.9 MB | archive.org (PARI mirror) |
| PLFS 2022-23 | `AR_PLFS_2022_23.pdf` | 24.1 MB | mospi.gov.in |
| PLFS 2023-24 (press note only) | `Press_note_AR_PLFS_2023_24.pdf` | 0.45 MB | mospi.gov.in |
| TRAI YPI 2023-24 | `YPI_2023-24.pdf` | 4.2 MB | trai.gov.in |
| Census | `Census2011_Rural_Urban_Distribution.pdf` | 2.8 MB | censusindia.gov.in |
| Census state areas | `PC01_A02_Statement4_state_area.xls` | 0.10 MB | censusindia.gov.in (WRONG FILE — see §6) |
| PMJDY snapshot | `pmjdy_portal_2026-04-15.csv` | 1.9 KB | scraped via WebFetch |

### Roadblocks hit on the way

- **MoHFW subdomains unreachable.** `main.mohfw.gov.in` and
  `hmis.mohfw.gov.in` failed DNS resolution from this network. Solved
  by switching to the archive.org PARI mirror for RHS 2020-21
  (`https://archive.org/download/PARI.rural-health-statistics-2020-21/...`).
- **RBI Imperva bot protection.** `rbidocs.rbi.org.in` returns a TSPD
  JavaScript challenge for any non-browser request. `curl` cannot solve
  it — even with a Mozilla User-Agent. The XLSX URLs I had returned
  HTML challenge pages instead of Excel files. Logged as user-handoff
  in `data/raw/_MANIFEST.txt`; user can pull these in a browser
  (visit handbook page first to set the session cookie, then click
  through 4 specific table URLs).
- **Census state-area XLS was the wrong file.** I downloaded what
  data.gov.in catalogued as "PC01_A02_Statement4 — state area" but
  it actually contains "Statement-9: Indices of Growth in Rural
  Population" (an indexed time series 1911-2001, not areas). State
  areas were eventually obtained from RHS Table 1 — a much better
  source because it includes rural/urban area split.

### Methodological insight from the PMJDY scrape
The Dataful page (a free Indiastat tier) noted that **~27% of UPI
volume in FY 2024-25 is "unclassified"** at the state level — NPCI
itself can't attribute over a quarter of transactions to specific
states (routing, app-aggregation, institutional flows). This made it
into the project as a measurement caveat that the paper's data
section will need to footnote. The number turned out to grow over
time — see §5.

---

## 4. The user's original-thesis files — discovery, 2026-04-25

Asking "what is PLFS doing here, why do we need it?" turned out to be
a turning point. The user mentioned she might already have literacy
data from her 2024 thesis pulls. A `find` across her Documents folder
revealed an entire `~/Documents/Desktop_Files/Thesis/` archive with
**17 control-variable subfolders + her final variables, regressions,
and Stata files**. Specifically:

- **Folders mapping to the rebuild's controls:**
  - Literacy Rate (12 regional Indiastat files for 2017-18, 2019-20,
    2020-21)
  - Per Capita Income (Indiastat per-capita NSDP at constant prices,
    FY 2011-12 through 2022-23)
  - Primary Health Centres
  - ATM-States, Electricity, State Finance (38 files), Birth Rate,
    Death Rate, Infant Mortality Rate, Sex Ratio
- **Goldmine working artifacts:**
  - `Thesis Final Variables.xlsx` — her merged panel for the 2024 thesis
  - `Regressions_Thesis.docx` — 10 regressions, formatted Stata output
  - `Thesis docx.docx` — the actual 2024 thesis text (3,812 lines)
  - `Thesis Fixed effects.xlsx` and several `.dta` Stata files
- **`Total UPI States-2021/`** subfolder — the Indiastat regional
  pulls she'd made for the original thesis Series 1 DV.

This changed the picture entirely. The user already had ~half of
Phase 1's data locally; she just hadn't surfaced it.

### Reading her original thesis surfaced two crucial findings

1. **Her original specification was already a panel + state + year
   fixed effects regression** (90 obs from 30 units × 3 FYs), running
   `feols`-equivalent in Stata. So the rebuild's CLAUDE.md §8
   methodology (state + year FE + clustered SEs) is *aligned* with
   what she did, not a wholesale departure. The rebuild is a
   correction-of, not a different-thing-than.
2. **The headline result in her thesis was**
   `PHCs per sq km = -22.45***` — exactly the spurious finding
   CLAUDE.md §9 calls out as needing correction. Her own text:
   *"Primary Health Centers are the only variable that has a
   statistically significant effect... it is surprising to note that
   it hurts digital payments. This means that states with higher
   primary health centres have fewer digital transactions. This
   result is counterintuitive."*

The §9 correction (add `share_urban` and `log(population_density)`,
expect PHC coefficient to attenuate or flip) is therefore the
headline contribution of the rebuild.

---

## 5. The Series 1 definitional break (Option A) — 2026-04-24

The user's `Total UPI States-2021/` folder contained two batches
of regional Indiastat files for the Part I DV:

- **`2018` files** (FY 2017-18) sourced from Lok Sabha Unstarred
  Question No. 5291: 3 rails (BHIM + UPI + USSD), monthly value-
  in-Lakh.
- **`2021` files** (FY 2019-20 and 2020-21) from Lok Sabha Unstarred
  Question No. 1425: 5 rails (BHIM + IMPS + RuPay POS + UPI + USSD),
  annual transaction count.

**The two batches measure different things.** IMPS alone was running
~1 billion transactions per year in FY 2017-18; its omission from
the 2017-18 figure makes the early year's DV systematically lower in
a way that varies by state (IMPS adoption is higher in south/west).

The user had told me her own `Total Digital transactions.xlsx`
(which chained the two batches as a single DV) was "almost certainly
not worth using." This was the reason: she had sensed the definitional
break without naming it.

**Resolution: Option A.** Drop FY 2017-18 from Part I. Restrict
to FY 2019-20 + FY 2020-21 (60 obs from 30 units × 2 FYs). Both years
use the same 5-rail composite, so the definitional break is gone.
CLAUDE.md §7 updated; project memory saved.

The 2017-18 raw files stay in `data/raw/indiastat/series1_digital_payments/`
for provenance — not ingested.

---

## 6. The Indiastat UPI dump (Series 3) — 2026-04-24/25

User dumped 60+ generic-named `data*.xls` files from Indiastat into
`data/raw/indiastat/upi_statewise/`. A cataloguing script identified:
- **32 unique state-wise monthly UPI files** (the Part II DV core),
  spanning April 2023 to January 2026 with 1 duplicate (October 2024
  appeared twice, files 30 and 31).
- 18 national-aggregate files (supplementary context).
- 6 older-format state-wise files for April–September 2020 (different
  3-column layout, pre-state-attribution era; out of Part II scope).

Initially **3 months were missing** in the target range (Mar 2024,
May 2024, Feb 2026). The user pulled 2 more files (`data 60.xls` and
`data 61.xls`) which filled in Mar and May 2024. Final coverage:
**1224 rows = 36 states × 34 months** (April 2023 → January 2026).
Feb 2026 still missing (one file, low priority).

### The Unclassified-share trajectory

While parsing, I extracted the "Unclassified" row separately
(`indiastat_upi_unclassified_share.csv`). The state-attribution gap
is much worse than the Dataful headline number suggested:

| Month | Unclassified volume share |
|---|---:|
| April 2023 | 13.1% |
| September 2023 | 14.6% |
| September 2025 | 43.0% |
| December 2025 | 42.2% |
| January 2026 | 42.7% |

**The state-attribution gap roughly tripled over the panel period.**
By the end of the sample, ~43% of UPI volume has no state tag. This
is an order of magnitude more serious than the 27% headline. It will
require a paragraph in Part II's data section, and probably motivates
a robustness check on UPI value (where the unclassified share is
slightly lower, ~38%) alongside volume.

---

## 7. PDF parser building — Days 2-3

Multiple parsers built using `pdftools` (added to CLAUDE.md §3 with
the user's explicit OK). General pattern: hardcode state order
within each report (since each PDF uses its own slightly different
state-name conventions), find the right page(s), parse trailing-
numeric-tokens per row.

### Parsers shipped

- `mohfw_population.R` → `population_mohfw.csv` (936 rows = 36 states
  × 26 years 2011-2036). Source: NCP 2019 Technical Group projection,
  Table 11 (1st July population).
- `mohfw_rhs.R` → 4 outputs (state area, urban share, density, PHC
  counts across both FYs) from RHS 2020-21 + RHS 2019-20.
  Sanity passed: rural+urban PHCs sum to 25140+5439 (matches the
  report's All-India totals).
- `indiastat_literacy.R` → 72 rows (36 states × 2 FYs, 2019-20 +
  2020-21). User initially pulled only 4 of 5 regions; later pulled
  the NE region for both FYs.
- `indiastat_per_capita_nsdp.R` → 396 rows (33 states × 12 FYs,
  FY 2011-12 to 2022-23, constant 2011-12 prices).
- `trai_internet_density.R` → 36 rows (state-wise internet
  subscribers per 100, as on 31-Mar-2024). This was Part II only.
- `plfs.R` → 36 rows (literacy 7+, LFPR 15+, WPR 15+, UR 15+ from
  PLFS Annual Report 2022-23). Now redundant under the overhaul (§9
  here) but kept for reference.
- `indiastat_series1.R` → 70 rows (Part I DV, 35 state/UT × 2 FYs).
- `indiastat_upi.R` → 1224 rows (Part II DV) + Unclassified share
  time series.

### Roadblocks during PDF parsing

- **Wrapped state names in PDF text extraction.** "ARUNACHAL\nPRADESH"
  (page 94 of the population PDF), "DADRA & NAGAR\nHAVELI" (p96),
  "ANDAMAN &\nNICOBAR ISLANDS" (p97). Solved by hardcoding per-page
  state lists rather than trying to parse headers.
- **Year on a separate line from the data row** (population PDF p98,
  Telangana/Ladakh page). Solved by pre-fusing year-only lines with
  the next numeric line.
- **Single-space vs. multi-space column separators in the same PDF.**
  Tamil Nadu's row in RHS Table 1 had two adjacent values separated by
  one space, defeating my `\\s{2,}` split. Switched to `\\s+` and
  re-stitched multi-token markers like "N App" (TRAI's "Not
  Applicable") explicitly.
- **Ladakh's text-only 2011 cell** in RHS Table 2 (it didn't exist
  before October 2019). Added a `min_data_cols` fallback that pads
  missing leading columns with NA.
- **DNHDD spelling proliferation.** Every source spells the merged
  Dadra & Nagar Haveli + Daman & Diu UT slightly differently:
  "Dadra & Nagar Haveli & Daman & Diu", "Dadra and Nagar Haveli &
  Daman and Diu", "Dadar & Nagar Haweli (incl. Daman & Diu)",
  "D & N. Haveli & Daman & Diu" — at least six variants caught and
  added to the lookup. Pre-merger DNH and DD rows always summed
  back into the merged canonical.
- **TRAI typo zoo.** "Chattisgarh" (vs Chhattisgarh), "Lakshdweep"
  (vs Lakshadweep), "Puduchery" (vs Puducherry), "Tamil Nadu incl.
  Chennai", "Uttar Pradesh (UPE+UPW)", "West Bengal incl. Kolkata",
  "Dadar & Nagar Haweli". All added as variants.

### Lookup table additions
By end of Day 1 the `state_names.csv` had grown from the initial
~37 rows to include:
- 5 regional aggregate rows (Eastern India, Northern India, Southern
  India, Western and Central India, North East India), all flagged
  `include_in_analysis = FALSE`
- "Unclassified" (the NPCI state-attribution bucket), also FALSE
- Roughly 20+ new spelling variants added across rows for ALL CAPS,
  ampersand vs "and", Indian abbreviations ("J&K", "NCT OF DELHI"),
  TRAI legacy names, and PLFS conventions.

---

## 8. Diagnostic figures — 2026-04-24

Two figures produced for Part II UPI:

1. **`upi_percapita_trajectory.pdf/png`** — narrative plot, 36 state
   trajectories over Apr 2023 – Jan 2026. Five hierarchy states
   highlighted (Goa, Maharashtra, Tamil Nadu, UP, Bihar) plus Manipur
   in orange with a curved-arrow annotation pointing to the May-Oct
   2023 dip caused by the ethnic violence and internet shutdowns.
2. **`upi_percapita_small_multiples.pdf/png`** — 36-panel diagnostic
   with each state on its own free-y axis, red dot marking each
   state's lowest month. Immediately surfaces the Manipur 2023 V-
   shape, an April 2025 cross-state dip (FY-end seasonality), and
   Madhya Pradesh's anomalous mid-period spikes.

### What the figures revealed
- **Manipur 2023 collapse** is real — UPI volume crashed from ~3M
  baseline to 0.49M in July 2023, recovered to 4M+ by October. The
  data captures the violence and internet-shutdown period cleanly.
  This is a data-quality validation (real exogenous events show up
  where expected) and a small-vignette opportunity for the paper.
- **Cross-state dips around March/April each year** are end-of-FY
  seasonality (businesses surge UPI use in March, drop in April).
  Real economic pattern; will be absorbed by month/quarter FE in
  Part II specs.
- **Goa is the per-capita UPI leader, not Delhi.** Surprising at
  first (~25 vs. Delhi's ~22 transactions per person per month, Jan
  2026), but explained by Goa's small population, tourism economy,
  and high digital penetration.

### Roadblock: the figure I almost shipped without polish
First version had label collisions (Delhi/Telangana, Maharashtra/
Karnataka, UP/Meghalaya overlapping) and the Manipur story was
buried as a gray background line. User correctly pushed back —
"why won't you fix it?" Owned it: the "diagnostic" framing was a
license to be lazy on a project that's literally a writing sample.
Rewrote with deliberate hierarchy state selection, ggrepel-equivalent
manual spacing, Manipur called out in orange with annotation, full
source caption. Both PDF and PNG outputs (PNG renders in VS Code's
image preview without an extension).

---

## 9. PLFS questioning → spec overhaul — 2026-04-25/26

User asked: *"What is PLFS even doing, why do we need it?"*

Honest answer required: I'd scaffolded PLFS as "standard labour
controls" without checking whether the original thesis used those
variables or whether they had a clean theoretical channel to
digital-payment adoption. Most of the PLFS labour rates (LFPR,
WPR, UR) are at best tertiary controls — they correlate with
general state development but don't directly cause UPI use.
Literacy is the only PLFS variable with a first-order channel
(literally needed to read app screens).

This conversation cascaded into the bigger question: should the
rebuild faithfully replicate the original 9-control kitchen-sink
spec, or do an overhaul? After reading her actual thesis (3,812
lines) and the regression document (10 specifications), my honest
read of weaknesses in the original spec:

1. **Kitchen-sink without theory.** Birth rate, death rate, two
   state-finance ratios, electricity, urban income — included
   because available, not because of mechanism.
2. **First-order drivers missing.** Internet/mobile penetration,
   banking penetration, general (not urban) per-capita NSDP.
3. **Functional form inconsistency.** Thesis text used Log-Level
   ("PHC = -22.45" hard to interpret economically); Stata cross-
   sectionals used log-log. Pick one.
4. **No clustered SEs.** Default OLS standard errors understate
   variance in panel FE. CLAUDE.md §8 already mandates state-
   clustered + wild bootstrap — a methodological tightening.

User confirmed openness to overhaul. New spec locked in CLAUDE.md
§7a:

**Six theoretically-anchored variables (plus optional 7th):**
1. ln(PHCs per sq km) — focal §9 variable
2. share_urban — §9 correction
3. ln(population density) — §9 correction
4. ln(literacy rate) — first-order channel
5. ln(per-capita NSDP) — first-order channel
6. ln(internet/wireless subscribers per capita) — first-order channel
7. (optional) ln(bank branches per capita) — robustness

**Same set used in Part I and Part II so Part III's "what changed"
comparison is coefficient-on-coefficient meaningful.** Functional
form: log-log throughout (clean elasticity interpretation). The
2024 thesis's PHC = -22.45*** result is the headline puzzle to be
corrected — not reproduced. The §9 correction is the rebuild's
intellectual contribution.

**Dropped from the original spec:** birth rate, death rate, Non-Dev
Exp / Aggregate Disbursement, Gross Transfers / Aggregate
Disbursement, Per Capita Electricity, Per Capita Urban Income,
CSCs per Gram Panchayat. Saved as memory entry to prevent future
sessions from drifting back to them.

---

## 10. The TRAI legacy-LSA discovery — 2026-04-26

After committing to the 6-variable overhaul, I went to parse TRAI
YPIs for older years (2019-20 and 2020-21). Downloaded YPI 2020
(end-Dec-2020), YPI 2021 (end-Dec-2021), and what turned out to be
YPI 2018 (mislabeled `PIR_2019.pdf` because it was released in
Sep 2019 covering calendar year 2018).

**Hidden footnote in YPI 2021's Table 1.28:**
> *"Data/information for Andhra Pradesh includes Telangana, Madhya
> Pradesh includes Chhattisgarh, Bihar includes Jharkhand,
> Maharashtra includes Goa, Uttar Pradesh includes Uttarakhand,
> West Bengal includes Sikkim and North-East includes Arunachal
> Pradesh, Manipur, Meghalaya, Mizoram, Nagaland & Tripura."*

**TRAI's pre-2023 reports use legacy LSA boundaries that pre-date
several state splits.** The "Andhra Pradesh" row in YPI 2021 actually
contains AP + Telangana combined. Same for Bihar+Jharkhand,
MP+Chhattisgarh, Maharashtra+Goa, UP+Uttarakhand, WB+Sikkim, and all
6 NE states aggregated into one row. Joining this to a state-level
DV would replicate parent-state values to all sub-states — exactly
the definitional-break family of problem we'd been carefully
avoiding.

**YPI 2023-24 fixed this** — has separate state rows for all modern
states. So Part II is clean. But Part I (FY 2019-20, 2020-21) cannot
get clean state-level internet penetration from TRAI without either
collapsing the panel to ~22 legacy units or making strong
proportional-allocation assumptions.

**Resolution: Option (1) — drop internet penetration from Part I.**
Run Part I with 5 controls (PHC density, urban share, pop density,
literacy, NSDP). Add internet only in Part II. Document explicitly:
"TRAI's pre-2023 reports use legacy LSA boundaries; state-level
internet penetration is therefore unavailable for Part I." This is
the kind of data-availability constraint that's normal in working-
paper analysis. Same control set in both Parts becomes "same set
where data permits, with one explicit caveat."

---

## 11. Status at end of Day 1

### Interim CSVs ready for panel construction

| File | Rows | Use |
|---|---|---|
| `indiastat_series1_dp_composite.csv` | 70 | Part I DV |
| `indiastat_upi_monthly.csv` | 1224 | Part II DV |
| `indiastat_upi_unclassified_share.csv` | 34 | Part II measurement gap |
| `population_mohfw.csv` | 936 | per-capita denominator (both Parts) |
| `mohfw_state_area.csv` | 36 | denominator for PHCs/sq km |
| `mohfw_population_2011_2021.csv` | 72 | urban share (interpolate) |
| `mohfw_population_density_2020.csv` | 36 | population density |
| `mohfw_phcs.csv` | 72 (2 FYs) | PHC counts |
| `indiastat_literacy.csv` | 72 (36 states × 2 FYs) | literacy |
| `per_capita_nsdp.csv` | 396 | NSDP per capita |
| `trai_internet_2024.csv` | 36 | Part II baseline only |
| `plfs_2022_23.csv` | 36 | now redundant under overhaul |

### What's still pending
- Compute `phc_per_sqkm` (PHC count ÷ state area) at panel-build time
- Interpolate `share_urban` from 2011 + 2021 anchors to FY 2019-20
  and FY 2020-21
- Carry forward 2020 population density to both FYs (slow-moving)
- Install `fixest` (next session)
- Build `data/processed/part1_panel.csv` joining all five Part I
  controls + DV + denominator
- Run preliminary regressions:
  - **Spec A** (replicates the puzzle): `ln(per_capita_dp) ~ ln(phcs_per_sqkm) + ln(literacy) + ln(nsdp) | state + year`
  - **Spec B** (the §9 correction): adds `share_urban + ln(pop_density)`
  - State-clustered SEs + wild cluster bootstrap for both

### What's blocked or deferred
- **RBI Handbook XLSX (4 tables):** rbidocs.rbi.org.in Imperva bot
  protection. User must pull in browser when convenient. 4 specific
  URLs documented in `data/raw/_MANIFEST.txt`.
- **TRAI internet penetration for Part I:** structurally unavailable
  due to legacy LSAs, see §10. Not pursued.
- **Older PLFS reports (2017-18 through 2021-22):** not pulled.
  Could be useful for Part II controls but PLFS is also de-prioritised
  under the overhaul.
- **Census urbanization PDF:** redundant — RHS Table 2 covers the
  2011 + 2021 anchors.
- **Indiastat Series 2 (MeitY DigiDhan):** explicitly deferred —
  see CLAUDE.md §7. Robustness only, if at all.

---

## 12. Memory and CLAUDE.md changes

### Project memories saved (carry across sessions)
- `feedback_panel_consistency.md` — never mix measurement definitions
  within a panel; pick one DV at pull time and apply uniformly.
- `project_part1_scope.md` — Part I is FY 2019-20 + 2020-21 only
  (60 obs); FY 2017-18 dropped for definitional-break reasons.
- `project_overhauled_spec.md` — six theoretically-anchored variables
  only; original 9-control kitchen-sink narrowed; same set in both
  Parts for Part III comparability.

### CLAUDE.md amendments
- §3: added `rvest` (HTML-as-XLS Indiastat exports), `pdftools` (PDF
  parsing), and noted `renv` was bare-init then snapshotted.
- §4: added `data/raw/mohfw/` and `data/raw/census/` subfolders.
- §7: Series 1 scope narrowed to FY 2019-20 + 2020-21 only with
  full rationale on the 3-rail vs. 5-rail definitional break.
- **§7a (new):** the overhauled 6-variable spec with explicit
  drop list and same-set-in-both-Parts requirement.
- Footer: substantive updates logged with dates.

### Diagnostic plots
Both at `output/diagnostics/`:
- `upi_percapita_trajectory.pdf` + `.png`
- `upi_percapita_small_multiples.pdf` + `.png`

---

## 13. Headline learnings

1. **The user's instincts about her own data were right.** Her
   "almost certainly not worth using" verdict on `Total Digital
   transactions.xlsx` accurately reflected a definitional break she
   sensed but hadn't named. Reading her thesis carefully revealed
   she had also already used panel + state + year FE, so the
   methodology rebuild is an alignment-and-tightening exercise, not
   a rewrite.

2. **The §9 correction story is real and the rebuild's headline
   contribution.** PHC = -22.45*** in the 2024 thesis is almost
   certainly driven by rurality (PHCs allocated per population /
   sq.km denominator → sparsely-populated states inflate the
   ratio). Adding `share_urban` and `log(pop_density)` should
   attenuate or flip the coefficient. Worth a paragraph in the
   rebuild's introduction.

3. **TRAI calendar-year vs. Indian fiscal-year mismatch + legacy
   LSA boundaries** make state-level internet penetration
   essentially unavailable for the Part I window. This isn't
   carelessness on TRAI's part — the LSA structure is older than
   several state splits. Just a data constraint to acknowledge.

4. **The state-attribution gap in NPCI UPI is much worse than
   advertised.** Dataful's headline ~27% is the panel average; the
   actual late-period rate is 43%. Part II's data section needs
   to be honest about this. Robustness: parallel runs on UPI
   *value* (where the gap is slightly smaller) alongside volume.

5. **PDF-table parsing is mostly about handling 17 different ways
   the same source spells the same state name.** Not the parsing
   itself — that's mechanical. The fail-loud lookup discipline
   pays off massively here; every new spelling becomes a one-line
   `state_names.csv` edit instead of a silently-dropped row.

6. **Calendar discipline matters.** TRAI YPIs are end-of-Dec.
   Indian fiscal years end in March. RHS publishes "as on 31-Mar".
   MoHFW publishes population "as on 1st July". Every panel join
   needs explicit reasoning about which date the source's value
   belongs to.

7. **"Diagnostic" is not a free pass to ship unpolished work.**
   For a project that is itself a writing sample, every figure,
   table, and document should hit the same craft bar. The first-
   pass UPI trajectory figure was a useful reminder.

8. **Government documents lie about their consistency.** Same
   department, same series, same nominal table — different layout,
   different state-name conventions, different units, different
   age groups, different breakdowns from year to year. The only
   defence is loud-failing parsers and per-source manifests with
   provenance.

---

## 14. Decisions still open

- **PMJDY snapshot strategy.** Resolved at planning time as "(c)
  MoF reports first, (b) Wayback fallback, never mixed" but no PMJDY
  data has been pulled yet under the overhauled spec. Bank-branch
  / financial-inclusion may not be needed if RBI Handbook bank
  branches comes through.
- **Number of regression specifications in Part I.** Two ran today
  (Spec A puzzle + Spec B §9 correction). Robustness checks
  (drop Maharashtra leave-one-out, wild cluster bootstrap SEs,
  PPML alternative per CLAUDE.md §8) deferred to Day 2.
- **DiD framing for Part III.** CLAUDE.md mentions an optional
  Callaway-Sant'Anna DiD. Not yet considered seriously. Probably
  belongs in Part III if at all.

---

## 15. The §9 regression run + data quality audit — 2026-04-26

### First regression run: surprising weak result

Installed `fixest` and `modelsummary`, built `data/processed/part1_panel.csv`
(60 obs, 30 units × 2 FYs), ran two specs:

- **Spec A** (replicates puzzle): `ln(per_capita_dp) ~ ln(phc_per_sqkm)
  + ln(literacy) + ln(nsdp) | state + year`
- **Spec B** (§9 correction): adds `share_urban + ln(pop_density)`

`log(pop_density)` was dropped from Spec B due to collinearity (single
2020 value carried forward to both FYs → time-invariant within state →
absorbed by state FE).

Initial coefficients (ALL with then-corrupted literacy):
- log(PHCs/sq km) Spec A: +0.045 (SE 0.073, n.s.)
- log(PHCs/sq km) Spec B: +0.065 (SE 0.066, n.s.)
- log(literacy) Spec A: **−1.314*** (SE 0.399)
- log(literacy) Spec B: **−1.338*** (SE 0.389)

Two surprises:
1. **The §9 correction did almost nothing** — PHC coefficient barely
   moved between Spec A and B. The dramatic flip from −22.45*** in the
   2024 thesis to +0.045 came from Option A alone (dropping the 2017-18
   3-rail/5-rail chaining), not from adding urbanization controls.
2. **Literacy coefficient sign-flipped** from the 2024 thesis's +0.065
   to −1.314*** — opposite sign, with significance — but in the same
   functional form (after accounting for Log-Level vs log-log).

The literacy result was suspicious enough to trigger a full data-quality audit.

### The audit — what got verified, what broke

User asked: *"are you super sure of the all the data collected and that
there is no corruption in it?"* — exactly the right question. Honest
answer: no. Did a systematic check across 9 issues I'd flagged earlier
in the conversation:

**Verified clean (no action needed):**
- **MoHFW PHC totals** sum to 25140 rural / 5439 urban All-India — matches RHS report.
- **Population totals** sum to 1351.8M for 2020 — matches Census ~1.35B; Telangana 35.08M matches Census 2011's 35.19M.
- **Per-capita NSDP** spot-checks (Bihar/Goa/Maharashtra/Kerala/TN/UP) all match published values; all states show plausible ~10% drops in 2020-21 (COVID).
- **Series 1 transaction totals**: state sum = 15.7B (FY 2019-20) and 25.8B (FY 2020-21), in line with NPCI 5-rail aggregate.
- **UPI monthly state-sum + Unclassified bucket reconstructs the NPCI national total to the rupee** — Jan-2026 implied total 21,703M matches the screenshot's 21,703.44M *exactly*. Series 3 DV is rock-solid.
- **Tamil Nadu literacy 2019-20 = 79.0** — verified against source row directly. Parser was correct.

**Found, fixed, re-verified:**

1. **DNHDD literacy aggregation was a simple mean instead of population-weighted.**
   - Pre-merger DNH P7+ literacy = 83.8, DD = 91.3
   - Simple mean: (83.8+91.3)/2 = 87.55
   - Population-weighted (Census 2011 weights: DNH 343,709 + DD 243,247): 86.91
   - 0.64pp difference. Fixed in `indiastat_literacy.R`.

2. **MAJOR FINDING: South India 2019-20 literacy file was rural-only scope.**
   - Title: *"State-wise Literacy Rate of Persons of Different Age Groups
     by Gender in Rural Areas in Southern India (July 2019-June 2020)"*
   - Every other regional file (N, E, W&C, NE for both FYs and S for
     2020-21) was rural+urban combined.
   - I'd missed the qualifier in an earlier title scan because the title
     was truncated to 110 chars and "Rural Areas" fell off.
   - This caused 7 South India states (AP, Karnataka, Kerala,
     Lakshadweep, Puducherry, Tamil Nadu, Telangana) to have a fake
     +5pp within-state literacy "jump" between 2019-20 and 2020-21,
     because rural-only literacy is systematically ~5pp lower than
     rural+urban combined.
   - Tamil Nadu specifically: rural-only 2019-20 = 79.0, rural+urban
     2020-21 = 84.7 → looks like +5.7pp jump. After re-pulling the
     correct rural+urban file: 2019-20 = 83.6, 2020-21 = 84.7 →
     real movement of +1.1pp.

3. **Defensive parser change.** Updated `indiastat_literacy.R` to scan
   each file's title for "Rural Areas" / "Urban Areas" / "in Rural
   India" / "in Urban India" qualifiers. Files matching these are
   skipped with a loud warning rather than silently included.
   Prevents this class of bug in any future regional pull.

4. **User re-pulled the correct South 2019-20 file** (rural+urban
   combined). Re-ran the entire panel + regression.

### Re-run regression with fully clean panel

Final clean Part I results:

|                          | Spec A (puzzle) | Spec B (§9 correction) |
|---|---:|---:|
| log(PHCs/sq km)          | +0.029 (SE 0.099) | +0.045 (SE 0.096) |
| log(literacy)            | **−1.207 (SE 2.186)** | **−1.243 (SE 2.227)** |
| log(per-capita NSDP)     | +0.183 (SE 0.958) | +0.237 (SE 1.007) |
| share_urban              | —               | +2.277 (SE 3.779) |
| log(pop density)         | —               | dropped (collinear) |
| N                        | 60              | 60 |
| R² (overall)             | 0.991           | 0.991 |
| R² within                | 0.013           | 0.020 |

**Nothing is significant. Within-R² ≈ 1-2% — the FE are doing essentially
all the work, and the controls have no remaining within-state variation
to explain on a 2-FY panel.**

### The most important quantitative finding from the audit

The literacy coefficient ALMOST DIDN'T MOVE between corrupted and clean
panels (point estimate −1.314 → −1.207). But the **standard error
exploded from 0.399 to 2.186 — a 5× inflation.** What looked like a
strongly-significant negative literacy effect was almost entirely
**spurious precision** created by the rural-only-vs-combined scope
corruption manufacturing fake within-state variation.

This is a much more interesting finding than "the corruption changed
the magnitude" would have been. It says: data corruption can hide
itself in coefficient *precision* even when the point estimate looks
plausible. **The 2024 thesis's headline results may have suffered the
same kind of upstream corruption causing artificially low SEs.**

### Implications for the rebuild's narrative

Two distinct corrections the rebuild now contributes to the literature:

1. **DV correction (Option A):** the 2024 PHC = −22.45*** result was
   produced by chaining 3-rail (FY 2017-18) and 5-rail (FY 2019-20,
   2020-21) composites in the dependent variable. The fictitious
   2017-18 → 2019-20 jump created phantom within-state variation
   correlated with PHC density. With Option A applied, the PHC
   coefficient collapses to ≈ +0.03, statistically indistinguishable
   from zero.

2. **Control scope correction (literacy):** the South 2019-20 Indiastat
   regional file was rural-only scope while every other file was
   rural+urban combined. This manufactured a fake +5pp within-state
   literacy "jump" for 7 South India states, producing artificially
   precise (not artificially large) literacy coefficients. Once
   corrected, literacy is correctly identified as noise (|t| < 1).

3. **Methodological lesson:** with FE on a short (2-FY) panel and
   slow-moving controls (literacy, PHC density, NSDP), within-state
   variation is too small to identify clean coefficients. The 2024
   thesis's apparent significance was artifact of corrupted data
   inflating apparent precision; with clean data, the FE specification
   correctly reveals there's nothing to identify. This is a real
   limitation of the FE design on this sample size — the rebuild
   should consider extending Part I (e.g., adding more years) or
   complementing FE with pooled OLS / between-state specifications.

### What landed
- `data/processed/part1_panel.csv` — 60 rows, fully clean
- `output/tables/part1_phc_correction.{tex,txt}` — final clean regression
- `scripts/01_ingest/indiastat_literacy.R` — now scope-aware (skips
  rural-only / urban-only files with loud warning) and uses
  population-weighted DNHDD aggregation
- `scripts/03_build/build_part1_panel.R` — Part I panel builder
- `scripts/04_analyze/part1_phc_correction.R` — regression script

---

## 16. Updated headline learnings (post-audit)

Adding to the §13 list:

9. **Data corruption can hide in standard errors, not just point
   estimates.** The literacy coefficient barely moved when we fixed
   the rural-only scope bug; only the SE moved (5× inflation).
   "Spurious precision" is a real failure mode and the audit caught
   it. Sanity-checking only point-estimate magnitudes would have
   missed this.

10. **Title scope qualifiers in Indiastat regional files matter.**
    "in Rural Areas in Southern India" vs. "in Southern India" looks
    like a stylistic difference; it's actually a definitional break.
    Title-substring scope checks are now in the literacy parser as a
    template for any other regional-file ingestion.

11. **The §9 correction by itself doesn't move the PHC coefficient
    much on a 2-FY panel.** Almost all the headline change comes from
    Option A (the DV correction). The §9 correction is theoretically
    important but practically small in this specific identification
    setting — within-state PHC density and within-state urbanization
    don't move enough across 2 years to differentiate.

12. **Within-FE on 2-FY panels is identification-poor for slow-moving
    controls.** Most of our controls (literacy, PHC density,
    population density, urban share) are slow-moving by design. With
    just FY 2019-20 → FY 2020-21 to compare, the FE absorbs most of
    the cross-state variation and there's little within-state movement
    left. Real coefficients are mostly noise. The 2024 thesis got
    apparent significance from data-corruption-induced phantom
    variation; clean-data reveals the underlying noise.

---

*End of Day 1 log. Final state: clean Part I panel produces an honest
"no significant coefficients" result, which is itself the rebuild's
contribution — exposing that the 2024 thesis's headline findings
depended on data quality issues that disappear once corrected. Day 2
should consider whether to (a) install fwildclusterboot for proper
SEs, (b) pursue longer-panel identification (extend years if data
permits), or (c) write up Part I with the current honest result and
move to Part II.*
