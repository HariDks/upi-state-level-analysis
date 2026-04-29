# scripts/04_analyze/diagnostic_upi_percapita_trajectory.R
#
# Purpose: Narrative figure of log per-capita monthly UPI transactions by
#          state, Apr-2023 through Jan-2026. Tells two stories:
#            (1) a stable per-capita hierarchy across states (Goa /
#                Maharashtra / Tamil Nadu / Uttar Pradesh / Bihar bracket
#                the distribution),
#            (2) Manipur's mid-2023 UPI collapse during the ethnic
#                violence and internet shutdowns, recovering by late-2023
#                — a real exogenous shock the state-monthly panel picks
#                up cleanly. Useful as a candidate Part II descriptive
#                figure once the narrative is finalised.
# Inputs:  data/interim/indiastat_upi_monthly.csv
#          data/interim/population_mohfw.csv
# Outputs: output/diagnostics/upi_percapita_trajectory.pdf
# Run:     Rscript scripts/04_analyze/diagnostic_upi_percapita_trajectory.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(lubridate)
  library(stringr); library(scales); library(tibble)
})

upi <- readr::read_csv("data/interim/indiastat_upi_monthly.csv", show_col_types = FALSE)
pop <- readr::read_csv("data/interim/population_mohfw.csv",      show_col_types = FALSE)

df <- upi |>
  dplyr::mutate(year = lubridate::year(year_month)) |>
  dplyr::inner_join(pop |> dplyr::select(state_canonical, year, population),
                    by = c("state_canonical", "year")) |>
  dplyr::mutate(per_capita = (upi_volume_million * 1e6) / population)

# Deliberate highlight set — one representative per per-capita tier so
# labels don't pile up. Manipur added explicitly because the May-Oct 2023
# dip is the single most striking pattern in the panel.
hierarchy_highlights <- c("Goa", "Maharashtra", "Tamil Nadu",
                          "Uttar Pradesh", "Bihar")
manipur <- "Manipur"
df <- df |>
  dplyr::mutate(
    series = dplyr::case_when(
      state_canonical %in% hierarchy_highlights ~ "hierarchy",
      state_canonical == manipur                ~ "manipur",
      TRUE                                       ~ "other"
    )
  )

latest <- max(df$year_month)
hierarchy_palette <- c(
  "Goa"           = "#B2182B",  # warm red, top tier
  "Maharashtra"   = "#EF8A62",
  "Tamil Nadu"    = "#67A9CF",
  "Uttar Pradesh" = "#2166AC",  # cool blue, lower tier
  "Bihar"         = "#053061"
)

# Manipur dip point (visible low) and annotation anchor.
manipur_dip <- df |>
  dplyr::filter(state_canonical == manipur) |>
  dplyr::slice_min(per_capita, n = 1)

p <- ggplot(df, aes(year_month, per_capita, group = state_canonical)) +
  geom_line(data = dplyr::filter(df, series == "other"),
            colour = "grey85", linewidth = 0.3) +
  geom_line(data = dplyr::filter(df, series == "hierarchy"),
            aes(colour = state_canonical), linewidth = 0.8) +
  geom_line(data = dplyr::filter(df, series == "manipur"),
            colour = "#E69F00", linewidth = 0.9) +

  # Right-side labels for the hierarchy lines (well-separated tiers).
  geom_text(
    data = dplyr::filter(df, series == "hierarchy", year_month == latest),
    aes(label = state_canonical, colour = state_canonical),
    hjust = 0, nudge_x = 25, size = 3.2, fontface = "bold",
    show.legend = FALSE
  ) +

  # Manipur annotation: arrow + caption near the dip.
  geom_curve(
    data = manipur_dip,
    aes(x = as.Date("2023-12-15"), y = 4.5, xend = year_month, yend = per_capita),
    curvature = -0.25, arrow = arrow(length = unit(0.18, "cm")),
    colour = "#E69F00", linewidth = 0.4, inherit.aes = FALSE
  ) +
  annotate(
    "text", x = as.Date("2023-12-20"), y = 5.5,
    label = "Manipur — May-Oct 2023\nethnic violence and\ninternet shutdowns",
    hjust = 0, size = 3.0, colour = "#9C5A00", lineheight = 0.9
  ) +

  scale_colour_manual(values = hierarchy_palette) +
  scale_y_log10(labels = scales::comma_format(accuracy = 0.1),
                breaks = c(0.5, 1, 3, 10, 30)) +
  scale_x_date(expand = expansion(mult = c(0.01, 0.20)),
               date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title    = "Monthly UPI transactions per capita, by state",
    subtitle = "April 2023 – January 2026, log scale",
    caption  = "Source: Indiastat NPCI state-wise total UPI volume (April 2023 – January 2026); MoHFW Technical Group on Population Projections (2019, 1 July mid-year). Author's calculations.",
    x = NULL,
    y = "Transactions per person per month (log)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position  = "none",
    plot.title       = element_text(face = "bold"),
    plot.caption     = element_text(size = 8, colour = "grey40", hjust = 0,
                                    margin = margin(t = 10)),
    plot.caption.position = "plot",
    panel.grid.minor = element_blank(),
    axis.text.x      = element_text(size = 9)
  )

if (!dir.exists("output/diagnostics")) dir.create("output/diagnostics", recursive = TRUE)
out_pdf <- "output/diagnostics/upi_percapita_trajectory.pdf"
out_png <- "output/diagnostics/upi_percapita_trajectory.png"
ggsave(out_pdf, p, width = 9, height = 5.5)
ggsave(out_png, p, width = 9, height = 5.5, dpi = 150)
message("Wrote ", out_pdf)
message("Wrote ", out_png)
