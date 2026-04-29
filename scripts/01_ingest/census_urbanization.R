# scripts/01_ingest/census_urbanization.R
#
# Purpose: Ingest two distinct state-level indicators used in the §9 PHC
#          correction and in per-area transforms:
#            (a) share_urban — fraction of state population classified
#                urban, by year. Census 2011 provides the baseline;
#                subsequent years come from the Registrar General's
#                urbanization projections OR interpolation between
#                Census points. Decide which source is used uniformly
#                across all state-years (panel-consistency rule).
#            (b) state_area_km2 — land area by state, in square
#                kilometres. Slow-changing. One row per state; boundary
#                exceptions (J&K / Ladakh after Oct-2019) handled in the
#                03_build step, not here.
# Inputs:  data/raw/census/*.xlsx (urbanization share, state areas)
# Outputs: data/interim/urbanization.csv       (state_canonical, state_code, year, share_urban)
#          data/interim/state_areas.csv        (state_canonical, state_code, area_km2)
# Part:    Both
# Role:    Support / controls.
# Run:     Rscript scripts/01_ingest/census_urbanization.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr); library(readr)
  library(janitor); library(stringr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir        <- "data/raw/census"
out_urban      <- "data/interim/urbanization.csv"
out_state_area <- "data/interim/state_areas.csv"

raw_files <- if (dir.exists(raw_dir)) {
  list.files(raw_dir, pattern = "\\.xlsx?$", full.names = TRUE, recursive = TRUE)
} else character(0)

if (length(raw_files) == 0) {
  stop(
    "No Census / area file found under ", raw_dir, "/.\n",
    "Two datasets needed:\n",
    "  (a) State-wise urban population share by year (2017-2026):\n",
    "      Source options (choose ONE and apply uniformly):\n",
    "        - Registrar General of India, urbanization projections, OR\n",
    "        - Linear interpolation between Census 2011 and the most\n",
    "          recent authoritative urban-share estimate.\n",
    "      Document the chosen source in the paper's data section.\n",
    "  (b) State land area in square kilometres (one value per state):\n",
    "      Source: Census of India state profile tables, or MoSPI\n",
    "      Statistical Yearbook. Note J&K boundary change (Oct 2019).\n",
    "Save both as .xlsx to ", raw_dir, "/ and re-run.",
    call. = FALSE
  )
}

stop(
  "Raw file(s) located:\n  - ", paste(raw_files, collapse = "\n  - "),
  "\nParsing not yet implemented. This script produces two interim CSVs\n",
  "from potentially two different source files — make sure the filename\n",
  "pattern distinguishes them before reading.",
  call. = FALSE
)

# --- Template (uncomment, fill TODOs) ---------------------------------------
# urban_path <- raw_files[stringr::str_detect(basename(raw_files), "urban")]
# area_path  <- raw_files[stringr::str_detect(basename(raw_files), "area")]
#
# # (a) Urbanization share
# raw_u <- readxl::read_excel(urban_path) |> janitor::clean_names()
# long_u <- raw_u |>
#   tidyr::pivot_longer(cols = c(), names_to = "year_raw", values_to = "share_urban") |>  # TODO
#   dplyr::mutate(year = as.integer(stringr::str_extract(year_raw, "\\d{4}")))
# rec_u <- reconcile_states(long_u$STATE_COL, "census-urbanization")  # TODO: state col
# out_u <- dplyr::bind_cols(long_u, rec_u) |>
#   dplyr::filter(include_in_analysis) |>
#   dplyr::select(state_canonical, state_code, year, share_urban) |>
#   dplyr::arrange(year, state_canonical)
# readr::write_csv(out_u, out_urban)
# message("Wrote ", nrow(out_u), " rows to ", out_urban)
#
# # (b) State area (km²)
# raw_a <- readxl::read_excel(area_path) |> janitor::clean_names()
# rec_a <- reconcile_states(raw_a$STATE_COL, "census-area")  # TODO: state col
# out_a <- dplyr::bind_cols(raw_a, rec_a) |>
#   dplyr::filter(include_in_analysis) |>
#   dplyr::select(state_canonical, state_code, area_km2) |>  # TODO
#   dplyr::arrange(state_canonical)
# readr::write_csv(out_a, out_state_area)
# message("Wrote ", nrow(out_a), " rows to ", out_state_area)
