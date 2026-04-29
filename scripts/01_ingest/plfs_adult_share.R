# scripts/01_ingest/plfs_adult_share.R
#
# Extract state-wise adult (15+) population SHARE from PLFS Annual Report
# 2023-24, Table 1 (sample composition by age and gender). Sums rural
# (page 64) and urban (page 65) sample counts per state to derive total
# persons enumerated and total persons aged 15+, then computes the share.
# Survey covers Jul 2023 - Jun 2024, midpoint ~Jan 2024 — ~9 months
# before the FY 2024-25 cross-section midpoint.
#
# Caveat: PLFS uses stratified multi-stage sampling that over-samples
# rural areas in absolute terms. Sample shares ≠ population shares
# exactly. Cross-state ranking is preserved because the sampling-design
# bias is uniform across states. Footnoted in the policy note.
#
# Output: data/interim/plfs_adult_share_2022_23.csv
# Run: Rscript scripts/01_ingest/plfs_adult_share.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(pdftools); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_file <- "data/raw/plfs/AR_PLFS_2023_24.pdf"
text <- pdftools::pdf_text(raw_file)

# PLFS 2023-24 Table 1 state ordering. URBAN page (p65) has all 36 units.
# RURAL page (p64) lacks Chandigarh (which has no rural area). Parse each
# page with its own state list.
plfs_state_order_urban <- c(
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
plfs_state_order_rural <- setdiff(plfs_state_order_urban, "Chandigarh")  # 35 states
stopifnot(length(plfs_state_order_urban) == 36L,
          length(plfs_state_order_rural) == 35L)

# Each data row: state name + 21 numeric columns. Last 4 are
# (Male, Female, Transgender, Person) for "all ages". Columns 16-18 are
# (Male, Female, Person) for "15 yrs & above". So:
#   number of trailing nums per row = 21
#   index of "Person 15+" from the end = 21 - 17 + 1 = 5  (i.e. 5th from the right when counting from 18)
# Wait — let me line that up to the column header:
#   col 16 = Male 15+
#   col 17 = Female 15+
#   col 18 = Person 15+
#   col 19 = Male all ages
#   col 20 = Female all ages
#   col 21 = Transgender all ages
#   col 22 = Person all ages
# 21 numeric columns total. Person 15+ is the 17th, Person all ages is the 21st (last).
# Equivalent: from the end of trailing numbers, Person 15+ is at position (21 - 17 + 1) = 5.

parse_num <- function(x) {
  x <- str_trim(as.character(x))
  if (x %in% c("-", "NA", "N.A.", "")) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", "", x)))
}

trailing_nums <- function(line, n) {
  raw <- str_trim(strsplit(str_trim(line), "\\s+")[[1]])
  raw <- raw[nchar(raw) > 0]
  if (length(raw) < n) return(NULL)
  candidates <- utils::tail(raw, n)
  vals <- vapply(candidates, parse_num, numeric(1))
  if (any(is.na(vals) & !candidates %in% c("-", "NA", "N.A."))) return(NULL)
  vals
}

# Walk a single page, assigning each 21-num row to next state in the
# given order. Caller supplies state_order to allow rural (35) vs urban (36).
parse_page <- function(pg_text, state_order) {
  lines <- strsplit(pg_text, "\n")[[1]]
  n <- length(state_order)
  out <- vector("list", n)
  i_state <- 1L
  for (line in lines) {
    if (i_state > n) break
    nums <- trailing_nums(line, 21)
    if (is.null(nums)) next
    expected <- state_order[i_state]
    head_word <- strsplit(expected, "\\s|&")[[1]][1]
    if (!grepl(head_word, line, fixed = TRUE)) next
    out[[i_state]] <- nums
    i_state <- i_state + 1L
  }
  miss <- which(vapply(out, is.null, logical(1)))
  if (length(miss) > 0) {
    stop("plfs_adult_share: no row for ",
         paste(state_order[miss], collapse = ", "), call. = FALSE)
  }
  m <- do.call(rbind, out)
  tibble(
    state_raw      = state_order,
    person_15plus  = m[, 17],   # 17th numeric = Person 15+
    person_all     = m[, 21]    # 21st numeric = Person all ages
  )
}

rural <- parse_page(text[64], plfs_state_order_rural) |> mutate(area = "rural")
urban <- parse_page(text[65], plfs_state_order_urban) |> mutate(area = "urban")

combined <- bind_rows(rural, urban) |>
  group_by(state_raw) |>
  summarise(
    person_15plus = sum(person_15plus),
    person_all    = sum(person_all),
    adult_share   = person_15plus / person_all,
    .groups = "drop"
  )

rec <- reconcile_states(combined$state_raw, "plfs-adult-share-2023-24")
out <- bind_cols(combined, rec) |>
  filter(include_in_analysis) |>
  select(state_canonical, state_code, adult_share, person_15plus, person_all) |>
  arrange(state_canonical)

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
out_file <- "data/interim/plfs_adult_share_2023_24.csv"
write_csv(out, out_file)

message("Wrote ", nrow(out), " rows to ", out_file)
message("\nSpot check (5 states):")
out |>
  filter(state_canonical %in% c("Bihar", "Kerala", "Maharashtra",
                                "Tamil Nadu", "Uttar Pradesh", "Goa")) |>
  mutate(adult_share_pct = round(adult_share * 100, 1)) |>
  select(state_canonical, adult_share_pct, person_15plus, person_all) |>
  as.data.frame() |>
  print(row.names = FALSE)
