# scripts/04_analyze/part1_headline_regression.R
#
# Part I headline regression: cross-state correlates of per-capita digital
# payment use across FY 2019-20 and FY 2020-21.
# DV: log(per_capita_5rail) — Series 1 5-rail composite per person, annual.
# Estimator: pooled OLS with year fixed effects (absorbs national-level
# growth between the two FYs) and state-clustered standard errors (per
# CLAUDE.md §8). N = 33 states x 2 FYs = 66 obs after dropping the 2
# states with missing NSDP across both FYs (Lakshadweep, DNHDD).
#
# Same control set as Part II's headline EXCLUDING internet density.
# Per the asymmetric-controls decision, Part III's coefficient comparison
# runs only on the 4 shared controls (NSDP, urban share, PMJDY/adult,
# bank offices); literacy is in the appendix in both parts.
#
# Outputs:
#   output/tables/part1_headline_regression.tex
#   output/tables/part1_headline_regression.txt
#
# Run: Rscript scripts/04_analyze/part1_headline_regression.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(modelsummary)
})

panel <- read_csv("data/processed/part1_panel_fy1920_fy2021.csv",
                  show_col_types = FALSE)

reg <- panel |>
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

cat(sprintf("\nRegression sample: N = %d (= %d states x 2 FYs)\n",
            nrow(reg), length(unique(reg$state_canonical))))
cat("Excluded (any NA in regressors): ",
    paste(setdiff(panel$state_canonical, reg$state_canonical), collapse = ", "),
    "\n\n", sep = "")

m1 <- feols(log_dp ~ log_nsdp                                                     | fy,
            data = reg, cluster = ~state_canonical)
m2 <- feols(log_dp ~ log_nsdp + log_urban                                       | fy,
            data = reg, cluster = ~state_canonical)
m3 <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy                           | fy,
            data = reg, cluster = ~state_canonical)
m4 <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches            | fy,
            data = reg, cluster = ~state_canonical)

mods <- list(
  "(1) NSDP only"        = m1,
  "(2) + urban share"    = m2,
  "(3) + PMJDY/adult"    = m3,
  "(4) + bank offices"   = m4
)

coef_map <- c(
  "log_nsdp"     = "log(per-capita NSDP)",
  "log_urban"    = "log(urban share)",
  "log_pmjdy"    = "log(PMJDY beneficiaries / adult)",
  "log_branches" = "log(bank offices / 100k pop)"
)

if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)

modelsummary(
  mods,
  output    = "output/tables/part1_headline_regression.tex",
  coef_map  = coef_map,
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map   = c("nobs", "r.squared", "adj.r.squared", "FE: fy"),
  fmt       = 3,
  title     = "Part I — Cross-state correlates of per-capita 5-rail digital payments, FY 2019-20 + FY 2020-21",
  notes     = paste0(
    "OLS with fiscal-year fixed effects. DV: log of annual per-capita ",
    "5-rail composite transactions (BHIM + IMPS + RuPay POS + UPI + USSD). ",
    "State-clustered standard errors in parentheses (35 clusters, 33 with ",
    "non-missing regressors). Coefficients on log-log terms are ",
    "All variables in logs; coefficients are elasticities. ",
    "Internet density excluded from Part I — see asymmetric-controls ",
    "decision in the data section. Literacy is in the appendix ",
    "(part1_appendix_with_literacy.tex). * p<.10, ** p<.05, *** p<.01."
  )
)

modelsummary(
  mods,
  output   = "output/tables/part1_headline_regression.txt",
  coef_map = coef_map,
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map  = c("nobs", "r.squared", "adj.r.squared", "FE: fy"),
  fmt      = 3
)

cat("\n=== Part I headline (year FE, state-clustered SEs) ===\n")
modelsummary(mods, coef_map = coef_map,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             gof_map = c("nobs", "r.squared", "adj.r.squared", "FE: fy"),
             fmt = 3, output = "markdown") |> print()

message("\nWrote output/tables/part1_headline_regression.{tex,txt}")
