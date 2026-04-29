# scripts/05_tables_figures/fig3_cross_state_scatter.R
#
# Figure 3 (paper): 4-panel cross-state scatter — per-capita UPI vs each
# of NSDP, literacy, internet density, urban share. Each panel: 30+ states
# as points, fitted OLS line, Pearson correlation. Single ggplot via
# facet_wrap (no extra packages needed). Top 3 and bottom 3 states by
# per-capita UPI labelled per panel using deliberately offset geom_text.
#
# Run: Rscript scripts/05_tables_figures/fig3_cross_state_scatter.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(scales)
  library(lubridate); library(tidyr); library(stringr); library(tibble)
})

panel <- read_csv("data/processed/part2_panel_3year.csv",
                  show_col_types = FALSE) |>
  filter(year_window == "2024-25") |>
  rename(NSDP = per_capita_nsdp,
         Literacy = literacy,
         Internet = internet_density,
         Urban = share_urban) |>
  mutate(Urban = Urban * 100)  # convert fraction to % for display

# Long form for facet_wrap. NSDP on log10; others on linear.
long <- panel |>
  pivot_longer(cols = c(NSDP, Literacy, Internet, Urban),
               names_to = "variable", values_to = "value") |>
  filter(!is.na(value), !is.na(per_capita_upi))

# Make NSDP log-transformed so the panel relationship is visually linear.
long <- long |>
  mutate(value_plot = ifelse(variable == "NSDP", log10(value), value))

# Per-panel correlations and labels
labels_df <- long |>
  group_by(variable) |>
  summarise(
    r_log    = cor(value_plot, log10(per_capita_upi), use = "complete.obs"),
    x_label  = max(value_plot, na.rm = TRUE),
    y_label  = max(per_capita_upi, na.rm = TRUE),
    .groups  = "drop"
  ) |>
  mutate(r_text = sprintf("Pearson r = %+.2f", r_log))

# Highlight top 3 + bottom 3 by per-capita UPI
top_bot <- panel |>
  arrange(desc(per_capita_upi)) |>
  slice(c(1:3, (n() - 2):n())) |>
  pull(state_canonical)

label_layer <- long |>
  filter(state_canonical %in% top_bot) |>
  mutate(label_state = state_canonical)

# Pretty axis labels per facet
var_labels <- c(
  NSDP     = "Per-capita NSDP (₹, log10, constant 2011-12 prices) — FY 2024-25",
  Literacy = "Literacy rate, persons 7+ (%) — FY 2023-24",
  Internet = "Internet subscribers per 100 — as on 31-Mar-2025",
  Urban    = "Urban population share (%, interpolated to 2024)"
)
long      <- long      |> mutate(variable = factor(variable, levels = names(var_labels), labels = var_labels))
labels_df <- labels_df |> mutate(variable = factor(variable, levels = names(var_labels), labels = var_labels))
label_layer <- label_layer |> mutate(variable = factor(variable, levels = names(var_labels), labels = var_labels))

p <- ggplot(long, aes(value_plot, per_capita_upi)) +
  geom_smooth(method = "lm", se = TRUE, formula = y ~ x,
              colour = "#1f77b4", fill = "#1f77b4", alpha = 0.18,
              linewidth = 0.5) +
  geom_point(size = 2, alpha = 0.55, colour = "grey40") +
  geom_point(data = label_layer, size = 2.5, colour = "#B2182B") +
  geom_text(data = label_layer, aes(label = label_state),
            colour = "#B2182B", size = 2.6, hjust = -0.12, vjust = 0.4,
            check_overlap = FALSE) +
  geom_text(data = labels_df,
            aes(x = x_label, y = y_label, label = r_text),
            inherit.aes = FALSE, hjust = 1.0, vjust = 1.5,
            size = 3, colour = "grey25", fontface = "plain") +
  facet_wrap(~ variable, scales = "free_x", ncol = 2) +
  scale_y_log10(labels = label_comma()) +
  labs(
    title    = "Per-capita UPI vs. state characteristics, FY 2024-25 cross-section",
    subtitle = "Each panel: 30+ states. Fitted OLS line, Pearson correlation (in log-log). Top 3 and bottom 3 states by per-capita UPI labelled.",
    x = NULL, y = "Monthly UPI per person, FY 2024-25 average (log)",
    caption = paste(
      "Source: Indiastat NPCI state-wise UPI (Apr 2024 - Mar 2025 monthly avg); MoHFW population mid-FY (mean of 1-Jul-2024, 1-Jul-2025);",
      "Indiastat per-capita NSDP at constant 2011-12 prices (FY 2024-25, fallback to 2023-24/2022-23 for some UTs);",
      "Indiastat literacy 7+ (FY 2023-24); TRAI YPI 2024-25 internet subscribers per 100 (as of 31-Mar-2025);",
      "Census-anchored urban share (linear interpolation 2011-2021, extrapolated to 2024).",
      "Author's calculations. Correlations are descriptive, not causal.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.title       = element_text(face = "bold", size = 12),
    plot.subtitle    = element_text(size = 9.5),
    plot.caption     = element_text(size = 7, colour = "grey40", hjust = 0,
                                    margin = margin(t = 10)),
    plot.caption.position = "plot",
    strip.text       = element_text(size = 9, face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave("output/figures/fig3_cross_state_scatter.pdf", p, width = 11, height = 9)
ggsave("output/figures/fig3_cross_state_scatter.png", p, width = 11, height = 9, dpi = 150)
message("Wrote output/figures/fig3_cross_state_scatter.{pdf,png}")
