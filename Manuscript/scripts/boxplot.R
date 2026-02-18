#!/usr/bin/env Rscript
# Boxplot for COHA dispersal manuscript supplement.

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
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
output_base <- file.path(output_dir, "boxplot")
output_png <- paste0(output_base, ".png")
output_pdf <- paste0(output_base, ".pdf")
repro_report_path <- file.path(output_dir, "repro_report_boxplot.txt")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

## Ensure expected columns exist (Dispersed vs Non-dispersed plot only needs `mass` and `dispersed`)
required_cols_box <- c("mass", "dispersed")
missing_cols_box <- setdiff(required_cols_box, names(coha_df))
if (length(missing_cols_box) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols_box, collapse = ", ")))
}

# Prepare data: classify as Dispersed vs Non-dispersed
plot_df <- coha_df %>%
  dplyr::mutate(
    disp_lower = tolower(trimws(as.character(dispersed))),
    dispersal_status = ifelse(disp_lower == "wisconsin", "Dispersed", "Non-dispersed"),
    dispersal_status = factor(dispersal_status, levels = c("Dispersed", "Non-dispersed"))
  ) %>%
  dplyr::filter(disp_lower %in% c("wisconsin", "unknown"))

# Define colors: #56677F for Dispersed (wisconsin), #C98C63 for Non-dispersed (unknown)
dispersal_colors <- c("Dispersed" = "#56677F", "Non-dispersed" = "#C98C63")

# Simple boxplot: x = dispersal status, y = mass
plot_obj <- ggplot(plot_df, aes(x = dispersal_status, y = mass, fill = dispersal_status)) +
  geom_boxplot(alpha = 0.85, outlier.shape = 21, outlier.alpha = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, color = "black", show.legend = FALSE) +
  scale_fill_manual(values = dispersal_colors, name = "Dispersal Status") +
  scale_y_continuous(breaks = pretty(plot_df$mass, n = 6), expand = expansion(mult = c(0.02, 0.05))) +
  labs(x = "Dispersal Status", y = "Mass (grams)", title = "COHA Mass: Dispersed vs Non-dispersed") +
  plot_theme(base_size = 12) +
  theme(plot.title = element_text(hjust = 0.5), legend.position = "none")

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
