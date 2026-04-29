# scripts/01_ingest/indiastat_literacy.R
#
# Purpose: Parse state-wise literacy rate (persons aged 7 years and above)
#          for FY 2019-20 and FY 2020-21 from Indiastat regional files.
#          These were originally pulled by Hari for the May 2024 thesis;
#          re-landed under data/raw/Literacy Rate/ on 2026-04-25. Same
#          5-region Indiastat structure as the Series 1 UPI files.
#
#          NOTE: FY 2017-18 files exist (4 regions) but use TWO different
#          table layouts (East/North use age-band 7+/5+ format; South/W&C
#          use rural/urban-split format). Since Option A (CLAUDE.md §7)
#          restricts Part I to 2019-20 and 2020-21, the 2017-18 files are
#          intentionally NOT parsed here. They stay in the raw folder for
#          reference.
#
#          PLFS literacy (data/interim/plfs_2022_23.csv) is now redundant
#          for Part I — this Indiastat source covers the exact Part I FYs.
# Inputs:  data/raw/Literacy Rate/Literacy rate - {2019-20|2020-21} - {N|S|E|W&C}.xls
#          (HTML-as-XLS — parsed with rvest, NOT readxl)
# Outputs: data/interim/indiastat_literacy.csv
#          columns: state_canonical, state_code, fy,
#                   literacy_rate_person_7plus
# Part:    I (control)
# Role:    Control (literacy is a first-order driver of digital payment uptake).
# Run:     Rscript scripts/01_ingest/indiastat_literacy.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(rvest); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir  <- "data/raw/Literacy Rate"
out_file <- "data/interim/indiastat_literacy.csv"

# Two file conventions exist in Indiastat's literacy series:
#   (a) Regional 5-file pulls (one per region: N/S/E/W&C/NE) for older FYs
#       2019-20 and 2020-21. These give state rows for 5-9 states each.
#   (b) Single all-India consolidated file per period (one file with all
#       36 states + India total). Used for newer years 2022-23, 2023-24,
#       and the calendar-year 2025 round.
# The parser detects which by checking the file title / filename and
# routes accordingly. Both share the same 7-column data layout
# (State | M7+ | M5+ | F7+ | F5+ | P7+ | P5+).
#
# Note on calendar year shift: PLFS shifted from fiscal-year (Jul-Jun)
# to calendar-year (Jan-Dec) reporting starting with the 2025 round.
all_files <- list.files(raw_dir, pattern = "\\.xls$", full.names = TRUE)
keep_files <- all_files[stringr::str_detect(
  basename(all_files),
  "(2019-20|2020-21|2022-23|2023-24|2024-25|- 2025 -)"
)]
if (length(keep_files) == 0) {
  stop("No literacy files matching target periods found under ", raw_dir, call. = FALSE)
}
message("Parsing ", length(keep_files), " files.")

# Each file's first table:
#   Header rows (5):  title, "(In %age)", "Age-group (Years)",
#                     Male/Female/Persons split, 7+ / 5+ split
#   Data rows: one per state; 6 numeric columns
#     col 2-3: Male 7+, Male 5+
#     col 4-5: Female 7+, Female 5+
#     col 6-7: Person 7+, Person 5+
#   Trailing rows: regional aggregate ("Northern India" etc.) and "All India",
#                  filtered out by reconcile_states() via include_in_analysis.
parse_one <- function(path) {
  # Period label: "2019-20", "2020-21", "2022-23", "2023-24" for FY-style;
  # "2025" for the calendar-year file.
  bn <- basename(path)
  fy <- stringr::str_extract(bn, "\\d{4}-\\d{2}")
  if (is.na(fy)) {
    fy <- stringr::str_extract(bn, "\\b(202[5-9])\\b")
  }
  doc <- rvest::read_html(path)
  tbls <- rvest::html_table(doc, fill = TRUE, header = FALSE)
  tb <- tbls[[1]]

  # Defensive scope check: the title sometimes carries "Rural Areas" or
  # "Urban Areas" qualifiers (e.g. South 2019-20 is rural-only). Including
  # such files in a "rural+urban" panel manufactures a fake within-state
  # literacy jump where some states are rural-only one year and combined
  # the next. Skip with a loud warning rather than silently corrupt data.
  title <- stringr::str_trim(as.character(tb[1, 1]))
  if (grepl("Rural Areas|in Rural India|Urban Areas|in Urban India",
            title, ignore.case = TRUE)) {
    warning(sprintf(
      "SKIPPING %s — title indicates partial scope (rural-only or urban-only):\n  %s",
      basename(path), substr(title, 1, 130)),
      call. = FALSE, immediate. = TRUE)
    return(NULL)
  }

  rows <- list()
  for (r in seq_len(nrow(tb))) {
    state_raw <- stringr::str_trim(as.character(tb[r, 1]))
    if (nchar(state_raw) == 0) next
    nums <- suppressWarnings(
      as.numeric(gsub(",", "", as.character(tb[r, 2:ncol(tb)])))
    )
    nums <- nums[!is.na(nums)]
    if (length(nums) < 6) next  # not a state-data row
    # Person 7+ is the 5th of 6 numeric columns (Male7, Male5, Fem7, Fem5, Per7, Per5)
    rows[[length(rows) + 1]] <- tibble::tibble(
      source_file = basename(path),
      fy          = fy,
      state_raw   = state_raw,
      literacy_rate_person_7plus = nums[5]
    )
  }
  dplyr::bind_rows(rows)
}

long <- purrr::map_dfr(keep_files, parse_one)
if (nrow(long) == 0) stop("No rows parsed from literacy files.", call. = FALSE)

rec <- reconcile_states(long$state_raw, "indiastat-literacy")

out_pre_agg <- dplyr::bind_cols(long, rec) |>
  dplyr::filter(include_in_analysis)

# Pre-merger Dadra & Nagar Haveli + Daman & Diu (both → DNHDD canonical)
# require POPULATION-WEIGHTED aggregation, not a simple mean — literacy is
# a rate, not a count. Pre-merger Census 2011 populations:
#   Dadra & Nagar Haveli  = 343,709
#   Daman & Diu           = 243,247
# Source: Census of India 2011 state totals.
dnhdd_weights <- c("Dadra & Nagar Haveli" = 343709,
                   "Daman & Diu"          = 243247)

out <- out_pre_agg |>
  dplyr::group_by(state_canonical, state_code, fy) |>
  dplyr::summarise(
    literacy_rate_person_7plus = {
      if (dplyr::n() == 1L) {
        literacy_rate_person_7plus
      } else {
        # Multi-row state — only DNHDD pre-merger should hit this branch.
        w <- dnhdd_weights[state_raw]
        if (any(is.na(w))) {
          stop("Unexpected multi-row aggregation for ", state_canonical[1],
               " (raw rows: ", paste(state_raw, collapse = ", "),
               "). Add Census-2011 weights to dnhdd_weights or split the row.",
               call. = FALSE)
        }
        sum(literacy_rate_person_7plus * w) / sum(w)
      }
    },
    .groups = "drop"
  ) |>
  dplyr::arrange(fy, state_canonical)

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
readr::write_csv(out, out_file)

message("Wrote ", nrow(out), " rows to ", out_file)
message("  states: ", length(unique(out$state_canonical)),
        " | FYs: ", paste(sort(unique(out$fy)), collapse = ", "))
message("\nSpot check (5 states × 2 FYs):")
out |>
  dplyr::filter(state_canonical %in% c("Bihar", "Kerala", "Maharashtra",
                                       "Tamil Nadu", "Uttar Pradesh")) |>
  as.data.frame() |>
  print(row.names = FALSE)
