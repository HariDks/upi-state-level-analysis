# scripts/05_tables_figures/fig6_bank_offices_vs_upi.R
#
# Figure 6 (paper): Bank-office density vs digital payments use.
# RBI "Functioning Offices" of scheduled commercial banks per 100,000
# population (snapshot 31-Mar-2025) vs per-capita UPI transactions
# (FY 2024-25 average). Counterpart to fig5 (PMJDY): one variable
# captures account-creation reach, the other physical-rail density.
# Both are financial-inclusion proxies; the regression in
# part2_headline_regression.R shows PMJDY adds explanatory power
# beyond income while bank-office density does not.
#
# Run: Rscript scripts/05_tables_figures/fig6_bank_offices_vs_upi.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(scales)
  library(lubridate); library(stringr)
})

panel <- read_csv("data/processed/part2_panel_3year.csv",
                  show_col_types = FALSE) |>
  filter(year_window == "2025-26r") |>
  filter(!is.na(bank_offices_per_100k), !is.na(per_capita_upi))

r <- cor(log(panel$bank_offices_per_100k), log(panel$per_capita_upi))

top_bot <- panel |> arrange(desc(per_capita_upi)) |>
  slice(c(1:3, (n() - 2):n())) |> pull(state_canonical)

p <- ggplot(panel, aes(bank_offices_per_100k, per_capita_upi)) +
  geom_smooth(method = "lm", se = TRUE, formula = y ~ x,
              colour = "#1f77b4", fill = "#1f77b4", alpha = 0.18,
              linewidth = 0.5) +
  geom_point(size = 2.2, alpha = 0.6, colour = "grey40") +
  geom_point(data = panel |> filter(state_canonical %in% top_bot),
             size = 2.6, colour = "#B2182B") +
  geom_text(data = panel |> filter(state_canonical %in% top_bot),
            aes(label = state_canonical),
            colour = "#B2182B", size = 2.9, hjust = -0.12, vjust = 0.4) +
  annotate("text",
           x = max(panel$bank_offices_per_100k),
           y = max(panel$per_capita_upi),
           label = sprintf("Pearson r (log-log) = %+.2f", r),
           hjust = 1.0, vjust = 1.5, size = 3.2, colour = "grey25",
           fontface = "plain") +
  scale_x_log10(labels = label_comma(accuracy = 1)) +
  scale_y_log10(labels = label_comma()) +
  labs(
    title    = "Bank-office density vs. digital payments use, by state",
    subtitle = paste0("RBI scheduled-commercial-bank offices per 100,000 ",
                      "population (snapshot 31-Dec-2025) vs. monthly UPI ",
                      "per capita (Feb 2025 – Jan 2026 average). 36 states/UTs; both axes log."),
    x = "Bank offices per 100,000 population",
    y = "Monthly UPI per capita (Feb 2025 – Jan 2026 avg)",
    caption = paste(
      "Source: RBI Database on Indian Economy, Other STRBI Table 13 ",
      "(State-wise Number of Functioning Offices of Commercial Banks, 31-Dec-2025);",
      "Indiastat NPCI state-wise UPI (Feb 2025 - Jan 2026 monthly);",
      "MoHFW population mid-period.",
      "Author's calculations. Correlation is descriptive, not causal.",
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

ggsave("output/figures/fig6_bank_offices_vs_upi.pdf", p, width = 9, height = 6)
ggsave("output/figures/fig6_bank_offices_vs_upi.png", p, width = 9, height = 6, dpi = 150)
message("Wrote output/figures/fig6_bank_offices_vs_upi.{pdf,png}")
message(sprintf("Pearson r (log-log) = %+.3f", r))
