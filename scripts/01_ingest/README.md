# Phase 1 — Data Inventory (DRAFT)

Per-source checklist for Phase 1 pulls. Every ingestion script under this
folder must (a) read raw files from [data/raw/](../../data/raw/), (b) pass
every raw state-name through `reconcile_states()` in
[_utils_state_names.R](_utils_state_names.R) before writing, and (c) write
its output as a state-level tidy CSV under [data/interim/](../../data/interim/).
See [CLAUDE.md](../../CLAUDE.md) sections 4, 5, 7 for the underlying rules.

**This document is a DRAFT.** Items flagged "anchored" are specified directly
by CLAUDE.md; items flagged "proposed" are inferred from the original thesis
context and need review before pulls begin. See the Open Questions at the
end.

---

## Geographic scope

- **Part I panel:** 30 units — 28 states + Jammu and Kashmir (single unit
  throughout 2017-18 to 2020-21) + Puducherry. Matches the original
  thesis's 90-observation panel. See
  [lookups/state_names.csv](../../lookups/state_names.csv).
- **Part II panel:** include every state/UT that NPCI reports separately
  with non-zero UPI volume. J&K and Ladakh separated if the source
  reports them separately (CLAUDE.md §6). Part III comparative section
  includes a robustness check restricting Part II to the 30-unit overlap
  with the Part I panel.

## Common ingestion contract

Every script in this folder follows the same shape:

```
scripts/01_ingest/<source>_<indicator>.R
  ├─ reads:  data/raw/<source>/<file(s)>
  ├─ uses:   reconcile_states() from _utils_state_names.R
  └─ writes: data/interim/<source>_<indicator>.csv
             columns: state_canonical, state_code, year (or year_month), <value cols>
```

Header comment block required: purpose, inputs, outputs, Part (I / II / both),
role (DV / IV / control).

---

## Source 1 — Indiastat: Digital Payments Series 1 *(anchored, CLAUDE.md §7)*

| Field | Value |
|---|---|
| Dataset | "State-wise Number of Digital Payment Transactions through BHIM App, IMPS, RuPay on POS, UPI and USSD" |
| Portal | Indiastat (paid subscription) |
| Geographic unit | State / UT |
| Frequency | Annual (fiscal year) |
| Years needed | 2017-18, 2019-20, 2020-21 (3 years — 2018-19 not reported in the compilation; this is the original thesis's sample) |
| Measure | Number of transactions, five-rail composite |
| Feeds | Part I only |
| Role | Dependent variable (enter as log per-capita) |
| Raw location | `data/raw/indiastat/series1_digital_payments/` |
| Interim output | `data/interim/indiastat_series1_dp_composite.csv` |
| Script | `indiastat_series1.R` (not yet written) |
| Status | Not pulled |
| Notes | Do NOT chain with Series 2 or Series 3 (CLAUDE.md §7). Treat as Part I DV only. |

## Source 2 — Indiastat: Digital Payments Series 2 (DEFERRED — optional robustness) *(anchored, CLAUDE.md §7)*

| Field | Value |
|---|---|
| Dataset | "State-wise Volume and Value of Digital Transactions (Financial and Non-Financial)" |
| Portal | Indiastat (MeitY DigiDhan-sourced) |
| Years | 2018-19 to 2022-23 |
| Measure | Definitionally broader than Series 1 (AePS + NACH + internet banking + non-financial). Do not interpret as the same DV. |
| Feeds | Part I robustness appendix only |
| Role | Robustness check with explicit structural-break control |
| Status | Defer pull until Part I baseline is running. Do not pull in this phase unless explicitly requested. |

## Source 3 — Indiastat / NPCI: UPI state-level *(anchored, CLAUDE.md §7)*

| Field | Value |
|---|---|
| Dataset | NPCI state-wise UPI transactions (via Indiastat), ideally including P2M split |
| Portal | Indiastat; cross-check against NPCI's own monthly statistics page |
| Geographic unit | State / UT |
| Frequency | Monthly |
| Date range | September 2023 onwards through the latest month available at pull time |
| Measure | UPI volume (count) and value (INR). P2M (person-to-merchant) subset strongly preferred as primary DV because it isolates retail adoption from institutional transfers (CLAUDE.md §7). |
| Feeds | Part II only |
| Role | Dependent variable (log per-capita) |
| Raw location | `data/raw/indiastat/upi_statewise/` |
| Interim output | `data/interim/indiastat_upi_monthly.csv` |
| Script | `indiastat_upi.R` (not yet written) |
| Status | Not pulled |
| DV selection rule | **One consistent measure across the whole Part II panel. No cell-by-cell fallback.** At pull time, inspect what Indiastat publishes. IF P2M is available for every state-month in the target panel → P2M is the DV. ELSE → total UPI is the DV, and the paper documents that P2M was not uniformly available. The choice is made once, at the panel level, not per row. |

## Source 4 — RBI Handbook of Statistics on Indian States *(proposed)*

| Field | Value |
|---|---|
| Publication | Reserve Bank of India, Handbook of Statistics on Indian States (annual release) |
| Portal | RBI website, "Database on Indian Economy" |
| Geographic unit | State |
| Frequency | Annual |
| Years needed | 2017-18 through 2025-26 (covers both Parts) |
| Indicators proposed | Per-capita NSDP (current prices); NSDP at constant prices; number of offices of scheduled commercial banks per state; credit-deposit ratio |
| Feeds | Part I and Part II (controls) |
| Role | Control variables |
| Raw location | `data/raw/rbi_handbook/` |
| Interim output(s) | `data/interim/rbi_nsdp.csv`, `data/interim/rbi_bank_offices.csv` |
| Script | `rbi_handbook.R` (not yet written) |
| Status | Not pulled |
| Notes | The original thesis used per-capita income as a control. Variable list here is a proposal to confirm before pulling. |

## Source 5 — PLFS (Periodic Labour Force Survey) *(proposed)*

| Field | Value |
|---|---|
| Publication | National Statistical Office, annual PLFS reports |
| Portal | MoSPI / NSO website |
| Geographic unit | State (state-level aggregates from published reports, not unit-level) |
| Frequency | Annual |
| Years needed | 2017-18 to 2024-25 (coverage dependent on latest released report) |
| Indicators proposed | LFPR (usual status, 15+); worker population ratio; unemployment rate; share of workforce in non-agricultural activities; literacy rate by state |
| Feeds | Part I and Part II (controls) |
| Role | Control variables |
| Raw location | `data/raw/plfs/` |
| Interim output | `data/interim/plfs_annual.csv` |
| Script | `plfs.R` (not yet written) |
| Status | Not pulled |
| Notes | Published reports include tables by state; unit-level data is available separately but not needed unless we want to reconstruct custom measures. Variable list to confirm. |

## Source 6 — TRAI (Telecom Regulatory Authority of India) *(proposed)*

| Field | Value |
|---|---|
| Publication | TRAI "Performance Indicators Report" (quarterly) and "Telecom Subscription Data" releases |
| Portal | trai.gov.in |
| Geographic unit | Telecom Service Area (LSA). Metro LSAs are aggregated into their parent states per the rule below. |
| Frequency | Quarterly |
| Years needed | 2017-18 to 2025-26 |
| Indicators proposed | Wireless teledensity (subscribers per 100); wireline subscribers; total internet subscribers (wireless + wireline, if reported) |
| Feeds | Part I and Part II (controls) |
| Role | Control variable (digital access) |
| Raw location | `data/raw/trai/` |
| Interim output | `data/interim/trai_telecom.csv` |
| Script | `trai.R` (not yet written) |
| Status | Not pulled |
| LSA → state mapping | Mumbai LSA + Maharashtra LSA → Maharashtra. Chennai LSA + Tamil Nadu LSA → Tamil Nadu. Kolkata LSA + West Bengal LSA → West Bengal. Delhi LSA → Delhi (Delhi is its own state-UT). All non-Metro LSAs map 1-to-1 to their namesake state; verify when the first file is in hand. Subscriber counts are summed; teledensity must be recomputed from summed subscribers and summed population, not averaged. |

## Source 7 — PMJDY (Pradhan Mantri Jan Dhan Yojana) *(proposed)*

| Field | Value |
|---|---|
| Publication | PMJDY state-wise beneficiary statistics |
| Portal | pmjdy.gov.in (state-wise report page); MoF periodic finmin reports |
| Geographic unit | State |
| Frequency | Portal publishes a running cumulative count; snapshots required for time series |
| Years needed | Snapshot at each FY end in-sample (31-Mar of 2018, 2019, 2020, 2021 for Part I; 2024, 2025, 2026 for Part II — confirm latest available) |
| Indicators proposed | Total accounts (cumulative); total deposits (INR); share of rural accounts; RuPay card issuance |
| Feeds | Part I and Part II (controls, financial inclusion) |
| Role | Control variable |
| Raw location | `data/raw/pmjdy/` |
| Interim output | `data/interim/pmjdy_snapshots.csv` |
| Script | `pmjdy.R` (not yet written) |
| Status | Not pulled |
| Source-selection rule | **One consistent source across all snapshot dates. No mixing.** Priority order: (c) MoF finmin quarterly/progress reports — preferred if state-wise PMJDY tables are present for every required FY-end date. ELSE (b) archive.org Wayback snapshots of pmjdy.gov.in state-wise page for every required date. Check (c) coverage first against every FY-end date in scope; only fall through to (b) if (c) fails on even one date. Document the chosen source. |

## Source 8 — MeitY DigiDhan *(proposed, possibly redundant with Series 2)*

| Field | Value |
|---|---|
| Publication | MeitY DigiDhan dashboard (digipay.gov.in) |
| Frequency | Daily / monthly |
| Feeds | If pulled, same role as Indiastat Series 2 — Part I robustness only |
| Status | Skip unless Series 2 is unavailable via Indiastat. Confirm before pulling. |

## Source 9 — MoHFW Population Projections *(anchored, CLAUDE.md §8)*

| Field | Value |
|---|---|
| Publication | Ministry of Health and Family Welfare, "Report of the Technical Group on Population Projections" (NCP, 2019 revision) |
| Why | Per-capita denominator for every DV transformation — consistent source across all years (CLAUDE.md §8) |
| Geographic unit | State |
| Frequency | Annual (projections by year) |
| Years needed | 2017 through 2026 (covers both Parts) |
| Raw location | Suggest `data/raw/mohfw/population/` — NEW subfolder, see open question |
| Interim output | `data/interim/population_mohfw.csv` |
| Script | `mohfw_population.R` (not yet written) |
| Status | Not pulled |
| Notes | Do NOT substitute Census interpolation or World Bank projections — the specified source is the MoHFW projection report. |

## Source 10 — MoHFW Rural Health Statistics (PHCs) *(anchored, CLAUDE.md §9)*

| Field | Value |
|---|---|
| Publication | MoHFW, Rural Health Statistics (annual) |
| Why | Needed to reproduce and correct the original thesis's PHC-per-sq-km result with urbanization controls (CLAUDE.md §9) |
| Geographic unit | State |
| Frequency | Annual |
| Years needed | 2017-18 to 2020-21 (Part I); extend if used in Part II |
| Indicators | PHC count; per-sq-km and per-capita forms |
| Raw location | Suggest `data/raw/mohfw/rhs/` |
| Interim output | `data/interim/mohfw_phcs.csv` |
| Script | `mohfw_rhs.R` (not yet written) |
| Status | Not pulled |

## Source 11 — Urbanization share and population density *(anchored, CLAUDE.md §9)*

| Field | Value |
|---|---|
| Why | Required controls for the PHC correction (CLAUDE.md §9). Also inputs to the per-sq-km denominator. |
| Indicators | `share_urban` (fraction of population living in urban areas, by state-year); `population_density` (state population / land area in km²) |
| Source options | Census 2011 baseline + annual urbanization projections from the Registrar General; alternative: PLFS urban/rural classification shares. Decision needed. |
| Raw location | Suggest `data/raw/census/` (NEW subfolder, see open question) |
| Interim output | `data/interim/urbanization.csv`, `data/interim/area_km2.csv` |
| Script | `census_urbanization.R` (not yet written) |
| Status | Not pulled |
| Notes | State land areas in km² are slow-changing; one authoritative value per state works, except where boundary changes apply (J&K/Ladakh). |

---

## Resolved (all, 2026-04-23)

- **Raw folder tree.** Added `data/raw/mohfw/` and `data/raw/census/`.
  CLAUDE.md §4 updated to match.
- **UPI DV consistency rule.** One consistent DV across the full Part II
  panel — no cell-by-cell fallback between P2M and total UPI. The choice
  is made once at pull time based on whether P2M has full state-month
  coverage. See Source 3 DV selection rule.
- **Part II UT coverage.** Include every state/UT that NPCI reports
  separately with non-zero UPI volume. Part III runs a robustness check
  restricting Part II to the 30-unit overlap with the Part I panel.
- **TRAI LSA → state mapping.** Aggregate the four Metro LSAs into their
  parent states: Mumbai+Maharashtra → Maharashtra, Chennai+Tamil Nadu →
  Tamil Nadu, Kolkata+West Bengal → West Bengal, Delhi LSA → Delhi. See
  Source 6 LSA mapping row for the aggregation detail (sum subscribers;
  recompute teledensity, do not average).
- **PMJDY source priority.** Try MoF finmin reports first; if they lack
  state-wise PMJDY data for every required FY-end date, use archive.org
  Wayback snapshots of pmjdy.gov.in for all dates. One source uniformly.
  See Source 7 source-selection rule.
- **Variable breadth.** Pull broadly under sources 4–8 and 11; specify
  the regression narrowly in Phase 3.
- **Indiastat access.** User has a subscription covering the three series
  in use. Claude does not handle credentials and cannot download from
  the portal — the user downloads files to `data/raw/indiastat/…` and
  ingestion scripts read from there.

## Next

1. Scaffold one ingestion script per source under this folder, each with
   the standard header block (purpose / inputs / outputs / Part / role),
   library loads, a `source()` of `_utils_state_names.R`, and a clean
   "missing raw file" error message so the script tells the user exactly
   which file to pull and where. Scripts run but error until raw files
   arrive.
2. Begin pulls in any order the user prefers. Start with Indiastat Series
   1 (Part I DV) and the MoHFW population projection — those unblock the
   first regressions.

---

*Last updated: 2026-04-23. All Phase-1 open questions resolved; scaffolding
is the next step.*
