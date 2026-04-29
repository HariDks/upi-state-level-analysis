# scripts/04_analyze/part3_comparison.R
#
# Part III table: cross-era coefficient comparison. Sets the Part I
# headline (4 controls, FY 2019-20 + FY 2020-21) and the Part II headline
# (5 controls, three twelve-month windows, April 2023 - January 2026)
# side by side. The four shared controls (NSDP, urban share, PMJDY/adult,
# bank offices) line up directly. Internet density is in Part II only.
#
# Outputs:
#   output/tables/part3_comparison.tex
#   output/tables/part3_comparison.txt
#
# Run: Rscript scripts/04_analyze/part3_comparison.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(modelsummary)
})

# ---- Part I (early-UPI era, 4 controls) ---------------------------------
panel1 <- read_csv("data/processed/part1_panel_fy1920_fy2021.csv",
                   show_col_types = FALSE) |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban),
         !is.na(pmjdy_per_adult), !is.na(bank_offices_per_100k),
         !is.na(per_capita_5rail)) |>
  mutate(
    log_dp       = log(per_capita_5rail),
    log_nsdp     = log(per_capita_nsdp),
    log_urban    = log(share_urban),
    log_pmjdy    = log(pmjdy_per_adult),
    log_branches = log(bank_offices_per_100k)
  )

m_part1 <- feols(
  log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches | fy,
  data = panel1, cluster = ~state_canonical
)

# ---- Part II (mature-UPI era, 5 controls) -------------------------------
panel2 <- read_csv("data/processed/part2_panel_3year.csv",
                   show_col_types = FALSE) |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban),
         !is.na(internet_density), !is.na(pmjdy_per_adult),
         !is.na(bank_offices_per_100k), !is.na(per_capita_upi)) |>
  mutate(
    log_dp       = log(per_capita_upi),
    log_nsdp     = log(per_capita_nsdp),
    log_internet = log(internet_density),
    log_urban    = log(share_urban),
    log_pmjdy    = log(pmjdy_per_adult),
    log_branches = log(bank_offices_per_100k)
  )

m_part2 <- feols(
  log_dp ~ log_nsdp + log_internet + log_urban + log_pmjdy + log_branches | year_window,
  data = panel2, cluster = ~state_canonical
)

mods <- list(
  "Part I (FY 2019-20 + 2020-21)"     = m_part1,
  "Part II (Apr 2023 - Jan 2026)"     = m_part2
)

# Reorder rows so the shared controls line up first, then the Part II-only
# control (internet) at the bottom.
coef_map <- c(
  "log_nsdp"     = "log(per-capita NSDP)",
  "log_urban"    = "log(urban share)",
  "log_pmjdy"    = "log(PMJDY beneficiaries / adult)",
  "log_branches" = "log(bank offices / 100k pop)",
  "log_internet" = "log(internet subs / 100)"
)

if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)

modelsummary(
  mods,
  output    = "output/tables/part3_comparison.tex",
  coef_map  = coef_map,
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map   = c("nobs", "r.squared", "adj.r.squared"),
  fmt       = 3,
  title     = "Cross-era coefficient comparison: Part I (early-UPI) vs Part II (mature-UPI)",
  notes     = paste0(
    "OLS with year (Part I) / year-window (Part II) fixed effects, ",
    "state-clustered standard errors in parentheses. DV: log of ",
    "per-capita digital-payment transactions. Part I uses the five-rail ",
    "composite (BHIM + IMPS + RuPay POS + UPI + USSD); Part II uses ",
    "pure UPI volume. The four shared controls (NSDP, urban share, ",
    "PMJDY/adult, bank offices) appear in both regressions. Internet ",
    "density is in Part II only because TRAI's pre-2023 service-area ",
    "boundaries do not produce reliable state-level internet penetration ",
    "for the early-UPI era. * p<.10, ** p<.05, *** p<.01."
  )
)

modelsummary(
  mods,
  output   = "output/tables/part3_comparison.txt",
  coef_map = coef_map,
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  fmt      = 3
)

cat("\n=== Part III — cross-era coefficient comparison ===\n")
modelsummary(mods, coef_map = coef_map,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             gof_map = c("nobs", "r.squared", "adj.r.squared"),
             fmt = 3, output = "markdown") |> print()

message("\nWrote output/tables/part3_comparison.{tex,txt}")
