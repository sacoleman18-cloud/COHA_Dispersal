# PHASE 3: ROBUSTNESS STANDARDS
**Project:** COHA Dispersal Analysis  
**Phase:** 3 - Robustness  
**Status:** In Progress  
**Date:** February 2026

---

## Overview

Phase 3 hardens the pipeline against failures and user errors. Rather than stopping execution when problems arise, the pipeline now:

1. **Returns structured results** with status fields instead of errors
2. **Logs all operations** for complete audit trail and debugging
3. **Performs defensive checks** before critical operations
4. **Reports data quality** metrics alongside results
5. **Enables graceful degradation** (continue when possible, fail gracefully when not)

**Phase 3 = Safety + Visibility + Continuity**

---

## 1. STRUCTURED ERROR RETURNS

### 1.1 Return Object Standard

All pipeline functions return structured lists with consistent fields:

```r
result <- operation_that_might_fail(...)

# Every result has these standard fields:
result$status          # "success", "partial", or "failed"
result$message         # Human-readable status message
result$timestamp       # POSIXct when operation completed
result$duration_secs   # How long operation took
result$operation       # What operation ran (e.g., "validate_data")

# Operation-specific fields (examples):
result$rows_processed  # For data operations
result$plots_generated # For plot operations
result$errors          # Character vector if status != "success"
result$warnings        # Character vector of non-blocking issues
result$quality_score   # 0-100 rating of operation success
```

### 1.2 Status Values Explained

| Status | Meaning | Action |
|--------|---------|--------|
| `"success"` | Operation completed fully, no issues | Continue pipeline |
| `"partial"` | Operation completed, some non-critical issues | Proceed with caution, log warnings |
| `"failed"` | Operation failed, cannot continue | Stop and report error |

### 1.3 Example: Safe Data Loading

**Before (Phase 1 - errors on problems):**
```r
df <- safe_read_csv("data.csv")  # Returns NULL on error, stops pipeline
```

**After (Phase 3 - structured returns):**
```r
result <- load_and_validate_data("data.csv")

# Returns:
# result$status = "success" or "partial" or "failed"
# result$data = data frame if status != "failed"
# result$rows = number of rows loaded
# result$errors = list of problems found
# result$warnings = list of non-critical issues
# result$quality_score = 0-100 rating

if (result$status == "success") {
  message("Data loaded successfully")
  df <- result$data
} else if (result$status == "partial") {
  warning(sprintf("Data loaded with warnings: %s", 
                  paste(result$warnings, collapse = ", ")))
  df <- result$data
} else {
  stop(sprintf("Failed to load data: %s", 
               paste(result$errors, collapse = ", ")))
}
```

### 1.4 Error vs Warning Pattern

**Error (status = "failed"):**
- Missing required columns
- Failed file read (file doesn't exist, corrupt)
- Invalid data types on required columns
- Pipeline cannot continue

**Warning (status = "partial", included in result$warnings):**
- Extra columns not in schema
- Data quality issues (outliers, suspicious values)
- Performance concerns
- Minor inconsistencies

---

## 2. DEFENSIVE PROGRAMMING

### 2.1 Pre-Condition Checks

Every function starts by validating inputs:

```r
my_function <- function(data, output_dir, verbose = FALSE) {
  # Log entry
  log_entry("my_function", verbose)
  
  # Defensive checks FIRST
  tryCatch(
    {
      assert_data_frame(data, "data")
      assert_not_empty(data, "data")
      assert_directory_exists(output_dir)
    },
    error = function(e) {
      log_error("Input validation", e$message, verbose)
      return(list(
        status = "failed",
        message = e$message,
        timestamp = Sys.time(),
        duration_secs = 0,
        errors = list(e$message)
      ))
    }
  )
  
  # Continue with operation...
}
```

### 2.2 Defensive Checks Checklist

Before any operation, verify:

- [ ] Input parameters exist and are non-null
- [ ] Input types are correct (data frame, character, numeric, etc.)
- [ ] Data is non-empty (has rows)
- [ ] Required columns exist in data frames
- [ ] Column types are correct
- [ ] Output directories exist (or can be created)
- [ ] File paths are valid
- [ ] Required packages are available

### 2.3 Safe Operations

Wrap potentially-failing operations in tryCatch:

```r
# Reading files
result <- tryCatch(
  {
    readr::read_csv(file_path, show_col_types = FALSE)
  },
  error = function(e) {
    log_error("Read file", e$message)
    return(NULL)
  }
)

# Writing files
result <- tryCatch(
  {
    ggplot2::ggsave(file_path, plot)
  },
  error = function(e) {
    log_error("Save plot", e$message)
    return(FALSE)  # Indicates failure
  }
)

# Calculations
result <- tryCatch(
  {
    computed_value <- expensive_calculation(data)
    computed_value
  },
  warning = function(w) {
    log_message(w$message, level = "WARN")
    NA  # Return NA on warning
  },
  error = function(e) {
    log_error("Calculation", e$message)
    NA  # Return NA on error
  }
)
```

---

## 3. DATA QUALITY REPORTING

### 3.1 Quality Metrics

Compute quality score (0-100) for data operations:

```r
# Data quality score components:
quality_score <- 0

# Completeness: no missing values
if (sum(is.na(df)) == 0) quality_score <- quality_score + 30
else quality_score <- quality_score + (30 * (1 - sum(is.na(df))/nrow(df)))

# Schema compliance: all required columns, correct types
required_cols <- c("mass", "year")
if (all(required_cols %in% names(df))) quality_score <- quality_score + 30

# Row count: meets minimum threshold
if (nrow(df) >= 100) quality_score <- quality_score + 20
else if (nrow(df) > 0) quality_score <- quality_score + (20 * nrow(df) / 100)

# No suspicious values (outliers)
if (max(df$mass) < 1000 && min(df$mass) > 0) quality_score <- quality_score + 20
```

### 3.2 Quality Report Format

Return quality metrics with operations:

```r
list(
  status = "success",
  message = "Data loaded and validated",
  data = df,
  rows = nrow(df),
  columns = ncol(df),
  quality = list(
    completeness = 0.98,      # Percentage of non-NA values
    schema_match = TRUE,       # Has all required columns/types
    row_count_ok = TRUE,       # Meets minimum row threshold
    outliers_detected = 2,     # Number of suspicious values
    warnings = c("Column 'year' has 3 NA values")
  ),
  quality_score = 88           # 0-100 overall score
)
```

### 3.3 Data Validation Report

When validating data, report all issues:

```r
validation_report <- validate_ridgeline_data(df, verbose = TRUE)

# Returns:
# $status = "partial" (some issues found)
# $message = "Data valid with warnings"
# $issues_found = 3
# $issues = list(
#   "Column 'mass': 2 NA values (expected none)",
#   "Column 'year': range 1980-2027, 1 value > 2026",
#   "Column 'origin': 5 unknown values found"
# )
# $warnings = same as $issues
# $quality_score = 85
```

---

## 4. ENHANCED LOGGING

### 4.1 Logging Checklist

Log these operations:

- [ ] Function entry (what was called, with parameters)
- [ ] Input validation (checks performed, results)
- [ ] Data transformations (rows before/after, operations)
- [ ] File operations (reads, writes, paths)
- [ ] Calculations (computation start/end, timing)
- [ ] Function exit (status, timing, summary)
- [ ] Errors (what failed, why, recovery actions)

### 4.2 Logging Format

```r
# Function entry
log_entry("generate_plot", verbose)
log_message(sprintf("Parameters: plot_id=%s, dpi=%d", plot_id, dpi),
            "DEBUG", verbose)

# Data operations
log_message(sprintf("Filtering data: %d rows before, %d rows after",
                   nrow(df_before), nrow(df_after)),
            "DEBUG", verbose)

# File operations
log_message(sprintf("Saving plot to %s", output_path), "INFO", verbose)

# Errors
log_error("Save plot failed", sprintf("Permission denied: %s", path), verbose)

# Function exit
log_success("Plot generation", sprintf("Completed in %.2f seconds", duration),
            verbose)
```

### 4.3 Log Levels in Phase 3

| Level | When to Use | Example |
|-------|-------------|---------|
| ERROR | Operation failed, cannot continue | "File not found: data.csv" |
| WARN | Issue found, continuing with caution | "Column has NA values, proceeding" |
| INFO | Major milestones completed | "Loaded 847 records from data.csv" |
| DEBUG | Detailed operational information | "Filtering rows by year: 1980-2026" |

---

## 5. ERROR RECOVERY STRATEGIES

### 5.1 Fail-Safe vs Fail-Fast

**Fail-Fast (Phase 1 pattern):** Stop immediately on first error
```r
# Phase 1: Stops pipeline
assert_columns_exist(df, "mass")  # STOPS if missing
```

**Fail-Safe (Phase 3 pattern):** Continue, report issue, decide later
```r
# Phase 3: Continues pipeline
result <- validate_data(df)
if (result$status == "failed") {
  # Decide what to do: stop, use default data, or continue with warnings
}
```

### 5.2 Graceful Degradation Examples

**Example 1: Missing Optional Data**
```r
# If supplementary file missing, use defaults instead of stopping
supplementary <- tryCatch(
  {
    read_csv("supplementary.csv")
  },
  error = function(e) {
    log_message("Supplementary file missing, using defaults", "WARN", verbose)
    data.frame(id = NA, value = NA)  # Return empty defaults
  }
)
```

**Example 2: Plot Generation Continues on Individual Failures**
```r
# Generate 20 plots, skip any that fail
for (plot_spec in plot_configs) {
  result <- try(
    {
      generate_plot(plot_spec, df)
    },
    silent = TRUE
  )
  
  if (inherits(result, "try-error")) {
    log_error("Plot generation", paste(result), verbose)
    # Continue with next plot instead of stopping
    next
  }
}
```

**Example 3: Data Quality Issues Don't Stop Pipeline**
```r
# Data has issues, but pipeline continues with quality warnings
if (quality_score < 50) {
  log_message("Data quality low, proceeding with caution", "WARN", verbose)
}
# Continue instead of stopping
```

---

## 6. IMPLEMENTATION ROADMAP

### Phase 3A: Data Operations (Days 1-2)

1. ✅ Create `load_and_validate_data()` with structured returns
   - Loads CSV -> validates -> returns result object
   - Fields: status, message, data, quality_score, issues
   
2. ✅ Create `compute_quality_metrics()` function
   - Calculates completeness, schema match, row count, outliers
   - Returns numeric 0-100 score

3. ✅ Enhance `validate_ridgeline_data()` with quality reporting
   - Reports all issues found
   - Returns structured result with warnings list

4. ✅ Add defensive checks to all data functions
   - assert_* calls at function start
   - tryCatch for file operations

### Phase 3B: Plot Operations (Days 3-4)

5. ⏳ Create `generate_plot_safe()` with structured returns
   - Wraps plot generation in error recovery
   - Returns: status, plot object, path, quality metrics

6. ⏳ Enhance `generate_all_plots()` to continue on individual failures
   - Logs each failure
   - Returns summary: success count, fail count, errors

7. ⏳ Add pre-plot defensive checks
   - Check output directory before saving
   - Validate plot dimensions
   - Check disk space

### Phase 3C: Pipeline Robustness (Days 5-6)

8. ⏳ Update `run_pipeline()` to return comprehensive result
   - Fields: status, message, plots_generated, data_quality, errors, warnings
   - Each sub-operation returns structured result
   - Aggregate results at end

9. ⏳ Add error recovery in pipeline
   - If data load fails partially, decide: continue or stop
   - If plot generation fails, log and continue
   - Return final status with summary of what succeeded/failed

10. ⏳ Create `generate_quality_report()` function
    - Summarizes quality across entire pipeline run
    - Report where issues occurred
    - Recommendations for data quality improvement

### Phase 3D: Logging Enhancement (Days 7)

11. ⏳ Add comprehensive logging to all functions
    - Log function entry, parameters
    - Log data transformations
    - Log errors with context
    - Log function exit with duration

12. ⏳ Verify logging to file works
    - Check log file created
    - Verify all operations logged
    - Test log rotation (new file per day)

---

## 7. QUALITY GATES FOR COMPLETION

Phase 3 is complete when ALL of the following are true:

- [ ] All data functions return structured result objects
- [ ] All plot functions return structured result objects
- [ ] Pipeline function returns comprehensive status report
- [ ] Defensive checks (assert_*) at start of all public functions
- [ ] tryCatch wrapping all I/O operations
- [ ] Quality scores computed for data and plots
- [ ] Quality issues logged as WARN not ERROR (where possible)
- [ ] Error messages include recovery suggestions
- [ ] Pipeline continues when individual plots fail
- [ ] Logs show complete operation timeline
- [ ] Test: Run with missing optional data - should degrade gracefully
- [ ] Test: Run with quality issues present - should warn not error
- [ ] Test: Run with missing file - should fail cleanly with suggestion
- [ ] Documentation updated with error codes and recovery steps

---

## 8. STRUCTURED RETURN TEMPLATE

Use this template for all Phase 3 functions:

```r
#' Operation Description
#' @export
my_operation <- function(input_data, param = "default", verbose = FALSE) {
  # 1. LOG ENTRY
  log_entry("my_operation", verbose)
  start_time <- Sys.time()
  
  # 2. INITIALIZE RESULT
  result <- list(
    status = "unknown",
    message = "",
    timestamp = Sys.time(),
    duration_secs = 0,
    operation = "my_operation",
    errors = list(),
    warnings = list()
  )
  
  # 3. DEFENSIVE CHECKS
  tryCatch(
    {
      assert_data_frame(input_data)
      assert_scalar_string(param)
    },
    error = function(e) {
      result$status <<- "failed"
      result$message <<- e$message
      result$errors <<- list(e$message)
      log_error("my_operation", e$message, verbose)
      return(result)
    }
  )
  
  # 4. MAIN OPERATION
  tryCatch(
    {
      # Do actual work here
      output <- transform_data(input_data, param)
      
      # SUCCESS
      result$status <<- "success"
      result$message <<- "Operation completed successfully"
      result$output <<- output
      log_success("my_operation", "completed", verbose)
    },
    error = function(e) {
      result$status <<- "failed"
      result$message <<- paste("Operation failed:", e$message)
      result$errors <<- list(e$message)
      log_error("my_operation", e$message, verbose)
    },
    warning = function(w) {
      result$warnings <<- c(result$warnings, list(w$message))
      log_message(w$message, "WARN", verbose)
      invokeRestart("muffleWarning")
    }
  )
  
  # 5. FINALIZE
  result$duration_secs <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  invisible(result)
}
```

---

## 9. ERROR CODES & RECOVERY

Document all error codes for user reference:

| Code | Message | Recovery |
|------|---------|----------|
| E001 | File not found | Check YAML config, ensure data.csv exists |
| E002 | Missing columns | Verify CSV has: mass, year, dispersed, origin |
| E003 | Invalid data type | Check column types: mass/year numeric, others character |
| E004 | Directory creation failed | Check permissions on parent directory |
| W001 | Data quality low | Consider data cleaning before analysis |
| W002 | Outliers detected | Review suspicious values in data |

---

## DOCUMENT HISTORY

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-10 | 1.0.0 | Initial Phase 3 Robustness Standards |

---

**Next:**
- Phase 3A: Implement structured returns for data operations
- Phase 3B: Implement structured returns for plot operations
- Phase 3C: Update pipeline with error recovery
- Phase 3D: Add comprehensive logging
- Phase 4: Testing and Polish
