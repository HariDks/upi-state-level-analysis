# scripts/01_ingest/series1_digital_payments.R
#
# Ingest the Series 1 5-rail composite (BHIM + IMPS + RuPay on POS + UPI +
# USSD) state-wise annual transaction counts for FY 2019-20 and FY 2020-21.
# This is the dependent variable for Part I of the paper.
#
# Source: Indiastat regional tables, originally compiled from Lok Sabha
# Unstarred Question No. 1425 (28.07.2021). Five regional HTML-as-XLS
# files cover all 36 states/UTs; each reports two FYs side-by-side.
#
# Note (per CLAUDE.md §7 + manifest): FY 2017-18 is intentionally NOT
# ingested. The corresponding LS QN5291 file is a 3-rail composite
# (BHIM + UPI + USSD), definitionally incompatible with the 5-rail
# definition above; chaining the two would re-introduce the
# definitional break the paper avoids. Option A decision (2026-04-24).
#
# Input:  data/raw/indiastat/series1_digital_payments/LS_QN1425_FY2019-20_2020-21/*.xls
# Output: data/interim/series1_5rail_state_fy.csv
#
# Run: Rscript scripts/01_ingest/series1_digital_payments.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(rvest); library(tidyr); library(stringr)
})

source("scripts/01_ingest/_utils_state_names.R")

raw_dir <- "data/raw/indiastat/series1_digital_payments/LS_QN1425_FY2019-20_2020-21"
files   <- list.files(raw_dir, pattern = "\\.xls$", full.names = TRUE)
stopifnot(length(files) == 5L)

read_one_region <- function(f) {
  h <- read_html(f)
  tabs <- html_table(h, fill = TRUE)
  # Table 1 contains: row 1 = section title, row 2 = header, rows 3+ = data.
  d <- tabs[[1]]
  stopifnot(ncol(d) == 4L)
  d <- d[-c(1, 2), ]
  names(d) <- c("state_raw", "fy_2019_20", "fy_2020_21", "pct_growth")
  d |>
    mutate(
      across(c(fy_2019_20, fy_2020_21),
             \(x) as.numeric(gsub(",", "", x))),
      source_file = basename(f)
    ) |>
    select(state_raw, fy_2019_20, fy_2020_21, source_file)
}

raw_long <- bind_rows(lapply(files, read_one_region)) |>
  filter(!is.na(state_raw), nzchar(state_raw))

# Reconcile through canonical lookup (fail-loud on unknown spellings).
recon <- reconcile_states(raw_long$state_raw, "indiastat-series1")
combined <- bind_cols(raw_long, recon |> select(state_canonical, state_code))

# Boundary handling: the source reports "Dadra & Nagar Haveli" and
# "Daman & Diu" as separate UTs for both FY 2019-20 and FY 2020-21,
# even though they merged into a single UT (DNHDD) in January 2020. The
# canonical lookup maps both raw spellings to the merged DNHDD; we
# aggregate transactions by (state_canonical, fy) so the panel uses
# post-merger units consistently with Part II. This mirrors the J&K /
# Ladakh combination convention in CLAUDE.md §6.
out <- combined |>
  pivot_longer(cols = c(fy_2019_20, fy_2020_21),
               names_to = "fy_tag", values_to = "transactions_total_5rail") |>
  mutate(fy = case_when(
    fy_tag == "fy_2019_20" ~ "2019-20",
    fy_tag == "fy_2020_21" ~ "2020-21"
  )) |>
  group_by(state_canonical, state_code, fy) |>
  summarise(transactions_total_5rail = sum(transactions_total_5rail),
            .groups = "drop") |>
  arrange(state_canonical, fy)

# Sanity checks
n_states <- length(unique(out$state_canonical))
n_rows   <- nrow(out)
cat(sprintf("\nSeries 1 5-rail panel: %d state-FY rows (%d states x 2 FYs).\n",
            n_rows, n_states))
cat("Range FY 2019-20:", format(min(out$transactions_total_5rail[out$fy=="2019-20"]),
                                 big.mark=","),
    "to", format(max(out$transactions_total_5rail[out$fy=="2019-20"]),
                  big.mark=","), "\n")
cat("Range FY 2020-21:", format(min(out$transactions_total_5rail[out$fy=="2020-21"]),
                                 big.mark=","),
    "to", format(max(out$transactions_total_5rail[out$fy=="2020-21"]),
                  big.mark=","), "\n")
cat("All-India total FY 2019-20:",
    format(sum(out$transactions_total_5rail[out$fy=="2019-20"]),
           big.mark=","), "\n")
cat("All-India total FY 2020-21:",
    format(sum(out$transactions_total_5rail[out$fy=="2020-21"]),
           big.mark=","), "\n")

stopifnot(n_rows == n_states * 2L)
stopifnot(all(!is.na(out$transactions_total_5rail)))

if (!dir.exists("data/interim")) dir.create("data/interim", recursive = TRUE)
out_file <- "data/interim/series1_5rail_state_fy.csv"
write_csv(out, out_file)
message("\nWrote ", n_rows, " rows to ", out_file)
