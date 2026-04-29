# scripts/01_ingest/rbi_handbook.R
#
# Purpose: Ingest state-level macroeconomic and banking controls from the
#          RBI Handbook of Statistics on Indian States. Pull broadly at
#          this stage (per CLAUDE.md §10 resolution): per-capita NSDP
#          (current and constant prices), number of offices of scheduled
#          commercial banks, credit-deposit ratio. The narrow regression
#          variable list is set in Phase 3.
# Inputs:  data/raw/rbi_handbook/*.xlsx (one file per indicator is common;
#          the RBI Handbook distributes per-topic workbooks)
# Outputs: data/interim/rbi_nsdp.csv               (state, fy, per_capita_nsdp_*, ...)
#          data/interim/rbi_bank_offices.csv       (state, fy, n_offices_scb)
#          data/interim/rbi_credit_deposit.csv     (state, fy, cd_ratio)
# Part:    I and II (controls)
# Role:    Controls.
# Run:     Rscript scripts/01_ingest/rbi_handbook.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(readr)
  library(janitor); library(stringr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir <- "data/raw/rbi_handbook"

raw_files <- if (dir.exists(raw_dir)) {
  list.files(raw_dir, pattern = "\\.xlsx?$", full.names = TRUE, recursive = TRUE)
} else character(0)

if (length(raw_files) == 0) {
  stop(
    "No Excel file found under ", raw_dir, "/.\n",
    "Pull from RBI's Database on Indian Economy — Handbook of Statistics on\n",
    "Indian States. Needed tables (annual, FY 2017-18 through 2025-26):\n",
    "  - Per-capita NSDP at current prices (and constant prices, base 2011-12)\n",
    "  - Number of offices of scheduled commercial banks, by state\n",
    "  - Credit-deposit ratio, by state\n",
    "Save the workbooks to ", raw_dir, "/ and re-run.",
    call. = FALSE
  )
}

stop(
  "Raw file(s) located:\n  - ", paste(raw_files, collapse = "\n  - "),
  "\nParsing not yet implemented. The Handbook tables typically have a\n",
  "multi-row header (the series label in row 1, unit in row 2). Expect to\n",
  "use read_excel(..., skip = N) and clean_names() per file. Write one\n",
  "interim CSV per indicator.",
  call. = FALSE
)

# --- Template per indicator (uncomment, fill TODOs) -------------------------
# parse_rbi <- function(path, value_name, out_csv) {
#   raw <- readxl::read_excel(path, skip = 0) |> janitor::clean_names()  # TODO: skip
#   long <- raw |>
#     tidyr::pivot_longer(cols = c(), names_to = "fy_raw", values_to = value_name) |>  # TODO
#     dplyr::mutate(fy = stringr::str_replace(fy_raw, "^x(\\d{4})_(\\d{2})$", "\\1-\\2"))
#   rec <- reconcile_states(long$STATE_COL, paste0("rbi-", value_name))
#   out <- dplyr::bind_cols(long, rec) |>
#     dplyr::filter(include_in_analysis) |>
#     dplyr::select(state_canonical, state_code, fy, all_of(value_name)) |>
#     dplyr::arrange(fy, state_canonical)
#   readr::write_csv(out, out_csv)
#   message("Wrote ", nrow(out), " rows to ", out_csv)
# }
#
# parse_rbi("<file>", "per_capita_nsdp_current", "data/interim/rbi_nsdp.csv")
# parse_rbi("<file>", "n_offices_scb",           "data/interim/rbi_bank_offices.csv")
# parse_rbi("<file>", "cd_ratio",                "data/interim/rbi_credit_deposit.csv")
