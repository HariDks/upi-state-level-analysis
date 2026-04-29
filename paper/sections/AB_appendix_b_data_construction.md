# Appendix B. Data construction notes

This appendix documents the source, parsing, and construction of every variable used in Parts I and II. The full ingestion code is in `scripts/01_ingest/` and the panel-build scripts in `scripts/03_build/`.

## State-name reconciliation

Every Indian data source spells state names differently. Census, RBI, NPCI, MoSPI, and Indiastat each use slightly different conventions, and within Indiastat the conventions vary by year and by report. We reconcile every incoming state name through a single canonical lookup table at `lookups/state_names.csv`. The lookup contains, for each canonical state or union territory, a pipe-separated list of every variant spelling encountered in the project. Every ingestion script joins through this table before writing to interim. Unrecognised spellings cause the script to fail loudly with the offending strings; we add new variants to the lookup and re-run rather than silently dropping rows or fuzzy-matching.

The lookup carries explicit treatment of three boundary cases. **Jammu and Kashmir** and **Ladakh** are reported as a single unit by some sources (Series 1 in Part I, RBI before 2019) and as separate units by others (post-2019 Indiastat, MoHFW). The canonical lookup keeps them as separate canonical entries; sources reporting J&K combined are aggregated to a single canonical "Jammu and Kashmir" row and Ladakh is absent from those sources. **Telangana** and **Andhra Pradesh** are separate units throughout our sample period (Telangana was bifurcated in June 2014, before the start of either Part I or Part II); no special handling is needed in our analytical period. **Dadra and Nagar Haveli** and **Daman and Diu** were merged into a single union territory in January 2020. Both pre-merger spellings appear in the lookup as variants of the merged canonical name; sources that report them as separate rows are aggregated by sum to the merged canonical.

## Dependent variable, Part I (Series 1 5-rail composite)

Source: Indiastat, "State-wise Number of Digital Payment Transactions through BHIM App, IMPS, RuPay on POS, UPI and USSD", five regional XLS files (HTML-as-XLS) covering Eastern, North-Eastern, Northern, Southern, and Western/Central India. The data originate from Lok Sabha Unstarred Question No. 1425, dated 28 July 2021. Each regional file reports an annual transaction count for FY 2019-20 and FY 2020-21 by state.

Parsing: HTML extraction via `rvest` (the files are saved as `.xls` but contain HTML tables, not Excel binary). The first table in each file contains the data; the second table contains source notes. Numeric values are read with comma stripping. Five regional files produce 36 raw rows (one per state including pre-merger Dadra and Nagar Haveli + Daman and Diu separately); after canonical reconciliation and aggregation across the merged DNHDD canonical, we have 35 unique state canonicals with two FYs each, for 70 state-FY observations.

Why FY 2017-18 is not included: an earlier Indiastat compilation (Lok Sabha Unstarred Question 5291, FY 2017-18) reports volumes on a three-rail composite, BHIM + UPI + USSD only, without IMPS or RuPay-on-POS. Chaining the two compilations would mix definitionally different DVs. We restrict Part I to the two FYs published on the consistent 5-rail composite. Decision documented in `data/raw/indiastat/series1_digital_payments/_MANIFEST.txt`.

## Dependent variable, Part II (pure UPI monthly)

Source: Indiastat, "State-wise Volume and Value of Transactions Made through Unified Payments Interface (UPI) in India", one HTML-as-XLS file per month, 35 files spanning April 2023 through January 2026. Each file reports per-state UPI transaction volume (in millions) and value (in rupees crore) for the named month.

Parsing: same `rvest` approach. Each month is a separate file; we batch-ingest all 35 into a single long table with columns `state_canonical`, `state_code`, `year_month`, `upi_volume_million`, `upi_value_crore`. The October 2024 file appears twice in the source download (one apparent duplicate); we de-duplicate at ingestion. The resulting interim file is at `data/interim/indiastat_upi_monthly.csv` with 1,260 rows (36 states × 35 months).

Per-capita normalisation in the build: for each twelve-month analytical window we compute a state's average monthly per-capita UPI as the mean of monthly volumes within the window divided by the mid-period population (defined below).

## Population

Source: Ministry of Health and Family Welfare, Population Projections for India and States 2011-2036 (the standard inter-census projection report used across Indian government statistical work). The PDF reports projected populations as of 1 July of each year from 2011 through 2036.

Parsing: pdftools page extraction targeting the state-wise tables. Output: `data/interim/population_mohfw.csv` with one row per state per year. Mid-period denominators in Parts I and II are computed as the mean of the two adjacent 1-July populations, placing the denominator near the midpoint of the relevant fiscal year (or rolling window).

## Per-capita Net State Domestic Product

Source: Indiastat compilation of MoSPI state-account data, expressed at constant 2011-12 prices. Two ingested workbooks cover separate FY ranges with overlapping years for cross-validation; we use the values from whichever workbook reports the more recent vintage for each state-year. Output: `data/interim/per_capita_nsdp.csv` covering FYs 2011-12 through 2024-25.

Coverage by year (states reporting non-missing values): 33 for FYs 2011-12 through 2022-23 (the same three states are persistently missing, Lakshadweep, Ladakh, Dadra and Nagar Haveli and Daman and Diu); 32 for FY 2023-24 (one additional state still in advance-estimates phase); 25 for FY 2024-25 (a larger set of states delays advance-estimates publication). The build scripts apply a fallback chain, for each window's NSDP, use the named FY first, then the prior FY, then the FY before that, to maximise observations. The three persistently-missing states are dropped from both regression samples.

## Literacy

Source: Indiastat compilation of PLFS-derived state-level literacy rates (persons aged 7 and above who can read and write a simple statement with understanding). Output: `data/interim/indiastat_literacy.csv` covering FYs 2019-20 through 2023-24 plus a CY 2025 release.

Coverage: 36 states for every year in the panel. We use FY-specific values for Part I (FY 2019-20 and FY 2020-21) and FY 2023-24 carried across windows for Part II (newer literacy data is not yet available for all states on a comparable basis).

## Urban population share

Source: Census 2011 enumerated urban–total population ratios as the lower anchor; Ministry of Health and Family Welfare 2021 projected urban–total population ratios as the upper anchor. The 2021 figure is a projection rather than an enumerated census because the 2021 decennial census was deferred; we use the same MoHFW report that provides the population projections.

Construction: linear interpolation between 2011 and 2021 anchors to the midpoint year of each analytical window, 2019.5 for FY 2019-20, 2020.5 for FY 2020-21, 2023.5 for Part II W1, 2024.5 for Part II W2, and 2025.5 for Part II W3. Two states (Lakshadweep and Chandigarh) interpolate to fractional values slightly above 1.0 in the post-2021 windows; we cap these at 1.0. The cap affects six state-window observations across the two parts and does not move any regression coefficient materially.

## PMJDY beneficiaries per adult

Numerator: cumulative count of basic savings accounts opened under the Pradhan Mantri Jan Dhan Yojana (launched August 2014), by state, captured from snapshots of the Department of Financial Services portal page `pmjdy.gov.in/statewise-statistics` archived on the Internet Archive's Wayback Machine. Five snapshots are used:

| Wayback date | Used for | Distance to anchor |
|---|---|---|
| 2019-10-17 | Part I FY 2019-20 | 5.5 months before FY end |
| 2021-03-05 | Part I FY 2020-21 | 26 days before FY end |
| 2024-02-27 | Part II W1 (FY 2023-24) | 33 days before window end |
| 2025-02-15 | Part II W2 (FY 2024-25) | 44 days before window end |
| 2025-12-13 | Part II W3 (rolling Feb 25–Jan 26) | 49 days before window end |

PMJDY beneficiary counts are cumulative since 2014; cross-state rank ordering is stable across small temporal offsets, and absolute values shift modestly with calendar progression.

Denominator: adult population, derived from PLFS 2023-24 Annual Report sample composition (Table 1 of the published report; persons aged 15 and above as a share of the total survey sample, by state). The all-India adult share is approximately 0.74. PLFS 2023-24 is the only adult-share round we use; the Indian adult share moves slowly enough that applying it to all five anchors introduces small approximation error.

## Bank-office density per 100,000 population

Source: Reserve Bank of India, Database on Indian Economy (DBIE), Other STRBI Table 13: "State-wise Number of Functioning Offices of Commercial Banks." Quarterly publication; the source XLSX provides quarter-end snapshots back to March 2006. "Functioning offices" includes branches plus administrative offices and extension counters across all scheduled commercial banks (public, private, foreign, RRB, small finance, payments banks).

We extract five snapshots: 31 March 2020, 31 March 2021, 31 March 2024, 31 March 2025, and 31 December 2025. The first two go to Part I; the latter three go to Part II's three windows (using 31 December 2025 as the closest available pre-publication snapshot for the rolling W3 window ending January 2026). Output: `data/interim/rbi_offices_state_panel.csv`.

The RBI source lists "Daman & Diu" as a separate row from "Dadra and Nagar Haveli and Daman and Diu" for some pre-merger snapshots, populating the latter with NA. Reconciliation through the canonical lookup aggregates both rows to the merged DNHDD canonical.

## Internet density

Source: Telecom Regulatory Authority of India, Yearly Performance Indicators (YPI). State-level internet subscribers per 100 population, on the comparable post-2023 service-area basis. Snapshots used: 31 March 2024 and 31 March 2025. Pre-2023 TRAI data is reported by Licensed Service Areas which combine post-split states (Andhra Pradesh and Telangana, Bihar and Jharkhand, others); state-level internet density on a comparable basis is therefore unavailable for Part I.

## Unclassified UPI volume, randomness test

The Indiastat NPCI state-wise files carry a "Unclassified" row in addition to the 36 state rows. The Unclassified row's share of national UPI volume grew from approximately 12 percent in April 2023 to nearly 40 percent in January 2026. The growing Unclassified share could in principle compress observed cross-state dispersion if the loss-to-Unclassified is concentrated in particular states.

We tested this directly. For each state and month, we computed the state's share of the national volume that is state-attributable (i.e., excluding Unclassified). If Unclassified loss were random across states, this share should be approximately stable per state across months. If it were systematically draining particular states, the share should fall fastest for those states. Pearson correlation between a state's per-capita UPI and its rate of Unclassified-share-loss over the panel period is small (|r| < 0.2) and not statistically distinguishable from zero. The convergence pattern in Section 5 is robust to the bucket. Diagnostic script: `scripts/04_analyze/test_unclassified_randomness.R`.

## Maharashtra share loss

One large state, Maharashtra, has lost close to six percentage points of national UPI share over the 34-month panel. This is consistent with a disproportionate share of Maharashtra's volume migrating into the Unclassified bucket as Mumbai-based payment-infrastructure routing changes. We document this here and in Section 5 as a partial driver of the observed convergence: leaving Maharashtra out of the cross-state dispersion calculation reduces the slope of both convergence measures (CV and SD-of-log) by approximately 20 percent, leaving the qualitative downward trend intact.

## Note on tools

The author drafted this paper with assistance from an AI tool (Anthropic Claude); analytical decisions and editorial direction are the author's; all errors are the author's own.
