# ============================================================================
# ERROR/LOGGING INTERFACE - Connector #4
# ============================================================================
# Purpose: Unified error handling, categorization, and logging
#
# Provides standardized ways to:
# - Capture and categorize errors across modules
# - Log errors with consistent formatting
# - Handle errors safely without stopping pipeline
# - Report errors to users in understandable ways
#
# Part of the LEGO-like modular architecture system.
# ============================================================================

# ============================================================================
# SECTION 1: Error & Log Level Constants
# ============================================================================

LOG_LEVELS <- list(
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
  FATAL = 5
)

# Error categories for systematic classification
ERROR_CATEGORIES <- list(
  # Configuration errors
  INVALID_CONFIG = "Configuration parameters invalid or missing",
  CONFIG_FILE_NOT_FOUND = "Configuration file not found",
  
  # Data errors
  INVALID_DATA = "Input data doesn't match expected schema",
  DATA_FILE_NOT_FOUND = "Required data file missing",
  CORRUPT_DATA = "Data file is corrupted or unreadable",
  INSUFFICIENT_DATA = "Not enough data to perform operation",
  
  # File/IO errors
  FILE_NOT_FOUND = "Required file missing",
  FILE_WRITE_ERROR = "Cannot write to file (permissions or disk space)",
  PATH_ERROR = "Invalid file path or directory",
  
  # Computation errors
  COMPUTATION_ERROR = "Mathematical or statistical computation failed",
  MEMORY_ERROR = "Out of memory",
  NUMERIC_ERROR = "Numeric computation error (NaN, Inf, etc)",
  
  # System/Access errors
  PERMISSION_ERROR = "File permission or access denied",
  EXTERNAL_TOOL_ERROR = "External tool (quarto, etc) failed",
  EXTERNAL_SERVICE_ERROR = "External service unavailable",
  
  # Module errors
  MODULE_NOT_FOUND = "Required module not found or not loaded",
  MODULE_INIT_ERROR = "Module initialization failed",
  MODULE_DEPENDENCY_ERROR = "Module dependency error",
  
  # Unknown errors
  UNKNOWN_ERROR = "Unexpected or unclassified error"
)

# ============================================================================
# SECTION 2: Core Error Handling Functions
# ============================================================================

#' Add Categorized Error to Module Result
#'
#' Adds an error to a module_result object with category information
#' for better error handling and diagnosis.
#'
#' @param result Module result object (from module_result.R)
#' @param error_message Human-readable error message
#' @param category Error category from ERROR_CATEGORIES
#' @param details Additional context (list)
#'
#' @return Updated result object with error added
add_categorized_error <- function(
  result,
  error_message,
  category = "UNKNOWN_ERROR",
  details = NULL
) {
  
  if (!inherits(result, "module_result")) {
    stop("Result must be a module_result object")
  }
  
  # Add error message
  if (!is.character(result$errors)) {
    result$errors <- character()
  }
  result$errors <- c(result$errors, error_message)
  
  # Add error category
  if (!"error_categories" %in% names(result)) {
    result$error_categories <- list()
  }
  error_index <- length(result$errors)
  result$error_categories[[error_index]] <- category
  
  # Add error details
  if (!is.null(details) && !"error_details" %in% names(result)) {
    result$error_details <- list()
  }
  if (!is.null(details)) {
    result$error_details[[error_index]] <- details
  }
  
  # Update status
  result$status <- "failed"
  
  result
}

#' Log Module Message with Context
#'
#' Standardized logging that includes module name, severity level, and context.
#' Integrates with existing logging.R infrastructure if available.
#'
#' @param module_name Name of module emitting log
#' @param level Log level: "DEBUG", "INFO", "WARN", "ERROR", "FATAL"
#' @param message Message to log
#' @param context Optional list with additional context
#'
#' @return Invisible NULL (logs to console/file)
log_module_message <- function(
  module_name,
  level = "INFO",
  message,
  context = NULL
) {
  
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  # Format message with module context
  formatted_msg <- sprintf(
    "[%s] [%s] %s: %s",
    timestamp,
    module_name,
    level,
    message
  )
  
  # Add context if provided
  if (!is.null(context) && length(context) > 0) {
    context_str <- paste(
      sprintf("%s=%s", names(context), as.character(context)),
      collapse = " | "
    )
    formatted_msg <- sprintf("%s | {%s}", formatted_msg, context_str)
  }
  
  # Output to console
  cat(formatted_msg, "\n")
  
  # Try to use logging.R if available
  if (exists("log_message", mode = "function")) {
    tryCatch({
      log_message(formatted_msg, level = level, verbose = TRUE)
    }, error = function(e) {
      # Silently fail if logging.R not available
    })
  }
  
  invisible(NULL)
}

#' Safe Module Function Execution with Error Capture
#'
#' Wraps a module function call with comprehensive error handling,
#' returning a module_result with error information instead of stopping.
#'
#' @param module_fn Function to execute
#' @param args List of arguments to pass to function
#' @param module_name Name of module (for logging)
#' @param operation Operation name (for result)
#' @param log_output Whether to log execution start/end
#'
#' @return Module result object with data/errors/warnings
safe_module_call <- function(
  module_fn,
  args = list(),
  module_name = "unknown",
  operation = "module_call",
  log_output = TRUE
) {
  
  start_time <- Sys.time()
  
  # Log execution start
  if (isTRUE(log_output)) {
    log_module_message(
      module_name,
      "INFO",
      sprintf("Starting: %s", operation)
    )
  }
  
  result <- tryCatch({
    
    # Execute the module function
    output <- do.call(module_fn, args)
    
    # If output is not a module_result, wrap it
    if (!inherits(output, "module_result")) {
      output <- create_module_result(
        operation = operation,
        module_name = module_name,
        data = output
      )
    }
    
    output
    
  }, error = function(e) {
    
    # Create error result
    result <- create_module_result(
      operation = operation,
      module_name = module_name,
      status = "failed"
    )
    
    # Categorize error based on message pattern
    category <- categorize_error(e$message)
    
    # Add error with category
    result <- add_categorized_error(
      result,
      sprintf("Execution failed: %s", e$message),
      category = category,
      details = list(
        error_class = class(e)[1],
        error_call = deparse(e$call)
      )
    )
    
    # Log error
    log_module_message(
      module_name,
      "ERROR",
      e$message,
      context = list(category = category)
    )
    
    result
    
  }, warning = function(w) {
    
    # Create result and capture warning
    result <- create_module_result(
      operation = operation,
      module_name = module_name,
      status = "partial"
    )
    
    result$warnings <- c(result$warnings, w$message)
    
    # Log warning
    log_module_message(module_name, "WARN", w$message)
    
    result
  })
  
  # Record execution timing
  result$duration_seconds <- as.numeric(
    difftime(Sys.time(), start_time, units = "secs")
  )
  
  # Log execution complete
  if (isTRUE(log_output)) {
    log_module_message(
      module_name,
      "INFO",
      sprintf("Completed: %s (%s) [%.2f sec]",
              operation,
              result$status,
              result$duration_seconds)
    )
  }
  
  result
}

#' Categorize Error Based on Message Pattern
#'
#' Heuristically categorizes an error based on its message text
#'
#' @param error_message Error message string
#'
#' @return Category from ERROR_CATEGORIES
categorize_error <- function(error_message) {
  
  msg_lower <- tolower(error_message)
  
  # Check patterns (order matters - most specific first)
  if (grepl("config|parameter|argument", msg_lower)) {
    return("INVALID_CONFIG")
  }
  
  if (grepl("not found|no such", msg_lower)) {
    if (grepl("file|path|directory", msg_lower)) {
      return("FILE_NOT_FOUND")
    } else if (grepl("module|function", msg_lower)) {
      return("MODULE_NOT_FOUND")
    }
  }
  
  if (grepl("permission|denied|access", msg_lower)) {
    return("PERMISSION_ERROR")
  }
  
  if (grepl("memory|ram|allocation", msg_lower)) {
    return("MEMORY_ERROR")
  }
  
  if (grepl("corrupt|invalid|malformed|wrong format", msg_lower)) {
    return("CORRUPT_DATA")
  }
  
  if (grepl("insufficient|not enough|minimum|too few", msg_lower)) {
    return("INSUFFICIENT_DATA")
  }
  
  if (grepl("nan|inf|numeric", msg_lower)) {
    return("NUMERIC_ERROR")
  }
  
  if (grepl("write|save|output", msg_lower)) {
    return("FILE_WRITE_ERROR")
  }
  
  if (grepl("data|schema|type|column", msg_lower)) {
    return("INVALID_DATA")
  }
  
  if (grepl("quarto|external|tool", msg_lower)) {
    return("EXTERNAL_TOOL_ERROR")
  }
  
  # Default
  "UNKNOWN_ERROR"
}

# ============================================================================
# SECTION 3: Error Reporting & Analysis
# ============================================================================

#' Check If Result Has Errors
#'
#' @param result Module result object
#'
#' @return Logical: TRUE if result has errors
has_errors <- function(result) {
  length(result$errors) > 0
}

#' Check If Result Has Warnings
#'
#' @param result Module result object
#'
#' @return Logical: TRUE if result has warnings
has_warnings <- function(result) {
  length(result$warnings) > 0
}

#' Get Error Category for Error at Index
#'
#' @param result Module result object
#' @param error_index Which error (1-based index)
#'
#' @return Category string or "UNKNOWN_ERROR" if not found
get_error_category <- function(result, error_index = 1) {
  
  if (!"error_categories" %in% names(result)) {
    return("UNKNOWN_ERROR")
  }
  
  if (error_index > length(result$error_categories)) {
    return("UNKNOWN_ERROR")
  }
  
  result$error_categories[[error_index]] %||% "UNKNOWN_ERROR"
}

#' Generate Error Report from Results
#'
#' Aggregates errors from multiple module results into a summary report
#' with statistics and categorization.
#'
#' @param results_list List of module_result objects
#'
#' @return List with aggregated error information
generate_error_report <- function(results_list) {
  
  if (!is.list(results_list) || length(results_list) == 0) {
    return(list(
      total_errors = 0,
      total_warnings = 0,
      modules_with_errors = character(),
      error_summary = data.frame()
    ))
  }
  
  all_errors <- data.frame(
    module = character(),
    error_message = character(),
    category = character(),
    index = integer(),
    stringsAsFactors = FALSE
  )
  
  modules_with_errors <- character()
  
  for (i in seq_along(results_list)) {
    result <- results_list[[i]]
    
    if (!inherits(result, "module_result")) next
    
    module_name <- result$module_name %||% "unknown"
    
    if (length(result$errors) > 0) {
      modules_with_errors <- c(modules_with_errors, module_name)
      
      for (j in seq_along(result$errors)) {
        category <- get_error_category(result, j)
        all_errors <- rbind(all_errors, data.frame(
          module = module_name,
          error_message = result$errors[[j]],
          category = category,
          index = j,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  # Count warnings
  total_warnings <- sum(sapply(results_list, \(r) {
    if (inherits(r, "module_result")) length(r$warnings) else 0
  }))
  
  list(
    total_errors = nrow(all_errors),
    total_warnings = total_warnings,
    modules_with_errors = unique(modules_with_errors),
    n_modules_affected = length(unique(modules_with_errors)),
    error_summary = all_errors,
    error_counts_by_category = if (nrow(all_errors) > 0) {
      table(all_errors$category)
    } else {
      integer()
    }
  )
}

#' Print Formatted Error Report
#'
#' Display error report in human-readable format
#'
#' @param report List returned by generate_error_report()
#'
#' @return Invisible NULL (prints to console)
print_error_report <- function(report) {
  
  cat("=" %*% 60, "\n", sep = "")
  cat("ERROR REPORT\n")
  cat("=" %*% 60, "\n", sep = "")
  
  cat(sprintf("Total Errors: %d\n", report$total_errors))
  cat(sprintf("Total Warnings: %d\n", report$total_warnings))
  cat(sprintf("Modules Affected: %d\n", report$n_modules_affected))
  
  if (report$total_errors > 0) {
    cat("\n")
    cat("ERRORS BY CATEGORY:\n")
    for (category in names(report$error_counts_by_category)) {
      count <- report$error_counts_by_category[[category]]
      cat(sprintf("  %s: %d\n", category, count))
    }
    
    cat("\nERRORS BY MODULE:\n")
    for (module in unique(report$error_summary$module)) {
      errors <- report$error_summary[report$error_summary$module == module, ]
      cat(sprintf("  %s: %d error(s)\n", module, nrow(errors)))
      
      for (i in seq_len(min(3, nrow(errors)))) {
        cat(sprintf("    - [%s] %s\n",
                    errors$category[[i]],
                    substring(errors$error_message[[i]], 1, 50)))
      }
      if (nrow(errors) > 3) {
        cat(sprintf("    ... and %d more\n", nrow(errors) - 3))
      }
    }
  }
  
  invisible(NULL)
}

# ============================================================================
# SECTION 4: Integration with Error Trapping
# ============================================================================

#' Collect All Errors from a Pipeline Run
#'
#' Intended to be called at end of pipeline to aggregate all
#' errors that occurred during execution.
#'
#' @param pipeline_results List of results from all modules
#' @param halt_on_error If TRUE, stop pipeline if any errors
#'
#' @return List with aggregated error information (invisibly)
trap_pipeline_errors <- function(pipeline_results, halt_on_error = FALSE) {
  
  report <- generate_error_report(pipeline_results)
  
  if (report$total_errors > 0) {
    print_error_report(report)
    
    if (isTRUE(halt_on_error)) {
      stop(sprintf(
        "Pipeline halted: %d error(s) in %d module(s)",
        report$total_errors,
        report$n_modules_affected
      ))
    }
  }
  
  invisible(report)
}

# ============================================================================
# SECTION 5: Helper Functions & Utilities
# ============================================================================

#' Get Error Category Description
#'
#' @param category Category code from ERROR_CATEGORIES
#'
#' @return Human-readable description
get_category_description <- function(category) {
  ERROR_CATEGORIES[[category]] %||% "Unknown error category"
}

#' List All Error Categories
#'
#' Display available error categories with descriptions
#'
#' @return Invisible data frame
list_error_categories <- function() {
  
  categories_df <- data.frame(
    category = names(ERROR_CATEGORIES),
    description = unlist(ERROR_CATEGORIES),
    stringsAsFactors = FALSE
  )
  
  cat("Available Error Categories:\n")
  print(categories_df, row.names = FALSE)
  cat("\n")
  
  invisible(categories_df)
}

#' Format Error for Display
#'
#' @param error_message Error message
#' @param category Error category
#' @param details Additional details (optional)
#'
#' @return Formatted error string
format_error_for_display <- function(
  error_message,
  category = "UNKNOWN_ERROR",
  details = NULL
) {
  
  category_desc <- get_category_description(category)
  
  out <- sprintf("ERROR [%s]:\n  %s\n  Category: %s",
                 category, error_message, category_desc)
  
  if (!is.null(details) && length(details) > 0) {
    out <- sprintf("%s\n  Details:\n", out)
    for (name in names(details)) {
      out <- sprintf("%s    %s: %s\n", out, name, details[[name]])
    }
  }
  
  out
}

# ============================================================================
# END: ERROR/LOGGING INTERFACE
# ============================================================================
