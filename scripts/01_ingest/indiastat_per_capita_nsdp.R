# scripts/01_ingest/indiastat_per_capita_nsdp.R
#
# Purpose: Parse state-wise Per Capita Net State Domestic Product (NSDP)
#          at Factor Cost, Constant 2011-12 Prices, FY 2011-12 through
#          FY 2022-23, from Indiastat. Originally pulled by Hari for the
#          May 2024 thesis; copied to data/raw/indiastat/per_capita_nsdp/
#          on 2026-04-26. Source: MoSPI / CSO national accounts.
# Inputs:  data/raw/indiastat/per_capita_nsdp/PerCapita_Income.xls
#          (HTML-as-XLS — parsed with rvest, NOT readxl)
# Outputs: data/interim/per_capita_nsdp.csv
#          columns: state_canonical, state_code, fy,
#                   per_capita_nsdp_constant_inr (Rs at 2011-12 prices)
# Part:    I (2019-20, 2020-21) and Part II (annual, mapped to year-month
#          via the panel-build step). Per CLAUDE.md §7a — first-order
#          channel: income / purchasing power → transaction volume.
# Role:    Control variable.
# Run:     Rscript scripts/01_ingest/indiastat_per_capita_nsdp.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(rvest); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_file <- "data/raw/indiastat/per_capita_nsdp/PerCapita_Income.xls"
out_file <- "data/interim/per_capita_nsdp.csv"
if (!file.exists(raw_file)) stop("Missing: ", raw_file, call. = FALSE)

# Layout (HTML-as-XLS, single primary table):
#   Row 1: Title — "State-wise Per Capita Net State Domestic Product..."
#   Row 2: "(In Rs.)" repeated across columns
#   Row 3: Headers — "States/UTs | 2011-2012 | 2012-2013 | ... | 2022-2023"
#   Rows 4-N: One row per state/UT, with FY columns.
#   Trailing rows: "All India" aggregate (filtered via include_in_analysis).
tbls <- rvest::read_html(raw_file) |>
  rvest::html_table(fill = TRUE, header = FALSE)
tb <- tbls[[1]]

# Column 1 = state, columns 2-13 = FYs 2011-12 through 2022-23.
fy_cols <- as.character(unlist(tb[3, 2:ncol(tb)]))
# FYs in source like "2011-2012" -> normalise to "2011-12".
fy_cols <- stringr::str_replace(fy_cols, "^(\\d{4})-\\d{2}(\\d{2})$", "\\1-\\2")

# Data rows start at row 4. Drop rows where col 1 is blank.
data_rows <- tb[4:nrow(tb), , drop = FALSE]
keep <- nzchar(stringr::str_trim(as.character(data_rows[[1]])))
data_rows <- data_rows[keep, , drop = FALSE]

parse_cell <- function(x) {
  x <- stringr::str_trim(as.character(x))
  if (x %in% c("-", "NA", "N.A.", "")) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", "", x)))
}

long <- purrr::map_dfr(seq_len(nrow(data_rows)), function(r) {
  state_raw <- stringr::str_trim(as.character(data_rows[[1]][r]))
  vals <- vapply(seq_along(fy_cols),
                 function(j) parse_cell(data_rows[[j + 1]][r]),
                 numeric(1))
  tibble::tibble(state_raw = state_raw, fy = fy_cols, per_capita_nsdp_constant_inr = vals)
})

rec <- reconcile_states(long$state_raw, "indiastat-per-capita-nsdp")

out <- dplyr::bind_cols(long, rec) |>
  dplyr::filter(include_in_analysis) |>
  dplyr::select(state_canonical, state_code, fy, per_capita_nsdp_constant_inr) |>
  dplyr::arrange(fy, state_canonical)

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
readr::write_csv(out, out_file)

message("Wrote ", nrow(out), " rows to ", out_file)
message("  states: ", length(unique(out$state_canonical)),
        " | FYs: ", paste(range(out$fy), collapse = " -> "),
        " (", length(unique(out$fy)), " years)")
message("  rows with NA NSDP (no published figure): ",
        sum(is.na(out$per_capita_nsdp_constant_inr)))
message("\nSpot check (5 states × 2 Part I FYs):")
out |>
  dplyr::filter(state_canonical %in% c("Bihar", "Goa", "Maharashtra",
                                       "Tamil Nadu", "Uttar Pradesh"),
                fy %in% c("2019-20", "2020-21")) |>
  as.data.frame() |>
  print(row.names = FALSE)
