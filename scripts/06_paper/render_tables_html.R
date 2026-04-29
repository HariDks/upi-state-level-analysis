# scripts/06_paper/render_tables_html.R
#
# Re-render every paper table as a markdown fragment for the combined
# HTML preview. Markdown is the most reliable format for inline embedding
# in pandoc — modelsummary's HTML output ships its own DOCTYPE/script
# wrapper that pandoc does not place cleanly inside another document.

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(fixest); library(modelsummary)
  library(tibble); library(knitr)
})

if (!dir.exists("output/tables/md")) dir.create("output/tables/md", recursive = TRUE)

# ---- Tab 1: descriptive statistics ---------------------------------------
panel_p2 <- read_csv("data/processed/part2_panel_3year.csv", show_col_types = FALSE) |>
  filter(year_window == "2025-26r")

var_spec <- tribble(
  ~var,                     ~label,                                                                  ~unit,             ~decimals, ~scale,
  "per_capita_upi",         "Per-capita UPI transactions (Feb 2025 – Jan 2026 avg)",                 "per person/month", 1,         1,
  "per_capita_nsdp",        "Per-capita NSDP (latest available, constant 2011-12 prices)",           "INR",              0,         1,
  "internet_density",       "Internet subscribers (31-Mar-2025, latest TRAI release)",               "per 100 persons",  1,         1,
  "share_urban",            "Urban population share (interpolated to 2025)",                         "%",                1,         100,
  "pmjdy_per_adult",        "PMJDY beneficiaries per adult (snapshot 13-Dec-2025)",                  "accounts / adult", 2,         1,
  "bank_offices_per_100k",  "Bank offices per 100,000 population (31-Dec-2025)",                     "per 100k pop",     1,         1,
  "literacy",               "Literacy rate, persons 7+ (FY 2023-24, appendix only)",                 "%",                1,         1
)

pop <- panel_p2$population
summarise_one <- function(var, label, unit, decimals, scale) {
  x <- panel_p2[[var]] * scale; ok <- !is.na(x)
  fmt <- function(z) formatC(z, digits = decimals, format = "f", big.mark = ",")
  india <- weighted.mean(x[ok], w = pop[ok])
  tibble(Variable = label, Unit = unit, N = as.integer(sum(ok)),
         Mean = fmt(mean(x[ok])), SD = fmt(sd(x[ok])),
         Min = fmt(min(x[ok])), Max = fmt(max(x[ok])),
         `India (pop-wt.)` = fmt(india))
}
tab1 <- purrr::pmap_dfr(var_spec, summarise_one)
writeLines(kable(tab1, format = "pipe"), "output/tables/md/tab1_descriptive.md")

# ---- Helper: render a list of fixest models as a markdown table ----------
render_md <- function(mods, coef_map, out_path, gof_map) {
  modelsummary(
    mods, output = out_path, coef_map = coef_map,
    stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
    gof_map = gof_map, fmt = 3
  )
}

# ---- Part I headline ------------------------------------------------------
panel1 <- read_csv("data/processed/part1_panel_fy1920_fy2021.csv", show_col_types = FALSE) |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban),
         !is.na(pmjdy_per_adult), !is.na(bank_offices_per_100k),
         !is.na(per_capita_5rail)) |>
  mutate(log_dp = log(per_capita_5rail), log_nsdp = log(per_capita_nsdp),
         log_urban = log(share_urban), log_pmjdy = log(pmjdy_per_adult),
         log_branches = log(bank_offices_per_100k))

p1_m1 <- feols(log_dp ~ log_nsdp                                              | fy, data = panel1, cluster = ~state_canonical)
p1_m2 <- feols(log_dp ~ log_nsdp + log_urban                                  | fy, data = panel1, cluster = ~state_canonical)
p1_m3 <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy                      | fy, data = panel1, cluster = ~state_canonical)
p1_m4 <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches       | fy, data = panel1, cluster = ~state_canonical)

cm_p1 <- c("log_nsdp" = "log(per-capita NSDP)",
           "log_urban" = "log(urban share)",
           "log_pmjdy" = "log(PMJDY beneficiaries / adult)",
           "log_branches" = "log(bank offices / 100k pop)")

render_md(list("(1) NSDP only" = p1_m1, "(2) + urban share" = p1_m2,
               "(3) + PMJDY/adult" = p1_m3, "(4) + bank offices" = p1_m4),
          cm_p1, "output/tables/md/part1_headline.md",
          c("nobs", "r.squared", "adj.r.squared", "FE: fy"))

# ---- Part II headline -----------------------------------------------------
panel2 <- read_csv("data/processed/part2_panel_3year.csv", show_col_types = FALSE) |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban),
         !is.na(internet_density), !is.na(pmjdy_per_adult),
         !is.na(bank_offices_per_100k), !is.na(per_capita_upi)) |>
  mutate(log_upi = log(per_capita_upi), log_nsdp = log(per_capita_nsdp),
         log_internet = log(internet_density), log_urban = log(share_urban),
         log_pmjdy = log(pmjdy_per_adult), log_branches = log(bank_offices_per_100k))

p2_m1 <- feols(log_upi ~ log_nsdp                                                              | year_window, data = panel2, cluster = ~state_canonical)
p2_m2 <- feols(log_upi ~ log_nsdp + log_internet                                               | year_window, data = panel2, cluster = ~state_canonical)
p2_m3 <- feols(log_upi ~ log_nsdp + log_internet + log_urban                                   | year_window, data = panel2, cluster = ~state_canonical)
p2_m4 <- feols(log_upi ~ log_nsdp + log_internet + log_urban + log_pmjdy                       | year_window, data = panel2, cluster = ~state_canonical)
p2_m5 <- feols(log_upi ~ log_nsdp + log_internet + log_urban + log_pmjdy + log_branches        | year_window, data = panel2, cluster = ~state_canonical)

cm_p2 <- c("log_nsdp" = "log(per-capita NSDP)",
           "log_internet" = "log(internet subs / 100)",
           "log_urban" = "log(urban share)",
           "log_pmjdy" = "log(PMJDY beneficiaries / adult)",
           "log_branches" = "log(bank offices / 100k pop)")

render_md(list("(1) NSDP only" = p2_m1, "(2) + internet" = p2_m2,
               "(3) + urban share" = p2_m3, "(4) + PMJDY/adult" = p2_m4,
               "(5) + bank offices" = p2_m5),
          cm_p2, "output/tables/md/part2_headline.md",
          c("nobs", "r.squared", "adj.r.squared", "FE: year_window"))

# ---- Part III: cross-era comparison --------------------------------------
m_p1 <- p1_m4
m_p2 <- p2_m5

cm_p3 <- c("log_nsdp" = "log(per-capita NSDP)",
           "log_urban" = "log(urban share)",
           "log_pmjdy" = "log(PMJDY beneficiaries / adult)",
           "log_branches" = "log(bank offices / 100k pop)",
           "log_internet" = "log(internet subs / 100)")

render_md(list("Part I (FY 2019-20 + 2020-21)" = m_p1,
               "Part II (Apr 2023 - Jan 2026)" = m_p2),
          cm_p3, "output/tables/md/part3_comparison.md",
          c("nobs", "r.squared", "adj.r.squared"))

# ---- Appendix A: Part I with literacy ------------------------------------
panel1_lit <- read_csv("data/processed/part1_panel_fy1920_fy2021.csv", show_col_types = FALSE) |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban), !is.na(literacy),
         !is.na(pmjdy_per_adult), !is.na(bank_offices_per_100k),
         !is.na(per_capita_5rail)) |>
  mutate(log_dp = log(per_capita_5rail), log_nsdp = log(per_capita_nsdp),
         log_urban = log(share_urban), log_lit = log(literacy),
         log_pmjdy = log(pmjdy_per_adult), log_branches = log(bank_offices_per_100k))

a1_head <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches            | fy, data = panel1_lit, cluster = ~state_canonical)
a1_lit  <- feols(log_dp ~ log_nsdp + log_urban + log_pmjdy + log_branches + log_lit  | fy, data = panel1_lit, cluster = ~state_canonical)
a1_uni  <- feols(log_dp ~ log_lit                                                    | fy, data = panel1_lit, cluster = ~state_canonical)

cm_a <- c("log_nsdp" = "log(per-capita NSDP)",
          "log_urban" = "log(urban share)",
          "log_pmjdy" = "log(PMJDY beneficiaries / adult)",
          "log_branches" = "log(bank offices / 100k pop)",
          "log_lit" = "log(literacy %)")

render_md(list("(A1) Univariate: literacy" = a1_uni,
               "(A2) Headline (no lit.)"   = a1_head,
               "(A3) Headline + literacy"  = a1_lit),
          cm_a, "output/tables/md/part1_appendix_with_literacy.md",
          c("nobs", "r.squared", "adj.r.squared", "FE: fy"))

# ---- Appendix A: Part II with literacy -----------------------------------
panel2_lit <- read_csv("data/processed/part2_panel_3year.csv", show_col_types = FALSE) |>
  filter(!is.na(per_capita_nsdp), !is.na(share_urban), !is.na(literacy),
         !is.na(internet_density), !is.na(pmjdy_per_adult),
         !is.na(bank_offices_per_100k), !is.na(per_capita_upi)) |>
  mutate(log_upi = log(per_capita_upi), log_nsdp = log(per_capita_nsdp),
         log_internet = log(internet_density), log_urban = log(share_urban),
         log_lit = log(literacy), log_pmjdy = log(pmjdy_per_adult),
         log_branches = log(bank_offices_per_100k))

a2_head <- feols(log_upi ~ log_nsdp + log_internet + log_urban + log_pmjdy + log_branches            | year_window, data = panel2_lit, cluster = ~state_canonical)
a2_lit  <- feols(log_upi ~ log_nsdp + log_internet + log_urban + log_pmjdy + log_branches + log_lit  | year_window, data = panel2_lit, cluster = ~state_canonical)
a2_uni  <- feols(log_upi ~ log_lit                                                                   | year_window, data = panel2_lit, cluster = ~state_canonical)

cm_a2 <- c("log_nsdp" = "log(per-capita NSDP)",
           "log_internet" = "log(internet subs / 100)",
           "log_urban" = "log(urban share)",
           "log_pmjdy" = "log(PMJDY beneficiaries / adult)",
           "log_branches" = "log(bank offices / 100k pop)",
           "log_lit" = "log(literacy %)")

render_md(list("(A1) Univariate: literacy" = a2_uni,
               "(A2) Headline (no lit.)"   = a2_head,
               "(A3) Headline + literacy"  = a2_lit),
          cm_a2, "output/tables/md/part2_appendix_with_literacy.md",
          c("nobs", "r.squared", "adj.r.squared", "FE: year_window"))

message("Wrote 6 markdown table fragments to output/tables/md/")
