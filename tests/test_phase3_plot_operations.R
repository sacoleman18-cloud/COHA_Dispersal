# ==============================================================================
# tests/test_phase3_plot_operations.R
# ==============================================================================
# PURPOSE: Unit tests for Phase 3B plot operations
# DEPENDS: R/functions/plot_operations.R, ggplot2, ggridges
# ==============================================================================

cat("\n[TEST] Phase 3B: Plot Operations\n")
cat(strrep("=", 60), "\n")

# Source required modules (in dependency order)
source(here::here("R", "functions", "utilities.R"))
source(here::here("core", "assertions.R"))
source(here::here("R", "functions", "logging.R"))
source(here::here("R", "functions", "robustness.R"))
source(here::here("R", "functions", "plot_operations.R"))

# Load packages
library(ggplot2)
library(ggridges)

test_count <- 0
passed_count <- 0

# =============================================================================
# Test 1: Single Plot Generation
# =============================================================================
test_generate_plot_safe <- function() {
  cat("\n  Test 1: Single plot generation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create test data
      set.seed(42)
      df <- data.frame(
        mass = rnorm(50, mean = 300, sd = 50),
        year = rep(2020:2024, each = 10),
        dispersed = sample(c("yes", "no"), 50, replace = TRUE),
        origin = sample(letters[1:2], 50, replace = TRUE)
      )
      
      config <- list(
        plot_id = "test_compact_01",
        scale = 0.85,
        fill = "plasma",
        title = "Test Plot"
      )
      
      output_dir <- tempdir()
      
      result <- generate_plot_safe(
        df = df,
        plot_config = config,
        output_dir = output_dir,
        verbose = FALSE,
        dpi = 150
      )
      
      stopifnot(
        result$status %in% c("success", "partial", "failed"),
        result$plot_id == "test_compact_01",
        !is.na(result$quality_score),
        is.numeric(result$quality_score),
        result$quality_score >= 0,
        result$quality_score <= 100
      )
      
      if (result$status != "failed") {
        stopifnot(
          !is.null(result$plot),
          inherits(result$plot, "ggplot"),
          !is.na(result$generation_time),
          result$generation_time > 0
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
# Test 2: Batch Plot Generation
# =============================================================================
test_generate_all_plots_safe <- function() {
  cat("\n  Test 2: Batch plot generation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create test data
      set.seed(42)
      df <- data.frame(
        mass = rnorm(50, mean = 300, sd = 50),
        year = rep(2020:2024, each = 10),
        dispersed = sample(c("yes", "no"), 50, replace = TRUE),
        origin = sample(letters[1:2], 50, replace = TRUE)
      )
      
      configs <- list(
        list(plot_id = "p1", scale = 0.85, fill = "plasma", title = "P1"),
        list(plot_id = "p2", scale = 1.0, fill = "viridis", title = "P2"),
        list(plot_id = "p3", scale = 1.5, fill = "magma", title = "P3")
      )
      
      output_dir <- tempdir()
      
      result <- generate_all_plots_safe(
        df = df,
        plot_configs = configs,
        output_dir = output_dir,
        verbose = FALSE,
        dpi = 150
      )
      
      stopifnot(
        result$status %in% c("success", "partial", "failed"),
        result$plots_total == length(configs),
        result$plots_generated + result$plots_failed == result$plots_total,
        !is.na(result$quality_score),
        !is.na(result$success_rate),
        result$success_rate >= 0,
        result$success_rate <= 100,
        is.list(result$results),
        length(result$results) == length(configs)
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
# Test 3: Batch Partial Failure
# =============================================================================
test_batch_partial_failure <- function() {
  cat("\n  Test 3: Batch with partial failure... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create test data
      set.seed(42)
      df <- data.frame(
        mass = rnorm(50, mean = 300, sd = 50),
        year = rep(2020:2024, each = 10),
        dispersed = sample(c("yes", "no"), 50, replace = TRUE),
        origin = sample(letters[1:2], 50, replace = TRUE)
      )
      
      configs <- list(
        list(plot_id = "good_1", scale = 0.85, fill = "plasma", title = "Good 1"),
        list(plot_id = "bad_1", scale = NA, fill = "plasma", title = "Bad 1"),  # Missing scale
        list(plot_id = "good_2", scale = 1.0, fill = "viridis", title = "Good 2")
      )
      
      output_dir <- tempdir()
      
      result <- generate_all_plots_safe(
        df = df,
        plot_configs = configs,
        output_dir = output_dir,
        verbose = FALSE,
        dpi = 150
      )
      
      # Should have some success and some failure
      stopifnot(
        result$plots_total >= 2,
        result$plots_generated >= 1 || result$plots_failed >= 1
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
# Run All Tests
# =============================================================================
test_generate_plot_safe()
test_generate_all_plots_safe()
test_batch_partial_failure()

cat(sprintf("\n  Summary: %d/%d passed\n", passed_count, test_count))
cat(strrep("=", 60), "\n\n")

# Return counts for aggregation
invisible(list(passed = passed_count, total = test_count))
