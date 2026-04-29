# scripts/04_analyze/part2_headline_regression.R
#
# Part II headline regression: cross-state correlates of per-capita UPI
# use across three 12-month windows (Apr 2023 – Mar 2024, Apr 2024 –
# Mar 2025, Feb 2025 – Jan 2026 rolling). Five-control headline:
# log(NSDP), log(internet density), share_urban, log(PMJDY/adult),
# log(bank offices/100k pop). Literacy is in the appendix.
#
# Estimator: pooled OLS with year-window fixed effects (absorb common
# UPI growth between windows) and state-clustered standard errors
# (CLAUDE.md §8 convention). N = 33 states x 3 windows = 99 obs after
# dropping the 3 states with persistent missing NSDP/urban (Lakshadweep,
# DNHDD, Ladakh).
#
# Outputs:
#   output/tables/part2_headline_regression.tex
#   output/tables/part2_headline_regression.txt
#
# Run: Rscript scripts/04_analyze/part2_headline_regression.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(modelsummary)
})

panel <- read_csv("data/processed/part2_panel_3year.csv",
                  show_col_types = FALSE)

reg <- panel |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban),
         !is.na(internet_density), !is.na(pmjdy_per_adult),
         !is.na(bank_offices_per_100k), !is.na(per_capita_upi)) |>
  mutate(
    log_upi      = log(per_capita_upi),
    log_nsdp     = log(per_capita_nsdp),
    log_internet = log(internet_density),
    log_urban    = log(share_urban),
    log_pmjdy    = log(pmjdy_per_adult),
    log_branches = log(bank_offices_per_100k)
  )

cat(sprintf("\nRegression sample: N = %d (= %d states x %d windows)\n",
            nrow(reg), length(unique(reg$state_canonical)),
            length(unique(reg$year_window))))
cat("Excluded: ",
    paste(setdiff(panel$state_canonical, reg$state_canonical), collapse = ", "),
    "\n\n", sep = "")

m1 <- feols(log_upi ~ log_nsdp                                                    | year_window,
            data = reg, cluster = ~state_canonical)
m2 <- feols(log_upi ~ log_nsdp + log_internet                                     | year_window,
            data = reg, cluster = ~state_canonical)
m3 <- feols(log_upi ~ log_nsdp + log_internet + log_urban                       | year_window,
            data = reg, cluster = ~state_canonical)
m4 <- feols(log_upi ~ log_nsdp + log_internet + log_urban + log_pmjdy           | year_window,
            data = reg, cluster = ~state_canonical)
m5 <- feols(log_upi ~ log_nsdp + log_internet + log_urban + log_pmjdy + log_branches | year_window,
            data = reg, cluster = ~state_canonical)

mods <- list(
  "(1) NSDP only"        = m1,
  "(2) + internet"       = m2,
  "(3) + urban share"    = m3,
  "(4) + PMJDY/adult"    = m4,
  "(5) + bank offices"   = m5
)

coef_map <- c(
  "log_nsdp"     = "log(per-capita NSDP)",
  "log_internet" = "log(internet subs / 100)",
  "log_urban"    = "log(urban share)",
  "log_pmjdy"    = "log(PMJDY beneficiaries / adult)",
  "log_branches" = "log(bank offices / 100k pop)"
)

if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)

modelsummary(
  mods,
  output    = "output/tables/part2_headline_regression.tex",
  coef_map  = coef_map,
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map   = c("nobs", "r.squared", "adj.r.squared", "FE: year_window"),
  fmt       = 3,
  title     = "Part II — Cross-state correlates of per-capita UPI use, 3-year stacked panel (Apr 2023 – Jan 2026)",
  notes     = paste0(
    "OLS with year-window fixed effects. DV: log of monthly UPI per ",
    "person, averaged within each 12-month window (W1: Apr 2023 – Mar ",
    "2024; W2: Apr 2024 – Mar 2025; W3: Feb 2025 – Jan 2026 rolling). ",
    "State-clustered standard errors in parentheses (33 clusters). ",
    "All variables in logs; coefficients are elasticities. ",
    "Literacy is in the appendix ",
    "(part2_appendix_with_literacy.tex). * p<.10, ** p<.05, *** p<.01."
  )
)

modelsummary(
  mods,
  output   = "output/tables/part2_headline_regression.txt",
  coef_map = coef_map,
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map  = c("nobs", "r.squared", "adj.r.squared", "FE: year_window"),
  fmt      = 3
)

cat("\n=== Part II headline (year-window FE, state-clustered SEs) ===\n")
modelsummary(mods, coef_map = coef_map,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             gof_map = c("nobs", "r.squared", "adj.r.squared", "FE: year_window"),
             fmt = 3, output = "markdown") |> print()

message("\nWrote output/tables/part2_headline_regression.{tex,txt}")
