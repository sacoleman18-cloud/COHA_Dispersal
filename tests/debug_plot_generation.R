# Debug plot generation - check which plots fail
library(here)

source(here::here("R", "pipeline", "pipeline.R"))

cat("\n=== Running pipeline with verbose output ===\n\n")
result <- run_pipeline(verbose = TRUE, use_registry = TRUE)

cat("\n\n=== PLOT GENERATION RESULTS ===\n")
cat(sprintf("Total plots configured: %d\n", result$phase_results$plot_generation$plots_total))
cat(sprintf("Plots generated: %d\n", result$phase_results$plot_generation$plots_generated))
cat(sprintf("Plots failed: %d\n", result$phase_results$plot_generation$plots_failed))
cat(sprintf("Success rate: %.1f%%\n", result$phase_results$plot_generation$success_rate))

cat("\n\n=== INDIVIDUAL PLOT STATUS ===\n")
for (i in seq_along(result$phase_results$plot_generation$results)) {
  r <- result$phase_results$plot_generation$results[[i]]
  cat(sprintf("\nPlot %d: %s\n", i, r$plot_id))
  cat(sprintf("  Status: %s\n", r$status))
  cat(sprintf("  Quality: %.0f/100\n", r$quality_score))
  
  if (length(r$errors) > 0) {
    cat("  ERRORS:\n")
    for (err in r$errors) {
      cat(sprintf("    - %s\n", err))
    }
  }
  
  if (length(r$warnings) > 0) {
    cat("  WARNINGS:\n")
    for (warn in r$warnings) {
      cat(sprintf("    - %s\n", warn))
    }
  }
}

cat("\n\n=== CHECKING WHICH PLOTS REGISTERED ===\n")
registry <- yaml::read_yaml(here::here("R", "config", "artifact_registry.yaml"))
plot_artifacts <- Filter(
  function(x) x$type == "ridgeline_plots",
  registry$artifacts
)
cat(sprintf("Registered plots: %d\n", length(plot_artifacts)))
for (name in names(plot_artifacts)) {
  cat(sprintf("  - %s (palette: %s)\n", name, plot_artifacts[[name]]$metadata$palette))
}
