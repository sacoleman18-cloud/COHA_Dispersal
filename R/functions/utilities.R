# ==============================================================================
# R/functions/utilities.R
# ==============================================================================
# PURPOSE
# -------
# Foundational utilities with ZERO internal dependencies.
# Provides safe I/O, file discovery, and path generation.
# Adapted from reference project for COHA ridgeline analysis.
#
# DEPENDS ON
# ----------
# - readr (read_csv)
# - base R (file operations, string handling)
#
# INPUTS
# ------
# Various: File paths, data frames, strings
#
# OUTPUTS
# -------
# - Utility functions with safe error handling
# - File I/O operations
# - Path generation with timestamps
#
# USAGE
# -----
# source("R/functions/utilities.R")
# df <- safe_read_csv("data/raw.csv", verbose = TRUE)
# ensure_dir_exists("results/plots")
# path <- make_output_path("plots", "ridgeline_01")
#
# ==============================================================================

# ==============================================================================
# OPERATORS
# ==============================================================================

#' Null Coalescing Operator
#'
#' @description
#' Returns left operand if not NULL, otherwise returns right operand.
#' Clean syntax for providing default values without if-else statements.
#'
#' @usage x %||% y
#'
#' @param x First value to test. If not NULL, returned.
#' @param y Default/fallback value if x is NULL.
#'
#' @return x if not NULL; otherwise y.
#'
#' @details
#' **Infix operator syntax:** x %||% y (not a function call)
#'
#' **Use cases:**
#' - config value or default: get_option("key") %||% "default"
#' - Function parameter defaults: param %||% computed_default
#' - Safe fallback chaining: x %||% y %||% z
#'
#' **Design:** Tests only NULL, not FALSE or NA.
#' Use conditional() if you need to check those values.
#'
#' @examples
#' # With NULL, returns default
#' value <- NULL %||% "default"
#' # Returns: "default"
#'
#' # With value, returns value
#' value <- "actual" %||% "default"
#' # Returns: "actual"
#'
#' # Chaining multiple defaults
#' value <- NULL %||% NULL %||% "fallback"
#' # Returns: "fallback"
#'
#' @seealso [ensure_dir_exists()] for directory utilities
#'
#' @export
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# ==============================================================================
# DIRECTORY MANAGEMENT
# ==============================================================================

#' Ensure Directory Exists
#'
#' @description
#' Creates directory if it doesn't exist, with all parent directories.
#' Safe to call multiple times (idempotent).
#' Used internally to guarantee output directories are available before file operations.
#'
#' @param dir_path Character. Directory path to ensure exists.
#'
#' @return Invisible logical TRUE.
#'
#' @details
#' **Recursive Creation:** Uses dir.create(recursive=TRUE) so creates all
#' parent directories in path if needed. Example:
#' ensure_dir_exists("results/plots/ridgeline/variants/compact")
#' creates the entire nested directory structure.
#'
#' **Idempotent:** Safe to call when directory already exists.
#' Does not error or warn if directory exists.
#'
#' **Silent Failures:** Uses showWarnings=FALSE so concurrent file creation
#' by another process doesn't produce spurious warnings.
#'
#' **Use in Pipelines:** Call before any write operation:
#' ```r
#' ensure_dir_exists("results")
#' saveRDS(plots, "results/plots.rds")
#' ```
#'
#' @examples
#' \dontrun{
#' # Create single directory
#' ensure_dir_exists("results")
#'
#' # Create nested structure
#' ensure_dir_exists("results/plots/ridgeline/variants")
#' }
#'
#' @seealso [safe_read_csv()], [make_output_path()]
#'
#' @export
ensure_dir_exists <- function(dir_path) {
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(TRUE)
}

# ==============================================================================
# SAFE I/O
# ==============================================================================

#' Safely Read a CSV File
#'
#' @description
#' Reads a CSV file from disk without stopping on failure.
#' Returns NULL on error instead of throwing, enabling continued pipeline execution.
#' Error details logged to disk with timestamps.
#'
#' @param file_path Character. Path to CSV file to read.
#' @param error_log_path Character. Path where errors are appended.
#'   Default: "logs/error_log.txt".
#' @param verbose Logical. Print progress messages to console.
#'   Default: FALSE.
#' @param ... Additional arguments passed to readr::read_csv().
#'   Example: col_types for specifying column types.
#'
#' @return Tibble (data frame) if read succeeds; NULL if read fails.
#'
#' @details
#' **Safe I/O Contract:**
#' - Returns NULL on failure (doesn't stop execution)
#' - Logs errors to file with timestamps
#' - Suppresses column type inference messages from readr
#' - Reads all columns as character initially (safe default)
#'
#' **Error Logging:** Each error appended to error_log_path with format:
#' YYYY-MM-DD HH:MM:SS - filepath - error message
#'
#' **Verbose Output:** When verbose=TRUE, shows:
#' - "Reading: filename"
#' - "✓ Loaded N rows, M columns" (on success)
#'
#' **Pipeline Integration:** Typical usage:
#' ```r
#' df <- safe_read_csv(here::here("data", "data.csv"), verbose = FALSE)
#' if (is.null(df)) stop("Data file missing or corrupted")
#' ```
#'
#' @examples
#' \dontrun{
#' # Basic usage - silent on errors
#' df <- safe_read_csv("data/data.csv")
#' if (is.null(df)) {
#'   warning("Failed to load data; using defaults")
#'   df <- get_default_data()
#' }
#'
#' # With progress messages
#' df <- safe_read_csv("data/data.csv", verbose = TRUE)
#'
#' # With custom error log location
#' df <- safe_read_csv(
#'   "data/data.csv",
#'   error_log_path = here::here("logs", "read_errors.log")
#' )
#' }
#'
#' @seealso [ensure_dir_exists()], [convert_empty_to_na()]
#'
#' @export
safe_read_csv <- function(file_path,
                          error_log_path = "logs/error_log.txt",
                          verbose = FALSE,
                          ...) {
  
  # Input validation
  if (!is.character(file_path) || length(file_path) != 1) {
    stop("file_path must be a single character string", call. = FALSE)
  }
  
  # Ensure log directory exists
  ensure_dir_exists(dirname(error_log_path))
  
  # Progress message
  if (verbose) {
    message(sprintf("  Reading: %s", basename(file_path)))
  }
  
  result <- NULL
  
  tryCatch(
    {
      result <- readr::read_csv(
        file_path,
        col_types = readr::cols(.default = readr::col_character()),
        show_col_types = FALSE,
        ...
      )
      
      # Success message
      if (!is.null(result) && verbose) {
        message(sprintf("  ✓ Loaded %s rows, %d columns",
                       format(nrow(result), big.mark = ","),
                       ncol(result)))
      }
    },
    error = function(e) {
      msg <- paste(Sys.time(), "-", file_path, "-", e$message)
      writeLines(msg, error_log_path, useBytes = TRUE)
    }
  )
  
  result
}

#' Convert Empty Strings to NA
#'
#' @description
#' Replaces empty or whitespace-only strings with NA in selected columns.
#' Useful for data cleaning after CSV import where empty strings should be NA.
#'
#' @param df Data frame to clean.
#' @param columns Character vector of column names to process.
#'   Only these columns are modified.
#'
#' @return Data frame with empty strings replaced by NA in specified columns.
#'   Other columns unchanged.
#'
#' @details
#' **Whitespace Handling:** Uses trimws() before checking, so whitespace-only
#' cells (" ", "  ", etc.) are also converted to NA.
#'
#' **Column Selection:** Only columns listed in columns parameter are modified.
#' Other columns left untouched.
#'
#' **Data Frame Type:** Returns same class as input (data.frame or tibble).
#' Uses dplyr::mutate() internally.
#'
#' **Quality Assurance:** Useful in data validation pipeline:
#' ```r
#' df <- convert_empty_to_na(df, c("origin", "dispersed"))
#' assert_no_na(df, "origin")  # Ensure now has no NAs
#' ```
#'
#' @examples
#' \dontrun{
#' # Clean character columns
#' df <- convert_empty_to_na(df, c("origin", "dispersed"))
#'
#' # Multiple columns at once
#' bad_cols <- c("origin", "dispersed", "status")
#' df <- convert_empty_to_na(df, bad_cols)
#' }
#'
#' @seealso [safe_read_csv()] for file I/O
#'
#' @export
convert_empty_to_na <- function(df, columns) {
  
  if (!is.data.frame(df)) {
    stop("df must be a data frame", call. = FALSE)
  }
  
  if (!is.character(columns)) {
    stop("columns must be a character vector", call. = FALSE)
  }
  
  missing_cols <- setdiff(columns, names(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Columns not found: %s", paste(missing_cols, collapse = ", ")),
         call. = FALSE)
  }
  
  # Replace empty strings with NA
  df %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(columns),
        ~ ifelse(trimws(.) == "", NA, .)
      )
    )
}

# ==============================================================================
# PATH GENERATION
# ==============================================================================

#' Generate Timestamped Output Path
#'
#' @description
#' Creates an output file path with timestamp for audit trail.
#' Useful for creating time-stamped output files that don't overwrite.
#'
#' @param base_name Character. Base name for the file (without extension).
#'   Example: "ridgeline_summary"
#' @param extension Character. File extension without dot.
#'   Default: "csv".
#' @param output_dir Character. Output directory path.
#'   Default: "results".
#'
#' @return Character. Full file path string with timestamp.
#'   Does not create file or directory.
#'
#' @details
#' **Path Construction:**
#' output_dir / base_name_YYYYMMDD_HHMMSS.extension
#'
#' **Example Output:**
#' make_output_path("ridgeline_summary")
#' → "results/ridgeline_summary_20260210_143530.csv"
#'
#' **Timestamp Format:** YYYYMMDD_HHMMSS (year, month, day, underscore,
#' hour, minute, second). Sortable and human-readable.
#'
#' **No Side Effects:** Returns path string only.
#' Caller is responsible for creating directory (via ensure_dir_exists)
#' and writing file (via write.csv, readr::write_csv, etc.).
#'
#' **Pipeline Integration:**
#' ```r
#' ensure_dir_exists("results")
#' path <- make_output_path("plots", "png", "results/plots")
#' saveRDS(df, path)
#' ```
#'
#' @examples
#' \dontrun{
#' # Default: CSV to results/
#' path <- make_output_path("summary")
#' # → "results/summary_20260210_143530.csv"
#'
#' # Custom extension and directory
#' path <- make_output_path("report", "html", "reports")
#' # → "reports/report_20260210_143530.html"
#'
#' # Use in pipeline
#' output_path <- make_output_path("ridgeline_data", "rds", "results")
#' saveRDS(processed_data, output_path)
#' }
#'
#' @seealso [ensure_dir_exists()], [safe_read_csv()]
#'
#' @export
make_output_path <- function(base_name,
                             extension = "csv",
                             output_dir = "results") {
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- sprintf("%s_%s.%s", base_name, timestamp, extension)
  
  file.path(output_dir, filename)
}

# ==============================================================================
# END R/functions/utilities.R
# ==============================================================================
