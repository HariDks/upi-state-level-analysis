# scripts/04_analyze/test_unclassified_randomness.R
#
# Test whether the growing "Unclassified" UPI bucket is concentrating in
# rich states (non-random) or absorbing transactions proportionally
# across states (random).
#
# Method: compute each state's SHARE of national attributed UPI volume
# for Apr-2023 (start of panel, 13% Unclassified) and Jan-2026 (end of
# panel, 43% Unclassified). If Unclassified is random, every state's
# share is preserved across these two points. If Unclassified
# concentrates in rich states, rich states' shares should DROP and
# poor states' shares should RISE.
#
# Then regress share-change on log(NSDP). A significant negative
# coefficient = rich states losing share = Unclassified non-random.
#
# Outputs to console + output/diagnostics/unclassified_randomness_test.{pdf,png}
# Run: Rscript scripts/04_analyze/test_unclassified_randomness.R

if (!file.exists("CLAUDE.md")) stop("Run from project root.", call. = FALSE)
suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tidyr); library(ggplot2)
  library(scales); library(stringr)
})

upi  <- read_csv("data/interim/indiastat_upi_monthly.csv", show_col_types = FALSE)
nsdp <- read_csv("data/interim/per_capita_nsdp.csv",       show_col_types = FALSE)

# Compute each state's share of national attributed UPI in Apr 2023 vs Jan 2026.
shares <- upi |>
  filter(year_month %in% as.Date(c("2023-04-01", "2026-01-01"))) |>
  group_by(year_month) |>
  mutate(national_attributed = sum(upi_volume_million),
         share = upi_volume_million / national_attributed) |>
  ungroup() |>
  select(state_canonical, year_month, share, upi_volume_million)

share_change <- shares |>
  pivot_wider(id_cols = state_canonical,
              names_from = year_month,
              values_from = c(share, upi_volume_million),
              names_glue = "{.value}_{format(year_month, '%Y_%m')}") |>
  rename(share_apr23 = share_2023_04,
         share_jan26 = share_2026_01,
         vol_apr23   = upi_volume_million_2023_04,
         vol_jan26   = upi_volume_million_2026_01) |>
  mutate(
    share_change_pp     = (share_jan26 - share_apr23) * 100,  # percentage points
    share_change_pct    = (share_jan26 - share_apr23) / share_apr23 * 100,
    log_share_change    = log(share_jan26) - log(share_apr23)
  )

# Latest available NSDP per state
nsdp_latest <- nsdp |>
  filter(fy %in% c("2024-25", "2023-24", "2022-23"),
         !is.na(per_capita_nsdp_constant_inr)) |>
  arrange(state_canonical, desc(fy)) |>
  group_by(state_canonical) |>
  slice_head(n = 1) |>
  ungroup() |>
  select(state_canonical, nsdp = per_capita_nsdp_constant_inr)

panel <- share_change |> inner_join(nsdp_latest, by = "state_canonical")

cat(sprintf("\nN states with NSDP available: %d / %d\n",
            nrow(panel), nrow(share_change)))

# Test 1: Pearson correlation between log(NSDP) and log share change.
r_test <- cor.test(log(panel$nsdp), panel$log_share_change)
cat("\n=== TEST 1: Correlation of log(NSDP) with log(share change Apr-23 → Jan-26) ===\n")
cat(sprintf("  Pearson r = %+.3f  (p = %.4f, n = %d)\n",
            r_test$estimate, r_test$p.value, nrow(panel)))
cat("  Interpretation:\n")
if (r_test$p.value < 0.05) {
  if (r_test$estimate < 0) {
    cat("  → SIGNIFICANT NEGATIVE: rich states' shares dropped relative to poor states'.\n")
    cat("  → Unclassified bucket appears to concentrate in RICH states.\n")
    cat("  → Convergence and income-UPI findings need caveat.\n")
  } else {
    cat("  → SIGNIFICANT POSITIVE: rich states' shares ROSE relative to poor states'.\n")
    cat("  → Unclassified bucket concentrates in POOR states (unexpected).\n")
  }
} else {
  cat("  → NOT significant: cannot reject 'Unclassified is random across states'.\n")
  cat("  → Convergence and income-UPI findings stand without this caveat.\n")
}

# Test 2: Linear regression — quantify the magnitude
m <- lm(log_share_change ~ log(nsdp), data = panel)
cat("\n=== TEST 2: Regression log(share change) ~ log(NSDP) ===\n")
print(summary(m)$coefficients)

# Test 3: Show top 5 share-gainers and top 5 share-losers, with their NSDP rank
top_losers  <- panel |> arrange(share_change_pp) |> head(5)
top_gainers <- panel |> arrange(desc(share_change_pp)) |> head(5)

cat("\n=== Top 5 SHARE LOSERS (Apr-23 → Jan-26) ===\n")
print(top_losers |> select(state_canonical, share_apr23, share_jan26,
                           share_change_pp, nsdp) |>
        mutate(across(c(share_apr23, share_jan26), \(x) round(x * 100, 2)),
               share_change_pp = round(share_change_pp, 2)) |>
        as.data.frame(), row.names = FALSE)
cat("\n=== Top 5 SHARE GAINERS (Apr-23 → Jan-26) ===\n")
print(top_gainers |> select(state_canonical, share_apr23, share_jan26,
                            share_change_pp, nsdp) |>
        mutate(across(c(share_apr23, share_jan26), \(x) round(x * 100, 2)),
               share_change_pp = round(share_change_pp, 2)) |>
        as.data.frame(), row.names = FALSE)

# Visual: scatter of log(NSDP) vs log share change
labels_states <- bind_rows(top_losers, top_gainers) |> pull(state_canonical)
p <- ggplot(panel, aes(nsdp, log_share_change)) +
  geom_smooth(method = "lm", se = TRUE, formula = y ~ x,
              colour = "#B2182B", fill = "#B2182B", alpha = 0.18, linewidth = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey40") +
  geom_point(aes(colour = state_canonical %in% labels_states), size = 2.4, alpha = 0.7) +
  geom_text(data = panel |> filter(state_canonical %in% labels_states),
            aes(label = state_canonical), hjust = -0.12, vjust = 0.4,
            size = 2.8, colour = "#B2182B") +
  scale_colour_manual(values = c(`TRUE` = "#B2182B", `FALSE` = "grey50"), guide = "none") +
  scale_x_log10(labels = scales::label_comma()) +
  annotate("text", x = max(panel$nsdp), y = max(panel$log_share_change),
           label = sprintf("Pearson r = %+.2f, p = %.3f", r_test$estimate, r_test$p.value),
           hjust = 1, vjust = 1.5, size = 3.2, colour = "grey25", fontface = "italic") +
  labs(
    title    = "Are rich states losing UPI share to the Unclassified bucket?",
    subtitle = "X: latest per-capita NSDP (₹, log).  Y: log change in share of national attributed UPI, Apr 2023 → Jan 2026.\nNegative slope = rich states' shares fell, suggesting Unclassified concentrates in rich states.",
    x = "Per-capita NSDP, latest (₹, log scale)",
    y = "Log change in state's share of national attributed UPI",
    caption = "Source: Indiastat NPCI state-wise UPI; Indiastat per-capita NSDP. Author's calculations.\nA flat slope (or insignificant Pearson r) implies the Unclassified bucket grew proportionally across states (random)."
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(size = 10),
        plot.caption = element_text(size = 8, colour = "grey40", hjust = 0),
        plot.caption.position = "plot",
        panel.grid.minor = element_blank())

if (!dir.exists("output/diagnostics")) dir.create("output/diagnostics", recursive = TRUE)
ggsave("output/diagnostics/unclassified_randomness_test.pdf", p, width = 9, height = 6)
ggsave("output/diagnostics/unclassified_randomness_test.png", p, width = 9, height = 6, dpi = 150)
message("\nWrote output/diagnostics/unclassified_randomness_test.{pdf,png}")
