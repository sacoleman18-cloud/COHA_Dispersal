# ==============================================================================
# R/functions/robustness.R
# ==============================================================================
# PURPOSE
# -------
# Phase 3 robustness helpers for structured error returns and quality reporting.
# Provides templates and utilities for returning structured results from operations.
#
# DEPENDS ON
# ----------
# - R/functions/assertions.R (validation)
# - R/functions/logging.R (audit trail)
# - base R
#
# INPUTS
# ------
# Operation results, quality metrics, error information
#
# OUTPUTS
# -------
# Structured result lists with status, message, quality scores
#
# USAGE
# -----
# source("R/functions/robustness.R")
# result <- create_result("my_operation")
# result <- add_status(result, "success", "Operation complete")
# result <- add_quality_metrics(result, completeness = 0.95)
#
# CHANGELOG
# ---------
# 2026-02-10 (v1.0.0): Phase 3 - Initial robustness helpers
#   - create_result() - Initialize structured result object
#   - start_timer() / stop_timer() - Track operation timing
#   - add_quality_metrics() - Add quality scores
#   - format_error_message() - Consistent error formatting
#
# ==============================================================================

#' Create Structured Result Object
#'
#' @description
#' Initialize a structured result object following Phase 3 standard.
#' All operations return objects with these fields.
#'
#' @param operation Character. Name of operation (e.g., "load_data", "generate_plot").
#' @param verbose Logical. Enable verbose logging. Default: FALSE.
#'
#' @return List with standard result fields:
#'   - status: "unknown" (updated after operation)
#'   - message: "" (human-readable status)
#'   - timestamp: Sys.time()
#'   - duration_secs: 0 (updated after operation)
#'   - operation: name of operation
#'   - errors: empty list
#'   - warnings: empty list
#'   - quality_score: NA (updated if applicable)
#'
#' @details
#' **Standard Fields:**
#' All operations return objects with these guaranteed fields.
#' Additional fields (data, plot, count, etc.) added as needed.
#'
#' **Status Values:** Unknown initially, set to success/partial/failed.
#' - success: Operation completed fully
#' - partial: Operation completed with non-blocking warnings
#' - failed: Operation failed, cannot continue
#'
#' **Usage Pattern:**
#' ```r
#' result <- create_result("my_operation", verbose)
#' # ... perform operation, update result fields ...
#' result$status <- "success"
#' result$message <- "Operation complete"
#' result$duration_secs <- elapsed_time
#' ```
#'
#' @examples
#' \dontrun{
#' result <- create_result("load_data")
#' # Returns:
#' # $status = "unknown"
#' # $message = ""
#' # $timestamp = <current time>
#' # $duration_secs = 0
#' # $operation = "load_data"
#' # $errors = list()
#' # $warnings = list()
#' # $quality_score = NA
#' }
#'
#' @export
create_result <- function(operation, verbose = FALSE) {
  list(
    status = "unknown",
    message = "",
    timestamp = Sys.time(),
    duration_secs = 0,
    operation = operation,
    errors = list(),
    warnings = list(),
    quality_score = NA_real_
  )
}

#' Set Result Status and Message
#'
#' @description
#' Update status and message fields of result object.
#'
#' @param result List. Result object from create_result().
#' @param status Character. One of: "success", "partial", "failed".
#' @param message Character. Human-readable status message.
#' @param verbose Logical. Log the status. Default: FALSE.
#'
#' @return List. Updated result object (invisibly).
#'
#' @details
#' **Status Values:**
#' - success: Full operation completion, no issues
#' - partial: Operation completed, some warnings or quality concerns
#' - failed: Operation failed, cannot continue
#'
#' **Message:** Concise explanation, e.g.:
#' - "Data loaded successfully"
#' - "Plot generated with warnings"
#' - "Data validation failed: missing columns"
#'
#' @examples
#' \dontrun{
#' result <- create_result("load_data")
#' result <- set_result_status(result, "success", "Loaded 847 records")
#' }
#'
#' @export
set_result_status <- function(result, status, message, verbose = FALSE) {
  valid_status <- c("success", "partial", "failed")
  if (!status %in% valid_status) {
    warning(sprintf("Invalid status '%s', must be one of: %s",
                   status, paste(valid_status, collapse = ", ")),
           call. = FALSE)
  }
  
  result$status <- status
  result$message <- message
  
  if (verbose) {
    level <- if (status == "failed") "ERROR" else "INFO"
    log_message(sprintf("[%s] %s", result$operation, message), level, verbose)
  }
  
  invisible(result)
}

#' Add Error to Result
#'
#' @description
#' Append error message to result's error list and update status.
#'
#' @param result List. Result object.
#' @param error_message Character. Error description.
#' @param verbose Logical. Log the error. Default: FALSE.
#'
#' @return List. Updated result with error added and status="failed".
#'
#' @details
#' **Usage:** Call when operation encounters error condition.
#' Updates status to "failed" and appends to errors list.
#'
#' @examples
#' \dontrun{
#' result <- create_result("operation")
#' result <- add_error(result, "File not found", verbose = TRUE)
#' # Result now has status = "failed", errors = list("File not found")
#' }
#'
#' @export
add_error <- function(result, error_message, verbose = FALSE) {
  result$errors <- c(result$errors, list(error_message))
  result$status <- "failed"
  
  if (verbose) {
    log_error(result$operation, error_message, verbose = TRUE)
  }
  
  invisible(result)
}

#' Add Warning to Result
#'
#' @description
#' Append warning message to result's warning list.
#' Doesn't necessarily change status to failed.
#'
#' @param result List. Result object.
#' @param warning_message Character. Warning description.
#' @param verbose Logical. Log the warning. Default: FALSE.
#'
#' @return List. Updated result with warning added.
#'   Status updated to "partial" if currently "success".
#'
#' @details
#' **Usage:** Call for non-blocking issues (data quality, performance, etc).
#' Preserves status = "success" if no errors, but changes "success" -> "partial".
#'
#' @examples
#' \dontrun{
#' result <- create_result("operation")
#' result <- set_result_status(result, "success", "Operation complete")
#' result <- add_warning(result, "Some data has NA values", verbose = TRUE)
#' # Result now has status = "partial", warnings = list("Some data...")
#' }
#'
#' @export
add_warning <- function(result, warning_message, verbose = FALSE) {
  result$warnings <- c(result$warnings, list(warning_message))
  
  # Upgrade status to "partial" if currently "success"
  if (result$status == "success") {
    result$status <- "partial"
  }
  
  if (verbose) {
    log_message(sprintf("[%s] %s", result$operation, warning_message),
               level = "WARN", verbose = TRUE)
  }
  
  invisible(result)
}

#' Add Quality Metrics to Result
#'
#' @description
#' Compute and attach quality score to result object.
#' Score ranges 0-100, higher is better.
#'
#' @param result List. Result object.
#' @param components List. Named numeric list of quality components.
#'   Each component 0-100. Example: list(completeness = 95, accuracy = 88).
#' @param weights Numeric vector. Optional weights for components (sum to 100).
#'   If NULL, components weighted equally.
#'
#' @return List. Updated result with quality_score field.
#'
#' @details
#' **Score Calculation:**
#' Unweighted: mean(components)
#' Weighted: sum(components * weights / 100)
#'
#' **Components Example:**
#' - completeness: percent of non-NA values (0-100)
#' - schema_match: percent of columns with correct type (0-100)
#' - row_count: 100 if >= minimum, less if below minimum
#' - outlier_rate: 100 - (count_outliers / total_rows * 100)
#'
#' **Interpretation:**
#' - 90-100: Excellent quality
#' - 75-89: Good quality, minor issues
#' - 50-74: Acceptable quality, some issues
#' - 0-49: Poor quality, significant issues
#'
#' @examples
#' \dontrun{
#' result <- create_result("validate_data")
#' components <- list(
#'   completeness = 95,
#'   schema = 100,
#'   row_count = 100,
#'   outliers = 85
#' )
#' result <- add_quality_metrics(result, components)
#' # result$quality_score = 95 (average)
#' }
#'
#' @export
add_quality_metrics <- function(result, components, weights = NULL) {
  if (!is.list(components) || length(components) == 0) {
    warning("components must be non-empty named list", call. = FALSE)
    return(result)
  }
  
  # Extract numeric values
  scores <- unlist(components)
  if (any(is.na(scores)) || any(scores < 0) || any(scores > 100)) {
    warning("All component scores must be numeric 0-100", call. = FALSE)
    return(result)
  }
  
  # Calculate weighted average
  if (is.null(weights)) {
    # Unweighted average
    overall_score <- mean(scores)
  } else {
    # Weighted average
    if (length(weights) != length(scores)) {
      warning("weights length must match components length", call. = FALSE)
      overall_score <- mean(scores)
    } else {
      overall_score <- sum(scores * weights) / sum(weights)
    }
  }
  
  result$quality_score <- overall_score
  result$quality_components <- as.list(scores)
  
  invisible(result)
}

#' Start Operation Timer
#'
#' @description
#' Record operation start time for duration tracking.
#'
#' @return POSIXct. Current time to pass to stop_timer().
#'
#' @details
#' **Usage Pattern:**
#' ```r
#' start_time <- start_timer()
#' # ... perform operation ...
#' result$duration_secs <- stop_timer(start_time)
#' ```
#'
#' @examples
#' start_time <- start_timer()
#' Sys.sleep(1)  # Simulate work
#' duration <- stop_timer(start_time)
#' # Returns: ~1.0 seconds
#'
#' @export
start_timer <- function() {
  Sys.time()
}

#' Stop Operation Timer
#'
#' @description
#' Calculate elapsed time since start_timer() call.
#'
#' @param start_time POSIXct. Time from start_timer().
#'
#' @return Numeric. Elapsed seconds (rounded to 2 digits).
#'
#' @details
#' Always returns positive number, safe even if called multiple times.
#'
#' @examples
#' start_time <- start_timer()
#' Sys.sleep(2.5)
#' elapsed <- stop_timer(start_time)
#' # Returns: ~2.5 seconds
#'
#' @export
stop_timer <- function(start_time) {
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  round(elapsed, 2)
}

#' Format Error Message for Result
#'
#' @description
#' Create consistent error message with context and recovery suggestion.
#'
#' @param operation Character. Name of operation that failed.
#' @param error_detail Character. What went wrong.
#' @param recovery Character. How to fix it (e.g., "Check data.csv exists").
#'
#' @return Character. Formatted error message.
#'
#' @details
#' **Format:**
#' "[OPERATION] Error: error_detail
#'  Recovery: recovery"
#'
#' **Usage:**
#' ```r
#' msg <- format_error_message(
#'   "load_data",
#'   "File not found: data.csv",
#'   "Check that data.csv exists in project root"
#' )
#' result <- add_error(result, msg)
#' ```
#'
#' @examples
#' msg <- format_error_message(
#'   "generate_plot",
#'   "Invalid palette: xyz",
#'   "Use one of: plasma, viridis, magma"
#' )
#'
#' @export
format_error_message <- function(operation, error_detail, recovery) {
  sprintf("[%s] %s\n  Recovery: %s", operation, error_detail, recovery)
}

#' Check Result Status
#'
#' @description
#' Query result status with helper convenience function.
#'
#' @param result List. Result object.
#'
#' @return Logical. TRUE if status is "success" or "partial", FALSE if "failed".
#'
#' @details
#' Useful for conditional logic: if (is_result_success(result)) ...
#' Returns FALSE only if status = "failed" (operation cannot proceed).
#'
#' @examples
#' result <- create_result("op")
#' result <- set_result_status(result, "success", "OK")
#' if (is_result_success(result)) {
#'   message("Can proceed")
#' }
#'
#' @export
is_result_success <- function(result) {
  result$status != "failed"
}

# ==============================================================================
# END R/functions/robustness.R
# ==============================================================================
