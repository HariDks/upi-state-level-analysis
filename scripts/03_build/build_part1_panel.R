# scripts/03_build/build_part1_panel.R
#
# Build the Part I panel: 35 states/UTs x 2 fiscal years (2019-20 + 2020-21)
# = 70 state-FY observations. DV is per-capita Series 1 5-rail composite
# transactions (BHIM + IMPS + RuPay POS + UPI + USSD) — see CLAUDE.md §7
# and the Series 1 raw manifest for the definitional rationale.
#
# State count is 35 (not 36) because the Series 1 source reports J&K as
# a single unit; per CLAUDE.md §6 we treat J&K as one unit throughout
# Part I. Ladakh did not exist as a separate UT until Oct 2019; even
# after creation, Series 1 keeps J&K combined.
#
# Same control set as Part II's headline EXCLUDING internet density.
# Per the asymmetric-controls decision: TRAI legacy LSA boundaries pre-
# 2023 combine post-split states (AP+Telangana, Bihar+Jharkhand, etc.)
# making state-level internet density unreliable for Part I. Part III's
# comparison runs only on the 4 shared controls (NSDP, urban share,
# PMJDY/adult, bank offices); literacy is in the appendix for both parts.
#
# Output: data/processed/part1_panel_fy1920_fy2021.csv
# Run:    Rscript scripts/03_build/build_part1_panel.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tidyr); library(lubridate); library(stringr)
})

dv_raw      <- read_csv("data/interim/series1_5rail_state_fy.csv",  show_col_types = FALSE)
pop         <- read_csv("data/interim/population_mohfw.csv",        show_col_types = FALSE)
nsdp        <- read_csv("data/interim/per_capita_nsdp.csv",         show_col_types = FALSE)
lit         <- read_csv("data/interim/indiastat_literacy.csv",      show_col_types = FALSE)
urban_anchors <- read_csv("data/interim/mohfw_population_2011_2021.csv", show_col_types = FALSE)
rbi_panel   <- read_csv("data/interim/rbi_offices_state_panel.csv", show_col_types = FALSE)
pmjdy_panel <- read_csv("data/interim/pmjdy_state_panel.csv",       show_col_types = FALSE)
adult_share <- read_csv("data/interim/plfs_adult_share_2023_24.csv", show_col_types = FALSE) |>
  select(state_canonical, adult_share)

# ---- Population denominator per (state, fy) -------------------------------
# Mid-FY mean of two adjacent 1-July populations, matching the convention
# used in Part II's build (mean of 1-Jul-2024 + 1-Jul-2025 for FY 2024-25).
pop_by_fy <- bind_rows(
  pop |> filter(year %in% c(2019, 2020)) |>
    group_by(state_canonical) |>
    summarise(population = mean(population), .groups = "drop") |>
    mutate(fy = "2019-20"),
  pop |> filter(year %in% c(2020, 2021)) |>
    group_by(state_canonical) |>
    summarise(population = mean(population), .groups = "drop") |>
    mutate(fy = "2020-21")
)

# ---- DV: per-capita 5-rail transactions ----------------------------------
dv <- dv_raw |>
  inner_join(pop_by_fy, by = c("state_canonical", "fy")) |>
  mutate(per_capita_5rail = transactions_total_5rail / population) |>
  select(state_canonical, state_code, fy, population,
         transactions_total_5rail, per_capita_5rail)

# ---- NSDP at FY-specific year --------------------------------------------
nsdp_fy <- nsdp |>
  filter(fy %in% c("2019-20", "2020-21"), !is.na(per_capita_nsdp_constant_inr)) |>
  select(state_canonical, fy, per_capita_nsdp = per_capita_nsdp_constant_inr)

# ---- Literacy at FY-specific year (appendix-only variable) ---------------
lit_fy <- lit |>
  filter(fy %in% c("2019-20", "2020-21")) |>
  select(state_canonical, fy, literacy = literacy_rate_person_7plus)

# ---- Urban share interpolated to FY midpoint -----------------------------
# Linear interp from 2011 and 2021 census anchors, capped at 1.0.
# FY 2019-20 -> 2019.5; FY 2020-21 -> 2020.5.
urban_panel <- urban_anchors |>
  mutate(s = population_urban / population_total) |>
  select(state_canonical, year, s) |>
  pivot_wider(names_from = year, values_from = s, names_prefix = "y") |>
  mutate(
    `2019-20` = pmin(y2011 + (2019.5 - 2011) / (2021 - 2011) * (y2021 - y2011), 1.0),
    `2020-21` = pmin(y2011 + (2020.5 - 2011) / (2021 - 2011) * (y2021 - y2011), 1.0)
  ) |>
  select(state_canonical, `2019-20`, `2020-21`) |>
  pivot_longer(cols = c(`2019-20`, `2020-21`),
               names_to = "fy", values_to = "share_urban")

# ---- Bank offices per 100k pop at end-of-FY ------------------------------
bank_fy <- rbi_panel |>
  filter(snapshot_date %in% as.Date(c("2020-03-31", "2021-03-31"))) |>
  mutate(fy = case_when(snapshot_date == as.Date("2020-03-31") ~ "2019-20",
                        snapshot_date == as.Date("2021-03-31") ~ "2020-21")) |>
  select(state_canonical, fy, offices)

# ---- PMJDY beneficiaries per adult, FY-anchored Wayback snapshot ---------
# Adult share comes from PLFS 2023-24 (the only round we've parsed). The
# 2019-20/2020-21 adult share would have been very similar — India's
# population age structure moves slowly — so this is a small approximation
# documented in the data section.
all_india_adult_share <- mean(adult_share$adult_share)
pmjdy_fy <- pmjdy_panel |>
  filter(fy_anchor %in% c("2019-20", "2020-21")) |>
  rename(fy = fy_anchor) |>
  inner_join(pop_by_fy, by = c("state_canonical", "fy")) |>
  left_join(adult_share, by = "state_canonical") |>
  mutate(
    adult_share_used = coalesce(adult_share, all_india_adult_share),
    adult_population = population * adult_share_used,
    pmjdy_per_adult  = total_beneficiaries / adult_population
  ) |>
  select(state_canonical, fy, pmjdy_per_adult)

# ---- Assemble panel ------------------------------------------------------
panel <- dv |>
  left_join(nsdp_fy,     by = c("state_canonical", "fy")) |>
  left_join(lit_fy,      by = c("state_canonical", "fy")) |>
  left_join(urban_panel, by = c("state_canonical", "fy")) |>
  left_join(bank_fy,     by = c("state_canonical", "fy")) |>
  left_join(pmjdy_fy,    by = c("state_canonical", "fy")) |>
  mutate(bank_offices_per_100k = offices / population * 1e5) |>
  select(
    state_canonical, state_code, fy, population,
    transactions_total_5rail, per_capita_5rail,
    per_capita_nsdp, literacy, share_urban,
    pmjdy_per_adult, bank_offices_per_100k
  ) |>
  arrange(state_canonical, fy)

# ---- Sanity / coverage report --------------------------------------------
cat("\nPart I panel:\n")
cat(sprintf("  Rows: %d  (expected 70 = 35 states x 2 FYs)\n", nrow(panel)))
cat(sprintf("  Unique states: %d\n", length(unique(panel$state_canonical))))
cat(sprintf("  FYs: %s\n", paste(sort(unique(panel$fy)), collapse = ", ")))

cat("\nMissing values per variable:\n")
for (v in c("per_capita_5rail", "per_capita_nsdp", "literacy",
            "share_urban", "pmjdy_per_adult", "bank_offices_per_100k")) {
  cat(sprintf("  %-22s: %d NA / %d total\n", v,
              sum(is.na(panel[[v]])), nrow(panel)))
}

if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)
out_file <- "data/processed/part1_panel_fy1920_fy2021.csv"
write_csv(panel, out_file)
message("\nWrote ", nrow(panel), " rows x ", ncol(panel), " cols to ", out_file)
