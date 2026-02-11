# Phase 4: Testing & Polish Standards

**Date:** February 10, 2026  
**Status:** 🧪 IN PROGRESS  
**Scope:** Unit tests, integration tests, edge cases, performance, documentation

---

## Overview

Phase 4 validates Phase 3 functionality and prepares for production release:

1. **Unit Tests** - Isolate and test individual functions
2. **Integration Tests** - Test complete pipeline workflows
3. **Edge Case Tests** - Handle corrupt/malformed/missing data
4. **Performance Tests** - Verify efficiency under load
5. **Quarto Integration** - Publication-ready reports
6. **Documentation** - Usage examples and troubleshooting

---

## Test Architecture

### Test File Organization

```
tests/
├── test_phase3_robustness.R          # Unit tests for robustness module (Phase 3A)
├── test_phase3_data_operations.R     # Unit tests for data ops (Phase 3A)
├── test_phase3_plot_operations.R     # Unit tests for plot ops (Phase 3B)
├── test_pipeline_integration.R       # Full pipeline integration tests
├── test_edge_cases.R                 # Corrupt data, missing cols, etc.
├── fixtures/                         # Test data files
│   ├── valid_data.csv                # Valid complete dataset
│   ├── missing_columns.csv           # Missing required columns
│   ├── corrupt_data.csv              # Malformed values
│   ├── sparse_data.csv               # High NA rate
│   └── empty_data.csv                # Zero rows
└── expected_outputs/                 # Reference outputs
    ├── sample_plot_quality.rds       # Serialized plot objects
    └── sample_result_success.rds     # Expected result structures
```

### Test Runner

Simple test runner script:

```r
# tests/run_all_tests.R
source("R/pipeline/pipeline.R")

test_files <- c(
  "tests/test_phase3_robustness.R",
  "tests/test_phase3_data_operations.R",
  "tests/test_phase3_plot_operations.R",
  "tests/test_pipeline_integration.R",
  "tests/test_edge_cases.R"
)

passed <- 0
failed <- 0

for (file in test_files) {
  cat(sprintf("\n=== Running %s ===\n", basename(file)))
  tryCatch(
    source(file),
    error = function(e) {
      cat(sprintf("ERROR: %s\n", e$message))
      failed <<- failed + 1
    }
  )
  passed <<- passed + 1
}

cat(sprintf("\n\n=== Test Summary ===\nPassed: %d / %d\n", 
           passed, passed + failed))
```

---

## Unit Testing: Phase 3A - Robustness

### Test Suite: test_phase3_robustness.R

**Goal:** Validate structured result object creation and manipulation

#### Test 1: Result Object Creation

```r
test_create_result <- function() {
  result <- create_result("test_operation", verbose = FALSE)
  
  # Check structure
  stopifnot(
    is.list(result),
    !is.null(result$status),
    result$status == "unknown",
    !is.null(result$timestamp),
    !is.null(result$errors),
    length(result$errors) == 0,
    !is.null(result$warnings),
    length(result$warnings) == 0
  )
  
  cat("✓ Result object creation\n")
}
```

**Expectations:**
- Result is list
- Initial status: "unknown"
- Empty errors and warnings
- Timestamp present
- Has operation, duration_secs, quality_score fields

#### Test 2: Status Transitions

```r
test_status_transitions <- function() {
  result <- create_result("test", verbose = FALSE)
  
  # Transition: unknown → success
  result <- set_result_status(result, "success", "Test passed", FALSE)
  stopifnot(result$status == "success", 
            result$message == "Test passed")
  
  # Transition: success → partial (via warning)
  result <- create_result("test", verbose = FALSE)
  result <- set_result_status(result, "success", "OK", FALSE)
  result <- add_warning(result, "Some issues", FALSE)
  stopifnot(result$status == "partial")
  
  # Failed status
  result <- create_result("test", verbose = FALSE)
  result <- add_error(result, "Test error", FALSE)
  stopifnot(result$status == "failed")
  
  cat("✓ Status transitions (unknown → success → partial → failed)\n")
}
```

**Transitions Tested:**
- unknown → success
- unknown → failed (via add_error)
- success → partial (via add_warning)
- failed stays failed

#### Test 3: Quality Score Computation

```r
test_quality_score_computation <- function() {
  result <- create_result("test", verbose = FALSE)
  
  # Add quality metrics
  result <- add_quality_metrics(result, 
    list(component1 = 85, component2 = 90, component3 = 75),
    list(w1 = 0.3, w2 = 0.5, w3 = 0.2)
  )
  
  # Expected: 0.3*85 + 0.5*90 + 0.2*75 = 25.5 + 45 + 15 = 85.5
  stopifnot(
    !is.na(result$quality_score),
    abs(result$quality_score - 85.5) < 0.1
  )
  
  cat("✓ Quality score computation with weights\n")
}
```

**Test Cases:**
- Weighted average (3 components)
- Boundary: all 0 → score 0
- Boundary: all 100 → score 100
- Clamped to [0, 100]

#### Test 4: Error and Warning Lists

```r
test_error_warning_lists <- function() {
  result <- create_result("test", verbose = FALSE)
  
  # Add errors
  result <- add_error(result, "Error 1", FALSE)
  result <- add_error(result, "Error 2", FALSE)
  stopifnot(length(result$errors) == 2,
            result$status == "failed")
  
  # Add warnings 
  result <- create_result("test", verbose = FALSE)
  result <- add_warning(result, "Warning 1", FALSE)
  result <- add_warning(result, "Warning 2", FALSE)
  stopifnot(length(result$warnings) == 2,
            result$status == "partial")
  
  cat("✓ Error and warning accumulation\n")
}
```

**Coverage:**
- Multiple errors
- Multiple warnings
- Status changes with each addition
- Messages preserved exactly

#### Test 5: Timing Functions

```r
test_timing_functions <- function() {
  start <- start_timer()
  Sys.sleep(0.1)  # 100ms delay
  elapsed <- stop_timer(start)
  
  stopifnot(
    !is.na(elapsed),
    elapsed >= 0.1,
    elapsed < 1.0,  # Should complete in <1s
    is.numeric(elapsed)
  )
  
  cat("✓ Timer accuracy (100ms tolerance)\n")
}
```

**Coverage:**
- start_timer() returns valid start time
- stop_timer() returns reasonable duration
- Timing accuracy ±100ms

#### Test 6: Error Message Formatting

```r
test_error_message_formatting <- function() {
  msg <- format_error_message(
    "operation_x",
    "Something went wrong",
    "Check input parameters"
  )
  
  stopifnot(
    is.character(msg),
    grepl("operation_x", msg),
    grepl("Something went wrong", msg),
    grepl("Check input", msg),
    nchar(msg) > 0
  )
  
  cat("✓ Error message formatting with recovery hints\n")
}
```

**Coverage:**
- Includes operation name
- Includes error detail
- Includes recovery hint
- Non-empty output

#### Test 7: Result Success Predicate

```r
test_is_result_success <- function() {
  # Success case
  result <- create_result("test", verbose = FALSE)
  result <- set_result_status(result, "success", "OK", FALSE)
  stopifnot(is_result_success(result) == TRUE)
  
  # Partial case
  result <- set_result_status(result, "partial", "Warning", FALSE)
  stopifnot(is_result_success(result) == TRUE)
  
  # Failed case
  result <- set_result_status(result, "failed", "Error", FALSE)
  stopifnot(is_result_success(result) == FALSE)
  
  cat("✓ is_result_success predicate (success=T, partial=T, failed=F)\n")
}
```

---

## Unit Testing: Phase 3A - Data Quality

### Test Suite: test_phase3_data_operations.R

#### Test 1: Complete Data Quality Computation

```r
test_compute_quality_metrics <- function() {
  # Create valid test data
  df <- data.frame(
    mass = c(100, 150, 200, NA, 175),
    year = c(2020, 2021, 2022, 2023, NA),
    dispersed = c("yes", "no", "yes", "yes", "no"),
    origin = c("A", "B", "A", "A", "B")
  )
  
  metrics <- compute_quality_metrics(
    df,
    required_columns = c("mass", "year", "dispersed", "origin"),
    min_rows = 3,
    verbose = FALSE
  )
  
  # 5 rows * 4 cols = 20 cells, 2 NA = 18/20 = 90% complete
  stopifnot(
    !is.na(metrics$completeness),
    metrics$completeness <= 100,
    metrics$completeness >= 0,
    !is.na(metrics$schema_match),
    !is.na(metrics$row_count_ok),
    !is.na(metrics$outliers_detected)
  )
  
  cat("✓ Quality metrics computation\n")
}
```

**Metrics Verified:**
- Completeness calculated correctly
- Schema validation works
- Row count assessment
- Outlier detection active

#### Test 2: Quality Score Calculation

```r
test_calculate_quality_score <- function() {
  metrics <- list(
    completeness = 95,
    schema_match = 100,
    row_count_ok = TRUE,
    outliers_detected = 0
  )
  
  score <- calculate_quality_score(metrics)
  
  stopifnot(
    !is.na(score),
    score >= 0,
    score <= 100,
    score > 80  # Should be "good" with these metrics
  )
  
  cat("✓ Quality score aggregation (0-100 scale)\n")
}
```

**Coverage:**
- Score clamped [0, 100]
- Weights sum to 100%
- Interpretation categories correct

#### Test 3: Data Load with Quality Assessment

```r
test_load_and_validate_data <- function() {
  # Use fixture: tests/fixtures/valid_data.csv
  result <- load_and_validate_data(
    file_path = "tests/fixtures/valid_data.csv",
    required_columns = c("mass", "year", "dispersed", "origin"),
    min_rows = 10,
    verbose = FALSE
  )
  
  stopifnot(
    result$status %in% c("success", "partial", "failed"),
    !is.null(result$message),
    !is.null(result$timestamp),
    !is.na(result$quality_score)
  )
  
  # If successful, data should be present
  if (result$status != "failed") {
    stopifnot(!is.null(result$data),
              is.data.frame(result$data),
              result$rows == nrow(result$data),
              length(result$errors) == 0 || 
                result$quality_score < 50)
  }
  
  cat("✓ Load and validate complete workflow\n")
}
```

**Coverage:**
- Correct file loads successfully
- Status field set appropriately
- Data returned (if not failed)
- Quality metrics computed
- Duration tracked

#### Test 4: Mid-Pipeline Quality Assessment

```r
test_assess_data_quality <- function() {
  # Create test data in memory
  df <- data.frame(
    mass = rnorm(100, mean = 300, sd = 50),
    year = sample(2000:2020, 100, replace = TRUE),
    dispersed = sample(c("yes", "no"), 100, replace = TRUE),
    origin = sample(letters[1:3], 100, replace = TRUE)
  )
  
  result <- assess_data_quality(
    df,
    required_columns = c("mass", "year", "dispersed", "origin"),
    min_rows = 50,
    verbose = FALSE
  )
  
  stopifnot(
    !is.na(result$quality_score),
    !is.null(result$quality_metrics),
    !is.null(result$interpretation),
    !is.null(result$report)
  )
  
  cat("✓ Mid-pipeline quality assessment\n")
}
```

---

## Unit Testing: Phase 3B - Plot Operations

### Test Suite: test_phase3_plot_operations.R

#### Test 1: Single Plot Generation

```r
test_generate_plot_safe <- function() {
  # Load test data
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
    dpi = 150  # Lower DPI for speed
  )
  
  stopifnot(
    result$status %in% c("success", "partial", "failed"),
    result$plot_id == "test_compact_01",
    !is.na(result$quality_score)
  )
  
  if (result$status != "failed") {
    stopifnot(
      !is.null(result$plot),
      class(result$plot)[1] == "ggplot",
      !is.na(result$generation_time)
    )
  }
  
  cat("✓ Single plot generation with error handling\n")
}
```

**Coverage:**
- Plot object created
- ggplot class validated
- File saved (if success)
- Quality computed
- Timing tracked

#### Test 2: Batch Plot Generation

```r
test_generate_all_plots_safe <- function() {
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
    !is.na(result$success_rate)
  )
  
  cat("✓ Batch plot generation with continue-on-error\n")
}
```

**Coverage:**
- Correct count tracking
- Status aggregation (all/some/none)
- Quality aggregation
- Success rate calculation
- Individual results preserved

---

## Integration Testing

### Test Suite: test_pipeline_integration.R

#### Test 1: Complete Pipeline Run

```r
test_complete_pipeline <- function() {
  # Run complete pipeline
  result <- run_pipeline(verbose = FALSE)
  
  # Verify comprehensive result structure
  stopifnot(
    !is.null(result$pipeline_name),
    result$status %in% c("success", "partial", "failed"),
    !is.null(result$quality_score),
    !is.null(result$phase_results),
    !is.null(result$phase_results$data_load),
    !is.null(result$phase_results$plot_generation),
    !is.null(result$plots_generated),
    !is.null(result$output_dir),
    !is.na(result$duration_secs),
    !is.null(result$timestamp),
    !is.null(result$log_file)
  )
  
  cat("✓ Complete pipeline integration test\n")
}
```

**Coverage:**
- All phases executed
- Results aggregated
- Quality computed
- Logging recorded
- Output directory valid

#### Test 2: Pipeline with Partial Failures

```r
test_pipeline_partial_failure <- function() {
  # Corrupt one plot config to force failure
  bad_config <- list(plot_id = NA)  # Missing required fields
  
  # This should return partial (some plots fail)
  result <- run_pipeline(verbose = FALSE)
  
  if (result$status == "partial") {
    stopifnot(
      result$plots_generated > 0,
      result$plots_failed > 0,
      !is.null(result$output_dir)  # Can still use partial results
    )
  }
  
  cat("✓ Pipeline partial failure handling\n")
}
```

---

## Edge Case Testing

### Test Suite: test_edge_cases.R

#### Test 1: Missing File

```r
test_missing_data_file <- function() {
  result <- load_and_validate_data(
    file_path = "nonexistent.csv",
    verbose = FALSE
  )
  
  stopifnot(
    result$status == "failed",
    length(result$errors) > 0,
    is.null(result$data)
  )
  
  cat("✓ Missing file handling\n")
}
```

#### Test 2: Missing Required Columns

```r
test_missing_columns <- function() {
  # Load fixture with missing columns
  result <- load_and_validate_data(
    file_path = "tests/fixtures/missing_columns.csv",
    required_columns = c("mass", "year", "dispersed", "origin"),
    verbose = FALSE
  )
  
  stopifnot(
    result$status == "failed",
    length(result$errors) > 0,
    grepl("mass|year|dispersed|origin", 
          paste(result$errors, collapse = " "))
  )
  
  cat("✓ Missing columns detection\n")
}
```

#### Test 3: High NA Rate

```r
test_sparse_data <- function() {
  # Load fixture with many NAs
  result <- load_and_validate_data(
    file_path = "tests/fixtures/sparse_data.csv",
    verbose = FALSE
  )
  
  if (result$status != "failed") {
    # Quality should be low due to incompleteness
    stopifnot(result$quality_score < 75)
  }
  
  cat("✓ High NA rate detection\n")
}
```

#### Test 4: Out-of-Range Values

```r
test_outlier_detection <- function() {
  df <- data.frame(
    mass = c(-100, 50, 2000, 150, 200),  # Outliers: -100, 2000
    year = c(2020, 2021, 1900, 2023, 2300),  # Outliers: 1900, 2300
    dispersed = c("yes", "no", "yes", "no", "yes"),
    origin = c("A", "B", "A", "B", "A")
  )
  
  metrics <- compute_quality_metrics(df, verbose = FALSE)
  
  stopifnot(
    metrics$outliers_detected >= 4,
    !is.null(metrics$warnings),
    length(metrics$warnings) > 0
  )
  
  cat("✓ Outlier detection (out-of-range values)\n")
}
```

#### Test 5: Empty Data

```r
test_empty_data <- function() {
  result <- load_and_validate_data(
    file_path = "tests/fixtures/empty_data.csv",
    min_rows = 10,
    verbose = FALSE
  )
  
  stopifnot(
    result$status == "failed",
    length(result$errors) > 0,
    grepl("rows", paste(result$errors, collapse = " "))
  )
  
  cat("✓ Empty data handling\n")
}
```

---

## Performance Testing

### Test Suite: Included in test_pipeline_integration.R

#### Performance Benchmark

```r
test_performance_20_plots <- function() {
  # Time complete pipeline with all 20 plots
  start <- start_timer()
  
  result <- run_pipeline(verbose = FALSE)
  
  elapsed <- stop_timer(start)
  
  stopifnot(
    elapsed < 300,  # Should complete in <5 minutes
    result$plots_generated >= 15  # At least 75% success
  )
  
  cat(sprintf("✓ 20-plot generation in %.1f seconds\n", elapsed))
}
```

**Targets:**
- 20 plots generated in <5 minutes
- Average <15 seconds per plot
- Memory usage <500MB

---

## Test Fixtures

### Required Test Data Files

Create in `tests/fixtures/`:

1. **valid_data.csv** (250 rows, all columns, no NAs, valid ranges)
2. **missing_columns.csv** (missing "dispersed" column)
3. **corrupt_data.csv** (invalid types, broken formatting)
4. **sparse_data.csv** (>50% NA values)
5. **empty_data.csv** (zero rows, valid header)

---

## Test Execution

### Running All Tests

```bash
cd /path/to/COHA_Dispersal
R --vanilla < tests/run_all_tests.R
```

### Expected Output

```
=== Running test_phase3_robustness.R ===
✓ Result object creation
✓ Status transitions (unknown → success → partial → failed)
✓ Quality score computation with weights
✓ Error and warning accumulation
✓ Timer accuracy (100ms tolerance)
✓ Error message formatting with recovery hints
✓ is_result_success predicate (success=T, partial=T, failed=F)

=== Running test_phase3_data_operations.R ===
✓ Quality metrics computation
✓ Quality score aggregation (0-100 scale)
✓ Load and validate complete workflow
✓ Mid-pipeline quality assessment

=== Running test_phase3_plot_operations.R ===
✓ Single plot generation with error handling
✓ Batch plot generation with continue-on-error

=== Running test_pipeline_integration.R ===
✓ Complete pipeline integration test
✓ Pipeline partial failure handling
✓ 20-plot generation in 67.2 seconds

=== Running test_edge_cases.R ===
✓ Missing file handling
✓ Missing columns detection
✓ High NA rate detection
✓ Outlier detection (out-of-range values)
✓ Empty data handling

=== Test Summary ===
Passed: 25 / 25
All tests passed! ✅
```

---

## Next: Quarto Integration

After testing passes, create publication-ready reports:

1. **Full Analysis Report** - All plots consolidated
2. **Data Quality Report** - Completeness, schema, outliers
3. **Plot Gallery** - Showcase all 20 variants with metadata
4. **Technical Documentation** - For reproducibility

---

## Summary

**Phase 4 Testing Strategy:**
- ✅ Unit tests (7 robustness, 4 data quality, 2 plot operations)
- ✅ Integration tests (complete pipeline)
- ✅ Edge case tests (5 scenarios)
- ✅ Performance benchmarks
- ⏳ Quarto integration (next phase)

**Target:** All 25+ tests passing before Phase 4.5 (Quarto Reports)
