cat("\n==== PLOT REGISTRY VALIDATION ====\n\n")

source("R/config/plot_registry.R")

# Count plots
n_ridgeline <- length(plot_registry$ridgeline$variants)
cat(sprintf("Total ridgeline variants: %d\n\n", n_ridgeline))

# Show all IDs
cat("Plot IDs:\n")
for (id in names(plot_registry$ridgeline$variants)) {
  cat(sprintf("  - %s\n", id))
}

# Check custom palettes
cat("\nCustom palettes (hawk colors):\n")
for (id in names(plot_registry$ridgeline$variants)) {
  cfg <- plot_registry$ridgeline$variants[[id]]
  if (!is.null(cfg$palette_type) && cfg$palette_type == "custom") {
    cat(sprintf("  ✓ %s: %s (%d colors)\n", 
                id, cfg$fill, length(cfg$fill_colors)))
  }
}

cat("\n==== VALIDATION COMPLETE ====\n")
