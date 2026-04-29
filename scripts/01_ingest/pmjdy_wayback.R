# scripts/01_ingest/pmjdy_wayback.R
#
# Ingest Pradhan Mantri Jan Dhan Yojana (PMJDY) state-wise total
# beneficiaries from archive.org Wayback Machine snapshots of the
# Department of Financial Services portal page
# https://pmjdy.gov.in/statewise-statistics. Three FY-end-aligned
# snapshots, one per analytical anchor:
#   - 2019-10-17 -> FY 2019-20 anchor (5.5 mo before FY end; closest pre)
#   - 2021-03-05 -> FY 2020-21 anchor (26 days before FY end)
#   - 2025-02-15 -> FY 2024-25 anchor (45 days before FY end)
#
# Source-uniformity rationale: the original PMJDY raw manifest
# (data/raw/pmjdy/_MANIFEST.txt) requires that all anchor snapshots come
# from a single source. Pulling all three from Wayback satisfies that
# rule and also gives FY 2024-25 a much closer temporal alignment than
# the prior live-portal scrape (15-Apr-2026, used by Part II until now).
#
# PMJDY beneficiary counts are CUMULATIVE since the scheme's 2014 launch.
# Cross-state rank ordering is therefore stable across small temporal
# offsets; absolute values shift modestly with calendar progression.
# Both effects are documented in the data section of the paper.
#
# Inputs:  data/raw/pmjdy/wayback/pmjdy_<YYYYMMDD>_for_FY<YYYY-YY>.html
# Output:  data/interim/pmjdy_state_panel.csv  (long form: state x snapshot)
#
# Run: Rscript scripts/01_ingest/pmjdy_wayback.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(rvest); library(tidyr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

# (snapshot_date_iso, fy_anchor_label, file_path) — five anchors aligned to
# the analytical FYs across both halves of the paper. Part I uses the
# first two; Part II's 3-year stack uses the last three (2023-24, 2024-25,
# and the 12-month rolling window ending Jan 2026 anchored at the Dec 2025
# snapshot).
snapshots <- tibble::tribble(
  ~snapshot_date,  ~fy_anchor,    ~file,
  "2019-10-17",    "2019-20",     "data/raw/pmjdy/wayback/pmjdy_20191017_for_FY2019-20.html",
  "2021-03-05",    "2020-21",     "data/raw/pmjdy/wayback/pmjdy_20210305_for_FY2020-21.html",
  "2024-02-27",    "2023-24",     "data/raw/pmjdy/wayback/pmjdy_20240227_for_FY2023-24.html",
  "2025-02-15",    "2024-25",     "data/raw/pmjdy/wayback/pmjdy_20250215_for_FY2024-25.html",
  "2025-12-13",    "2025-26roll", "data/raw/pmjdy/wayback/pmjdy_20251213_for_FY2025-26roll.html"
)

parse_one <- function(file, snapshot_date, fy_anchor) {
  h    <- read_html(file)
  tabs <- html_table(h, fill = TRUE)
  d    <- tabs[[1]]   # State-wise statistics is always the first table
  stopifnot("State Name" %in% names(d), "Total Beneficiaries" %in% names(d))

  d |>
    select(state_raw = `State Name`,
           total_beneficiaries = `Total Beneficiaries`) |>
    mutate(
      state_raw = trimws(state_raw),
      total_beneficiaries = as.numeric(gsub(",", "", total_beneficiaries))
    ) |>
    filter(!is.na(state_raw), nzchar(state_raw)) |>
    filter(!grepl("^total|^grand", state_raw, ignore.case = TRUE)) |>
    mutate(snapshot_date = as.Date(snapshot_date),
           fy_anchor     = fy_anchor)
}

raw <- pmap_dfr(snapshots, parse_one)
stopifnot(all(!is.na(raw$total_beneficiaries)))

# Reconcile state names through canonical lookup (fail-loud).
recon <- reconcile_states(raw$state_raw, "pmjdy-wayback")
panel <- bind_cols(raw, recon |> select(state_canonical, state_code)) |>
  group_by(state_canonical, state_code, snapshot_date, fy_anchor) |>
  summarise(total_beneficiaries = sum(total_beneficiaries), .groups = "drop") |>
  arrange(state_canonical, snapshot_date)

cat("\nPMJDY Wayback panel:\n")
panel |>
  group_by(snapshot_date, fy_anchor) |>
  summarise(n_states = n(),
            min = format(min(total_beneficiaries), big.mark = ","),
            max = format(max(total_beneficiaries), big.mark = ","),
            india_total = format(sum(total_beneficiaries), big.mark = ","),
            .groups = "drop") |>
  print()

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
out_file <- "data/interim/pmjdy_state_panel.csv"
write_csv(panel, out_file)
message("\nWrote ", nrow(panel), " state-snapshot rows to ", out_file)
