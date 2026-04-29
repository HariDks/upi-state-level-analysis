# scripts/01_ingest/trai_internet_density.R
#
# Purpose: Parse Table 1.35 of TRAI's "Indian Telecom Services Yearly
#          Performance Indicators 2023-24" report — state/UT-wise number
#          of internet subscribers per 100 population as of 31-Mar-2024.
#          Internet penetration is the first-order channel for UPI use
#          (UPI requires a smartphone with internet) per CLAUDE.md §7a.
# Inputs:  data/raw/trai/YPI_2023-24.pdf
# Outputs: data/interim/trai_internet_2024.csv
#          columns: state_canonical, state_code, year_end (= "2024-03"),
#                   internet_subs_total_million, internet_density_total
# Part:    II baseline (FY 2023-24). For Part I (FY 2019-20, 2020-21) and
#          later Part II years, separate annual TRAI YPI reports must be
#          pulled — flagged in data/raw/trai/_MANIFEST.txt.
# Role:    Control variable.
# Run:     Rscript scripts/01_ingest/trai_internet_density.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(pdftools); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

# Multi-year TRAI parser: YPI 2023-24 (data Mar-2024) and YPI 2024-25
# (data Mar-2025). Both have a State/UT internet-subscribers-per-100 table
# at modern boundaries (separate Telangana, Jharkhand, etc.). Pages differ:
#   YPI 2023-24 → Table 1.35 at p57
#   YPI 2024-25 → Table 1.43 at p68
sources <- list(
  list(file = "data/raw/trai/YPI_2023-24.pdf", pages = 57,    year_end = "2024-03"),
  list(file = "data/raw/trai/YPI_2024-25.pdf", pages = 68:69, year_end = "2025-03")
)
out_file <- "data/interim/trai_internet_panel.csv"
sources <- Filter(function(s) file.exists(s$file), sources)
if (length(sources) == 0) stop("No TRAI YPI files present.", call. = FALSE)

# Table 1.35 lives on PDF page 57. State order is fixed: 28 states
# alphabetical (with TRAI's typos) then 8 UTs alphabetical. Because the
# UT serial numbers reset to 1, position-in-order anchoring is more
# reliable than serial tracking. Use TRAI's exact spellings — variants
# are in the lookup so reconcile_states() handles the typos cleanly.
state_order <- c(
  # 28 states (TRAI alphabetical)
  "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chattisgarh",
  "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand",
  "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur",
  "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab",
  "Rajasthan", "Sikkim", "Tamil Nadu incl. Chennai", "Telangana", "Tripura",
  "Uttar Pradesh (UPE+UPW)", "Uttarakhand", "West Bengal incl. Kolkata",
  # 8 UTs (TRAI alphabetical)
  "Andaman & Nicobar Islands", "Chandigarh",
  "Dadar & Nagar Haweli (incl. Daman & Diu)", "Delhi",
  "Jammu & Kashmir", "Ladakh", "Lakshdweep", "Puduchery"
)
stopifnot(length(state_order) == 36L)

# (no-op block — kept for backward reference)
pg <- NULL; lines <- NULL

parse_num <- function(x) {
  x <- stringr::str_trim(as.character(x))
  if (x %in% c("-", "NA", "N.A.", "NApp", "")) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", "", x)))
}

# Take n trailing numeric/NA tokens from a line. Splits on any whitespace
# (TRAI uses single-space between columns in some rows).
trailing_nums <- function(line, n) {
  raw <- stringr::str_trim(strsplit(stringr::str_trim(line), "\\s+")[[1]])
  raw <- raw[nchar(raw) > 0]
  if (length(raw) < n) return(NULL)
  candidates <- utils::tail(raw, n)
  vals <- vapply(candidates, parse_num, numeric(1))
  ok <- !is.na(vals) | candidates %in% c("-", "NA", "N.A.", "NApp")
  if (!all(ok)) return(NULL)
  vals
}

# For each YPI source: walk the target page, attribute each 6-num row
# to the next state in state_order, and tag with the year_end label.
parse_one_ypi <- function(src) {
  text <- pdftools::pdf_text(src$file)
  # Concatenate text for the requested pages (Table 1.43 in YPI 2024-25
  # spans p68 + p69; Table 1.35 in YPI 2023-24 fits on p57).
  combined <- paste(text[src$pages], collapse = "\n")
  lines <- strsplit(combined, "\n")[[1]]
  # Skip until we hit a line that looks like the start of the State/UT
  # data table — the first row reading state-1 (Andhra Pradesh) — to avoid
  # consuming the Service Area table that may also be on the same page.
  start_idx <- which(grepl("Andhra Pradesh", lines) & grepl("[0-9]", lines))[1]
  if (!is.na(start_idx)) lines <- lines[start_idx:length(lines)]
  out <- vector("list", 36)
  i_state <- 1L
  for (line in lines) {
    if (i_state > 36L) break
    nums <- trailing_nums(line, 6)
    if (is.null(nums)) next
    out[[i_state]] <- nums
    i_state <- i_state + 1L
  }
  missing <- which(vapply(out, is.null, logical(1)))
  if (length(missing) > 0) {
    stop("TRAI ", basename(src$file), " pages ",
         paste(src$pages, collapse = ","),
         ": no row found for ",
         paste(state_order[missing], collapse = ", "),
         " (parsed ", i_state - 1L, " of 36 expected).",
         call. = FALSE)
  }
  m <- do.call(rbind, out)
  tibble::as_tibble(m, .name_repair = ~ paste0("v", seq_along(.x))) |>
    dplyr::mutate(state_raw = state_order, .before = 1) |>
    dplyr::transmute(
      state_raw,
      year_end = src$year_end,
      internet_subs_total_million = v3,
      internet_density_total      = v6
    )
}
wide <- purrr::map_dfr(sources, parse_one_ypi)

rec <- reconcile_states(wide$state_raw, "trai-ypi-multi-year")
out_df <- dplyr::bind_cols(wide, rec) |>
  dplyr::filter(include_in_analysis) |>
  dplyr::select(state_canonical, state_code, year_end,
                internet_subs_total_million, internet_density_total) |>
  dplyr::arrange(year_end, state_canonical)

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
readr::write_csv(out_df, out_file)

message("Wrote ", nrow(out_df), " rows to ", out_file)
message("\nSpot check (5 states, internet subscribers per 100 as of 31-Mar-2024):")
out_df |>
  dplyr::filter(state_canonical %in% c("Bihar", "Goa", "Maharashtra",
                                       "Tamil Nadu", "Uttar Pradesh", "Delhi")) |>
  as.data.frame() |>
  print(row.names = FALSE)
