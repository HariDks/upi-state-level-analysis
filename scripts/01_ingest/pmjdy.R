# scripts/01_ingest/pmjdy.R
#
# Purpose: Build a time series of state-wise PMJDY snapshots at FY-end
#          dates. The PMJDY portal publishes a running cumulative count,
#          not a time series, so snapshots must be assembled from a single
#          consistent source per the source-selection rule in
#          scripts/01_ingest/README.md:
#            Priority (c): MoF finmin reports with state-wise PMJDY tables
#                          at each required FY-end date. Preferred.
#            Fallback (b): archive.org Wayback snapshots of pmjdy.gov.in
#                          state-wise page at each required date.
#          One source for every date — NEVER mix (c) and (b) within the
#          same panel.
# Inputs:  data/raw/pmjdy/*.{xlsx,csv,html}  (one file per snapshot date)
# Outputs: data/interim/pmjdy_snapshots.csv
#          columns: state_canonical, state_code, snapshot_date (Date),
#                   total_accounts, rural_accounts, urban_accounts,
#                   total_deposits_inr_cr, rupay_cards_issued
# Part:    I and II (controls, financial inclusion)
# Role:    Controls.
# Run:     Rscript scripts/01_ingest/pmjdy.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(readr)
  library(janitor); library(stringr); library(rvest); library(lubridate)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir  <- "data/raw/pmjdy"
out_file <- "data/interim/pmjdy_snapshots.csv"

raw_files <- if (dir.exists(raw_dir)) {
  list.files(raw_dir, pattern = "\\.(xlsx?|csv|html?)$", full.names = TRUE,
             recursive = TRUE, ignore.case = TRUE)
} else character(0)

if (length(raw_files) == 0) {
  stop(
    "No PMJDY snapshot file found under ", raw_dir, "/.\n",
    "Required snapshot dates (FY ends):\n",
    "  Part I:  31-Mar-2018, 31-Mar-2019, 31-Mar-2020, 31-Mar-2021\n",
    "  Part II: 31-Mar-2024, 31-Mar-2025, 31-Mar-2026 (once available)\n",
    "\n",
    "Source-selection rule (CLAUDE.md panel-consistency principle):\n",
    "  1. First try MoF finmin periodic reports. If every required date has\n",
    "     a state-wise PMJDY table in those reports, use (c) uniformly.\n",
    "  2. Else, use archive.org Wayback snapshots of\n",
    "     https://pmjdy.gov.in/statewise-statistics captured at/near each\n",
    "     required date, and use (b) uniformly for all dates.\n",
    "\n",
    "Save one file per snapshot date to ", raw_dir, "/. Filename convention:\n",
    "  pmjdy_<source>_<yyyy-mm-dd>.<ext>  e.g. pmjdy_mof_2018-03-31.xlsx\n",
    "Re-run this script once at least one file is present.",
    call. = FALSE
  )
}

stop(
  "Raw file(s) located:\n  - ", paste(raw_files, collapse = "\n  - "),
  "\nParsing not yet implemented. Implement one read function per source\n",
  "type (html vs xlsx) and assert in the script that every file carries\n",
  "the same source tag before binding.",
  call. = FALSE
)

# --- Template (uncomment, fill TODOs) ---------------------------------------
# read_snapshot <- function(path) {
#   meta <- stringr::str_match(basename(path),
#     "pmjdy_(mof|wayback)_(\\d{4}-\\d{2}-\\d{2})\\.(\\w+)$")
#   source_tag    <- meta[, 2]
#   snapshot_date <- as.Date(meta[, 3])
#   ext           <- tolower(meta[, 4])
#   raw <- switch(ext,
#     "xlsx" = readxl::read_excel(path),
#     "xls"  = readxl::read_excel(path),
#     "csv"  = readr::read_csv(path, show_col_types = FALSE),
#     "html" = rvest::read_html(path) |> rvest::html_table() |> dplyr::first(),
#     "htm"  = rvest::read_html(path) |> rvest::html_table() |> dplyr::first(),
#     stop("Unexpected extension: ", ext)
#   ) |> janitor::clean_names()
#   dplyr::mutate(raw, source_tag = source_tag, snapshot_date = snapshot_date)
# }
#
# raw <- purrr::map_dfr(raw_files, read_snapshot)
# stopifnot(length(unique(raw$source_tag)) == 1L)  # enforce consistency rule
# rec <- reconcile_states(raw$STATE_COL, "pmjdy")  # TODO: state col
# out <- dplyr::bind_cols(raw, rec) |>
#   dplyr::filter(include_in_analysis) |>
#   dplyr::select(state_canonical, state_code, snapshot_date,
#                 total_accounts, rural_accounts, urban_accounts,
#                 total_deposits_inr_cr, rupay_cards_issued) |>  # TODO
#   dplyr::arrange(snapshot_date, state_canonical)
# readr::write_csv(out, out_file)
# message("Wrote ", nrow(out), " rows to ", out_file)
