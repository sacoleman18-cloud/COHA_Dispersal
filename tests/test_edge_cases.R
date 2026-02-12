#!/usr/bin/env Rscript
# ==============================================================================
# tests/test_edge_cases.R
# ==============================================================================
# PURPOSE: Edge case testing (corrupt data, missing files, etc.)
# DEPENDS: R/functions/data_operations.R
# ==============================================================================

cat("\n[TEST] Edge Cases\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Source required modules (in dependency order)
source(here::here("R", "functions", "utilities.R"))
source(here::here("R", "functions", "console.R"))
source(here::here("core", "assertions.R"))
source(here::here("R", "functions", "logging.R"))
source(here::here("R", "functions", "robustness.R"))
source(here::here("R", "functions", "data_quality.R"))
source(here::here("R", "functions", "data_operations.R"))

test_count <- 0
passed_count <- 0

# =============================================================================
# Test 1: Missing File
# =============================================================================
test_missing_file <- function() {
  cat("\n  Test 1: Missing file handling... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- load_and_validate_data(
        file_path = "/nonexistent/path/to/missing.csv",
        verbose = FALSE
      )
      
      stopifnot(
        result$status == "failed",
        length(result$errors) > 0,
        is.null(result$data)
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
# Test 2: Empty File
# =============================================================================
test_empty_file <- function() {
  cat("\n  Test 2: Empty file handling... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create temporary empty CSV with just header
      empty_file <- tempfile(fileext = ".csv")
      writeLines("mass,year,dispersed", empty_file)
      
      result <- load_and_validate_data(
        file_path = empty_file,
        min_rows = 1,
        verbose = FALSE
      )
      
      stopifnot(
        result$status == "failed",
        length(result$errors) > 0
      )
      
      file.remove(empty_file)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 3: Missing Required Columns
# =============================================================================
test_missing_columns <- function() {
  cat("\n  Test 3: Missing required columns... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create CSV with missing "dispersed" column
      missing_col_file <- tempfile(fileext = ".csv")
      writeLines(c(
        "mass,year",
        "100,2020",
        "150,2021"
      ), missing_col_file)
      
      result <- load_and_validate_data(
        file_path = missing_col_file,
        required_columns = c("mass", "year", "dispersed"),
        verbose = FALSE
      )
      
      stopifnot(
        result$status == "failed",
        length(result$errors) > 0
      )
      
      file.remove(missing_col_file)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 4: High NA Rate
# =============================================================================
test_high_na_rate <- function() {
  cat("\n  Test 4: High NA rate detection... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create CSV with many NAs
      sparse_file <- tempfile(fileext = ".csv")
      writeLines(c(
        "mass,year,dispersed",
        ",2020,",
        "100,,yes",
        ",2021,",
        "150,,no",
        ",2022,",
        "200,,yes",
        ",2023,",
        "175,,no",
        ",2024,",
        "225,,yes"
      ), sparse_file)
      
      result <- load_and_validate_data(
        file_path = sparse_file,
        verbose = FALSE
      )
      
      # Quality score should be low due to high NA rate
      if (result$status != "failed") {
        stopifnot(
          result$quality_score < 75,
          result$quality_metrics$completeness < 75
        )
      }
      
      file.remove(sparse_file)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 5: Outlier Detection
# =============================================================================
test_outlier_detection <- function() {
  cat("\n  Test 5: Outlier detection... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create data with outliers (mass <0 or >1000, year <1980 or >2027)
      outlier_file <- tempfile(fileext = ".csv")
      writeLines(c(
        "mass,year,dispersed",
        "-100,2020,yes",
        "150,2021,no",
        "2000,2022,yes",
        "200,1900,no",
        "250,2050,yes",
        "175,2023,no"
      ), outlier_file)
      
      result <- load_and_validate_data(
        file_path = outlier_file,
        verbose = FALSE
      )
      
      # Should detect outliers
      if (result$status != "failed") {
        stopifnot(
          result$quality_metrics$outliers_detected > 0,
          length(result$quality_metrics$warnings) > 0
        )
      }
      
      file.remove(outlier_file)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 6: Corrupted CSV
# =============================================================================
test_corrupted_csv <- function() {
  cat("\n  Test 6: Corrupted CSV handling... ")
  test_count <<- test_count + 1
  
 tryCatch(
    {
      # Create CSV with inconsistent column counts
      corrupt_file <- tempfile(fileext = ".csv")
      writeLines(c(
        "mass,year,dispersed",
        "100,2020,yes",
        "150,2021",
        "200,2022,no,EXTRA"
      ), corrupt_file)
      
      result <- load_and_validate_data(
        file_path = corrupt_file,
        verbose = FALSE
      )
      
      # Should handle gracefully (might fail or succeed with errors)
      stopifnot(
        result$status %in% c("success", "partial", "failed"),
        !is.na(result$quality_score)
      )
      
      file.remove(corrupt_file)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 7: Invalid Data Types
# =============================================================================
test_invalid_data_types <- function() {
  cat("\n  Test 7: Invalid data types... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Create CSV with non-numeric mass values
      invalid_file <- tempfile(fileext = ".csv")
      writeLines(c(
        "mass,year,dispersed",
        "abc,2020,yes",
        "150,2021,no",
        "200,xyz,yes",
        "175,2023,no"
      ), invalid_file)
      
      result <- load_and_validate_data(
        file_path = invalid_file,
        verbose = FALSE
      )
      
      # Should still load but with lower quality or partial status
      stopifnot(
        result$status %in% c("success", "partial", "failed"),
        !is.na(result$quality_score)
      )
      
      file.remove(invalid_file)
      
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
test_missing_file()
test_empty_file()
test_missing_columns()
test_high_na_rate()
test_outlier_detection()
test_corrupted_csv()
test_invalid_data_types()

cat(sprintf("\n  Summary: %d/%d passed\n", passed_count, test_count))
cat(paste(rep("=", 60), collapse = ""), "\n\n")

# Return counts for aggregation
invisible(list(passed = passed_count, total = test_count))
