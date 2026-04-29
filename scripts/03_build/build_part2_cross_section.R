# scripts/03_build/build_part2_cross_section.R
#
# Build the FY 2024-25 cross-section panel for the policy note's headline
# regression. One row per state/UT (36). Columns: state_canonical,
# state_code, per_capita_upi (12-mo avg Apr 2024 - Mar 2025), and the
# six controls anchored at FY 2024-25 (or latest-available for slow-
# moving variables).
#
# Output: data/processed/part2_cross_section_fy2425.csv
# Run:    Rscript scripts/03_build/build_part2_cross_section.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tidyr); library(lubridate); library(stringr)
})

upi   <- read_csv("data/interim/indiastat_upi_monthly.csv", show_col_types = FALSE)
pop   <- read_csv("data/interim/population_mohfw.csv",     show_col_types = FALSE)
nsdp  <- read_csv("data/interim/per_capita_nsdp.csv",     show_col_types = FALSE)
lit   <- read_csv("data/interim/indiastat_literacy.csv",  show_col_types = FALSE)
trai  <- read_csv("data/interim/trai_internet_panel.csv", show_col_types = FALSE)
urban_anchors <- read_csv("data/interim/mohfw_population_2011_2021.csv", show_col_types = FALSE)
pmjdy_panel <- read_csv("data/interim/pmjdy_state_panel.csv", show_col_types = FALSE) |>
  filter(fy_anchor == "2024-25") |>
  select(state_canonical, pmjdy_total_beneficiaries = total_beneficiaries)
adult_share <- read_csv("data/interim/plfs_adult_share_2023_24.csv", show_col_types = FALSE) |>
  select(state_canonical, adult_share)
rbi_offices <- read_csv("data/interim/rbi_offices_state_panel.csv", show_col_types = FALSE) |>
  filter(snapshot_date == as.Date("2025-03-31")) |>
  select(state_canonical, offices_2025_03 = offices)

source("scripts/01_ingest/_utils_state_names.R")

# Population denominator: mean of (1-Jul-2024 + 1-Jul-2025) populations,
# closer to FY 2024-25 midpoint (Sep-Oct 2024) than either year alone.
pop_denom <- pop |>
  filter(year %in% c(2024, 2025)) |>
  group_by(state_canonical) |>
  summarise(population = mean(population), .groups = "drop")

# DV: average per-capita UPI across the 12 months of FY 2024-25.
fy2425_months <- seq(as.Date("2024-04-01"), as.Date("2025-03-01"), by = "month")
dv <- upi |>
  filter(year_month %in% fy2425_months) |>
  inner_join(pop_denom, by = "state_canonical") |>
  mutate(per_capita_upi_month = upi_volume_million * 1e6 / population) |>
  group_by(state_canonical, state_code, population) |>
  summarise(
    n_months = n(),
    per_capita_upi   = mean(per_capita_upi_month),
    upi_volume_avg_million = mean(upi_volume_million),
    upi_value_avg_crore    = mean(upi_value_crore),
    .groups = "drop"
  )

stopifnot(all(dv$n_months == 12L))

# Controls
nsdp_2425 <- nsdp |> filter(fy == "2024-25", !is.na(per_capita_nsdp_constant_inr)) |>
  select(state_canonical, nsdp_2425 = per_capita_nsdp_constant_inr)
nsdp_2324 <- nsdp |> filter(fy == "2023-24", !is.na(per_capita_nsdp_constant_inr)) |>
  select(state_canonical, nsdp_2324 = per_capita_nsdp_constant_inr)
nsdp_2223 <- nsdp |> filter(fy == "2022-23", !is.na(per_capita_nsdp_constant_inr)) |>
  select(state_canonical, nsdp_2223 = per_capita_nsdp_constant_inr)

lit_2324 <- lit |> filter(fy == "2023-24") |>
  select(state_canonical, literacy = literacy_rate_person_7plus)

internet_2503 <- trai |> filter(year_end == "2025-03") |>
  select(state_canonical, internet_density = internet_density_total)

urban_2024 <- urban_anchors |>
  mutate(s = population_urban / population_total) |>
  select(state_canonical, year, s) |>
  pivot_wider(names_from = year, values_from = s, names_prefix = "y") |>
  mutate(share_urban_raw = y2011 + (2024 - 2011) / (2021 - 2011) * (y2021 - y2011)) |>
  # Cap at 1.0: linear extrapolation from 2011/2021 anchors pushes a few
  # near-100%-urban UTs (Chandigarh, Lakshadweep) marginally above 1.0
  # in 2024. Capping is the mathematically-correct treatment for a
  # share variable; the affected values are <= 1.03 so the cap moves
  # nothing materially.
  mutate(share_urban = pmin(share_urban_raw, 1.0)) |>
  select(state_canonical, share_urban)

# PMJDY per ADULT: cumulative beneficiaries ÷ (population × adult share).
# Adult share from PLFS 2023-24 sample (Jul 23 - Jun 24); states without
# adult share fall back to all-India avg ~0.74.
all_india_adult_share <- weighted.mean(adult_share$adult_share,
                                       w = rep(1, nrow(adult_share)))
pmjdy <- pmjdy_panel |>
  inner_join(dv |> select(state_canonical, population), by = "state_canonical") |>
  left_join(adult_share, by = "state_canonical") |>
  mutate(
    adult_share_used = coalesce(adult_share, all_india_adult_share),
    adult_population = population * adult_share_used,
    pmjdy_per_adult  = pmjdy_total_beneficiaries / adult_population
  ) |>
  select(state_canonical, pmjdy_per_adult)

# Join everything and assemble
panel <- dv |>
  left_join(nsdp_2425, by = "state_canonical") |>
  left_join(nsdp_2324, by = "state_canonical") |>
  left_join(nsdp_2223, by = "state_canonical") |>
  mutate(per_capita_nsdp = coalesce(nsdp_2425, nsdp_2324, nsdp_2223)) |>
  left_join(lit_2324,    by = "state_canonical") |>
  left_join(internet_2503, by = "state_canonical") |>
  left_join(urban_2024,  by = "state_canonical") |>
  left_join(pmjdy,       by = "state_canonical") |>
  left_join(rbi_offices |> select(state_canonical, offices_2025_03),
            by = "state_canonical") |>
  mutate(bank_offices_per_100k = offices_2025_03 / population * 1e5) |>
  select(
    state_canonical, state_code, population,
    upi_volume_avg_million, upi_value_avg_crore, per_capita_upi,
    per_capita_nsdp, literacy, internet_density,
    share_urban, pmjdy_per_adult, bank_offices_per_100k
  ) |>
  arrange(state_canonical)

# Coverage summary
cat("\nFY 2024-25 cross-section panel:\n")
cat(sprintf("  States/UTs: %d\n", nrow(panel)))
cat("\nMissing values per variable:\n")
for (v in c("per_capita_upi", "per_capita_nsdp", "literacy",
            "internet_density", "share_urban", "pmjdy_per_adult",
            "bank_offices_per_100k")) {
  cat(sprintf("  %-20s: %d NA / %d total\n", v,
              sum(is.na(panel[[v]])), nrow(panel)))
}

if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)
out_file <- "data/processed/part2_cross_section_fy2425.csv"
write_csv(panel, out_file)
message("\nWrote ", nrow(panel), " rows × ", ncol(panel), " cols to ", out_file)
