# scripts/05_tables_figures/fig2_state_ranking_jan2026.R
#
# Figure 2 (paper): State ranking by per-capita UPI transactions, January 2026.
# Horizontal bar chart, 36 states sorted descending. Coloured by income
# tier (per-capita NSDP quartiles, latest available FY 2022-23) so the
# income-payments correlation is visible at a glance. Vertical line at the
# India weighted-average per-capita UPI. India's national figure for Jan
# 2026 (from screenshot): 21,703.44M / ~1.40B population ≈ 15.5/person/month.
#
# Run: Rscript scripts/05_tables_figures/fig2_state_ranking_jan2026.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(forcats)
  library(scales); library(lubridate); library(tibble)
})

panel <- read_csv("data/processed/part2_panel_3year.csv",
                  show_col_types = FALSE) |>
  filter(year_window == "2025-26r")

df <- panel |>
  rename(per_capita = per_capita_upi, nsdp = per_capita_nsdp) |>
  mutate(income_tier = ntile(nsdp, 4)) |>
  mutate(income_tier = factor(income_tier,
                              levels = 1:4,
                              labels = c("Low income (Q1)", "Lower-mid (Q2)",
                                         "Upper-mid (Q3)", "High income (Q4)"))) |>
  arrange(per_capita) |>
  mutate(state_canonical = fct_inorder(state_canonical))

india_avg <- weighted.mean(df$per_capita, w = df$population)

p <- ggplot(df, aes(per_capita, state_canonical, fill = income_tier)) +
  geom_col(width = 0.75) +
  geom_vline(xintercept = india_avg, linetype = "dashed",
             colour = "grey30", linewidth = 0.4) +
  annotate("text", x = india_avg, y = 1, hjust = -0.05, vjust = -0.4,
           label = sprintf("India avg ≈ %.1f", india_avg),
           size = 3, colour = "grey30") +
  geom_text(aes(label = sprintf("%.1f", per_capita)),
            hjust = -0.15, size = 2.8, colour = "grey20") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.10))) +
  scale_fill_manual(values = c("Low income (Q1)"  = "#B2182B",
                               "Lower-mid (Q2)"   = "#EF8A62",
                               "Upper-mid (Q3)"   = "#67A9CF",
                               "High income (Q4)" = "#2166AC"),
                    na.value = "grey70") +
  labs(
    title    = "State ranking by per-capita UPI transactions, most recent 12 months (Feb 2025 – Jan 2026)",
    subtitle = "Average across the 12 months ending January 2026. Coloured by income tier (per-capita NSDP quartiles, latest available with fallback to FY 2023-24/2022-23). Dashed line = India weighted average.",
    x = "Monthly UPI transactions per person (Feb 2025 – Jan 2026 avg)",
    y = NULL, fill = "Income tier",
    caption = "Source: Indiastat NPCI state-wise UPI (rolling 12-month window ending Jan 2026); MoHFW population mid-period (mean of 1-Jul-2025, 1-Jul-2026); per-capita NSDP at constant 2011-12 prices, latest available.\nAuthor's calculations."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.title    = element_text(face = "bold"),
    plot.caption  = element_text(size = 7, colour = "grey40", hjust = 0),
    plot.caption.position = "plot",
    legend.position = "top",
    legend.title    = element_text(size = 9),
    legend.key.height = unit(0.4, "cm"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y = element_text(size = 8.5)
  )

ggsave("output/figures/fig2_state_ranking_w3.pdf", p, width = 8, height = 9)
ggsave("output/figures/fig2_state_ranking_w3.png", p, width = 8, height = 9, dpi = 150)
message("Wrote output/figures/fig2_state_ranking_w3.{pdf,png}")
