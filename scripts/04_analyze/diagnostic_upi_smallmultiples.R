# scripts/04_analyze/diagnostic_upi_smallmultiples.R
#
# Purpose: 36-panel small-multiples view of monthly per-capita UPI by
#          state. Pure diagnostic — meant to surface weird trajectories
#          (level breaks, missing months, non-monotonic shapes) at a
#          glance. NOT a paper figure. Each panel is on its own y-axis
#          (free_y) so the trajectory shape is visible regardless of the
#          state's per-capita level. Panels ordered by descending
#          per-capita in the latest month (so big-volume states cascade
#          to the top-left).
# Inputs:  data/interim/indiastat_upi_monthly.csv
#          data/interim/population_mohfw.csv
# Outputs: output/diagnostics/upi_percapita_small_multiples.pdf
# Run:     Rscript scripts/04_analyze/diagnostic_upi_smallmultiples.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(lubridate)
  library(forcats); library(scales)
})

upi <- readr::read_csv("data/interim/indiastat_upi_monthly.csv", show_col_types = FALSE)
pop <- readr::read_csv("data/interim/population_mohfw.csv",      show_col_types = FALSE)

df <- upi |>
  dplyr::mutate(year = lubridate::year(year_month)) |>
  dplyr::inner_join(pop |> dplyr::select(state_canonical, year, population),
                    by = c("state_canonical", "year")) |>
  dplyr::mutate(per_capita = (upi_volume_million * 1e6) / population)

latest <- max(df$year_month)
order_by_latest <- df |>
  dplyr::filter(year_month == latest) |>
  dplyr::arrange(dplyr::desc(per_capita)) |>
  dplyr::pull(state_canonical)

df <- df |>
  dplyr::mutate(state_canonical = factor(state_canonical, levels = order_by_latest))

p <- ggplot(df, aes(year_month, per_capita)) +
  geom_line(colour = "#1f77b4", linewidth = 0.4) +
  geom_point(data = df |> dplyr::group_by(state_canonical) |>
               dplyr::slice_min(per_capita, n = 1, with_ties = FALSE) |>
               dplyr::ungroup(),
             colour = "#d62728", size = 0.9) +
  facet_wrap(~ state_canonical, scales = "free_y", ncol = 6) +
  scale_x_date(date_breaks = "1 year", date_labels = "%y") +
  scale_y_continuous(labels = scales::comma_format(accuracy = 0.1)) +
  labs(
    title    = "Monthly UPI transactions per capita — small multiples diagnostic",
    subtitle = paste0("Each panel free y-axis; red dot = each state's lowest month. ",
                      "Panels ordered by January-2026 per-capita."),
    caption  = "Source: Indiastat NPCI state-wise total UPI / MoHFW population projections (2019). Diagnostic, not for paper.",
    x = NULL,
    y = "Transactions per person per month"
  ) +
  theme_minimal(base_size = 9) +
  theme(
    plot.title       = element_text(face = "bold", size = 12),
    plot.subtitle    = element_text(size = 9),
    plot.caption     = element_text(size = 7, colour = "grey40", hjust = 0,
                                    margin = margin(t = 8)),
    plot.caption.position = "plot",
    strip.text       = element_text(size = 8, face = "bold"),
    panel.grid.minor = element_blank(),
    axis.text        = element_text(size = 7)
  )

if (!dir.exists("output/diagnostics")) dir.create("output/diagnostics", recursive = TRUE)
out_pdf <- "output/diagnostics/upi_percapita_small_multiples.pdf"
out_png <- "output/diagnostics/upi_percapita_small_multiples.png"
ggsave(out_pdf, p, width = 13, height = 9)
ggsave(out_png, p, width = 13, height = 9, dpi = 130)
message("Wrote ", out_pdf)
message("Wrote ", out_png)
