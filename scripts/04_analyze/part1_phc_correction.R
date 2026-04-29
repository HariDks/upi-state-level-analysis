# scripts/04_analyze/part1_phc_correction.R
#
# Purpose: Headline Part I regression — the §9 PHC correction. Two
#          specifications side-by-side:
#            Spec A (replicates the original-thesis puzzle):
#              ln(per_capita_dp) ~ ln(phc_per_sqkm) + ln(literacy)
#                                 + ln(per_capita_nsdp) | state + year
#            Spec B (the §9 correction):
#              + share_urban + ln(population_density)
#          Expectation: the negative PHC coefficient in Spec A attenuates
#          or flips when share_urban + log(pop_density) are added in
#          Spec B, because the original effect was mostly absorbing
#          rurality. Per CLAUDE.md §7a, log-log throughout; per §8,
#          state + year fixed effects with state-clustered SEs.
# Inputs:  data/processed/part1_panel.csv
# Outputs: output/tables/part1_phc_correction.txt   (text summary)
#          output/tables/part1_phc_correction.tex   (LaTeX, modelsummary)
# Run:     Rscript scripts/04_analyze/part1_phc_correction.R (from project root).

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(fixest); library(modelsummary); library(dplyr); library(readr)
})

panel <- readr::read_csv("data/processed/part1_panel.csv",
                         show_col_types = FALSE) |>
  dplyr::mutate(
    log_pcd       = log(per_capita_dp),
    log_phc_per_sqkm   = log(phc_per_sqkm),
    log_literacy  = log(literacy_rate),
    log_nsdp      = log(per_capita_nsdp),
    log_pop_density = log(population_density)
  )

stopifnot(all(is.finite(panel$log_pcd)),
          all(is.finite(panel$log_phc_per_sqkm)),
          all(is.finite(panel$log_nsdp)),
          all(is.finite(panel$log_pop_density)),
          all(is.finite(panel$share_urban)))

# Literacy may be NA for the 7 South-India states' FY 2019-20 row because
# the corresponding Indiastat regional file was rural-only scope and was
# skipped by the literacy parser. feols will drop those rows automatically.
n_lit_na <- sum(!is.finite(panel$log_literacy))
if (n_lit_na > 0) {
  cat(sprintf("\nNote: %d rows have NA literacy and will be dropped from the regression.\n",
              n_lit_na))
  cat("These are the FY 2019-20 rows for: ",
      paste(panel$state_canonical[!is.finite(panel$log_literacy)],
            collapse = ", "), "\n", sep = "")
}

spec_a <- fixest::feols(
  log_pcd ~ log_phc_per_sqkm + log_literacy + log_nsdp | state_canonical + fy,
  data    = panel,
  cluster = ~ state_canonical
)

spec_b <- fixest::feols(
  log_pcd ~ log_phc_per_sqkm + log_literacy + log_nsdp +
            share_urban + log_pop_density | state_canonical + fy,
  data    = panel,
  cluster = ~ state_canonical
)

# Console summary — side-by-side coefficient table.
cat("\n", strrep("=", 78), "\n", sep = "")
cat("Part I — §9 PHC correction (state + FY FE; state-clustered SEs)\n")
cat(strrep("=", 78), "\n\n", sep = "")
cat("Sample: ", nobs(spec_a), " state-FY observations (",
    length(unique(panel$state_canonical)), " states × ",
    length(unique(panel$fy)), " FYs)\n\n", sep = "")

print(modelsummary::msummary(
  list("Spec A (puzzle)" = spec_a, "Spec B (§9 correction)" = spec_b),
  output    = "markdown",
  stars     = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_omit  = "AIC|BIC|Log.Lik|RMSE|Std.Errors",
  fmt       = 3,
  notes     = c("State-clustered standard errors in parentheses.",
                "Wild cluster bootstrap p-values pending fwildclusterboot install.",
                "30 states × FY 2019-20 + FY 2020-21 = 60 obs.")
))

# File outputs.
if (!dir.exists("output/tables")) dir.create("output/tables", recursive = TRUE)

modelsummary::msummary(
  list("Spec A (puzzle)" = spec_a, "Spec B (§9 correction)" = spec_b),
  output   = "output/tables/part1_phc_correction.tex",
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_omit = "AIC|BIC|Log.Lik|RMSE|Std.Errors",
  fmt      = 3
)
sink("output/tables/part1_phc_correction.txt")
cat("Part I — §9 PHC correction\n")
cat("State + FY FE, state-clustered SEs. Sample = 30 states × 2 FYs = 60 obs.\n\n")
cat("=== Spec A (replicates the original-thesis puzzle) ===\n")
print(summary(spec_a))
cat("\n\n=== Spec B (the §9 correction: + share_urban + log_pop_density) ===\n")
print(summary(spec_b))
sink()

cat("\n\nWrote output/tables/part1_phc_correction.{tex,txt}\n")

# Headline message — what changed?
co_a <- coef(spec_a)["log_phc_per_sqkm"]
co_b <- coef(spec_b)["log_phc_per_sqkm"]
se_a <- sqrt(diag(vcov(spec_a)))["log_phc_per_sqkm"]
se_b <- sqrt(diag(vcov(spec_b)))["log_phc_per_sqkm"]
cat("\n", strrep("-", 78), "\n", sep = "")
cat("§9 CORRECTION HEADLINE — log(PHCs per sq km) coefficient:\n")
cat(sprintf("  Spec A (puzzle):       %+.3f  (SE %.3f, t=%.2f)\n",
            co_a, se_a, co_a / se_a))
cat(sprintf("  Spec B (correction):   %+.3f  (SE %.3f, t=%.2f)\n",
            co_b, se_b, co_b / se_b))
cat(sprintf("  Change:                %+.3f  (%s)\n",
            co_b - co_a,
            if (sign(co_a) != sign(co_b)) "FLIPPED SIGN"
            else if (abs(co_b) < abs(co_a)) "attenuated"
            else "amplified — investigate"))
cat(strrep("-", 78), "\n", sep = "")
