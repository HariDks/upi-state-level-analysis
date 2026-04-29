# scripts/05_tables_figures/fig5_pmjdy_vs_upi.R
#
# Figure 5 (paper): Banking access vs digital payments use — PMJDY total
# beneficiaries per capita (April 2026 snapshot) vs per-capita UPI
# transactions (January 2026). Each point a state; fitted line; correlation.
# Tests whether states with broader bank-account access also see higher
# digital payment usage. Note: PMJDY is a CUMULATIVE total since 2014;
# more accurately measures "banking infrastructure built up by 2026"
# rather than "new accounts opened in 2026."
#
# Run: Rscript scripts/05_tables_figures/fig5_pmjdy_vs_upi.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(scales)
  library(lubridate); library(stringr)
})

panel <- read_csv("data/processed/part2_panel_3year.csv",
                  show_col_types = FALSE) |>
  filter(year_window == "2025-26r") |>
  filter(!is.na(pmjdy_per_adult), !is.na(per_capita_upi))

r <- cor(log(panel$pmjdy_per_adult), log(panel$per_capita_upi))

# Highlight outliers — top and bottom by per-capita UPI, plus any states
# very off the fitted line
top_bot <- panel |> arrange(desc(per_capita_upi)) |>
  slice(c(1:3, (n() - 2):n())) |> pull(state_canonical)

p <- ggplot(panel, aes(pmjdy_per_adult, per_capita_upi)) +
  geom_smooth(method = "lm", se = TRUE, formula = y ~ x,
              colour = "#1f77b4", fill = "#1f77b4", alpha = 0.18,
              linewidth = 0.5) +
  geom_point(size = 2.2, alpha = 0.6, colour = "grey40") +
  geom_point(data = panel |> filter(state_canonical %in% top_bot),
             size = 2.6, colour = "#B2182B") +
  geom_text(data = panel |> filter(state_canonical %in% top_bot),
            aes(label = state_canonical),
            colour = "#B2182B", size = 2.9, hjust = -0.12, vjust = 0.4) +
  annotate("text", x = max(panel$pmjdy_per_adult), y = max(panel$per_capita_upi),
           label = sprintf("Pearson r (log-log) = %+.2f", r),
           hjust = 1.0, vjust = 1.5, size = 3.2, colour = "grey25",
           fontface = "plain") +
  scale_x_log10(labels = label_comma(accuracy = 0.01)) +
  scale_y_log10(labels = label_comma()) +
  labs(
    title    = "PMJDY targeting reach vs. digital payments use, by state",
    subtitle = "PMJDY beneficiaries per adult (snapshot 13-Dec-2025, cumulative since 2014) vs. monthly UPI per capita (Feb 2025 – Jan 2026 average). 36 states/UTs; both axes log.",
    x = "PMJDY beneficiaries per adult (cumulative since 2014)",
    y = "Monthly UPI per capita (Feb 2025 – Jan 2026 avg)",
    caption = paste(
      "Source: PMJDY portal (https://pmjdy.gov.in/statewise-statistics) via Wayback Machine snapshot 13-Dec-2025;",
      "Indiastat NPCI state-wise UPI (Feb 2025 - Jan 2026 monthly); MoHFW population mid-period;",
      "Adult share derived from PLFS 2023-24 Table 1 sample composition (Jul 2023 - Jun 2024).",
      "Author's calculations. PMJDY beneficiary totals are cumulative since the scheme's 2014 launch.",
      "Correlation is descriptive, not causal.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(size = 10),
    plot.caption     = element_text(size = 8, colour = "grey40", hjust = 0,
                                    margin = margin(t = 10)),
    plot.caption.position = "plot",
    panel.grid.minor = element_blank()
  )

ggsave("output/figures/fig5_pmjdy_vs_upi.pdf", p, width = 9, height = 6)
ggsave("output/figures/fig5_pmjdy_vs_upi.png", p, width = 9, height = 6, dpi = 150)
message("Wrote output/figures/fig5_pmjdy_vs_upi.{pdf,png}")
message(sprintf("Pearson r (log-log) = %+.3f", r))
