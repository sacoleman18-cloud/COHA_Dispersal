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
# FILE DISCOVERY (Phase 0b addition from Reference_code)
# ==============================================================================

#' Find Most Recent File Matching Pattern (by Filename Timestamp)
#'
#' @description
#' Searches a directory for files matching a regex pattern and returns the
#' file with the most recent timestamp embedded in its filename.
#' Adapted from KPro Reference_code for COHA use.
#'
#' @param directory Character. Directory to search (not recursive).
#' @param pattern Character. Regex pattern to match filenames.
#' @param error_if_none Logical. Stop with error if no files found? Default: TRUE
#' @param hint Character or NULL. Hint message if no files found. Default: NULL
#'
#' @return Character. Full path to most recent file, or NULL if none found
#'   and error_if_none = FALSE.
#'
#' @section Timestamp Extraction:
#' Expects filenames with YYYYMMDD_HHMMSS timestamp:
#' - summary_data_20260211_143025.rds
#' - plot_results_20260211_143025.rds
#'
#' @section CONTRACT:
#' - Uses filename timestamps (not file modification time)
#' - Deterministic across file systems
#' - Returns full path with here::here()
#' - Stops with actionable error if no files found and error_if_none = TRUE
#'
#' @examples
#' \dontrun{
#' # Find most recent plot results
#' latest <- find_most_recent_file(
#'   directory = "results/rds",
#'   pattern = "^plot_results_.*\\.rds$"
#' )
#' }
#'
#' @export
find_most_recent_file <- function(directory,
                                  pattern,
                                  error_if_none = TRUE,
                                  hint = NULL) {
  
  # List matching files
  matching_files <- list.files(
    directory,
    pattern = pattern,
    full.names = TRUE
  )
  
  if (length(matching_files) == 0) {
    if (error_if_none) {
      hint_msg <- if (!is.null(hint)) sprintf("\n  Hint: %s", hint) else ""
      stop(sprintf("No files matching '%s' found in %s%s", pattern, directory, hint_msg))
    } else {
      return(NULL)
    }
  }
  
  # Extract timestamps from filenames
  basenames <- basename(matching_files)
  timestamps <- sub(".*_(\\d{8}_\\d{6})(?:_.*?)?\\.\\w+$", "\\1", basenames)
  
  # Convert to POSIXct for proper datetime sorting
  if (!requireNamespace("lubridate", quietly = TRUE)) {
    # Fallback: string sorting (works for YYYYMMDD_HHMMSS)
    most_recent_idx <- which.max(timestamps)
  } else {
    timestamps_dt <- lubridate::ymd_hms(timestamps, quiet = TRUE)
    
    # Filter out files where timestamp parsing failed
    valid_idx <- !is.na(timestamps_dt)
    
    if (!any(valid_idx)) {
      if (error_if_none) {
        stop(sprintf(
          "No files with valid timestamps found matching '%s' in %s\n  Expected format: ..._YYYYMMDD_HHMMSS.ext",
          pattern, directory
        ))
      } else {
        return(NULL)
      }
    }
    
    # Keep only valid timestamped files
    matching_files <- matching_files[valid_idx]
    timestamps_dt <- timestamps_dt[valid_idx]
    
    # Sort by actual datetime (descending - most recent first)
    sorted_idx <- order(timestamps_dt, decreasing = TRUE)
    most_recent_idx <- sorted_idx[1]
  }
  
  matching_files[most_recent_idx]
}


#' Generate Versioned Output Path (Auto-Increment)
#'
#' @description
#' Creates output path with auto-incrementing version number.
#' Scans directory for existing versions and increments to next available.
#'
#' @param base_name Character. Base name for file.
#' @param extension Character. File extension. Default: "csv"
#' @param output_dir Character. Output directory. Default: "results"
#'
#' @return Character. Full file path string with version number.
#'
#' @section CONTRACT:
#' - Scans output_dir for existing versions
#' - Increments to next available version number
#' - Returns path only (does not create file)
#'
#' @examples
#' \dontrun{
#' path <- make_versioned_path("ridgeline_summary", "csv", "results")
#' # First call:  "results/ridgeline_summary_v1.csv"
#' # Second call: "results/ridgeline_summary_v2.csv"
#' # Third call:  "results/ridgeline_summary_v3.csv"
#' }
#'
#' @export
make_versioned_path <- function(base_name,
                                extension = "csv",
                                output_dir = "results") {
  
  pattern <- sprintf("^%s_v(\\d+)\\.%s$", base_name, extension)
  existing <- list.files(output_dir, pattern = pattern)
  
  if (length(existing) == 0) {
    next_version <- 1
  } else {
    versions <- as.integer(sub(pattern, "\\1", existing))
    next_version <- max(versions) + 1
  }
  
  filename <- sprintf("%s_v%d.%s", base_name, next_version, extension)
  
  file.path(output_dir, filename)
}


#' Fill README Template
#'
#' @description
#' Populates a README template with project parameters and pipeline metadata.
#' Used in release bundle generation.
#'
#' @param template_path Character. Path to README template file.
#' @param output_path Character. Path for output README.md.
#' @param parameters List. Project parameters (from config).
#' @param replacements List. Named list of placeholder → value mappings.
#'   Defaults will look for {{PLACEHOLDER}} and replace.
#'
#' @return Invisible TRUE.
#'
#' @section CONTRACT:
#' - Replaces {{PLACEHOLDER}} strings in template
#' - Creates output directory if needed
#' - Writes filled template to output_path
#'
#' @examples
#' \dontrun{
#' fill_readme_template(
#'   template_path = "templates/README_template.md",
#'   output_path = "results/releases/README.md",
#'   replacements = list(
#'     PROJECT_NAME = "COHA Dispersal Analysis",
#'     VERSION = "1.0",
#'     DATE = format(Sys.Date(), "%Y-%m-%d")
#'   )
#' )
#' }
#'
#' @export
fill_readme_template <- function(template_path,
                                 output_path,
                                 parameters = NULL,
                                 replacements = list()) {
  
  # Read template
  if (!file.exists(template_path)) {
    stop(sprintf("Template not found: %s", template_path))
  }
  
  template_text <- readLines(template_path)
  
  # Replace placeholders
  filled_text <- template_text
  for (key in names(replacements)) {
    placeholder <- sprintf("{{%s}}", key)
    filled_text <- gsub(placeholder, replacements[[key]], filled_text, fixed = TRUE)
  }
  
  # Ensure output directory exists
  ensure_dir_exists(dirname(output_path))
  
  # Write filled template
  writeLines(filled_text, output_path)
  
  invisible(TRUE)
}

# ==============================================================================
# END R/functions/core/utilities.R
# ==============================================================================
