# ==============================================================================
# R/core/module_result.R
# ==============================================================================
# PURPOSE
# -------
# Standardized result object structure for all modules.
# Ensures consistent module return format enabling module chaining and composition.
# This is CONNECTOR #1 in the LEGO-like modular architecture.
#
# DESIGN PRINCIPLE
# ----------------
# Every module returns a "module_result" object with predictable structure:
#   - status: success|partial|failed
#   - data: primary output
#   - errors/warnings: any issues
#   - quality_score: 0-100 metric
#   - timing: duration_seconds
#
# Without this, modules can't be chained (A's output ≠ B's input format).
# With this, any module can consume any other module's output.
#
# FUNCTIONS PROVIDED
# ------------------
# Core Result Management:
#   - create_module_result(): Initialize result object
#   - add_error(): Append error message
#   - add_warning(): Append warning message
#   - finalize_result(): Record execution time
#   - is_successful(): Check if result succeeded
#
# Utilities:
#   - format_result_summary(): Human-readable summary
#   - export_result_json(): JSON serialization
#
# S3 Methods:
#   - print.module_result: Pretty printing
#
# CHANGELOG
# ---------
# 2026-02-12: Phase 1.12 - Created module_result.R
#             - Standardized result object structure (CONNECTOR #1)
#             - Core helpers and S3 methods
#             - Integration with existing robustness.R pattern
# ==============================================================================

# ==============================================================================
# RESULT OBJECT STRUCTURE & CREATION
# ==============================================================================

#' Create a Standardized Module Result Object
#'
#' Initializes a module result with standard fields. All modules should return
#' this structure to enable proper module composition and error handling.
#'
#' @param operation Character. Name of operation performed (required).
#'   Example: "load_data", "generate_plot", "validate_config"
#'
#' @param module_name Character. Name of module producing this result (optional).
#'   Example: "data_loader", "plot_generator". Default: NA_character_
#'
#' @param data Object. Primary output from operation. Default: NULL
#'   Can be: data.frame, ggplot, list, vector, etc. Depends on operation.
#'
#' @param status Character. Overall result status (default: "success")
#'   Valid values: "success", "partial", "failed"
#'   - success: Operation completed without issues
#'   - partial: Operation completed but with warnings/quality concerns
#'   - failed: Operation did not complete (errors present)
#'
#' @param call Character. Debugging info - what function called this (optional)
#'
#' @return Object of class "module_result" (list) with standardized fields:
#'   - $status: "success"|"partial"|"failed"
#'   - $operation: Name of operation
#'   - $module_name: Name of module
#'   - $data: Primary output
#'   - $metadata: Extra domain-specific info (initially empty)
#'   - $quality_score: 0-100 quality metric (initially NA)
#'   - $timestamp: When result created
#'   - $duration_seconds: Execution time (initially NA)
#'   - $errors: Collected error messages (initially empty)
#'   - $warnings: Collected warning messages (initially empty)
#'   - $input_parameters: Parameters passed to operation (initially empty)
#'   - $call: Debugging info (initially NA)
#'
#' @section CLASS ATTRIBUTE:
#' Result has S3 class "module_result" allowing custom print/summary methods.
#'
#' @examples
#' # Create result for successful operation
#' result <- create_module_result(
#'   operation = "load_data",
#'   module_name = "data_loader",
#'   data = data.frame(x = 1:10)
#' )
#'
#' # Check status
#' if (is_successful(result)) {
#'   df <- result$data  # Safe to use
#' }
#'
#' # Create result that will receive errors
#' result <- create_module_result(
#'   operation = "validate",
#'   status = "failed"
#' )
#' result <- add_error(result, "File not found: data.csv")
#'
#' @export
create_module_result <- function(
  operation,
  module_name = NA_character_,
  data = NULL,
  status = "success",
  call = NA_character_
) {

  if (missing(operation)) {
    stop("argument 'operation' is required", call. = FALSE)
  }

  # Validate status
  valid_statuses <- c("success", "partial", "failed")
  if (!(status %in% valid_statuses)) {
    stop(sprintf(
      "Invalid status '%s'. Must be one of: %s",
      status, paste(valid_statuses, collapse = ", ")
    ), call. = FALSE)
  }

  # Build result object
  result <- structure(
    list(
      # ===== STATUS FIELDS =====
      status = status,
      operation = operation,
      module_name = module_name,

      # ===== OUTPUT FIELDS =====
      data = data,
      metadata = list(),

      # ===== QUALITY METRICS =====
      quality_score = NA_real_,

      # ===== TIMING =====
      timestamp = Sys.time(),
      duration_seconds = NA_real_,

      # ===== ERROR/WARNING TRACKING =====
      errors = character(),
      warnings = character(),

      # ===== CONTEXT =====
      input_parameters = list(),
      call = call
    ),
    class = c("module_result", "list")
  )

  result
}

# ==============================================================================
# RESULT OBJECT MANIPULATION
# ==============================================================================

#' Add Error to Module Result
#'
#' Appends an error message to a module result and sets status appropriately.
#' Multiple calls accumulate errors.
#'
#' @param result Object. A module_result (from create_module_result)
#' @param error_message Character. Error message to add
#' @param details List. Optional additional error details (stored in metadata)
#'
#' @return Modified result object with error appended and status updated
#'
#' @section STATUS UPDATE:
#' - If status was "success", changes to "failed"
#' - If status was "partial", remains "partial" (but will be "failed" if more errors added)
#' - If status was "failed", remains "failed"
#'
#' @examples
#' result <- create_module_result("test", status = "success")
#' result <- add_error(result, "Something went wrong")
#' result$status  # Now "failed"
#' result$errors  # c("Something went wrong")
#'
#' @export
add_error <- function(result, error_message, details = NULL) {

  if (!inherits(result, "module_result")) {
    stop("'result' must be a module_result object", call. = FALSE)
  }

  # Append error message
  if (!is.character(result$errors)) result$errors <- character()
  result$errors <- c(result$errors, error_message)

  # Update status if not already failed or partial
  if (result$status == "success") {
    result$status <- "failed"
  }

  # Store details if provided
  if (!is.null(details)) {
    if (!"error_details" %in% names(result$metadata)) {
      result$metadata$error_details <- list()
    }
    error_index <- length(result$errors)
    result$metadata$error_details[[error_index]] <- details
  }

  result
}

#' Add Warning to Module Result
#'
#' Appends a warning message to a module result and updates status if appropriate.
#' Multiple calls accumulate warnings.
#'
#' @param result Object. A module_result
#' @param warning_message Character. Warning message to add
#' @param severity Character. Severity level: "low", "medium", "high"
#'   (For categorization/filtering). Default: "medium"
#'
#' @return Modified result object with warning appended
#'
#' @section STATUS UPDATE:
#' Warnings typically change status to "partial" only if status is "success".
#' If status is already "failed", remains "failed".
#'
#' @examples
#' result <- create_module_result("validate")
#' result <- add_warning(result, "Column X has 5 NA values")
#' result$status  # Now "partial"
#'
#' @export
add_warning <- function(result, warning_message, severity = "medium") {

  if (!inherits(result, "module_result")) {
    stop("'result' must be a module_result object", call. = FALSE)
  }

  # Append warning message
  if (!is.character(result$warnings)) result$warnings <- character()
  result$warnings <- c(result$warnings, warning_message)

  # Update status only if still "success"
  if (result$status == "success") {
    result$status <- "partial"
  }

  # Track severity
  if (!"warning_severity" %in% names(result$metadata)) {
    result$metadata$warning_severity <- character()
  }
  result$metadata$warning_severity <- c(result$metadata$warning_severity, severity)

  result
}

#' Record Execution Timing for Result
#'
#' Calculates elapsed time from start_time and stores in duration_seconds.
#' Call this just before returning result from a module.
#'
#' @param result Object. A module_result
#' @param start_time POSIXct. When operation started (from Sys.time())
#'   If NULL, duration_seconds remains NA
#'
#' @return Modified result with duration_seconds populated
#'
#' @examples
#' start <- Sys.time()
#' # ... do work ...
#' result <- finalize_result(result, start)
#' cat(sprintf("Took: %.2f seconds\n", result$duration_seconds))
#'
#' @export
finalize_result <- function(result, start_time = NULL) {

  if (!inherits(result, "module_result")) {
    stop("'result' must be a module_result object", call. = FALSE)
  }

  if (!is.null(start_time)) {
    if (!inherits(start_time, "POSIXct")) {
      stop("'start_time' must be POSIXct (from Sys.time())", call. = FALSE)
    }
    result$duration_seconds <- as.numeric(
      difftime(Sys.time(), start_time, units = "secs")
    )
  }

  result
}

# ==============================================================================
# RESULT INSPECTION
# ==============================================================================

#' Check if Result Indicates Success
#'
#' Convenience function to determine if operation succeeded.
#' TRUE if status is "success" AND no errors present.
#'
#' @param result Object. A module_result
#'
#' @return Logical. TRUE if result indicates success, FALSE otherwise
#'
#' @examples
#' result <- create_module_result("test")
#' is_successful(result)  # TRUE
#'
#' result <- add_error(result, "Something failed")
#' is_successful(result)  # FALSE
#'
#' @export
is_successful <- function(result) {
  if (!inherits(result, "module_result")) return(FALSE)
  result$status == "success" && length(result$errors) == 0
}

#' Check if Result Has Errors
#'
#' @param result Object. A module_result
#' @return Logical. TRUE if errors present
#'
#' @export
has_errors <- function(result) {
  if (!inherits(result, "module_result")) return(FALSE)
  length(result$errors) > 0
}

#' Check if Result Has Warnings
#'
#' @param result Object. A module_result
#' @return Logical. TRUE if warnings present
#'
#' @export
has_warnings <- function(result) {
  if (!inherits(result, "module_result")) return(FALSE)
  length(result$warnings) > 0
}

#' Count Issues in Result
#'
#' @param result Object. A module_result
#' @return List with:
#'   - errors: Integer count
#'   - warnings: Integer count
#'   - total: Integer count
#'
#' @export
count_result_issues <- function(result) {
  if (!inherits(result, "module_result")) {
    return(list(errors = 0, warnings = 0, total = 0))
  }

  err_count <- length(result$errors)
  warn_count <- length(result$warnings)

  list(
    errors = err_count,
    warnings = warn_count,
    total = err_count + warn_count
  )
}

# ==============================================================================
# RESULT FORMATTING & DISPLAY
# ==============================================================================

#' Print a Module Result
#'
#' S3 method for pretty-printing module results with status, timing, and issues.
#'
#' @param x Object. A module_result
#' @param ... Additional arguments (ignored)
#'
#' @return Invisibly returns x
#'
#' @examples
#' result <- create_module_result("test", module_name = "my_module")
#' result <- add_error(result, "Test error")
#' print(result)
#'
#' @export
print.module_result <- function(x, ...) {

  # Status indicator
  status_symbol <- switch(x$status,
    "success" = "✓",
    "partial" = "⚠",
    "failed" = "✗",
    "?"
  )

  # Timing info
  timing_str <- if (is.na(x$duration_seconds)) {
    "..."
  } else {
    sprintf("%.2f sec", x$duration_seconds)
  }

  # Issue counts
  issues <- count_result_issues(x)

  # Header
  cat(sprintf(
    "%s [%s] %s @ %s\n",
    status_symbol,
    x$status,
    x$operation,
    format(x$timestamp, "%H:%M:%S")
  ))

  # Module + timing
  if (!is.na(x$module_name)) {
    cat(sprintf("  Module: %s\n", x$module_name))
  }
  cat(sprintf("  Duration: %s\n", timing_str))

  # Quality score if present
  if (!is.na(x$quality_score)) {
    cat(sprintf("  Quality: %.0f/100\n", x$quality_score))
  }

  # Issues summary
  if (issues$total > 0) {
    cat(sprintf("  Issues: %d error%s, %d warning%s\n",
      issues$errors, if (issues$errors == 1) "" else "s",
      issues$warnings, if (issues$warnings == 1) "" else "s"
    ))

    # List errors
    if (issues$errors > 0) {
      cat("  Errors:\n")
      for (i in seq_along(x$errors)) {
        cat(sprintf("    [%d] %s\n", i, x$errors[i]))
      }
    }

    # List warnings
    if (issues$warnings > 0) {
      cat("  Warnings:\n")
      for (i in seq_along(x$warnings)) {
        cat(sprintf("    [%d] %s\n", i, x$warnings[i]))
      }
    }
  }

  invisible(x)
}

#' Format Result as Summary String
#'
#' Creates concise string representation suitable for logs or reports.
#'
#' @param result Object. A module_result
#' @param include_errors Logical. Include error list (default: TRUE)
#'
#' @return Character string summary
#'
#' @examples
#' result <- create_module_result("test")
#' cat(format_result_summary(result))
#'
#' @export
format_result_summary <- function(result, include_errors = TRUE) {

  if (!inherits(result, "module_result")) {
    return("[Invalid result object]")
  }

  issues <- count_result_issues(result)

  # Basic summary
  summary <- sprintf(
    "[%s] %s (%s, %.2f sec, %d issue%s)",
    result$status,
    result$operation,
    if (!is.na(result$module_name)) result$module_name else "?",
    if (!is.na(result$duration_seconds)) result$duration_seconds else 0,
    issues$total,
    if (issues$total == 1) "" else "s"
  )

  # Add error list if requested
  if (include_errors && length(result$errors) > 0) {
    errors_str <- paste("  -", result$errors, collapse = "\n")
    summary <- sprintf("%s\nErrors:\n%s", summary, errors_str)
  }

  summary
}

#' Export Result as JSON
#'
#' Convert module result to JSON for serialization/logging.
#'
#' @param result Object. A module_result
#'
#' @return Character string with JSON representation
#'
#' @examples
#' result <- create_module_result("test")
#' json_str <- export_result_json(result)
#'
#' @export
export_result_json <- function(result) {

  if (!inherits(result, "module_result")) {
    stop("'result' must be a module_result object", call. = FALSE)
  }

  # Convert to list, but exclude large data objects
  export_list <- list(
    status = result$status,
    operation = result$operation,
    module_name = result$module_name,
    quality_score = result$quality_score,
    duration_seconds = result$duration_seconds,
    timestamp = as.character(result$timestamp),
    errors = result$errors,
    warnings = result$warnings,
    issue_count = count_result_issues(result)
  )

  # Use jsonlite if available, else fallback
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::toJSON(export_list, pretty = TRUE, auto_unbox = TRUE)
  } else {
    # Simple fallback
    paste(names(export_list), sapply(export_list, toString), sep = ": ", collapse = "\n")
  }
}

# ==============================================================================
# BATCH RESULT OPERATIONS
# ==============================================================================

#' Combine Multiple Results
#'
#' Aggregates results from multiple operations into a summary result.
#' Useful for gathering status from parallel operations.
#'
#' @param results List of module_result objects
#' @param combined_operation Character. Name for combined operation
#'   Default: "batch_operation"
#'
#' @return Single module_result with:
#'   - status: "success"|"partial"|"failed" based on all results
#'   - data: List of individual result$data objects
#'   - errors: All errors from all results combined
#'   - warnings: All warnings from all results combined
#'
#' @export
combine_results <- function(results, combined_operation = "batch_operation") {

  if (!is.list(results) || length(results) == 0) {
    return(create_module_result(combined_operation, status = "failed"))
  }

  # Determine overall status
  statuses <- sapply(results, function(r) {
    if (inherits(r, "module_result")) r$status else "unknown"
  })

  overall_status <- if (any(statuses == "failed")) {
    "failed"
  } else if (any(statuses == "partial")) {
    "partial"
  } else {
    "success"
  }

  # Combine data, errors, warnings
  combined <- create_module_result(
    operation = combined_operation,
    status = overall_status,
    data = lapply(results, function(r) {
      if (inherits(r, "module_result")) r$data else r
    })
  )

  # Aggregate errors and warnings
  for (result in results) {
    if (inherits(result, "module_result")) {
      if (length(result$errors) > 0) {
        combined$errors <- c(combined$errors, result$errors)
      }
      if (length(result$warnings) > 0) {
        combined$warnings <- c(combined$warnings, result$warnings)
      }
    }
  }

  combined
}

# ==============================================================================
# EOF
# ==============================================================================
