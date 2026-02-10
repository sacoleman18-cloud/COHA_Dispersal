# Example: Using the COHA Dispersal Analysis Pipeline
#
# This script demonstrates the main ways to use the pipeline for generating
# ridgeline plots. Run this script to see examples of pipeline usage.

# Load the pipeline
source("R/pipeline.R")

# ============================================================================
# Example 1: Run the complete pipeline
# ============================================================================
cat("Example 1: Running complete pipeline...\n")
cat("This will generate all 20 plots and save them to results/png/\n\n")

# Uncomment to run:
# plots <- run_pipeline()

# ============================================================================
# Example 2: Generate plots without saving (for exploration)
# ============================================================================
cat("\nExample 2: Generate plots without saving to disk\n")
cat("Useful for interactive exploration in RStudio\n\n")

# Uncomment to run:
# plots <- run_pipeline(save_plots = FALSE, verbose = TRUE)
# 
# # View the first plot
# print(plots$compact_01)

# ============================================================================
# Example 3: List all available plots
# ============================================================================
cat("\nExample 3: List all available plot configurations\n\n")

# List plots
available_plots <- list_plots()
print(available_plots)

# ============================================================================
# Example 4: Generate a single plot by ID
# ============================================================================
cat("\n\nExample 4: Generate a specific plot\n\n")

# Generate one plot
p <- generate_plot("compact_01")
print(p)

# ============================================================================
# Example 5: Generate multiple specific plots
# ============================================================================
cat("\n\nExample 5: Generate multiple specific plots\n")
cat("Useful when you only need a subset of plots\n\n")

# Uncomment to run:
# plot_ids <- c("compact_01", "expanded_01", "compact_05")
# 
# for (id in plot_ids) {
#   cat("Generating:", id, "\n")
#   p <- generate_plot(id)
#   
#   # Save manually if needed
#   ggsave(
#     filename = file.path("results/png", paste0(id, "_custom.png")),
#     plot = p,
#     width = 10,
#     height = 7,
#     dpi = 300
#   )
# }

# ============================================================================
# Example 6: Customize output directory
# ============================================================================
cat("\n\nExample 6: Save plots to a custom directory\n\n")

# Uncomment to run:
# plots <- run_pipeline(
#   output_dir = "results/png/custom_run",
#   save_plots = TRUE
# )

# ============================================================================
# Example 7: Add your own plot configuration
# ============================================================================
cat("\n\nExample 7: Create a custom plot configuration\n")
cat("See R/config.R for the structure of plot_configs\n\n")

# Create a custom config
custom_config <- list(
  list(
    id = "custom_test",
    name = "Custom Test Plot",
    scale_value = 1.5,
    line_height = 0.9,
    fill_palette = "plasma",
    color_palette = "plasma",
    palette_type = "viridis"
  )
)

# Uncomment to run with custom config:
# plots <- run_pipeline(
#   configs = custom_config,
#   output_dir = "results/png/custom",
#   save_plots = TRUE
# )

cat("\n\n✓ Examples complete! Uncomment sections to run.\n")
cat("For more details, see README.md\n")
