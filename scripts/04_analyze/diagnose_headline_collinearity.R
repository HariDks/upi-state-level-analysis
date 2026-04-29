# scripts/04_analyze/diagnose_headline_collinearity.R
#
# Diagnostic: why does log(literacy) flip strongly negative in the headline
# spec when its univariate correlation with log(per-capita UPI) is positive?
# Three checks:
#   1. Pairwise correlation matrix among the five regressors.
#   2. Variance inflation factors (VIF) for each coefficient.
#   3. Leave-one-out re-fits — drop suspected outlier groups
#      (NE small states, Kerala, both) and see how the literacy elasticity moves.
#
# Output: console report + output/diagnostics/headline_collinearity.txt
#
# Run: Rscript scripts/04_analyze/diagnose_headline_collinearity.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(tibble)
})

panel <- read_csv("data/processed/part2_cross_section_fy2425.csv",
                  show_col_types = FALSE)

reg <- panel |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban),
         !is.na(literacy), !is.na(internet_density),
         !is.na(pmjdy_per_adult), !is.na(bank_offices_per_100k),
         !is.na(per_capita_upi)) |>
  mutate(
    log_upi      = log(per_capita_upi),
    log_nsdp     = log(per_capita_nsdp),
    log_lit      = log(literacy),
    log_internet = log(internet_density),
    log_pmjdy    = log(pmjdy_per_adult),
    log_branches = log(bank_offices_per_100k)
  )

# ---- 1. Correlation matrix among regressors ---------------------------------
X <- reg |> select(log_nsdp, log_lit, log_internet, share_urban,
                   log_pmjdy, log_branches)
cor_mat <- cor(X)

# ---- 2. VIFs ----------------------------------------------------------------
# VIF_j = 1 / (1 - R²_j), where R²_j is from regressing regressor j on the others.
Xdf  <- as.data.frame(X)
vifs <- setNames(numeric(ncol(Xdf)), names(Xdf))
for (j in names(Xdf)) {
  d  <- data.frame(.y = Xdf[[j]], Xdf[, setdiff(names(Xdf), j), drop = FALSE])
  r2 <- summary(lm(.y ~ ., data = d))$r.squared
  vifs[j] <- 1 / (1 - r2)
}

# ---- 3. Leave-one-group-out — full-spec literacy elasticity -----------------
ne_small <- c("Mizoram", "Meghalaya", "Nagaland", "Manipur", "Tripura",
              "Arunachal Pradesh", "Sikkim")
fit_full <- function(d) {
  feols(log_upi ~ log_nsdp + log_lit + log_internet + share_urban +
                  log_pmjdy + log_branches,
        data = d, vcov = "hetero")
}
samples <- list(
  "Full sample (N=33)"            = reg,
  "Drop Kerala"                   = reg |> filter(state_canonical != "Kerala"),
  "Drop 7 NE small states"        = reg |> filter(!state_canonical %in% ne_small),
  "Drop Kerala + 7 NE"            = reg |> filter(state_canonical != "Kerala",
                                                  !state_canonical %in% ne_small),
  "Univariate: literacy only"     = reg
)

extract_lit <- function(name, d) {
  if (name == "Univariate: literacy only") {
    m <- feols(log_upi ~ log_lit, data = d, vcov = "hetero")
  } else {
    m <- fit_full(d)
  }
  cf <- coef(m)["log_lit"]
  se <- sqrt(diag(vcov(m)))["log_lit"]
  tibble(spec = name, n = nobs(m), beta_lit = cf, se_lit = se,
         t = cf / se, p = 2 * pt(-abs(cf / se), df = nobs(m) - length(coef(m))))
}
loo_tbl <- purrr::map2_dfr(names(samples), samples, extract_lit)

# ---- Write report -----------------------------------------------------------
if (!dir.exists("output/diagnostics")) dir.create("output/diagnostics", recursive = TRUE)
sink("output/diagnostics/headline_collinearity.txt", split = TRUE)

cat("=== Headline regression collinearity diagnostic ===\n")
cat(sprintf("Sample: N = %d states/UTs (full regression sample).\n\n", nrow(reg)))

cat("1. Pairwise Pearson correlations among the five regressors:\n")
print(round(cor_mat, 3))
cat("\n  -> Look for |r| > 0.7 between literacy and any other regressor.\n\n")

cat("2. Variance inflation factors:\n")
print(round(vifs, 2))
cat("  Rule of thumb: VIF > 5 = concerning, VIF > 10 = severe collinearity.\n\n")

cat("3. log(literacy) coefficient under leave-one-group-out re-fits:\n")
print(loo_tbl |> mutate(across(c(beta_lit, se_lit, t, p), \(x) round(x, 3))))
cat("\n  Compare full-spec literacy elasticity across rows.\n")
cat("  If it moves substantially when small groups are dropped,\n")
cat("  the headline coefficient is being driven by those observations.\n")

sink()

message("\nWrote output/diagnostics/headline_collinearity.txt")
