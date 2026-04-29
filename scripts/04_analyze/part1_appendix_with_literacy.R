# scripts/04_analyze/part1_appendix_with_literacy.R
#
# Part I appendix: headline spec WITH log(literacy) added back, alongside
# the headline spec WITHOUT literacy and a univariate-literacy column.
# Mirrors Part II's appendix table for the comparative discussion in
# Part III: does literacy behave differently in the early (2019-21) era
# than in the mature (2024-25) era? In Part II the conditional literacy
# elasticity was strongly negative (~-2.5) with no univariate basis,
# diagnosed as a measurement-validity problem.
#
# Outputs:
#   output/tables/part1_appendix_with_literacy.tex
#   output/tables/part1_appendix_with_literacy.txt
#
# Run: Rscript scripts/04_analyze/part1_appendix_with_literacy.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(modelsummary)
})

panel <- read_csv("data/processed/part1_panel_fy1920_fy2021.csv",
                  show_col_types = FALSE)

reg <- panel |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban), !is.na(literacy),
         !is.na(pmjdy_per_adult), !is.na(bank_offices_per_100k),
         !is.na(per_capita_5rail)) |>
  mutate(
    log_dp       = log(per_capita_5rail),
    log_nsdp     = log(per_capita_nsdp),
    log_urban    = log(share_urban),
    log_lit      = log(literacy),
    log_pmjdy    = log(pmjdy_per_adult),
    log_branches = log(bank_offices_per_100k)
  )

cat(sprintf("\nAppendix sample: N = %d states x 2 FYs = %d obs\n",
            length(unique(reg$state_canonical)), nrow(reg)))

m_headline   <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches | fy,
                      data = reg, cluster = ~state_canonical)
m_with_lit   <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches + log_lit | fy,
                      data = reg, cluster = ~state_canonical)
m_lit_alone  <- feols(log_dp ~ log_lit | fy,
                      data = reg, cluster = ~state_canonical)

mods <- list(
  "(A1) Univariate: literacy"  = m_lit_alone,
  "(A2) Headline (no lit.)"    = m_headline,
  "(A3) Headline + literacy"   = m_with_lit
)

coef_map <- c(
  "log_nsdp"     = "log(per-capita NSDP)",
  "log_urban"    = "log(urban share)",
  "log_pmjdy"    = "log(PMJDY beneficiaries / adult)",
  "log_branches" = "log(bank offices / 100k pop)",
  "log_lit"      = "log(literacy %)"
)

if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)

modelsummary(
  mods,
  output    = "output/tables/part1_appendix_with_literacy.tex",
  coef_map  = coef_map,
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map   = c("nobs", "r.squared", "adj.r.squared", "FE: fy"),
  fmt       = 3,
  title     = "Part I literacy specifications (Appendix): univariate, headline, and headline + literacy",
  notes     = paste0(
    "OLS with year fixed effects, state-clustered SEs. DV: log of annual ",
    "per-capita 5-rail composite transactions, FY 2019-20 + FY 2020-21. ",
    "Column A1 regresses log(DP per cap) on log(literacy) only; A2 is ",
    "the headline four-variable spec from the main Part I table; A3 ",
    "adds log(literacy). Compared with the analogous Part II appendix ",
    "table for whether literacy's conditional behaviour differs between ",
    "the early (2019-21) and mature (2024-25) UPI eras. ",
    "* p<.10, ** p<.05, *** p<.01."
  )
)

modelsummary(
  mods,
  output   = "output/tables/part1_appendix_with_literacy.txt",
  coef_map = coef_map,
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map  = c("nobs", "r.squared", "adj.r.squared", "FE: fy"),
  fmt      = 3
)

cat("\n=== Part I appendix (literacy specifications) ===\n")
modelsummary(mods, coef_map = coef_map,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             gof_map = c("nobs", "r.squared", "adj.r.squared", "FE: fy"),
             fmt = 3, output = "markdown") |> print()

message("\nWrote output/tables/part1_appendix_with_literacy.{tex,txt}")
