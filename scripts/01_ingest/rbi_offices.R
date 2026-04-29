# scripts/01_ingest/rbi_offices.R
#
# Ingest RBI Database on Indian Economy (DBIE) — Statistical Tables
# Relating to Banks in India, Other STRBI Table No. 13:
# "State-wise Number of Functioning Offices of Commercial Banks", quarterly.
#
# We extract end-of-FY snapshots used across both halves of the paper:
#   - 31-Mar-2020 (end of FY 2019-20) and 31-Mar-2021 (end of FY 2020-21)
#     for Part I
#   - 31-Mar-2025 (end of FY 2024-25) for Part II
#
# "Functioning Offices" includes branches + administrative offices +
# extension counters of all scheduled commercial banks (public, private,
# foreign, RRB, small finance, payments banks). Conceptually a measure of
# physical banking-system presence per state.
#
# DNHDD merger handling: the source file lists "DAMAN & DIU" as a separate
# row alongside "DADRA AND NAGAR HAVELI AND DAMAN AND DIU". For dates
# after the January-2020 merger, the D&D row is mostly NA. For earlier
# dates it may carry the pre-merger Daman & Diu count. The canonical
# lookup maps both raw spellings to the merged DNHDD canonical; we
# aggregate by sum so the panel uses post-merger units consistently.
#
# Input:  data/raw/rbi_handbook/Other STRBI Table No 13. State-Wise Number
#         of Functioning Offices of Commercial Banks.xlsx
# Output: data/interim/rbi_offices_state_panel.csv  (long form: state x date)
#
# Run: Rscript scripts/01_ingest/rbi_offices.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(readxl); library(tidyr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_file <- "data/raw/rbi_handbook/Other STRBI Table No 13. State-Wise Number of Functioning Offices of Commercial Banks.xlsx"
target_dates <- as.Date(c("2020-03-31", "2021-03-31",
                          "2024-03-31", "2025-03-31",
                          "2025-12-31"))

raw <- suppressWarnings(suppressMessages(
  read_excel(raw_file, sheet = 1, col_names = FALSE, .name_repair = "minimal")
))

date_serials  <- suppressWarnings(as.numeric(unlist(raw[3, ])))
quarter_dates <- as.Date(date_serials, origin = "1899-12-30")

# Extract one snapshot date and reduce to canonical state level.
extract_snapshot <- function(td) {
  col <- which(quarter_dates == td)
  if (length(col) != 1L) {
    stop("Could not locate the ", td, " column in row 3 of ", raw_file,
         call. = FALSE)
  }
  body <- raw[4:nrow(raw), c(3, col)]
  names(body) <- c("state_raw", "offices")
  body <- body |>
    mutate(state_raw = as.character(state_raw),
           offices   = suppressWarnings(as.numeric(offices))) |>
    filter(!is.na(state_raw), nzchar(state_raw)) |>
    filter(!grepl("^total|^grand", state_raw, ignore.case = TRUE)) |>
    # Drop "DAMAN & DIU" only when its count is NA (post-merger artifact);
    # keep it when there is a real value (pre-merger pre-2020-01) so that
    # canonical-aggregation captures the full DNHDD count.
    filter(!(state_raw == "DAMAN & DIU" & is.na(offices)))

  recon <- reconcile_states(body$state_raw, paste0("rbi-offices-", td))
  bind_cols(body, recon |> select(state_canonical, state_code)) |>
    group_by(state_canonical, state_code) |>
    summarise(offices = sum(offices, na.rm = FALSE), .groups = "drop") |>
    mutate(snapshot_date = td) |>
    select(state_canonical, state_code, snapshot_date, offices)
}

panel <- map_dfr(target_dates, extract_snapshot) |>
  arrange(state_canonical, snapshot_date)

cat("\nRBI offices panel (long form):\n")
panel |>
  group_by(snapshot_date) |>
  summarise(n_states = n(),
            min = min(offices, na.rm = TRUE),
            max = max(offices, na.rm = TRUE),
            india_total = sum(offices, na.rm = TRUE),
            .groups = "drop") |>
  print()

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
out_file <- "data/interim/rbi_offices_state_panel.csv"
write_csv(panel, out_file)
message("\nWrote ", nrow(panel), " state-date rows to ", out_file)
