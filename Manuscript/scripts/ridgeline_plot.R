#!/usr/bin/env Rscript
# Ridgeline plot for COHA dispersal manuscript supplement.

# load shared helpers and data loader
suppressPackageStartupMessages({
  library(ggplot2)
  library(ggridges)
  library(dplyr)
  library(ggtext)
  library(digest)
})

set.seed(12345)

if (exists("manuscript_root") && nzchar(manuscript_root)) {
  source(normalizePath(file.path(manuscript_root, "scripts", "shared_utils.R")))
  source(normalizePath(file.path(manuscript_root, "scripts", "data_loader.R")))
} else if (file.exists(file.path("scripts", "shared_utils.R"))) {
  source(file.path("scripts", "shared_utils.R"))
  source(file.path("scripts", "data_loader.R"))
} else if (file.exists(file.path("Manuscript", "scripts", "shared_utils.R"))) {
  source(file.path("Manuscript", "scripts", "shared_utils.R"))
  source(file.path("Manuscript", "scripts", "data_loader.R"))
} else {
  stop("Could not locate shared_utils.R or data_loader.R. Run the runner from Manuscript/ or open this file in RStudio and Source it.")
}

res <- load_coha_data()
coha_df <- res$data
data_source <- res$data_source

output_dir <- "figures"
output_base <- file.path(output_dir, "ridgeline")
output_png <- paste0(output_base, ".png")
output_pdf <- paste0(output_base, ".pdf")
repro_report_path <- file.path(output_dir, "repro_report_ridgeline.txt")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
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

# HawkO_natural palette (use shared `period_levels()` from `shared_utils.R`)
plot_df <- coha_df %>%
  dplyr::filter(!is.na(period)) %>%
  dplyr::mutate(
    # create a local lowercased dispersal indicator from canonical `dispersed`
    disp_lower = tolower(trimws(as.character(dispersed))),
    period = factor(period, levels = period_levels(), ordered = TRUE)
  )

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

n_periods <- length(period_levels())
fill_colors <- hawkO_palette(n_periods)

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
  plot_theme()

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

write_repro_report(repro_report_path, script_name = "ridgeline_plot.R", input_paths = c(res$data_path, res$data_frozen_path), output_paths = c(output_png, output_pdf), seed = 12345)

message(sprintf("Saved figure to: %s", output_png))
message(sprintf("Saved figure to: %s", output_pdf))
message(sprintf("Wrote reproducibility report to: %s", repro_report_path))
