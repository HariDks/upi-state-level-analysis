# scripts/01_ingest/mohfw_rhs.R
#
# Purpose: Extract four state-wise tables from MoHFW Rural Health
#          Statistics 2020-21 (PDF). Together these cover everything
#          CLAUDE.md §9 requires for the PHC correction:
#            - Table 1 → state geographic area (sq.km)
#            - Table 2 → rural / urban population (2011 + 2021 mid-year)
#                         and rural-share of population (= 1 - urban share)
#            - Table 3 → population density 2020 (persons / sq.km)
#            - Table 6 → number of SCs, PHCs, CHCs functioning
#                         in rural and urban areas, as on 31-Mar-2021
#          (The Census urbanization PDF in data/raw/census/ is now
#          redundant for the 2011 baseline — Table 2 has it.)
# Inputs:  data/raw/mohfw/rhs/RHS_2020-21.pdf
# Outputs: data/interim/mohfw_state_area.csv         (state, area_total_km2,
#                                                     area_rural_km2, area_urban_km2)
#          data/interim/mohfw_population_2011_2021.csv (state, year,
#                                                       population_rural,
#                                                       population_urban,
#                                                       population_total)
#          data/interim/mohfw_population_density_2020.csv (state, density_total)
#          data/interim/mohfw_phcs.csv                (state, sc_rural, sc_urban,
#                                                      phc_rural, phc_urban,
#                                                      chc_rural, chc_urban)
# Part:    I (PHC correction §9), feeds into per-area transforms.
# Role:    Controls + focal variables for the §9 correction.
# Run:     Rscript scripts/01_ingest/mohfw_rhs.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(pdftools); library(dplyr); library(tidyr); library(readr)
  library(tibble); library(stringr); library(purrr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_2021 <- "data/raw/mohfw/rhs/RHS_2020-21.pdf"   # FY 2020-21 (as on 31-Mar-2021)
raw_2020 <- "data/raw/mohfw/rhs/RHS_2019-20.pdf"   # FY 2019-20 (as on 31-Mar-2020)
if (!file.exists(raw_2021)) stop("Missing: ", raw_2021, call. = FALSE)
text  <- pdftools::pdf_text(raw_2021)
have_2020 <- file.exists(raw_2020)
text20 <- if (have_2020) pdftools::pdf_text(raw_2020) else NULL

# RHS tables list states in a fixed order across every table — alphabetical
# states 1-28 then alphabetical UTs 29-36. Hardcoding the order avoids
# having to parse wrapped state-name headers (e.g. "Andaman & Nicobar" on
# one line, "Islands" on the next).
state_order <- c(
  "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
  "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand",
  "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur",
  "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab",
  "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
  "Uttarakhand", "Uttar Pradesh", "West Bengal",
  "Andaman and Nicobar Islands", "Chandigarh",
  "Dadra and Nagar Haveli and Daman and Diu", "Delhi",
  "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
)
stopifnot(length(state_order) == 36L)

# Treat NA tokens consistently across tables.
parse_num <- function(x) {
  x <- stringr::str_trim(as.character(x))
  if (x %in% c("NA", "N.A.", "N App", "NApp", "-", "*", "")) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", "", x)))
}

# Pull n trailing numeric-or-NA tokens from one line. Split on any
# whitespace because some columns are separated by a single space in the
# PDF text extraction (e.g. Tamil Nadu's row in Table 1).
trailing_nums <- function(line, n) {
  raw <- stringr::str_trim(strsplit(stringr::str_trim(line), "\\s+")[[1]])
  raw <- raw[nchar(raw) > 0]
  if (length(raw) < n) return(NULL)
  # Re-stitch a multi-token "N App" (the "Not applicable" marker) into one.
  i <- 1; tokens <- character(0)
  while (i <= length(raw)) {
    if (i < length(raw) && raw[i] == "N" && raw[i + 1] == "App") {
      tokens <- c(tokens, "NApp"); i <- i + 2
    } else {
      tokens <- c(tokens, raw[i]); i <- i + 1
    }
  }
  if (length(tokens) < n) return(NULL)
  candidates <- utils::tail(tokens, n)
  vals <- vapply(candidates, parse_num, numeric(1))
  ok <- !is.na(vals) | candidates %in% c("NA", "N.A.", "N App", "NApp", "-", "*")
  if (!all(ok)) return(NULL)
  vals
}

# Walk the page text, attribute each row of n trailing numbers to the
# most recently seen serial 1-36. Handles wrapped state names where the
# data row has no serial prefix (e.g. row 31 DNHDD across multiple pages).
parse_table_pages <- function(pages_text, n_data_cols, min_data_cols = n_data_cols) {
  lines <- unlist(strsplit(pages_text, "\n"))
  out <- vector("list", 36)
  current <- NA_integer_
  for (line in lines) {
    serial_m <- stringr::str_match(line, "^\\s*(\\d+)\\b")
    if (!is.na(serial_m[1, 1])) {
      s <- as.integer(serial_m[1, 2])
      if (s >= 1L && s <= 36L) current <- s
    }
    nums <- trailing_nums(line, n_data_cols)
    # Fallback: row with text in some cells (e.g. Ladakh's "UT came to
    # existence..." note in Table 2 leaves only the 2021 numbers parseable).
    # Pad missing leading columns with NA.
    if (is.null(nums) && min_data_cols < n_data_cols) {
      for (try_n in seq(n_data_cols - 1L, min_data_cols)) {
        partial <- trailing_nums(line, try_n)
        if (!is.null(partial)) {
          nums <- c(rep(NA_real_, n_data_cols - try_n), partial); break
        }
      }
    }
    if (!is.null(nums) && !is.na(current) && is.null(out[[current]])) {
      out[[current]] <- nums
    }
  }
  missing_serials <- which(vapply(out, is.null, logical(1)))
  if (length(missing_serials) > 0) {
    stop("parse_table_pages(): no data row found for serial(s) ",
         paste(missing_serials, collapse = ", "),
         " (",
         paste(state_order[missing_serials], collapse = ", "),
         "). Inspect PDF; layout may have shifted.",
         call. = FALSE)
  }
  m <- do.call(rbind, out)
  tibble::as_tibble(m, .name_repair = ~ paste0("v", seq_along(.x))) |>
    dplyr::mutate(state_raw = state_order, .before = 1)
}

# --- Table 1: state area (PDF page 134). 7 trailing numeric columns:
#     Tribal | Rural | Urban | Total | Rural% | Districts | Villages.
t1 <- parse_table_pages(text[134], 7) |>
  dplyr::transmute(
    state_raw,
    area_rural_km2 = v2,
    area_urban_km2 = v3,
    area_total_km2 = v4
  )

# --- Table 2: population 2011 census + 2021 mid-year estimate (p135).
#     8 trailing numeric columns:
#     R2011 | U2011 | T2011 | RPct2011 | R2021 | U2021 | T2021 | RPct2021.
#     Ladakh row has a text-only 2011 cell ("Ladakh UT came to existence...");
#     for parsing we accept a 2-column tail-shorted row and re-fetch later.
t2 <- parse_table_pages(text[135], 8, min_data_cols = 4) |>
  dplyr::transmute(
    state_raw,
    population_rural_2011 = v1, population_urban_2011 = v2, population_total_2011 = v3,
    population_rural_2021 = v5, population_urban_2021 = v6, population_total_2021 = v7
  )
# Reshape wide to long.
t2_long <- dplyr::bind_rows(
  t2 |> dplyr::transmute(state_raw, year = 2011L,
                         population_rural = population_rural_2011,
                         population_urban = population_urban_2011,
                         population_total = population_total_2011),
  t2 |> dplyr::transmute(state_raw, year = 2021L,
                         population_rural = population_rural_2021,
                         population_urban = population_urban_2021,
                         population_total = population_total_2021)
) |> dplyr::arrange(state_raw, year)

# --- Table 3: population density 2020 (p136). 3 trailing numeric columns:
#     Rural | Urban | Total density.
t3 <- parse_table_pages(text[136], 3) |>
  dplyr::transmute(state_raw, density_total = v3)

# --- Table 6: SC, PHC, CHC counts. 6 trailing numeric columns:
#     SC_R | SC_U | PHC_R | PHC_U | CHC_R | CHC_U.
#     2020-21 PDF: page 142 (data as on 31-Mar-2021)
#     2019-20 PDF: page 158 (data as on 31-Mar-2020)
parse_t6 <- function(pdf_text, fy, source_label) {
  parse_table_pages(pdf_text, 6) |>
    dplyr::transmute(
      state_raw,
      fy = fy,
      sc_rural = v1, sc_urban = v2,
      phc_rural = v3, phc_urban = v4,
      chc_rural = v5, chc_urban = v6
    )
}
t6_2021 <- parse_t6(text[142],   "2020-21", "mohfw-rhs-2020-21")
t6 <- if (have_2020) {
  t6_2020 <- parse_t6(text20[158], "2019-20", "mohfw-rhs-2019-20")
  dplyr::bind_rows(t6_2020, t6_2021)
} else {
  message("RHS 2019-20 PDF not present — phc output covers 2020-21 only.")
  t6_2021
}

# Reconcile state names across all four tables (single failure surface).
all_raw <- unique(c(t1$state_raw, t2$state_raw, t3$state_raw, t6$state_raw))
rec <- reconcile_states(all_raw, "mohfw-rhs")
rec_lookup <- dplyr::distinct(rec, original, state_canonical, state_code)

attach_canonical <- function(df) {
  dplyr::left_join(df, rec_lookup, by = c("state_raw" = "original")) |>
    dplyr::select(state_canonical, state_code, dplyr::everything(), -state_raw) |>
    dplyr::arrange(state_canonical)
}

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)

write_one <- function(df, path) {
  readr::write_csv(df, path)
  message("Wrote ", nrow(df), " rows to ", path)
}

write_one(attach_canonical(t1),                      "data/interim/mohfw_state_area.csv")
write_one(attach_canonical(t2_long) |>
            dplyr::select(state_canonical, state_code, year,
                          population_rural, population_urban, population_total),
                                                     "data/interim/mohfw_population_2011_2021.csv")
write_one(attach_canonical(t3),                      "data/interim/mohfw_population_density_2020.csv")
phcs_out <- attach_canonical(t6) |>
  dplyr::select(state_canonical, state_code, fy,
                sc_rural, sc_urban, phc_rural, phc_urban, chc_rural, chc_urban) |>
  dplyr::arrange(fy, state_canonical)
write_one(phcs_out,                                  "data/interim/mohfw_phcs.csv")

# Sanity per FY (each year's report publishes its own All-India totals).
message("\nSanity (state-sum vs report-stated All-India totals):")
phcs_out |>
  dplyr::group_by(fy) |>
  dplyr::summarise(phc_rural_sum = sum(phc_rural, na.rm = TRUE),
                   phc_urban_sum = sum(phc_urban, na.rm = TRUE),
                   .groups = "drop") |>
  as.data.frame() |>
  print(row.names = FALSE)
message("  (RHS 2020-21 report All-India: 25140 rural / 5439 urban PHC.)")
