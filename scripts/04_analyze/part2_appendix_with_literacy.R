# scripts/04_analyze/part2_appendix_with_literacy.R
#
# Part II appendix: headline spec WITH log(literacy) added back, alongside
# the headline spec WITHOUT literacy and a univariate-literacy column.
# Mirrors Part I's appendix table for the comparative discussion in
# Part III.
#
# Outputs:
#   output/tables/part2_appendix_with_literacy.tex
#   output/tables/part2_appendix_with_literacy.txt
#
# Run: Rscript scripts/04_analyze/part2_appendix_with_literacy.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(modelsummary)
})

panel <- read_csv("data/processed/part2_panel_3year.csv",
                  show_col_types = FALSE)

reg <- panel |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban), !is.na(literacy),
         !is.na(internet_density), !is.na(pmjdy_per_adult),
         !is.na(bank_offices_per_100k), !is.na(per_capita_upi)) |>
  mutate(
    log_upi      = log(per_capita_upi),
    log_nsdp     = log(per_capita_nsdp),
    log_lit      = log(literacy),
    log_internet = log(internet_density),
    log_urban    = log(share_urban),
    log_pmjdy    = log(pmjdy_per_adult),
    log_branches = log(bank_offices_per_100k)
  )

cat(sprintf("\nAppendix sample: N = %d (= %d states x %d windows)\n",
            nrow(reg), length(unique(reg$state_canonical)),
            length(unique(reg$year_window))))

m_headline   <- feols(log_upi ~ log_nsdp + log_internet + log_urban +
                                log_pmjdy + log_branches | year_window,
                      data = reg, cluster = ~state_canonical)
m_with_lit   <- feols(log_upi ~ log_nsdp + log_internet + log_urban +
                                log_pmjdy + log_branches + log_lit | year_window,
                      data = reg, cluster = ~state_canonical)
m_lit_alone  <- feols(log_upi ~ log_lit | year_window,
                      data = reg, cluster = ~state_canonical)

mods <- list(
  "(A1) Univariate: literacy"  = m_lit_alone,
  "(A2) Headline (no lit.)"    = m_headline,
  "(A3) Headline + literacy"   = m_with_lit
)

coef_map <- c(
  "log_nsdp"     = "log(per-capita NSDP)",
  "log_internet" = "log(internet subs / 100)",
  "log_urban"    = "log(urban share)",
  "log_pmjdy"    = "log(PMJDY beneficiaries / adult)",
  "log_branches" = "log(bank offices / 100k pop)",
  "log_lit"      = "log(literacy %)"
)

if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)

modelsummary(
  mods,
  output    = "output/tables/part2_appendix_with_literacy.tex",
  coef_map  = coef_map,
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map   = c("nobs", "r.squared", "adj.r.squared", "FE: year_window"),
  fmt       = 3,
  title     = "Part II literacy specifications (Appendix): univariate, headline, and headline + literacy",
  notes     = paste0(
    "OLS with year-window fixed effects, state-clustered SEs. DV: log of ",
    "monthly UPI per person, 12-month-window average. Column A1 ",
    "regresses log(UPI per cap) on log(literacy) only; A2 is the ",
    "headline five-variable spec from the main Part II table; A3 adds ",
    "log(literacy). Compared with the analogous Part I appendix for ",
    "whether literacy's conditional behaviour differs across the ",
    "early (2019-21) and mature (2024-25) UPI eras. ",
    "* p<.10, ** p<.05, *** p<.01."
  )
)

modelsummary(
  mods,
  output   = "output/tables/part2_appendix_with_literacy.txt",
  coef_map = coef_map,
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map  = c("nobs", "r.squared", "adj.r.squared", "FE: year_window"),
  fmt      = 3
)

cat("\n=== Part II appendix (literacy specifications) ===\n")
modelsummary(mods, coef_map = coef_map,
             stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
             gof_map = c("nobs", "r.squared", "adj.r.squared", "FE: year_window"),
             fmt = 3, output = "markdown") |> print()

message("\nWrote output/tables/part2_appendix_with_literacy.{tex,txt}")
