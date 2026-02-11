# ==============================================================================
# tests/test_edge_cases.R
# ==============================================================================
# PURPOSE: Edge case testing (corrupt data, missing files, etc.)
# DEPENDS: R/functions/phase3_data_operations.R
# ==============================================================================

cat("\n[TEST] Edge Cases\n")
cat("="*60, "\n")

# Source required modules
source(here::here("R", "functions", "phase3_data_operations.R"))
source(here::here("R", "functions", "robustness.R"))
source(here::here("R", "functions", "logging.R"))
source(here::here("R", "functions", "assertions.R"))
source(here::here("R", "functions", "utilities.R"))

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
      writeLines("mass,year,dispersed,origin", empty_file)
      
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
    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 3: Missing Required Columns\n# =============================================================================\ntest_missing_columns <- function() {\n  cat(\"\\n  Test 3: Missing required columns... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      # Create CSV with missing \"dispersed\" column\n      missing_col_file <- tempfile(fileext = \".csv\")\n      writeLines(c(\n        \"mass,year,origin\",\n        \"100,2020,A\",\n        \"150,2021,B\"\n      ), missing_col_file)\n      \n      result <- load_and_validate_data(\n        file_path = missing_col_file,\n        required_columns = c(\"mass\", \"year\", \"dispersed\", \"origin\"),\n        verbose = FALSE\n      )\n      \n      stopifnot(\n        result$status == \"failed\",\n        length(result$errors) > 0,\n        grepl(\"dispersed\", paste(result$errors, collapse = \" \"))\n      )\n      \n      file.remove(missing_col_file)\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 4: High NA Rate\n# =============================================================================\ntest_high_na_rate <- function() {\n  cat(\"\\n  Test 4: High NA rate detection... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      # Create CSV with many NAs\n      sparse_file <- tempfile(fileext = \".csv\")\n      writeLines(c(\n        \"mass,year,dispersed,origin\",\n        \",2020,,A\",\n        \"100,,yes,\",\n        \",2021,,B\",\n        \"150,,no,\",\n        \",2022,,A\",\n        \"200,,yes,\",\n        \",2023,,B\",\n        \"175,,no,\",\n        \",2024,,A\",\n        \"225,,yes,\"\n      ), sparse_file)\n      \n      result <- load_and_validate_data(\n        file_path = sparse_file,\n        verbose = FALSE\n      )\n      \n      # Quality score should be low due to high NA rate\n      if (result$status != \"failed\") {\n        stopifnot(\n          result$quality_score < 75,\n          result$quality_metrics$completeness < 75\n        )\n      }\n      \n      file.remove(sparse_file)\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 5: Outlier Detection\n# =============================================================================\ntest_outlier_detection <- function() {\n  cat(\"\\n  Test 5: Outlier detection... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      # Create data with outliers (mass <0 or >1000, year <1980 or >2027)\n      outlier_file <- tempfile(fileext = \".csv\")\n      writeLines(c(\n        \"mass,year,dispersed,origin\",\n        \"-100,2020,yes,A\",\n        \"150,2021,no,B\",\n        \"2000,2022,yes,A\",\n        \"200,1900,no,B\",\n        \"250,2050,yes,A\",\n        \"175,2023,no,B\"\n      ), outlier_file)\n      \n      result <- load_and_validate_data(\n        file_path = outlier_file,\n        verbose = FALSE\n      )\n      \n      # Should detect outliers\n      if (result$status != \"failed\") {\n        stopifnot(\n          result$quality_metrics$outliers_detected > 0,\n          length(result$quality_metrics$warnings) > 0\n        )\n      }\n      \n      file.remove(outlier_file)\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 6: Corrupted CSV\n# =============================================================================\ntest_corrupted_csv <- function() {\n  cat(\"\\n  Test 6: Corrupted CSV handling... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      # Create CSV with inconsistent column counts\n      corrupt_file <- tempfile(fileext = \".csv\")\n      writeLines(c(\n        \"mass,year,dispersed,origin\",\n        \"100,2020,yes\",  # Missing origin\n        \"150,2021\",      # Missing 2 columns\n        \"200,2022,no,B,EXTRA\"  # Too many columns\n      ), corrupt_file)\n      \n      result <- load_and_validate_data(\n        file_path = corrupt_file,\n        verbose = FALSE\n      )\n      \n      # Should handle gracefully (might fail or succeed with errors)\n      stopifnot(\n        result$status %in% c(\"success\", \"partial\", \"failed\"),\n        !is.na(result$quality_score)\n      )\n      \n      file.remove(corrupt_file)\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Test 7: Invalid Data Types\n# =============================================================================\ntest_invalid_data_types <- function() {\n  cat(\"\\n  Test 7: Invalid data types... \")\n  test_count <<- test_count + 1\n  \n  tryCatch(\n    {\n      # Create CSV with non-numeric mass values\n      invalid_file <- tempfile(fileext = \".csv\")\n      writeLines(c(\n        \"mass,year,dispersed,origin\",\n        \"abc,2020,yes,A\",\n        \"150,2021,no,B\",\n        \"200,xyz,yes,A\",\n        \"175,2023,no,B\"\n      ), invalid_file)\n      \n      result <- load_and_validate_data(\n        file_path = invalid_file,\n        verbose = FALSE\n      )\n      \n      # Should still load but with lower quality or partial status\n      stopifnot(\n        result$status %in% c(\"success\", \"partial\", \"failed\"),\n        !is.na(result$quality_score)\n      )\n      \n      file.remove(invalid_file)\n      \n      cat(\"✓\\n\")\n      passed_count <<- passed_count + 1\n    },\n    error = function(e) {\n      cat(sprintf(\"✗ %s\\n\", e$message))\n    }\n  )\n}\n\n# =============================================================================\n# Run All Tests\n# =============================================================================\ntest_missing_file()\ntest_empty_file()\ntest_missing_columns()\ntest_high_na_rate()\ntest_outlier_detection()\ntest_corrupted_csv()\ntest_invalid_data_types()\n\ncat(sprintf(\"\\n  Summary: %d/%d passed\\n\", passed_count, test_count))\ncat(\"=\"*60, \"\\n\\n\")\n\n# Return counts for aggregation\ninvisible(list(passed = passed_count, total = test_count))\n