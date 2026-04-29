# scripts/03_build/build_part2_panel.R
#
# Build the Part II 3-year stacked panel for the headline regression.
# 36 states/UTs x 3 12-month windows = 108 state-window observations.
#
# Three rolling windows over the available state-level monthly UPI data
# (April 2023 – January 2026):
#   W1 (year_window = "2023-24"):  Apr 2023 – Mar 2024
#   W2 (year_window = "2024-25"):  Apr 2024 – Mar 2025
#   W3 (year_window = "2025-26r"): Feb 2025 – Jan 2026  (12-mo rolling)
#
# All three windows are exactly 12 months; the third is rolling rather
# than fiscal-year-aligned because Mar 2026 monthly data is not yet
# published. The rolling label is documented and treated identically
# to a fiscal year for analysis purposes.
#
# Estimator (downstream): year-window FE + state-clustered SEs, parallel
# to Part I's 2-FY panel structure for clean Part III comparison.
#
# Output: data/processed/part2_panel_3year.csv
# Run:    Rscript scripts/03_build/build_part2_panel.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tidyr); library(lubridate); library(stringr)
})

upi   <- read_csv("data/interim/indiastat_upi_monthly.csv", show_col_types = FALSE)
pop   <- read_csv("data/interim/population_mohfw.csv",     show_col_types = FALSE)
nsdp  <- read_csv("data/interim/per_capita_nsdp.csv",      show_col_types = FALSE)
lit   <- read_csv("data/interim/indiastat_literacy.csv",   show_col_types = FALSE)
trai  <- read_csv("data/interim/trai_internet_panel.csv",  show_col_types = FALSE)
urban_anchors <- read_csv("data/interim/mohfw_population_2011_2021.csv", show_col_types = FALSE)
rbi_panel   <- read_csv("data/interim/rbi_offices_state_panel.csv", show_col_types = FALSE)
pmjdy_panel <- read_csv("data/interim/pmjdy_state_panel.csv",       show_col_types = FALSE)
adult_share <- read_csv("data/interim/plfs_adult_share_2023_24.csv", show_col_types = FALSE) |>
  select(state_canonical, adult_share)

# ---- Window specification ------------------------------------------------
# Per-window: months range, population reference years (mean of two 1-Jul),
# urban-share interpolation midpoint year, NSDP fy lookup, internet date,
# bank-office date, and PMJDY anchor key.
windows <- tibble::tribble(
  ~year_window, ~month_start,    ~month_end,      ~pop_years,        ~urban_year,
  "2023-24",    as.Date("2023-04-01"), as.Date("2024-03-01"), list(c(2023, 2024)), 2023.5,
  "2024-25",    as.Date("2024-04-01"), as.Date("2025-03-01"), list(c(2024, 2025)), 2024.5,
  "2025-26r",   as.Date("2025-02-01"), as.Date("2026-01-01"), list(c(2025, 2026)), 2025.5
)

window_lookups <- tibble::tribble(
  ~year_window, ~nsdp_fy,    ~internet_date, ~rbi_date,                ~pmjdy_anchor,
  "2023-24",    "2023-24",   "2024-03",      as.Date("2024-03-31"),    "2023-24",
  "2024-25",    "2024-25",   "2025-03",      as.Date("2025-03-31"),    "2024-25",
  "2025-26r",   "2024-25",   "2025-03",      as.Date("2025-12-31"),    "2025-26roll"
  # NSDP for 25-26r falls back to 24-25 (latest available); internet to Mar-25
)

# ---- Population denominator per (state, year_window) ---------------------
pop_by_window <- windows |>
  select(year_window, pop_years) |>
  rowwise() |>
  mutate(yr_pair = list(pop_years[[1]])) |>
  ungroup() |>
  unnest(yr_pair) |>
  rename(year = yr_pair) |>
  inner_join(pop, by = "year", relationship = "many-to-many") |>
  group_by(state_canonical, year_window) |>
  summarise(population = mean(population), .groups = "drop")

# ---- DV: 12-month average per-capita UPI per (state, window) -------------
dv_long <- windows |>
  select(year_window, month_start, month_end) |>
  rowwise() |>
  mutate(months = list(seq(month_start, month_end, by = "month"))) |>
  ungroup() |>
  select(year_window, months) |>
  unnest(months) |>
  rename(year_month = months) |>
  inner_join(upi, by = "year_month") |>
  inner_join(pop_by_window, by = c("state_canonical", "year_window")) |>
  mutate(per_capita_upi_month = upi_volume_million * 1e6 / population) |>
  group_by(state_canonical, state_code, year_window, population) |>
  summarise(
    n_months = n(),
    per_capita_upi   = mean(per_capita_upi_month),
    upi_volume_avg_million = mean(upi_volume_million),
    upi_value_avg_crore    = mean(upi_value_crore),
    .groups = "drop"
  )

stopifnot(all(dv_long$n_months == 12L))

# ---- NSDP at window-specific FY, with cascading fallback -----------------
# Some states delay publication of NSDP "Advance Estimates" so the latest
# FY may have sparse coverage. Fall back to the most-recent prior FY for
# each state to maximise observations. Same convention as the original
# build_part2_cross_section.R.
nsdp_fallback_chain <- list(
  "2023-24"  = c("2023-24", "2022-23", "2021-22"),
  "2024-25"  = c("2024-25", "2023-24", "2022-23"),
  "2025-26r" = c("2024-25", "2023-24", "2022-23")
)

nsdp_for_window <- function(yw) {
  chain <- nsdp_fallback_chain[[yw]]
  d <- nsdp |>
    filter(fy %in% chain, !is.na(per_capita_nsdp_constant_inr)) |>
    mutate(fy_rank = match(fy, chain)) |>
    arrange(state_canonical, fy_rank) |>
    group_by(state_canonical) |>
    slice(1) |>
    ungroup() |>
    select(state_canonical, per_capita_nsdp = per_capita_nsdp_constant_inr)
  d |> mutate(year_window = yw)
}
nsdp_window <- bind_rows(lapply(windows$year_window, nsdp_for_window))

# ---- Literacy: only FY 2023-24 available; carries across windows ---------
lit_2324 <- lit |> filter(fy == "2023-24") |>
  select(state_canonical, literacy = literacy_rate_person_7plus)
lit_window <- bind_rows(lapply(windows$year_window, function(yw) {
  lit_2324 |> mutate(year_window = yw)
}))

# ---- Internet density at window-end snapshot -----------------------------
internet_for_window <- function(yw) {
  d <- window_lookups$internet_date[window_lookups$year_window == yw]
  trai |>
    filter(year_end == d) |>
    select(state_canonical, internet_density = internet_density_total) |>
    mutate(year_window = yw)
}
internet_window <- bind_rows(lapply(windows$year_window, internet_for_window))

# ---- Urban share interpolated to window midpoint -------------------------
urban_anchors_wide <- urban_anchors |>
  mutate(s = population_urban / population_total) |>
  select(state_canonical, year, s) |>
  pivot_wider(names_from = year, values_from = s, names_prefix = "y")

urban_window <- tidyr::crossing(
  urban_anchors_wide,
  windows |> select(year_window, urban_year)
) |>
  mutate(share_urban = pmin(
    y2011 + (urban_year - 2011) / (2021 - 2011) * (y2021 - y2011), 1.0)) |>
  select(state_canonical, year_window, share_urban)

# ---- Bank offices per 100k pop at window-end snapshot --------------------
bank_window <- inner_join(
  rbi_panel |> rename(rbi_date = snapshot_date),
  window_lookups |> select(year_window, rbi_date),
  by = "rbi_date"
) |> select(state_canonical, year_window, offices)

# ---- PMJDY beneficiaries per adult, window-anchored ----------------------
all_india_adult_share <- mean(adult_share$adult_share)
pmjdy_window <- inner_join(
  pmjdy_panel |> rename(pmjdy_anchor = fy_anchor),
  window_lookups |> select(year_window, pmjdy_anchor),
  by = "pmjdy_anchor"
) |>
  inner_join(pop_by_window, by = c("state_canonical", "year_window")) |>
  left_join(adult_share, by = "state_canonical") |>
  mutate(
    adult_share_used = coalesce(adult_share, all_india_adult_share),
    adult_population = population * adult_share_used,
    pmjdy_per_adult  = total_beneficiaries / adult_population
  ) |>
  select(state_canonical, year_window, pmjdy_per_adult)

# ---- Assemble panel ------------------------------------------------------
panel <- dv_long |>
  left_join(nsdp_window,     by = c("state_canonical", "year_window")) |>
  left_join(lit_window,      by = c("state_canonical", "year_window")) |>
  left_join(internet_window, by = c("state_canonical", "year_window")) |>
  left_join(urban_window,    by = c("state_canonical", "year_window")) |>
  left_join(bank_window,     by = c("state_canonical", "year_window")) |>
  left_join(pmjdy_window,    by = c("state_canonical", "year_window")) |>
  mutate(bank_offices_per_100k = offices / population * 1e5) |>
  select(
    state_canonical, state_code, year_window, population,
    upi_volume_avg_million, upi_value_avg_crore, per_capita_upi,
    per_capita_nsdp, literacy, internet_density,
    share_urban, pmjdy_per_adult, bank_offices_per_100k
  ) |>
  arrange(state_canonical, year_window)

cat("\nPart II 3-year stacked panel:\n")
cat(sprintf("  Rows: %d  (expected 108 = 36 states x 3 windows)\n", nrow(panel)))
cat(sprintf("  Unique states: %d\n", length(unique(panel$state_canonical))))
cat(sprintf("  Windows: %s\n", paste(sort(unique(panel$year_window)), collapse = ", ")))

cat("\nMissing values per variable:\n")
for (v in c("per_capita_upi", "per_capita_nsdp", "literacy",
            "internet_density", "share_urban", "pmjdy_per_adult",
            "bank_offices_per_100k")) {
  cat(sprintf("  %-22s: %d NA / %d total\n", v,
              sum(is.na(panel[[v]])), nrow(panel)))
}

if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)
out_file <- "data/processed/part2_panel_3year.csv"
write_csv(panel, out_file)
message("\nWrote ", nrow(panel), " rows x ", ncol(panel), " cols to ", out_file)
