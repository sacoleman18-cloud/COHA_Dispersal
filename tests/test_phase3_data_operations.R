# ==============================================================================
# tests/test_phase3_data_operations.R
# ==============================================================================
# PURPOSE: Unit tests for Phase 3A data quality and operations
# DEPENDS: R/functions/data_quality.R, R/functions/data_operations.R
# ==============================================================================

cat("\n[TEST] Phase 3A: Data Quality & Operations\n")
cat(strrep("=", 60), "\n")

# Source required modules
source(here::here("R", "functions", "data_quality.R"))
source(here::here("R", "functions", "data_operations.R"))
source(here::here("R", "functions", "robustness.R"))
source(here::here("R", "functions", "logging.R"))
source(here::here("core", "assertions.R"))
source(here::here("R", "functions", "utilities.R"))

test_count <- 0
passed_count <- 0

# =============================================================================
# Test 1: Compute Quality Metrics
# =============================================================================
test_compute_quality_metrics <- function() {
  cat("\n  Test 1: Quality metrics computation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create test data with known properties
      df <- data.frame(
        mass = c(100, 150, 200, NA, 175),
        year = c(2020, 2021, 2022, 2023, NA),
        dispersed = c("yes", "no", "yes", "yes", "no")
      )
      
      metrics <- compute_quality_metrics(
        df,
        required_columns = c("mass", "year", "dispersed"),
        min_rows = 3,
        verbose = FALSE
      )
      
      # 5 rows * 3 cols = 15 cells, 1 NA = 14/15 = 93.3% complete
      stopifnot(
        !is.na(metrics$completeness),
        metrics$completeness >= 85,
        metrics$completeness <= 100,
        !is.na(metrics$schema_match),
        metrics$schema_match == 100,  # All columns present
        !is.na(metrics$row_count_ok),
        metrics$row_count_ok == TRUE,
        !is.na(metrics$outliers_detected)
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
# Test 2: Calculate Quality Score
# =============================================================================
test_calculate_quality_score <- function() {
  cat("\n  Test 2: Quality score aggregation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      metrics <- list(
        completeness = 95,
        schema_match = 100,
        row_count_ok = TRUE,
        outliers_detected = 0
      )
      
      score <- calculate_quality_score(metrics)
      
      stopifnot(
        !is.na(score),
        is.numeric(score),
        score >= 0,
        score <= 100,
        score > 80
      )
      
      # Test boundary conditions
      metrics_low <- list(
        completeness = 20,
        schema_match = 50,
        row_count_ok = FALSE,
        outliers_detected = 10
      )
      score_low <- calculate_quality_score(metrics_low)
      stopifnot(score_low < score)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 3: Load and Validate Data
# =============================================================================
test_load_and_validate_data <- function() {
  cat("\n  Test 3: Load and validate with quality... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Use fixture file
      fixture_path <- here::here("tests", "fixtures", "valid_data.csv")
      
      result <- load_and_validate_data(
        file_path = fixture_path,
        required_columns = c("mass", "year", "dispersed"),
        min_rows = 10,
        verbose = FALSE
      )
      
      stopifnot(
        result$status %in% c("success", "partial", "failed"),
        !is.null(result$message),
        !is.null(result$timestamp),
        !is.na(result$quality_score),
        !is.null(result$duration_secs)
      )
      
      # If successful, verify data
      if (result$status == "success") {
        stopifnot(
          !is.null(result$data),
          is.data.frame(result$data),
          result$rows == nrow(result$data),
          result$columns == ncol(result$data),
          length(result$errors) == 0 ||
            result$quality_score < 75
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
# Test 4: Assess Data Quality
# =============================================================================
test_assess_data_quality <- function() {
  cat("\n  Test 4: Mid-pipeline quality assessment... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create test data in memory
      set.seed(42)
      df <- data.frame(
        mass = rnorm(100, mean = 300, sd = 50),
        year = sample(2000:2020, 100, replace = TRUE),
        dispersed = sample(c("yes", "no"), 100, replace = TRUE)
      )
      
      result <- assess_data_quality(
        df,
        required_columns = c("mass", "year", "dispersed"),
        min_rows = 50,
        verbose = FALSE
      )
      
      stopifnot(
        !is.na(result$quality_score),
        is.numeric(result$quality_score),
        !is.null(result$quality_metrics),
        !is.null(result$interpretation),
        !is.null(result$report),
        is.character(result$report)
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
test_compute_quality_metrics()
test_calculate_quality_score()
test_load_and_validate_data()
test_assess_data_quality()

cat(sprintf("\n  Summary: %d/%d passed\n", passed_count, test_count))
cat(strrep("=", 60), "\n\n")

# Return counts for aggregation
invisible(list(passed = passed_count, total = test_count))
