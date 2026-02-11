#!/usr/bin/env Rscript
# ==============================================================================
# run_analysis.R
# ==============================================================================
# Execute complete COHA Dispersal analysis pipeline
# ==============================================================================

# Set working directory to project root
setwd(here::here())

# Load pipeline orchestrator
source("R/pipeline/pipeline.R")

# Run the complete pipeline
cat("\n")
cat("================================================================================\n")
cat("COHA DISPERSAL ANALYSIS - RUNNING COMPLETE PIPELINE\n")
cat("================================================================================\n")
cat("\n")

result <- run_pipeline(verbose = TRUE)

# Print summary
cat("\n")
cat("================================================================================\n")
cat("PIPELINE EXECUTION SUMMARY\n")
cat("================================================================================\n")
cat(sprintf("Status: %s\n", result$status))
cat(sprintf("Data Quality Score: %.0f/100\n", result$data_quality_score))
plots_generated <- result$plots_generated %||% 0
plots_failed <- result$plots_failed %||% 0
plots_total <- plots_generated + plots_failed
success_rate <- if (plots_total > 0) (plots_generated / plots_total) * 100 else 0
cat(sprintf("Plots: %d/%d generated, %d failed (%.0f%% success)\n",
			plots_generated, plots_total, plots_failed, success_rate))
cat(sprintf("Pipeline Quality: %.0f/100\n", result$quality_score %||% 0))
cat(sprintf("Duration: %.2f seconds\n", result$duration_secs))
cat(sprintf("Output Directory: %s\n", result$output_dir))
cat(sprintf("Log File: %s\n", result$log_file))
cat("================================================================================\n")
cat("\n")

invisible(result)
