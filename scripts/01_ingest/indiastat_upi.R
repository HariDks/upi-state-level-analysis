# scripts/01_ingest/indiastat_upi.R
#
# Purpose: Ingest Part II DV — state-wise monthly UPI volume and value
#          from Indiastat's "State-wise Volume and Value of Transactions
#          Made through Unified Payments Interface (UPI) in India" series
#          (one HTML-as-XLS file per month). Per the 2026-04-23 UPI DV
#          consistency rule (see scripts/01_ingest/README.md), the DV is
#          total UPI (not P2M) at state level because Indiastat does not
#          expose a state × month × P2M split.
# Inputs:  data/raw/indiastat/upi_statewise/*.xls
#          (HTML-as-XLS; parsed with rvest, NOT readxl)
# Outputs: data/interim/indiastat_upi_monthly.csv
#          columns: state_canonical, state_code, year_month (Date, first
#                   of month), upi_volume_million, upi_value_crore
#          data/interim/indiastat_upi_unclassified_share.csv
#          columns: year_month, unclassified_volume_share, unclassified_value_share
#          (state-attribution gap that the paper's data section should
#           footnote — CLAUDE.md §7 measurement caveat)
# Part:    II
# Role:    Dependent variable.
# Run:     Rscript scripts/01_ingest/indiastat_upi.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(rvest); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr); library(lubridate)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir  <- "data/raw/indiastat/upi_statewise"
out_main <- "data/interim/indiastat_upi_monthly.csv"
out_uncl <- "data/interim/indiastat_upi_unclassified_share.csv"

raw_files <- if (dir.exists(raw_dir)) {
  list.files(raw_dir, pattern = "\\.xls$", full.names = TRUE)
} else character(0)
if (length(raw_files) == 0) stop("No files in ", raw_dir, call. = FALSE)

# Each file is an HTML table. Target layout:
#   Row 1: title with "... Unified Payments Interface (UPI) in India(<Month>, <Year>)"
#   Row 2: headers: States/UTs | Volume(In Million) | Volume Contribution(In %age) |
#                   Value(Rs. in Crore) | Value Contribution(In %age)
#   Rows 3-38: 36 state/UT rows
#   Row 39 (or similar): "Unclassified" — state-attribution gap; filtered via lookup
# Files that don't match this title pattern are skipped with a note — they're
# national-aggregate or bank-level tables that happen to be in the same folder.

parse_one <- function(path) {
  tbls <- rvest::read_html(path) |> rvest::html_table(fill = TRUE, header = FALSE)
  if (length(tbls) == 0) return(NULL)
  tb <- tbls[[1]]
  title <- gsub("\\s+", " ", stringr::str_trim(as.character(tb[1, 1])))

  if (!stringr::str_detect(title,
      "State-wise Volume and Value of Transactions Made through Unified Payments Interface")) {
    return(NULL)  # not a Series 3 state-monthly file
  }

  m <- stringr::str_match(title, "\\(([A-Za-z]+),?\\s*(\\d{4})\\)")
  if (is.na(m[1, 1])) return(NULL)
  month_name <- m[1, 2]
  year       <- as.integer(m[1, 3])
  year_month <- as.Date(paste(year,
                              match(month_name, month.name), "01",
                              sep = "-"))

  # Rows 3+ = data. Col 1 = state, col 2 = volume (Million),
  # col 4 = value (Crore). Drop rows where col 2 can't parse as numeric.
  vol <- suppressWarnings(as.numeric(gsub(",", "", as.character(tb[[2]]))))
  val <- suppressWarnings(as.numeric(gsub(",", "", as.character(tb[[4]]))))
  keep <- !is.na(vol) & !is.na(val)

  tibble::tibble(
    source_file        = basename(path),
    year_month         = year_month,
    state_raw          = stringr::str_trim(as.character(tb[[1]][keep])),
    upi_volume_million = vol[keep],
    upi_value_crore    = val[keep]
  )
}

long <- purrr::map_dfr(raw_files, parse_one)
if (nrow(long) == 0) stop("No Series 3 state-monthly tables found among raw files.", call. = FALSE)

# Reconcile and filter.
rec <- reconcile_states(long$state_raw, "indiastat-upi-statewise")
tagged <- dplyr::bind_cols(long, rec)

# Extract Unclassified share per month (before filtering it out) so the
# paper's data section can footnote the state-attribution gap.
uncl <- tagged |>
  dplyr::group_by(year_month) |>
  dplyr::summarise(
    unclassified_volume_share = {
      u <- upi_volume_million[state_canonical == "Unclassified"]
      t <- sum(upi_volume_million, na.rm = TRUE)
      if (length(u) == 1 && t > 0) u / t else NA_real_
    },
    unclassified_value_share = {
      u <- upi_value_crore[state_canonical == "Unclassified"]
      t <- sum(upi_value_crore, na.rm = TRUE)
      if (length(u) == 1 && t > 0) u / t else NA_real_
    },
    .groups = "drop"
  ) |>
  dplyr::arrange(year_month)

# Main panel: drop include_in_analysis = FALSE (All India, Unclassified).
panel <- tagged |>
  dplyr::filter(include_in_analysis)

# De-dupe on (state_canonical, year_month). If the same (state, month) appears
# in multiple files with identical values, keep one. If values differ, error.
dups <- panel |>
  dplyr::group_by(state_canonical, year_month) |>
  dplyr::summarise(
    n = dplyr::n(),
    vol_range = max(upi_volume_million) - min(upi_volume_million),
    val_range = max(upi_value_crore)    - min(upi_value_crore),
    .groups = "drop"
  ) |>
  dplyr::filter(n > 1)

if (nrow(dups) > 0) {
  bad <- dups |> dplyr::filter(vol_range > 0 | val_range > 0)
  if (nrow(bad) > 0) {
    stop("Duplicate (state, year_month) rows with conflicting values:\n",
         paste(capture.output(print(bad)), collapse = "\n"), call. = FALSE)
  }
  message("De-duplicating identical duplicates on (state, year_month): ",
          nrow(dups), " pairs.")
}

panel <- panel |>
  dplyr::group_by(state_canonical, state_code, year_month) |>
  dplyr::summarise(
    upi_volume_million = dplyr::first(upi_volume_million),
    upi_value_crore    = dplyr::first(upi_value_crore),
    .groups = "drop"
  ) |>
  dplyr::arrange(year_month, state_canonical)

# Missing-month report vs. CLAUDE.md §7 target (Sep-2023 through last month present).
target_start <- as.Date("2023-09-01")
target_end   <- max(panel$year_month)
target_months <- seq(target_start, target_end, by = "month")
have_months   <- sort(unique(panel$year_month))
missing <- as.character(setdiff(target_months, have_months))
if (length(missing) > 0) {
  message("Months missing vs. Sep-2023 -> ", target_end, " target: ",
          length(missing), " (", paste(missing, collapse = ", "), ")")
}

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
readr::write_csv(panel, out_main)
readr::write_csv(uncl,  out_uncl)

message("Wrote ", nrow(panel), " rows to ", out_main)
message("  distinct states: ", length(unique(panel$state_canonical)))
message("  month range: ", min(panel$year_month), " -> ", max(panel$year_month),
        " (", length(unique(panel$year_month)), " distinct months)")
message("Wrote ", nrow(uncl), " rows to ", out_uncl)
message("  avg unclassified volume share: ",
        sprintf("%.1f%%", 100 * mean(uncl$unclassified_volume_share, na.rm = TRUE)))
