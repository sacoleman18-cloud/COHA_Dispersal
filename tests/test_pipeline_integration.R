# ==============================================================================
# tests/test_pipeline_integration.R
# ==============================================================================
# PURPOSE: Integration tests for complete pipeline
# DEPENDS: R/pipeline/pipeline.R (all modules)
# ==============================================================================

cat("\n[TEST] Pipeline Integration\n")
cat(strrep("=", 60), "\n")

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
    {
      result <- run_pipeline(verbose = FALSE)
      
      plot_result <- result$phase_results$plot_generation
      
      stopifnot(
        !is.null(plot_result$status),
        plot_result$status %in% c("success", "partial", "failed"),
        !is.null(plot_result$plots_generated),
        is.numeric(plot_result$plots_generated),
        !is.null(plot_result$plots_failed),
        is.numeric(plot_result$plots_failed),
        !is.null(plot_result$plots_total),
        plot_result$plots_total == plot_result$plots_generated + plot_result$plots_failed,
        !is.null(plot_result$quality_score),
        is.numeric(plot_result$quality_score),
        !is.null(plot_result$success_rate),
        is.numeric(plot_result$success_rate),
        plot_result$success_rate >= 0,
        plot_result$success_rate <= 100
      )
      
      # Check individual results
      if (length(plot_result$results) > 0) {
        stopifnot(
          is.list(plot_result$results),
          length(plot_result$results) == plot_result$plots_total
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
# Test 4: Quality Score Aggregation
# =============================================================================
test_quality_score_aggregation <- function() {
  cat("\n  Test 4: Quality score aggregation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- run_pipeline(verbose = FALSE)
      
      data_quality <- result$phase_results$data_load$quality_score
      plot_quality <- result$phase_results$plot_generation$quality_score
      overall <- result$quality_score
      
      # Overall should be weighted: data 40%, plots 60%
      expected_overall <- (data_quality * 0.4) + (plot_quality * 0.6)
      
      stopifnot(
        !is.na(overall),
        is.numeric(overall),
        overall >= 0,
        overall <= 100,
        abs(overall - expected_overall) < 1  # Allow small rounding difference
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
# Test 5: Output Directory Valid
# =============================================================================
test_output_directory_valid <- function() {
  cat("\n  Test 5: Output directory created... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- run_pipeline(verbose = FALSE)
      
      # Output directory should exist
      stopifnot(
        !is.null(result$output_dir),
        is.character(result$output_dir),
        dir.exists(result$output_dir)
      )
      
      # If plots were generated, should have PNG files
      if (result$plots_generated > 0) {
        png_files <- list.files(result$output_dir, pattern = "\\.png$")
        stopifnot(length(png_files) >= result$plots_generated)
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
# Test 6: Log File Generated
# =============================================================================
test_log_file_generated <- function() {
  cat("\n  Test 6: Log file generated... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- run_pipeline(verbose = FALSE)
      
      stopifnot(
        !is.null(result$log_file),
        is.character(result$log_file),
        file.exists(result$log_file)
      )
      
      # Log should have some content
      log_content <- readLines(result$log_file, warn = FALSE)
      stopifnot(length(log_content) > 0)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Run All Tests
# =============================================================================
test_complete_pipeline()
test_data_phase_results()
test_plot_phase_results()
test_quality_score_aggregation()
test_output_directory_valid()
test_log_file_generated()

cat(sprintf("\n  Summary: %d/%d passed\n", passed_count, test_count))
cat(strrep("=", 60), "\n\n")

# Return counts for aggregation
invisible(list(passed = passed_count, total = test_count))
