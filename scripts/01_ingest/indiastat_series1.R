# scripts/01_ingest/indiastat_series1.R
#
# Purpose: Ingest Part I DV — Series 1 5-rail composite digital payment
#          transactions (BHIM + IMPS + RuPay POS + UPI + USSD) for
#          FY 2019-20 and FY 2020-21. Source = Lok Sabha Unstarred Q No.
#          1425 (2021), distributed by Indiastat as 5 regional files.
#          Per the 2026-04-24 Option A decision (CLAUDE.md §7), FY
#          2017-18 is NOT included — its underlying LS-5291 compilation
#          is a 3-rail composite and chaining would create a definitional
#          break. See data/raw/indiastat/series1_digital_payments/_MANIFEST.txt.
# Inputs:  data/raw/indiastat/series1_digital_payments/LS_QN1425_FY2019-20_2020-21/*.xls
#          (these are HTML-as-XLS — parsed with rvest, NOT readxl)
# Outputs: data/interim/indiastat_series1_dp_composite.csv
#          columns: state_canonical, state_code, fy, transactions_count
# Part:    I
# Role:    Dependent variable (enter as log per-capita in regression).
# Run:     Rscript scripts/01_ingest/indiastat_series1.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(rvest); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir  <- "data/raw/indiastat/series1_digital_payments/LS_QN1425_FY2019-20_2020-21"
out_file <- "data/interim/indiastat_series1_dp_composite.csv"

raw_files <- if (dir.exists(raw_dir)) {
  list.files(raw_dir, pattern = "\\.xls$", full.names = TRUE)
} else character(0)

if (length(raw_files) == 0) {
  stop("No regional files found under ", raw_dir, "/.", call. = FALSE)
}

# Each file is an HTML table (served as .xls by Indiastat). Layout:
#   Row 1 : merged title ("State-wise Number of Digital Payment Transactions...")
#   Row 2 : column headers ("States/UT" | "2019-2020" | "2020-2021" | "%age Growth")
#   Row 3+: data rows — one per state/UT in the region; a regional subtotal
#           may appear at the end (e.g. "Southern India") and is filtered
#           out by reconcile_states() via include_in_analysis.
parse_regional <- function(path) {
  tbls <- rvest::read_html(path) |> rvest::html_table(fill = TRUE, header = FALSE)
  tb <- tbls[[1]]

  v19 <- suppressWarnings(as.numeric(gsub(",", "", as.character(tb[[2]]))))
  v20 <- suppressWarnings(as.numeric(gsub(",", "", as.character(tb[[3]]))))
  keep <- !is.na(v19) & !is.na(v20)

  tibble::tibble(
    source_file       = basename(path),
    state_raw         = stringr::str_trim(as.character(tb[[1]][keep])),
    `2019-20`         = v19[keep],
    `2020-21`         = v20[keep]
  )
}

wide <- purrr::map_dfr(raw_files, parse_regional)
stopifnot(nrow(wide) > 0)

long <- wide |>
  tidyr::pivot_longer(
    cols      = c(`2019-20`, `2020-21`),
    names_to  = "fy",
    values_to = "transactions_count"
  )

rec <- reconcile_states(long$state_raw, "indiastat-series1-LS1425")

out <- dplyr::bind_cols(long, rec) |>
  dplyr::filter(include_in_analysis) |>
  # Indiastat reports pre-merger Dadra & Nagar Haveli and Daman & Diu as
  # separate rows even for FY 2020-21 (post-Jan-2020 merger). Sum them
  # back into the canonical DNHDD unit so each (state, fy) has one row.
  dplyr::group_by(state_canonical, state_code, fy) |>
  dplyr::summarise(transactions_count = sum(transactions_count), .groups = "drop") |>
  dplyr::arrange(fy, state_canonical)

# Sanity: every Part I panel unit should appear in both FYs.
panel_units <- readr::read_csv("lookups/state_names.csv", show_col_types = FALSE) |>
  dplyr::filter(include_in_analysis,
                stringr::str_detect(notes, "Part I original panel")) |>
  dplyr::pull(state_canonical)

coverage <- out |>
  dplyr::count(state_canonical, name = "fy_count") |>
  dplyr::filter(state_canonical %in% panel_units)
missing <- setdiff(panel_units, coverage$state_canonical)
incomplete <- coverage$state_canonical[coverage$fy_count != 2]

if (length(missing) > 0 || length(incomplete) > 0) {
  warning(
    "Part I panel coverage issues:\n",
    if (length(missing) > 0)    paste0("  missing entirely: ", paste(missing, collapse = ", "), "\n") else "",
    if (length(incomplete) > 0) paste0("  only one FY present: ", paste(incomplete, collapse = ", "), "\n") else "",
    "Investigate before using this file downstream.",
    call. = FALSE
  )
}

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
readr::write_csv(out, out_file)
message("Wrote ", nrow(out), " rows to ", out_file)
message("  state_canonical distinct: ", length(unique(out$state_canonical)))
message("  FYs: ", paste(sort(unique(out$fy)), collapse = ", "))
