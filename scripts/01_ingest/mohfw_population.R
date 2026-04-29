# scripts/01_ingest/mohfw_population.R
#
# Purpose: Parse state-wise projected population from Table 11 ("Projected
#          Total Population by Sex as on 1st July - 2011-2036") of the
#          MoHFW / National Commission on Population Technical Group
#          report (2019 revision). Mid-FY population is the per-capita
#          denominator for every DV transform (CLAUDE.md §8). Values are
#          reported in thousands and are converted to absolute counts.
# Inputs:  data/raw/mohfw/population/Report_Population_Projection_2019.pdf
# Outputs: data/interim/population_mohfw.csv
#          columns: state_canonical, state_code, year (integer, 1st July),
#                   population (persons, absolute count)
# Part:    Both (denominator)
# Role:    Support variable — enters every per-capita transformation.
# Run:     Rscript scripts/01_ingest/mohfw_population.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(pdftools); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_file <- "data/raw/mohfw/population/Report_Population_Projection_2019.pdf"
out_file <- "data/interim/population_mohfw.csv"

if (!file.exists(raw_file)) stop("Missing: ", raw_file, call. = FALSE)

text <- pdftools::pdf_text(raw_file)

# Table 11 — "1st July" — spans PDF pages 86 through 98. State layouts
# within each page are fixed by the document and hardcoded here because
# several pages split state names across two text rows (e.g. "ARUNACHAL"
# on one line, "PRADESH" on the next), which defeats generic header
# detection. Each page has 1-3 blocks of (Persons, Male, Females) columns
# in the order below.
page_layout <- list(
  `86` = c("INDIA", "JAMMU & KASHMIR", "HIMACHAL PRADESH"),
  `87` = c("PUNJAB", "HARYANA", "NCT OF DELHI"),
  `88` = c("RAJASTHAN", "UTTAR PRADESH", "BIHAR"),
  `89` = c("ASSAM", "WEST BENGAL", "JHARKHAND"),
  `90` = c("ODISHA", "CHHATTISGARH", "MADHYA PRADESH"),
  `91` = c("GUJARAT", "MAHARASHTRA", "ANDHRA PRADESH"),
  `92` = c("KARNATAKA", "KERALA", "TAMIL NADU"),
  `93` = c("CHANDIGARH", "UTTARAKHAND", "SIKKIM"),
  `94` = c("ARUNACHAL PRADESH", "NAGALAND", "MANIPUR"),
  `95` = c("MIZORAM", "TRIPURA", "MEGHALAYA"),
  `96` = c("DAMAN & DIU", "DADRA & NAGAR HAVELI", "GOA"),
  `97` = c("LAKSHADWEEP", "PUDUCHERRY", "ANDAMAN & NICOBAR ISLANDS"),
  `98` = c("TELANGANA", "LADAKH")
)

# Parse one page given its known state list. Each year row has
# 1 year + 3*n_states numbers; take positions 1, 4, 7 (Persons column
# for each state).
parse_page <- function(txt, states) {
  lines <- strsplit(txt, "\n")[[1]]
  n <- length(states)
  # On some pages (e.g. p98 Telangana/Ladakh) the year sits alone on one
  # line and its numeric row follows on the next. Fuse those pairs back
  # together before running the main pattern.
  i <- 1
  fused <- character(0)
  while (i <= length(lines)) {
    if (i < length(lines) &&
        grepl("^\\s*20\\d{2}\\s*$", lines[i]) &&
        grepl("^\\s+[0-9,]+", lines[i + 1])) {
      fused <- c(fused, paste(stringr::str_trim(lines[i]), lines[i + 1]))
      i <- i + 2
    } else {
      fused <- c(fused, lines[i])
      i <- i + 1
    }
  }
  lines <- fused

  pat <- paste0("^\\s*(20\\d{2})\\s+",
                paste(rep("([0-9,]+)", 3 * n), collapse = "\\s+"),
                "\\s*$")
  m <- stringr::str_match(lines, pat)
  ok <- !is.na(m[, 1])
  if (!any(ok)) return(tibble::tibble())
  rows <- as.data.frame(m[ok, 2:(3 * n + 2), drop = FALSE], stringsAsFactors = FALSE)
  colnames(rows) <- c("year", paste0("v", seq_len(3 * n)))
  rows$year <- as.integer(rows$year)
  for (c in paste0("v", seq_len(3 * n))) rows[[c]] <- as.numeric(gsub(",", "", rows[[c]]))
  persons_cols <- paste0("v", seq(1, 3 * n, by = 3))

  purrr::map_dfr(seq_len(n), function(i) {
    tibble::tibble(
      state_raw  = states[i],
      year       = rows$year,
      population = rows[[persons_cols[i]]]
    )
  })
}

long <- purrr::map_dfr(
  names(page_layout),
  function(pg) parse_page(text[as.integer(pg)], page_layout[[pg]])
)
if (nrow(long) == 0) stop("No data parsed from Table 11.", call. = FALSE)

rec <- reconcile_states(long$state_raw, "mohfw-population-table11")

out <- dplyr::bind_cols(long, rec) |>
  dplyr::filter(include_in_analysis) |>
  # Report publishes populations in thousands — convert to absolute count.
  dplyr::mutate(population = as.integer(round(population * 1000))) |>
  # Pre-merger Dadra & Nagar Haveli + Daman & Diu both map to the merged
  # DNHDD canonical; sum them so each (state, year) has one row.
  dplyr::group_by(state_canonical, state_code, year) |>
  dplyr::summarise(population = sum(population), .groups = "drop") |>
  dplyr::arrange(year, state_canonical)

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
readr::write_csv(out, out_file)

message("Wrote ", nrow(out), " rows to ", out_file)
message("  distinct states/UTs: ", length(unique(out$state_canonical)))
message("  year range: ", min(out$year), " -> ", max(out$year))
message("  total 2020 India pop (sum across states, millions): ",
        sprintf("%.1f", sum(out$population[out$year == 2020]) / 1e6))
