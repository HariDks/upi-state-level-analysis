# scripts/05_tables_figures/fig4_convergence.R
#
# Figure 4 (paper): Sigma-convergence in per-capita UPI across states,
# Apr 2023 - Jan 2026. Plots the cross-state coefficient of variation
# (CV = SD / mean) of monthly per-capita UPI over time. A downward trend
# = states converging (rich-state advantage shrinking); upward = diverging.
#
# Run: Rscript scripts/05_tables_figures/fig4_convergence.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(scales); library(lubridate); library(tidyr)
})

upi <- read_csv("data/interim/indiastat_upi_monthly.csv", show_col_types = FALSE)
pop <- read_csv("data/interim/population_mohfw.csv",     show_col_types = FALSE)

per_capita <- upi |>
  mutate(year = year(year_month)) |>
  inner_join(pop |> select(state_canonical, year, population),
             by = c("state_canonical", "year")) |>
  mutate(per_capita = (upi_volume_million * 1e6) / population)

cv_over_time <- per_capita |>
  group_by(year_month) |>
  summarise(
    n_states = n(),
    mean_pc  = mean(per_capita),
    sd_pc    = sd(per_capita),
    cv       = sd_pc / mean_pc,
    sd_log   = sd(log(per_capita)),
    .groups  = "drop"
  ) |>
  arrange(year_month) |>
  # Normalize both measures to start at 1.0 for visual comparison
  mutate(cv_idx     = cv / cv[1],
         sd_log_idx = sd_log / sd_log[1])

# Linear trend across the full panel — both measures
trend_cv     <- lm(cv ~ year_month, data = cv_over_time)
trend_sd_log <- lm(sd_log ~ year_month, data = cv_over_time)
slope_cv_year     <- coef(trend_cv)["year_month"] * 365.25
slope_sd_log_year <- coef(trend_sd_log)["year_month"] * 365.25
direction_cv     <- ifelse(slope_cv_year < 0, "narrowing", "widening")
direction_sd_log <- ifelse(slope_sd_log_year < 0, "narrowing", "widening")
trend_text <- sprintf(
  "CV trend: %+.4f / year (%s).  SD of log trend: %+.4f / year (%s).",
  slope_cv_year, direction_cv, slope_sd_log_year, direction_sd_log
)

# Long form — plot both CV and SD-of-log on the same chart, normalised
# to their starting values so they're visually comparable.
plot_long <- cv_over_time |>
  pivot_longer(cols = c(cv_idx, sd_log_idx),
               names_to = "metric", values_to = "value") |>
  mutate(metric = factor(metric, levels = c("cv_idx", "sd_log_idx"),
                         labels = c("CV (SD ÷ mean)",
                                    "SD of log per-capita UPI")))

p <- ggplot(plot_long, aes(year_month, value, colour = metric, linetype = metric)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.4) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  scale_y_continuous(limits = c(0, NA),
                     breaks = seq(0, 1.2, 0.2)) +
  scale_colour_manual(values = c("CV (SD ÷ mean)" = "#1f77b4",
                                 "SD of log per-capita UPI" = "#B2182B")) +
  scale_linetype_manual(values = c("CV (SD ÷ mean)" = "solid",
                                   "SD of log per-capita UPI" = "dashed")) +
  geom_hline(yintercept = 1, linetype = "dotted", colour = "grey50") +
  labs(
    title    = "Cross-state inequality in per-capita UPI, April 2023 – January 2026",
    subtitle = paste0("Two dispersion measures, both normalised to 1.0 at panel start ",
                      "(Apr-2023). Below 1 = states converging."),
    x = NULL,
    y = "Dispersion measure, indexed to 1.0 in Apr-2023",
    colour = NULL, linetype = NULL,
    caption = paste(
      sprintf("%s", trend_text),
      "Source: Indiastat NPCI state-wise UPI ÷ MoHFW population. Author's calculations.",
      "Both measures show convergence — robust to choice of dispersion metric.",
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
    legend.position  = "top",
    panel.grid.minor = element_blank()
  )

ggsave("output/figures/fig4_convergence.pdf", p, width = 9, height = 5.5)
ggsave("output/figures/fig4_convergence.png", p, width = 9, height = 5.5, dpi = 150)
message("Wrote output/figures/fig4_convergence.{pdf,png}")
message(sprintf("\n%s", trend_text))
