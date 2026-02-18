#!/usr/bin/env Rscript
# Boxplot for COHA dispersal manuscript supplement.

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(digest)
})

set.seed(12345)

source(file.path("Manuscript", "scripts", "shared_utils.R"))
source(file.path("Manuscript", "scripts", "data_loader.R"))

res <- load_coha_data()
coha_df <- res$data
data_source <- res$data_source

output_dir <- "figures"
output_base <- file.path(output_dir, "boxplot")
output_png <- paste0(output_base, ".png")
output_pdf <- paste0(output_base, ".pdf")
repro_report_path <- file.path(output_dir, "repro_report_boxplot.txt")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Ensure expected columns exist (extra check for boxplot)
required_cols_box <- c("mass", "year", "disp_lower")
missing_cols_box <- setdiff(required_cols_box, names(coha_df))
if (length(missing_cols_box) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols_box, collapse = ", ")))
}

# Create plotting dataframe: filter and set factor levels
plot_df <- coha_df %>%
  dplyr::filter(!is.na(period)) %>%
  dplyr::mutate(
    # create a local lowercased dispersal indicator from canonical `dispersed`
    disp_lower = tolower(trimws(as.character(dispersed)))
  ) %>%
  dplyr::filter(disp_lower %in% c("wisconsin", "unknown")) %>%
  dplyr::mutate(
    dispersal_status = ifelse(disp_lower == "wisconsin", "Dispersed", "Non-dispersed"),
    dispersal_status = factor(dispersal_status, levels = c("Dispersed", "Non-dispersed"))
  ) %>%
  dplyr::mutate(period = factor(period, levels = period_levels(), ordered = TRUE))

# Define colors: #56677F for Dispersed (wisconsin), #C98C63 for Non-dispersed (unknown)
dispersal_colors <- c("Dispersed" = "#56677F", "Non-dispersed" = "#C98C63")

plot_obj <- ggplot(plot_df, aes(x = period, y = mass, fill = dispersal_status)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.alpha = 0.5, position = position_dodge(width = 0.8)) +
  stat_summary(
    fun = mean,
    geom = "point",
    shape = 23,
    size = 3,
    color = "black",
    position = position_dodge(width = 0.8),
    show.legend = FALSE
  ) +
  stat_summary(
    fun = mean,
    geom = "line",
    aes(group = dispersal_status),
    position = position_dodge(width = 0.8),
    linewidth = 0.6,
    alpha = 0.7,
    show.legend = FALSE
  ) +
  scale_fill_manual(values = dispersal_colors, name = "Dispersal Status") +
  scale_y_continuous(
    breaks = pretty(plot_df$mass, n = 6),
    expand = expansion(mult = c(0.02, 0.05))
  ) +
  labs(
    x = "Period",
    y = "Mass (grams)",
    title = "COHA Mass by Period and Dispersal Status"
  ) +
  plot_theme(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

ggsave(
  filename = output_png,
  plot = plot_obj,
  width = 10,
  height = 6,
  dpi = 300
)

ggsave(
  filename = output_pdf,
  plot = plot_obj,
  width = 10,
  height = 6
)

write_repro_report(repro_report_path, script_name = "boxplot.R", input_paths = c(res$data_path, res$data_frozen_path), output_paths = c(output_png, output_pdf), seed = 12345)

message(sprintf("Saved figure to: %s", output_png))
message(sprintf("Saved figure to: %s", output_pdf))
message(sprintf("Wrote reproducibility report to: %s", repro_report_path))
