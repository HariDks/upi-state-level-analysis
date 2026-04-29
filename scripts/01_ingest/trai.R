# scripts/01_ingest/trai.R
#
# Purpose: Ingest TRAI "Telecom Subscription Data" / "Performance Indicators
#          Report" — wireless, wireline, and internet subscribers by
#          Licensed Service Area (LSA), aggregated up to the state level.
#          Metro LSAs are summed into their parent states per the resolved
#          rule in scripts/01_ingest/README.md (Mumbai + Maharashtra LSAs
#          → Maharashtra; Chennai + Tamil Nadu LSAs → Tamil Nadu; Kolkata
#          + West Bengal LSAs → West Bengal; Delhi LSA → Delhi). After
#          summing subscribers, teledensity is RECOMPUTED from summed
#          subscribers and summed population — never averaged across LSAs.
# Inputs:  data/raw/trai/*.xlsx  (quarterly files or aggregated compilations)
# Outputs: data/interim/trai_telecom.csv
#          columns: state_canonical, state_code, year_quarter (Date, first
#          of quarter), wireless_subs, wireline_subs, internet_subs,
#          wireless_teledensity
# Part:    I and II (controls)
# Role:    Control variable (digital access).
# Run:     Rscript scripts/01_ingest/trai.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(readr)
  library(janitor); library(stringr); library(lubridate)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir  <- "data/raw/trai"
out_file <- "data/interim/trai_telecom.csv"

raw_files <- if (dir.exists(raw_dir)) {
  list.files(raw_dir, pattern = "\\.xlsx?$", full.names = TRUE, recursive = TRUE)
} else character(0)

if (length(raw_files) == 0) {
  stop(
    "No Excel file found under ", raw_dir, "/.\n",
    "Pull TRAI state/LSA-level telecom subscriber data (wireless, wireline,\n",
    "internet), quarterly from 2017-Q2 through the latest quarter available.\n",
    "Either \"Telecom Subscription Data\" monthly releases (aggregate to\n",
    "quarter) or the \"Performance Indicators Report\" quarterly tables work.\n",
    "Save .xlsx file(s) to ", raw_dir, "/ and re-run.",
    call. = FALSE
  )
}

# Metro LSA → parent state lookup. Used by the aggregation step in the
# template below. Add Delhi LSA explicitly because "Delhi" is both an LSA
# label and a canonical state label, and we want the parent row to resolve
# through reconcile_states() cleanly.
lsa_parent <- tibble::tribble(
  ~lsa_label,         ~parent_state,
  "Mumbai",           "Maharashtra",
  "Maharashtra",      "Maharashtra",
  "Chennai",          "Tamil Nadu",
  "Tamil Nadu",       "Tamil Nadu",
  "Kolkata",          "West Bengal",
  "West Bengal",      "West Bengal",
  "Delhi",            "Delhi"
)

stop(
  "Raw file(s) located:\n  - ", paste(raw_files, collapse = "\n  - "),
  "\nParsing not yet implemented. Remember: sum subscribers across LSA\n",
  "components of a state, then recompute teledensity from summed subscribers\n",
  "and state population. Do NOT average LSA-level teledensity.",
  call. = FALSE
)

# --- Template (uncomment, fill TODOs) ---------------------------------------
# raw <- readxl::read_excel(raw_files[1]) |> janitor::clean_names()
# # TODO: identify LSA column and subscriber columns.
# mapped <- raw |>
#   dplyr::mutate(lsa_label = LSA_COL) |>                          # TODO
#   dplyr::left_join(lsa_parent, by = "lsa_label") |>
#   dplyr::mutate(parent_state = dplyr::coalesce(parent_state, lsa_label))
#
# # Non-metro LSAs still need to pass reconcile_states() so spellings are checked.
# rec <- reconcile_states(mapped$parent_state, "trai")
# aggregated <- dplyr::bind_cols(mapped, rec) |>
#   dplyr::filter(include_in_analysis) |>
#   dplyr::group_by(state_canonical, state_code, year_quarter) |>   # TODO: year_quarter col
#   dplyr::summarise(
#     wireless_subs = sum(wireless_subs, na.rm = FALSE),
#     wireline_subs = sum(wireline_subs, na.rm = FALSE),
#     internet_subs = sum(internet_subs, na.rm = FALSE),
#     population    = sum(population,    na.rm = FALSE),            # TODO: if reported
#     .groups = "drop"
#   ) |>
#   dplyr::mutate(wireless_teledensity = 100 * wireless_subs / population)
#
# readr::write_csv(aggregated, out_file)
# message("Wrote ", nrow(aggregated), " rows to ", out_file)
