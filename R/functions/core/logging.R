# ==============================================================================
# R/functions/logging.R
# ==============================================================================
# PURPOSE
# -------
# File-based and console logging for complete audit trail of pipeline operations.
# Every significant operation should be logged.
#
# DEPENDS ON
# ----------
# - here::here() for path management
# - base R only for core functions
#
# INPUTS
# ------
# Messages, log levels, verbose flags
#
# OUTPUTS
# -------
# - logs/pipeline_YYYY-MM-DD.log (append mode)
# - Console output (if verbose = TRUE)
#
# USAGE
# -----
# source("R/functions/logging.R")
# log_message("Pipeline started", level = "INFO", verbose = TRUE)
# log_message("Generated plot 5", level = "DEBUG", verbose = FALSE)
#
# ==============================================================================

#' Initialize Pipeline Logging
#'
#' @description
#' Creates logs directory if needed and returns path to today's log file.
#' Call once at pipeline start; all future log_message() calls append to this file.
#'
#' @param verbose Logical. Print initialization message to console.
#'   Default: FALSE.
#'
#' @return Character. Path to log file (returned invisibly).
#'   File path includes date: logs/pipeline_YYYY-MM-DD.log
#'
#' @details
#' **File Naming:** Uses Sys.Date() so all operations on same calendar day share
#' one log file. Different dates automatically get new log files.
#'
#' **Determinism:** Uses here::here("logs") so log directory is always
#' relative to project root, enabling portable paths across machines.
#'
#' **Directory Creation:** Creates logs/ directory with recursive=TRUE if missing.
#' Safe for concurrent pipeline calls (no race conditions with showWarnings=FALSE).
#'
#' **Design Pattern:** Should be called once at pipeline initialization:
#' ```r
#' log_file <- initialize_pipeline_log(verbose = TRUE)
#' # Now all log_message() calls append to this file
#' ```
#'
#' @examples
#' \dontrun{
#' # At pipeline start
#' log_file <- initialize_pipeline_log(verbose = TRUE)
#' # Returns: logs/pipeline_2026-02-10.log
#' }
#'
#' @seealso [log_message()], [get_log_file()], [show_log()]
#'
#' @export
initialize_pipeline_log <- function(verbose = FALSE) {
  # Require here package
  if (!requireNamespace("here", quietly = TRUE)) {
    stop("Package 'here' required. Install with: install.packages('here')",
         call. = FALSE)
  }
  
  log_dir <- here::here("logs")
  
  # Create logs directory if it doesn't exist
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)
  }
  
  # Create log file path with today's date
  log_file <- file.path(
    log_dir,
    sprintf("pipeline_%s.log", format(Sys.Date(), "%Y-%m-%d"))
  )
  
  if (verbose) {
    message(sprintf("[LOG] Initialized: %s", log_file))
  }
  
  invisible(log_file)
}

#' Get Today's Log File Path
#'
#' @description
#' Returns path to today's log file without creating it or writing to it.
#' Useful for checking log file location without side effects.
#'
#' @return Character. Path to log file (returned invisibly).
#'   Returns path even if file doesn't exist yet.
#'
#' @details
#' **No Side Effects:** Unlike initialize_pipeline_log(), this function:
#' - Does NOT create the logs/ directory
#' - Does NOT create the log file
#' - Does NOT write any messages
#'
#' Useful for querying log path in functions that don't initialize logging
#' (assumes initialize_pipeline_log() was called elsewhere).
#'
#' @examples
#' \dontrun{
#' # Get log file path without side effects
#' log_file <- get_log_file()
#' # Returns: logs/pipeline_2026-02-10.log
#' }
#'
#' @seealso [initialize_pipeline_log()], [show_log()]
#'
#' @export
get_log_file <- function() {
  if (!requireNamespace("here", quietly = TRUE)) {
    stop("Package 'here' required.", call. = FALSE)
  }
  
  file.path(
    here::here("logs"),
    sprintf("pipeline_%s.log", format(Sys.Date(), "%Y-%m-%d"))
  )
}

#' Log Message to File and/or Console
#'
#' @description
#' Records timestamped message to log file with optional console output.
#' Core logging function used by all logging operations.
#'
#' @param message Character. Message text to log.
#' @param level Character. Log severity level. One of:
#'   "ERROR", "WARN", "INFO", "DEBUG".
#'   Default: "INFO".
#' @param verbose Logical. Also print message to console.
#'   Default: FALSE (logs to file only).
#' @param to_file Logical. Write to log file. Default: TRUE.
#'   Set FALSE to only print console (rare).
#'
#' @return Invisible logical TRUE (invisibly).
#'
#' @details
#' **Log Format:** [YYYY-MM-DD HH:MM:SS] [LEVEL] message
#' Example: [2026-02-10 14:30:45] [INFO] Pipeline started
#'
#' **Verbose Gating:** Controls console output independent of file writing.
#' - verbose=FALSE (default): Logs to file silently
#' - verbose=TRUE: Prints to console AND logs to file
#'
#' **Day Boundaries:** Automatically creates new log file at midnight.
#' Each calendar day gets its own log file (pipeline_YYYY-MM-DD.log).
#'
#' **Safe I/O:** Uses tryCatch() so file write failures produce warning,
#' not error. Pipeline continues even if logging fails.
#'
#' **Log Levels:** Used for filtering in tools/dashboards:
#' - ERROR: Critical failures
#' - WARN: Problems that might affect results
#' - INFO: Major milestones (default)
#' - DEBUG: Detailed operational information
#'
#' @examples
#' # Log to file silently (typical)
#' log_message("Pipeline started")
#'
#' # Log with console output (debugging)
#' log_message("Generated plot 5", level = "DEBUG", verbose = TRUE)
#'
#' # Error logging
#' log_message("Unexpected value in mass column", "ERROR", verbose = TRUE)
#'
#' @seealso [initialize_pipeline_log()], [log_entry()], [log_success()], [log_error()]
#'
#' @export
log_message <- function(message, level = "INFO", verbose = FALSE, to_file = TRUE) {
  # Validate level
  valid_levels <- c("ERROR", "WARN", "INFO", "DEBUG")
  if (!level %in% valid_levels) {
    stop(sprintf("Invalid log level '%s'. Must be one of: %s",
                 level, paste(valid_levels, collapse = ", ")),
         call. = FALSE)
  }
  
  # Format message with timestamp
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  formatted <- sprintf("[%s] [%s] %s", timestamp, level, message)
  
  # Write to file if requested
  if (to_file) {
    tryCatch(
      {
        log_dir <- here::here("logs")
        if (!dir.exists(log_dir)) {
          dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)
        }
        
        log_file <- file.path(
          log_dir,
          sprintf("pipeline_%s.log", format(Sys.Date(), "%Y-%m-%d"))
        )
        
        cat(formatted, "\n", file = log_file, append = TRUE)
      },
      error = function(e) {
        warning("Could not write to log file", call. = FALSE)
      }
    )
  }
  
  # Print to console if requested
  if (verbose) {
    cat(formatted, "\n")
  }
  
  invisible(TRUE)
}

#' Log Pipeline Entry
#'
#' @description
#' Convenience function to log the start of an operation.
#' Automatically prepends "[START]" to message.
#'
#' @param operation Character. Name of operation being started
#'   (e.g., "Loading data", "Generating plots").
#' @param verbose Logical. Print to console. Default: FALSE.
#'
#' @return Invisible logical TRUE.
#'
#' @details
#' Shortcut for log_message(sprintf("[START] %s", operation), ...)
#' Useful for marking entry points to major code sections.
#'
#' **Example Log Output:**
#' [2026-02-10 14:30:45] [INFO] [START] Loading data
#'
#' @examples
#' log_entry("Loading raw data", verbose = FALSE)
#' log_entry("Generating ridgeline plots", verbose = TRUE)
#'
#' @seealso [log_success()], [log_error()]
#'
#' @export
log_entry <- function(operation, verbose = FALSE) {
  msg <- sprintf("[START] %s", operation)
  log_message(msg, level = "INFO", verbose = verbose)
}

#' Log Pipeline Success
#'
#' @description
#' Convenience function to log successful operation completion.
#' Automatically prepends "[COMPLETE]" to message.
#'
#' @param operation Character. Name of completed operation
#'   (e.g., "Loading data", "Generating plots").
#' @param details Character. Optional additional details about result
#'   included in parentheses. Default: "" (no details).
#' @param verbose Logical. Print to console. Default: FALSE.
#'
#' @return Invisible logical TRUE.
#'
#' @details
#' Shortcut for building success messages. Example:
#' log_success("Generated plots", "20 variants created", verbose=TRUE)
#' produces: [COMPLETE] Generated plots (20 variants created)
#'
#' **Example Log Output:**
#' [2026-02-10 14:30:47] [INFO] [COMPLETE] Generating ridgeline plots (20 plots)
#'
#' @examples
#' log_success("Data loading", verbose = FALSE)
#' log_success("Ridgeline generation", "Created 20 plots", verbose = TRUE)
#'
#' @seealso [log_entry()], [log_error()]
#'
#' @export
log_success <- function(operation, details = "", verbose = FALSE) {
  if (details == "") {
    msg <- sprintf("[COMPLETE] %s", operation)
  } else {
    msg <- sprintf("[COMPLETE] %s (%s)", operation, details)
  }
  log_message(msg, level = "INFO", verbose = verbose)
}

#' Log Pipeline Error
#'
#' @description
#' Convenience function to log operation failure.
#' Automatically sets log level to "ERROR" and formats message.
#'
#' @param operation Character. Name of failed operation.
#' @param error Character. Error message or description of what failed.
#' @param verbose Logical. Print to console. Default: FALSE.
#'
#' @return Invisible logical TRUE.
#'
#' @details
#' Shortcut for log_message(..., level="ERROR", ...)
#' Useful for consistent error logging across pipeline.
#'
#' **Example Log Output:**
#' [2026-02-10 14:30:46] [ERROR] Data validation - Column 'mass' not found
#'
#' **Design:** Always uses level="ERROR" so these entries stand out in logs.
#'
#' @examples
#' \dontrun{
#' tryCatch(
#'   { assert_columns_exist(df, "mass") },
#'   error = function(e) {
#'     log_error("Data validation", "Column missing", verbose = TRUE)
#'   }
#' )
#' }
#'
#' @seealso [log_entry()], [log_success()]
#'
#' @export
log_error <- function(operation, error, verbose = FALSE) {
  msg <- sprintf("[ERROR] %s - %s", operation, error)
  log_message(msg, level = "ERROR", verbose = verbose)
}

#' Print Log File Contents
#'
#' @description
#' Display contents of current log file (today's) to console.
#' Useful for debugging and monitoring pipeline progress.
#'
#' @param n_lines Numeric. Number of most recent lines to show.
#'   Default: 50. Set to NULL to show all lines.
#'
#' @return Invisible NULL (invisibly).
#'   Side effect: prints log contents to console with line numbers.
#'
#' @details
#' **Line Numbering:** Leftmost column shows line numbers for reference.
#' Useful when log is long; count from bottom = recent operations.
#'
#' **No File Created:** Does NOT create log file if it doesn't exist.
#' Prints message "No log file exists yet" instead.
#'
#' **Tail Behavior:** With default n_lines=50, shows last 50 lines
#' (most recent operations). Set n_lines=NULL for complete log.
#'
#' **Use Cases:**
#' - Check if latest pipeline run succeeded: show_log() 
#' - Debug specific phase: show_log(100) for more context
#' - Archive before new run: show_log(NULL) to analyze complete log
#'
#' @examples
#' \dontrun{
#' # After running pipeline, check final messages
#' show_log()        # Last 50 lines (default)
#'
#' # Get more context for debugging
#' show_log(100)     # Last 100 lines
#'
#' # Review complete log from pipeline start
#' show_log(NULL)    # All lines
#' }
#'
#' @seealso [initialize_pipeline_log()], [log_message()]
#'
#' @export
show_log <- function(n_lines = 50) {
  log_file <- get_log_file()
  
  if (!file.exists(log_file)) {
    message("No log file exists yet")
    return(invisible(NULL))
  }
  
  # Read all lines
  lines <- readLines(log_file)
  
  # Show last n_lines (or all if NULL)
  if (!is.null(n_lines) && n_lines < length(lines)) {
    start_idx <- length(lines) - n_lines + 1
    lines <- lines[start_idx:length(lines)]
  }
  
  # Print with line numbers
  for (i in seq_along(lines)) {
    cat(sprintf("%4d: %s\n", i, lines[i]))
  }
  
  invisible(NULL)
}

# ==============================================================================
# END R/functions/logging.R
# ==============================================================================
