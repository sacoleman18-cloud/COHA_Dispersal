#!/usr/bin/env Rscript
# Ridgeline plot for COHA dispersal manuscript supplement.

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggridges)
  library(dplyr)
  library(ggtext)
  library(digest)
})

set.seed(12345)

data_path <- file.path("data", "data.csv")
data_frozen_path <- file.path("data", "data_frozen.rds")
output_dir <- "figures"
output_base <- file.path(output_dir, "ridgeline")
output_png <- paste0(output_base, ".png")
output_pdf <- paste0(output_base, ".pdf")
repro_report_path <- file.path(output_dir, "repro_report.txt")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Read data for manuscript figure.
if (file.exists(data_frozen_path)) {
  coha_df <- readRDS(data_frozen_path)
  data_source <- data_frozen_path
} else {
  coha_df <- read.csv(data_path, stringsAsFactors = FALSE)
  saveRDS(coha_df, data_frozen_path)
  data_source <- data_path
}

# Ensure expected columns exist.
required_cols <- c("mass", "year")
missing_cols <- setdiff(required_cols, names(coha_df))
if (length(missing_cols) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
}

# Create 6-year period bins to match the pipeline.
coha_df$year <- as.integer(coha_df$year)
coha_df$period <- dplyr::case_when(
  coha_df$year >= 1980 & coha_df$year <= 1985 ~ "1980-1985",
  coha_df$year >= 1986 & coha_df$year <= 1991 ~ "1986-1991",
  coha_df$year >= 1992 & coha_df$year <= 1997 ~ "1992-1997",
  coha_df$year >= 1998 & coha_df$year <= 2003 ~ "1998-2003",
  coha_df$year >= 2004 & coha_df$year <= 2009 ~ "2004-2009",
  coha_df$year >= 2010 & coha_df$year <= 2015 ~ "2010-2015",
  coha_df$year >= 2016 & coha_df$year <= 2021 ~ "2016-2021",
  coha_df$year >= 2022 & coha_df$year <= 2027 ~ "2022-2027",
  TRUE ~ NA_character_
)

# HawkO_natural palette
period_levels <- c(
  "1980-1985", "1986-1991", "1992-1997", "1998-2003",
  "2004-2009", "2010-2015", "2016-2021", "2022-2027"
)
plot_df <- plot_df %>%
  dplyr::mutate(period = factor(period, levels = period_levels, ordered = TRUE))

data_unknown <- plot_df %>%
  dplyr::filter(disp_lower == "unknown")

period_means <- plot_df %>%
  dplyr::filter(disp_lower == "wisconsin") %>%
  dplyr::group_by(period) %>%
  dplyr::summarise(mean_mass = mean(mass, na.rm = TRUE), .groups = "drop")

unknown_means <- data_unknown %>%
  dplyr::group_by(period) %>%
  dplyr::summarise(mean_mass = mean(mass, na.rm = TRUE), .groups = "drop")

period_counts <- plot_df %>%
  dplyr::group_by(period) %>%
  dplyr::summarise(
    n_wisconsin = sum(disp_lower == "wisconsin", na.rm = TRUE),
    n_unknown = sum(disp_lower == "unknown", na.rm = TRUE),
    .groups = "drop"
  )

label_map <- period_counts %>%
  dplyr::mutate(
    label = sprintf(
      "<span style='color:#000000;'>%s</span><br><span style='color:#666666;'>Dispersal: %d<br>Non-dispersal: %d</span>",
      period,
      n_wisconsin,
      n_unknown
    )
  ) %>%
  dplyr::arrange(period)
period_labels <- label_map$label
names(period_labels) <- label_map$period

hawkO_natural <- c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27")
n_periods <- length(period_levels)
fill_colors <- grDevices::colorRampPalette(hawkO_natural)(n_periods)

plot_obj <- ggplot(plot_df, aes(x = mass, y = period, fill = period)) +
  geom_density_ridges(scale = 2.25, alpha = 0.7, show.legend = FALSE) +
  geom_segment(
    data = period_means,
    aes(
      x = mean_mass,
      xend = mean_mass,
      y = as.numeric(period),
      yend = as.numeric(period) + 1.0
    ),
    color = "black",
    linetype = "dashed",
    linewidth = 0.4,
    alpha = 0.7
  ) +
  geom_segment(
    data = unknown_means,
    aes(
      x = mean_mass,
      xend = mean_mass,
      y = as.numeric(period),
      yend = as.numeric(period) + 1.0,
      color = period
    ),
    linetype = "solid",
    linewidth = 0.8,
    alpha = 1
  ) +
  geom_point(
    data = period_means,
    aes(x = mean_mass, y = period, fill = period),
    shape = 21,
    size = 3,
    stroke = 0.6,
    color = "black",
    inherit.aes = FALSE
  ) +
  geom_point(
    data = unknown_means,
    aes(x = mean_mass, y = period, fill = period),
    shape = 24,
    size = 3,
    stroke = 0.6,
    color = "black",
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = fill_colors, guide = "none") +
  scale_color_manual(values = fill_colors, guide = "none") +
  scale_x_continuous(
    breaks = pretty(plot_df$mass, n = 6),
    labels = function(x) format(x, trim = TRUE, scientific = FALSE),
    expand = expansion(mult = c(0.02, 0.02))
  ) +
  scale_y_discrete(labels = period_labels) +
  labs(
    x = "Mass (grams)",
    y = "Period"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray50"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10, face = "bold", color = "black"),
    axis.text.y = ggtext::element_markdown(lineheight = 1.1),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title.y = element_text(angle = 0, vjust = 0.5, margin = margin(r = 8)),
    axis.title.x = element_text(margin = margin(t = 8)),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(
  filename = output_png,
  plot = plot_obj,
  width = 8,
  height = 6,
  dpi = 300
)

ggsave(
  filename = output_pdf,
  plot = plot_obj,
  width = 8,
  height = 6
)

sink(repro_report_path)
cat("=== Reproducibility Report ===\n\n")
cat("Script: ridgeline_plot.R\n")
cat("Execution time: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n", sep = "")
cat("R version: ", R.version.string, "\n", sep = "")
cat("OS: ", Sys.info()["sysname"], " ", Sys.info()["release"], "\n\n", sep = "")

cat("Loaded packages:\n")
print(sessionInfo()$otherPkgs)
cat("\n")

cat("Input files:\n")
if (file.exists(data_path)) {
  cat("- ", data_path, " (sha256): ",
      digest::digest(data_path, algo = "sha256", file = TRUE), "\n", sep = "")
}
if (file.exists(data_frozen_path)) {
  cat("- ", data_frozen_path, " (sha256): ",
      digest::digest(data_frozen_path, algo = "sha256", file = TRUE), "\n", sep = "")
}
cat("\n")

cat("Output files:\n")
if (file.exists(output_png)) {
  cat("- ", output_png, " (sha256): ",
      digest::digest(output_png, algo = "sha256", file = TRUE), "\n", sep = "")
}
if (file.exists(output_pdf)) {
  cat("- ", output_pdf, " (sha256): ",
      digest::digest(output_pdf, algo = "sha256", file = TRUE), "\n", sep = "")
}
cat("\n")

cat("Random seed: 12345\n")
sink()

message(sprintf("Saved figure to: %s", output_png))
message(sprintf("Saved figure to: %s", output_pdf))
message(sprintf("Wrote reproducibility report to: %s", repro_report_path))
