# scripts/01_ingest/plfs.R
#
# Purpose: Extract state-wise labour-market and literacy indicators from
#          the PLFS Annual Report 2022-23 (NSO/MoSPI). Pulls the headline
#          rural+urban combined figures for working-age (15+) labour
#          metrics and persons-aged-7+ literacy:
#            - Table 3 (page 70): Literacy rate, persons aged 7+
#            - Table 6 (page 84): Labour Force Participation Rate (LFPR),
#                                 usual status (ps+ss), age 15+
#            - Table 7 (page 89): Worker Population Ratio (WPR),
#                                 usual status (ps+ss), age 15+
#            - Table 8 (page 94): Unemployment Rate (UR),
#                                 usual status (ps+ss), age 15+
#          All four tables use the same alphabetical state ordering (28
#          states + 7 UTs in one block, no separate UT section), which is
#          hardcoded below.
# Inputs:  data/raw/plfs/AR_PLFS_2022_23.pdf
# Outputs: data/interim/plfs_2022_23.csv
#          columns: state_canonical, state_code, period (= "2022-23"),
#                   literacy_rate_persons_7plus,
#                   lfpr_15plus_persons, wpr_15plus_persons, ur_15plus_persons
# Part:    I and II (controls)
# Role:    Controls.
# Run:     Rscript scripts/01_ingest/plfs.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(pdftools); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_file <- "data/raw/plfs/AR_PLFS_2022_23.pdf"
if (!file.exists(raw_file)) stop("Missing: ", raw_file, call. = FALSE)
text <- pdftools::pdf_text(raw_file)

# PLFS uses a single alphabetical block (Delhi appears at position 6 with
# the states, not segregated to a UT section like RHS does). 36 units.
plfs_state_order <- c(
  "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
  "Delhi", "Goa", "Gujarat", "Haryana", "Himachal Pradesh",
  "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra",
  "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha",
  "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana",
  "Tripura", "Uttarakhand", "Uttar Pradesh", "West Bengal",
  "Andaman & N. Island", "Chandigarh",
  "Dadra & Nagar Haveli & Daman & Diu", "Jammu & Kashmir",
  "Ladakh", "Lakshadweep", "Puducherry"
)
stopifnot(length(plfs_state_order) == 36L)

parse_num <- function(x) {
  x <- stringr::str_trim(as.character(x))
  if (x %in% c("NA", "N.A.", "-", "*", "")) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", "", x)))
}

# Take n trailing numeric tokens from a line. Used to identify state-data
# rows even when the state-name column wraps onto extra lines.
trailing_nums <- function(line, n) {
  tokens <- stringr::str_trim(strsplit(stringr::str_trim(line), "\\s+")[[1]])
  tokens <- tokens[nchar(tokens) > 0]
  if (length(tokens) < n) return(NULL)
  candidates <- utils::tail(tokens, n)
  vals <- vapply(candidates, parse_num, numeric(1))
  if (any(is.na(vals) & !candidates %in% c("NA", "N.A.", "-", "*"))) return(NULL)
  vals
}

# Walk a single page; assign each n-trailing-num row to the next state in
# plfs_state_order. PLFS pages have one row per state in fixed order, no
# wrapping in the rural+urban tables we're parsing — this is simpler than
# the RHS layout because there's no serial-number column to anchor to.
parse_plfs_page <- function(pg_text, n_data_cols) {
  lines <- strsplit(pg_text, "\n")[[1]]
  out <- vector("list", 36)
  i_state <- 1L
  for (line in lines) {
    if (i_state > 36L) break
    nums <- trailing_nums(line, n_data_cols)
    if (is.null(nums)) next
    # Make sure the line actually mentions the expected state name (or a
    # word from it) — guards against header rows that happen to have n
    # numeric tokens at the end.
    expected <- plfs_state_order[i_state]
    head_word <- strsplit(expected, "\\s|&")[[1]][1]
    if (!grepl(head_word, line, fixed = TRUE)) next
    out[[i_state]] <- nums
    i_state <- i_state + 1L
  }
  missing <- which(vapply(out, is.null, logical(1)))
  if (length(missing) > 0) {
    stop("parse_plfs_page(): no row for ",
         paste(plfs_state_order[missing], collapse = ", "), call. = FALSE)
  }
  m <- do.call(rbind, out)
  tibble::as_tibble(m, .name_repair = ~ paste0("v", seq_along(.x))) |>
    dplyr::mutate(state_raw = plfs_state_order, .before = 1)
}

# Table 3 (literacy, p70 = rural+urban combined): 6 trailing numbers ─
# male 7+, male 5+, female 7+, female 5+, persons 7+, persons 5+.
t3 <- parse_plfs_page(text[70], 6) |>
  dplyr::transmute(state_raw, literacy_rate_persons_7plus = v5)

# Table 6/7/8 at age 15+: 9 trailing numbers ─
# rural M/F/P, urban M/F/P, total M/F/P. We keep the total-persons column.
t6 <- parse_plfs_page(text[84], 9) |>
  dplyr::transmute(state_raw, lfpr_15plus_persons = v9)
t7 <- parse_plfs_page(text[89], 9) |>
  dplyr::transmute(state_raw, wpr_15plus_persons = v9)
t8 <- parse_plfs_page(text[94], 9) |>
  dplyr::transmute(state_raw, ur_15plus_persons = v9)

combined <- t3 |>
  dplyr::full_join(t6, by = "state_raw") |>
  dplyr::full_join(t7, by = "state_raw") |>
  dplyr::full_join(t8, by = "state_raw")

rec <- reconcile_states(combined$state_raw, "plfs-2022-23")

out <- dplyr::bind_cols(combined, rec) |>
  dplyr::filter(include_in_analysis) |>
  dplyr::mutate(period = "2022-23") |>
  dplyr::select(state_canonical, state_code, period,
                literacy_rate_persons_7plus,
                lfpr_15plus_persons, wpr_15plus_persons, ur_15plus_persons) |>
  dplyr::arrange(state_canonical)

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
out_file <- "data/interim/plfs_2022_23.csv"
readr::write_csv(out, out_file)

message("Wrote ", nrow(out), " rows to ", out_file)
message("\nSpot check (rural+urban, age 15+ persons):")
out |>
  dplyr::filter(state_canonical %in%
                  c("Bihar", "Kerala", "Maharashtra", "Tamil Nadu", "Uttar Pradesh")) |>
  as.data.frame() |>
  print(row.names = FALSE)
