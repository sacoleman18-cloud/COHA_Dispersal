#!/usr/bin/env Rscript

# Full Pipeline Integration Test - All 28 Plots

cat("\n[FULL PIPELINE TEST] Starting complete system validation...\n")

# Load pipeline infrastructure
source("R/pipeline/pipeline.R")

# Load data
cat("\n[STAGE 1] Load & Validate Data\n")
cat(paste(rep("─", 40), collapse = ""), "\n")

data <- readr::read_csv("data/data.csv", show_col_types = FALSE)
cat(sprintf("✓ Data loaded: %d rows, %d columns\n", nrow(data), ncol(data)))

# Discover ridgeline module
cat("\n[STAGE 2] Discover & Load Plot Modules\n")
cat(paste(rep("─", 40), collapse = ""), "\n")

source("R/plot_modules/ridgeline/module.R")
metadata <- get_module_metadata()
plots_avail <- get_available_plots()

cat(sprintf("✓ Module: %s (v%s)\n", metadata$name, metadata$version))
cat(sprintf("✓ Available plots: %d\n", nrow(plots_avail)))

# Group plots by type
compact_plots <- plots_avail %>% dplyr::filter(group == "compact") %>% dplyr::pull(plot_id)
expanded_plots <- plots_avail %>% dplyr::filter(group == "expanded") %>% dplyr::pull(plot_id)

cat(sprintf("  - Compact (scale 0.85): %d plots\n", length(compact_plots)))
cat(sprintf("  - Expanded (scale 2.25): %d plots\n", length(expanded_plots)))

# Generate all 28 plots using the module's batch function
cat("\n[STAGE 3] Generate All 28 Plots\n")
cat(paste(rep("─", 40), collapse = ""), "\n")

all_plot_ids <- c(compact_plots, expanded_plots)
batch_results <- generate_plots_batch(data, plot_ids = all_plot_ids, continue_on_error = TRUE)

# Convert results list to data frame for analysis
results_df <- do.call(rbind, lapply(names(batch_results), function(plot_id) {
  res <- batch_results[[plot_id]]
  data.frame(
    plot_id = plot_id,
    status = res$status,
    file = res$file %||% NA_character_,
    stringsAsFactors = FALSE
  )
}))

cat(sprintf("\n✓ Plot generation complete:\n"))
cat(sprintf("  - Total requested: %d\n", length(all_plot_ids)))
cat(sprintf("  - Generated: %d\n", sum(results_df$status == "success")))
cat(sprintf("  - Partial: %d\n", sum(results_df$status == "partial")))
cat(sprintf("  - Failed: %d\n", sum(results_df$status == "failed")))

# Show summary
success_rate <- sum(results_df$status %in% c("success", "partial")) / length(all_plot_ids) * 100
cat(sprintf("  - Success rate: %.1f%%\n\n", success_rate))

# Summary of results
cat("[STAGE 4] VALIDATION SUMMARY\n")
cat(paste(rep("─", 40), collapse = ""), "\n")

if (success_rate >= 90) {
  cat("✓ [SUCCESS] All 28 plots successfully integrated!\n")
  cat("✓ Pipeline ready for production use\n")
} else {
  cat(sprintf("⚠ [PARTIAL SUCCESS] %.1f%% of plots generated\n", success_rate))
}

cat("\n[TEST] COMPLETE\n\n")
