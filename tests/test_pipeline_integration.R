# ==============================================================================
# tests/test_pipeline_integration.R
# ==============================================================================
# PURPOSE: Integration tests for complete pipeline
# DEPENDS: R/pipeline/pipeline.R (all modules)
# ==============================================================================

cat("\n[TEST] Pipeline Integration\n")
cat("="*60, "\n")

# Source complete pipeline
source(here::here("R", "pipeline", "pipeline.R"))

test_count <- 0
passed_count <- 0

# =============================================================================
# Test 1: Complete Pipeline Run
# =============================================================================
test_complete_pipeline <- function() {
  cat("\n  Test 1: Complete pipeline execution... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Run complete pipeline with verbose=FALSE for faster testing
      result <- run_pipeline(verbose = FALSE)
      
      # Verify comprehensive result structure
      stopifnot(
        !is.null(result$pipeline_name),
        result$status %in% c("success", "partial", "failed"),
        !is.null(result$quality_score),
        is.numeric(result$quality_score),
        result$quality_score >= 0,
        result$quality_score <= 100,
        !is.null(result$phase_results),
        is.list(result$phase_results),
        !is.null(result$phase_results$data_load),
        !is.null(result$phase_results$plot_generation),
        !is.null(result$plots_generated),
        is.numeric(result$plots_generated),
        !is.null(result$output_dir),
        !is.na(result$duration_secs),
        is.numeric(result$duration_secs),
        result$duration_secs > 0,
        !is.null(result$timestamp),
        inherits(result$timestamp, "POSIXct"),
        !is.null(result$log_file),
        is.character(result$log_file)
      )
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 2: Data Phase Results
# =============================================================================
test_data_phase_results <- function() {
  cat("\n  Test 2: Data phase result structure... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- run_pipeline(verbose = FALSE)
      
      data_result <- result$phase_results$data_load
      
      stopifnot(
        !is.null(data_result$status),
        data_result$status %in% c("success", "partial", "failed"),
        !is.null(data_result$quality_score),
        !is.null(data_result$rows),
        is.numeric(data_result$rows),
        !is.null(data_result$columns),
        is.numeric(data_result$columns),
        !is.null(data_result$quality_metrics),
        is.list(data_result$quality_metrics)
      )
      
      # If data loaded, should have data frame
      if (data_result$status != "failed") {
        stopifnot(
          !is.null(data_result$data),
          is.data.frame(data_result$data),
          data_result$rows == nrow(data_result$data),
          data_result$columns == ncol(data_result$data)
        )
      }
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 3: Plot Phase Results\n# =============================================================================
test_plot_phase_results <- function() {
  cat("\n  Test 3: Plot phase result structure... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {\n      result <- run_pipeline(verbose = FALSE)\n      \n      plot_result <- result$phase_results$plot_generation\n      \n      stopifnot(\n        !is.null(plot_result$status),\n        plot_result$status %in% c(\"success\", \"partial\", \"failed\"),\n        !is.null(plot_result$plots_generated),\n        is.numeric(plot_result$plots_generated),\n        !is.null(plot_result$plots_failed),\n        is.numeric(plot_result$plots_failed),\n        !is.null(plot_result$plots_total),\n        plot_result$plots_total == plot_result$plots_generated + plot_result$plots_failed,\n        !is.null(plot_result$quality_score),\n        is.numeric(plot_result$quality_score),\n        !is.null(plot_result$success_rate),\n        is.numeric(plot_result$success_rate),\n        plot_result$success_rate >= 0,\n        plot_result$success_rate <= 100\n      )\n      \n      # Check individual results\n      if (length(plot_result$results) > 0) {\n        stopifnot(\n          is.list(plot_result$results),\n          length(plot_result$results) == plot_result$plots_total\n        )\n      }\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 4: Quality Score Aggregation\n# =============================================================================\ntest_quality_score_aggregation <- function() {\n  cat(\"\\n  Test 4: Quality score aggregation... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      result <- run_pipeline(verbose = FALSE)\n      \n      data_quality <- result$phase_results$data_load$quality_score\n      plot_quality <- result$phase_results$plot_generation$quality_score\n      overall <- result$quality_score\n      \n      # Overall should be weighted: data 40%, plots 60%\n      expected_overall <- (data_quality * 0.4) + (plot_quality * 0.6)\n      \n      stopifnot(\n        !is.na(overall),\n        is.numeric(overall),\n        overall >= 0,\n        overall <= 100,\n        abs(overall - expected_overall) < 1  # Allow small rounding difference\n      )\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 5: Output Directory Valid\n# =============================================================================\ntest_output_directory_valid <- function() {\n  cat(\"\\n  Test 5: Output directory created... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      result <- run_pipeline(verbose = FALSE)\n      \n      # Output directory should exist\n      stopifnot(\n        !is.null(result$output_dir),\n        is.character(result$output_dir),\n        dir.exists(result$output_dir)\n      )\n      \n      # If plots were generated, should have PNG files\n      if (result$plots_generated > 0) {\n        png_files <- list.files(result$output_dir, pattern = \"\\\\.png$\")\n        stopifnot(length(png_files) >= result$plots_generated)\n      }\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 6: Log File Generated\n# =============================================================================\ntest_log_file_generated <- function() {\n  cat(\"\\n  Test 6: Log file generated... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      result <- run_pipeline(verbose = FALSE)\n      \n      stopifnot(\n        !is.null(result$log_file),\n        is.character(result$log_file),\n        file.exists(result$log_file)\n      )\n      \n      # Log should have some content\n      log_content <- readLines(result$log_file, warn = FALSE)\n      stopifnot(length(log_content) > 0)\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Run All Tests\n# =============================================================================\ntest_complete_pipeline()\ntest_data_phase_results()\ntest_plot_phase_results()\ntest_quality_score_aggregation()\ntest_output_directory_valid()\ntest_log_file_generated()\n\ncat(sprintf(\"\\n  Summary: %d/%d passed\\n\", passed_count, test_count))\ncat(\"=\"*60, \"\\n\\n\")\n\n# Return counts for aggregation\ninvisible(list(passed = passed_count, total = test_count))\n