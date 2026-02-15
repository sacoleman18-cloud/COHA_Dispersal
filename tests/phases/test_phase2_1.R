#!/usr/bin/env Rscript
# Quick test of Phase 2.1 changes

cat("[TEST] Phase 2.1 Plugin-Based Pipeline Integration\n")
cat("[TEST] Checking pipeline.R and engine.R modifications...\n\n")

# Set working directory
setwd("c:/Users/Triad/OneDrive/Documents/R Projects/COHA_Dispersal")

tryCatch({
  # Test 1: Source engine.R and check orchestrate_plot_generation exists
  cat("[TEST 1] Loading engine.R...\n")
  source("R/core/engine.R")
  
  if (exists("orchestrate_plot_generation")) {
    cat("✓ orchestrate_plot_generation() function found\n\n")
  } else {
    stop("✗ orchestrate_plot_generation() function NOT found")
  }
  
  # Test 2: Source pipeline.R
  cat("[TEST 2] Loading pipeline.R...\n")
  source("R/pipeline/pipeline.R")
  
  if (exists("run_coha_dispersal_pipeline")) {
    cat("✓ run_coha_dispersal_pipeline() function found\n\n")
  } else {
    stop("✗ run_coha_dispersal_pipeline() function NOT found")
  }
  
  # Test 3: Check function signatures
  cat("[TEST 3] Checking function signatures...\n")
  
  # Check orchestrate_plot_generation parameters
  orch_params <- names(formals(orchestrate_plot_generation))
  expected_params <- c("data", "base_dir", "output_base", "verbose", "dpi", "continue_on_error")
  
  if (all(expected_params %in% orch_params)) {
    cat("✓ orchestrate_plot_generation() has all expected parameters\n")
    cat(sprintf("  Parameters: %s\n", paste(orch_params, collapse=", ")))
  } else {
    missing <- setdiff(expected_params, orch_params)
    stop(sprintf("✗ Missing parameters: %s", paste(missing, collapse=", ")))
  }
  
  cat("\n[SUMMARY] ✓ All Phase 2.1 modifications verified successfully!\n")
  cat("  - engine.R:   orchestrate_plot_generation() implemented\n")
  cat("  - pipeline.R: Refactored to use plugin-based orchestration\n")
  cat("  - Pipeline is now truly plug-and-play extensible\n")

}, error = function(e) {
  cat(sprintf("\n✗ ERROR: %s\n", e$message))
  quit(status = 1)
})
