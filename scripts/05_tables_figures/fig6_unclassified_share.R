# scripts/05_tables_figures/fig6_unclassified_share.R
#
# Figure 6 (paper): The state-attribution gap in NPCI UPI data, Apr 2023 -
# Jan 2026. Both volume and value shares of "Unclassified" UPI transactions
# (those NPCI cannot attribute to any specific state — routing, app
# aggregation, institutional flows). Highlights why state-level analyses
# of late-period UPI need to be treated with caveat.
#
# Run: Rscript scripts/05_tables_figures/fig6_unclassified_share.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(tidyr); library(scales)
})

uncl <- read_csv("data/interim/indiastat_upi_unclassified_share.csv",
                 show_col_types = FALSE) |>
  pivot_longer(cols = c(unclassified_volume_share, unclassified_value_share),
               names_to = "metric", values_to = "share") |>
  mutate(metric = factor(metric,
                         levels = c("unclassified_volume_share",
                                    "unclassified_value_share"),
                         labels = c("Share of total UPI VOLUME (count)",
                                    "Share of total UPI VALUE (₹)")))

# Annotation values
start_vol <- uncl |> filter(metric == "Share of total UPI VOLUME (count)") |>
  arrange(year_month) |> slice(1)
end_vol <- uncl |> filter(metric == "Share of total UPI VOLUME (count)") |>
  arrange(desc(year_month)) |> slice(1)

p <- ggplot(uncl, aes(year_month, share, colour = metric, linetype = metric)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.4) +
  scale_y_continuous(labels = label_percent(accuracy = 1),
                     limits = c(0, 0.5),
                     breaks = seq(0, 0.5, by = 0.1)) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  scale_colour_manual(values = c("Share of total UPI VOLUME (count)" = "#B2182B",
                                 "Share of total UPI VALUE (₹)"      = "#1f77b4")) +
  scale_linetype_manual(values = c("Share of total UPI VOLUME (count)" = "solid",
                                   "Share of total UPI VALUE (₹)"      = "dashed")) +
  annotate("text",
           x = start_vol$year_month, y = start_vol$share + 0.025,
           label = sprintf("%.0f%% (Apr-2023)", 100 * start_vol$share),
           hjust = 0, size = 3, colour = "#B2182B") +
  annotate("text",
           x = end_vol$year_month, y = end_vol$share + 0.025,
           label = sprintf("%.0f%% (Jan-2026)", 100 * end_vol$share),
           hjust = 1, size = 3, colour = "#B2182B") +
  labs(
    title    = "The state-attribution gap in NPCI UPI data, Apr 2023 – Jan 2026",
    subtitle = paste0("Share of monthly UPI transactions classified as ",
                      "“Unclassified” — NPCI cannot attribute to a specific state."),
    x = NULL, y = "Unclassified share",
    colour = NULL, linetype = NULL,
    caption = paste(
      "Source: Indiastat NPCI state-wise UPI monthly. Author's calculations.",
      "The Unclassified bucket reflects routing, app-aggregation, institutional, and cross-border flows that NPCI cannot",
      "attribute to a state at month of report. State-level analyses of late-period UPI must footnote this measurement gap.",
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

ggsave("output/figures/fig6_unclassified_share.pdf", p, width = 9, height = 5.5)
ggsave("output/figures/fig6_unclassified_share.png", p, width = 9, height = 5.5, dpi = 150)
message("Wrote output/figures/fig6_unclassified_share.{pdf,png}")
