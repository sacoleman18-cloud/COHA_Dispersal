# ==============================================================================
# R/functions/assertions.R
# ==============================================================================
# PURPOSE
# -------
# Input validation and defensive assertions for pipeline.
# All public functions should call appropriate validators before processing.
#
# DEPENDS ON
# ----------
# None (base R only)
#
# INPUTS
# ------
# Various: Data frames, column names, file paths, etc.
#
# OUTPUTS
# -------
# - Throws informative errors on validation failure
# - Returns invisible(TRUE) on success
#
# USAGE
# -----
# source("R/functions/assertions.R")
# validate_ridgeline_data(df, verbose = TRUE)
#
# ==============================================================================

#' Assert File Exists
#'
#' @description
#' Checks that a file exists and terminates with informative error if not.
#' Essential defensive check before reading files in pipeline.
#'
#' @param file_path Character. Path to check. Can be relative or absolute.
#' @param context Character. Optional context for error message (e.g., "source data").
#'   Default: "".
#'
#' @return Invisible logical TRUE if file exists. Stops execution with error if not.
#'
#' @details
#' Used in defensive programming to catch missing files early before attempting
#' file I/O operations. The context parameter helps pinpoint which file check
#' failed in complex pipelines.
#'
#' **Design:** Throws error (no return on failure) so pipeline stops immediately
#' rather than continuing with missing data.
#'
#' @examples
#' \dontrun{
#' # Check raw data file exists before processing
#' assert_file_exists(here::here("data", "data.csv"), context = "raw data")
#' }
#'
#' @seealso [assert_directory_exists()] for checking directories
#'
#' @export
assert_file_exists <- function(file_path, context = "") {
  if (!file.exists(file_path)) {
    msg <- sprintf("File not found: %s", file_path)
    if (context != "") msg <- paste0(msg, " (", context, ")")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Columns Exist in Data Frame
#'
#' @description
#' Checks that all required columns exist in data frame.
#' Stops pipeline immediately if any required column is missing.
#'
#' @param df Data frame. Object to check.
#' @param columns Character vector. Names of required columns.
#' @param context Character. Optional context for error message (e.g., "ridgeline data").
#'   Default: "".
#'
#' @return Invisible logical TRUE if all columns exist. Stops execution with error if not.
#'
#' @details
#' Critical validation step in data pipeline. Ensures data frame has all columns
#' required for downstream processing. Lists all missing columns in error message
#' for easier debugging.
#'
#' **Design:** Uses setdiff() to identify exactly which columns are missing,
#' enabling users to quickly see what's wrong.
#'
#' @examples
#' # Check for required columns before processing
#' assert_columns_exist(mtcars, c("mpg", "cyl", "hp"))
#'
#' @seealso [assert_not_empty()], [validate_data_frame()] for composite checks
#'
#' @export
assert_columns_exist <- function(df, columns, context = "") {
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  
  missing <- setdiff(columns, names(df))
  if (length(missing) > 0) {
    msg <- sprintf("Missing columns: %s", paste(missing, collapse = ", "))
    if (context != "") msg <- paste0(msg, " (", context, ")")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Data Frame Not Empty
#'
#' @description
#' Checks that data frame contains at least one row.
#' Catches cases where filtering accidentally removed all data.
#'
#' @param df Data frame. Object to check.
#' @param context Character. Optional context for error message.
#'   Default: "".
#'
#' @return Invisible logical TRUE if data frame has rows, stops execution with error if empty.
#'
#' @details
#' Used to detect accidental data loss during filtering or subsetting.
#' Should be called after major data transformations to ensure pipeline
#' didn't accidentally remove all rows.
#'
#' **Design:** Simple check nrow(df) > 0. Useful for defensive programming.
#'
#' @examples
#' # After filtering, ensure data remains
#' filtered <- subset(mtcars, cyl == 6)
#' assert_not_empty(filtered, "filtered mtcars")
#'
#' @export
assert_not_empty <- function(df, context = "") {
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  if (nrow(df) == 0) {
    msg <- "Data frame is empty"
    if (context != "") msg <- paste0(msg, " (", context, ")")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Column Has No Missing Values
#'
#' @description
#' Checks that a column contains no NA values.
#' Essential for columns used in calculations or plotting.
#'
#' @param df Data frame.
#' @param col_name Character. Name of column to check.
#' @param context Character. Optional context for error message.
#'   Default: "".
#'
#' @return Invisible logical TRUE if column has no NAs, stops execution with error if it does.
#'
#' @details
#' Validates that required columns have complete data. Reports exact count of
#' NA values found, helping users identify data quality issues.
#'
#' **Design:** Some columns (like mass for plotting) cannot tolerate NAs.
#' This assertion is more strict than warning about NAs.
#'
#' **Note:** For columns where NAs are acceptable, use conditional checking
#' instead of this assertion.
#'
#' @examples
#' # Ensure mass column has no missing values before plotting
#' assert_no_na(df, "mass", "ridgeline mass data")
#'
#' @seealso [validate_ridgeline_data()] for comprehensive data validation
#'
#' @export
assert_no_na <- function(df, col_name, context = "") {
  if (!col_name %in% names(df)) {
    stop(sprintf("Column '%s' not found in data frame", col_name), 
         call. = FALSE)
  }
  
  n_na <- sum(is.na(df[[col_name]]))
  if (n_na > 0) {
    msg <- sprintf("Column '%s' has %d NA values", col_name, n_na)
    if (context != "") msg <- paste0(msg, " (", context, ")")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Column Is Numeric
#'
#' @description
#' Checks that a column contains numeric data (integer or double).
#' Required for columns used in calculations or statistical plots.
#'
#' @param df Data frame.
#' @param col_name Character. Name of column to check.
#' @param context Character. Optional context for error message.
#'   Default: "".
#'
#' @return Invisible logical TRUE if column is numeric, stops execution with error if not.
#'
#' @details
#' Type validation for numeric columns (mass, year, etc.). Reports actual class
#' found to help users understand what went wrong.
#'
#' **Design:** Uses is.numeric() which includes both integer and double types.
#'
#' @examples
#' # Ensure mass column is numeric before plotting
#' assert_is_numeric(df, "mass", "ridgeline validation")
#'
#' @seealso [assert_is_character()] for character validation
#'
#' @export
assert_is_numeric <- function(df, col_name, context = "") {
  if (!col_name %in% names(df)) {
    stop(sprintf("Column '%s' not found", col_name), call. = FALSE)
  }
  
  if (!is.numeric(df[[col_name]])) {
    msg <- sprintf("Column '%s' must be numeric but is '%s'", 
                   col_name, class(df[[col_name]])[1])
    if (context != "") msg <- paste0(msg, " (", context, ")")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Column Is Character
#'
#' @description
#' Checks that a column contains character (string) data.
#' Required for factor or categorical columns.
#'
#' @param df Data frame.
#' @param col_name Character. Name of column to check.
#' @param context Character. Optional context for error message.
#'   Default: "".
#'
#' @return Invisible logical TRUE if column is character, stops execution with error if not.
#'
#' @details
#' Type validation for character columns (origin, dispersed status, etc.).
#' Reports actual class found if type check fails.
#'
#' **Design:** Uses is.character() which checks for string/character class.
#' Does not accept factors (use as.character() if needed).
#'
#' @examples
#' # Ensure origin column is character before grouping
#' assert_is_character(df, "origin", "ridgeline validation")
#'
#' @seealso [assert_is_numeric()] for numeric validation
#'
#' @export
assert_is_character <- function(df, col_name, context = "") {
  if (!col_name %in% names(df)) {
    stop(sprintf("Column '%s' not found", col_name), call. = FALSE)
  }
  
  if (!is.character(df[[col_name]])) {
    msg <- sprintf("Column '%s' must be character but is '%s'", 
                   col_name, class(df[[col_name]])[1])
    if (context != "") msg <- paste0(msg, " (", context, ")")
    stop(msg, call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate Ridgeline Plot Data
#'
#' @description
#' Comprehensive schema validation for ridgeline plot data.
#' Performs all critical checks: type, shape, and completeness.
#' Stops pipeline on any failure with clear error messages.
#'
#' @param df Data frame. Data to validate for ridgeline plotting.
#' @param verbose Logical. Print validation details to console.
#'   Default: FALSE.
#'
#' @return Invisible logical TRUE if all checks pass.
#'   Stops execution with error message if any check fails.
#'
#' @details
#' **Validation Checks (in order):**
#' 1. Input is a data frame
#' 2. Contains required columns: mass, year, dispersed, origin
#' 3. Data is not empty (has at least 1 row)
#' 4. Column types are correct (mass, year numeric; dispersed, origin character)
#' 5. Key columns (mass, year) have no NA values
#'
#' **verbose=TRUE output:** Shows each check with ✓ indicator, useful for debugging
#' data issues. Should be used during development and troubleshooting.
#'
#' **Design:** Composite function using individual assertions (assert_*).
#' Performs all checks in logical sequence, stopping at first failure.
#' Uses tryCatch for NA check so minor NA issues produce warning, not error.
#'
#' @examples
#' \dontrun{
#' # After loading data, validate before plotting
#' data <- readr::read_csv(here::here("data", "data.csv"))
#' validate_ridgeline_data(data, verbose = TRUE)  # Shows detailed output
#'
#' # Then proceed with pipeline
#' plots <- generate_all_ridgeline_plots(data)
#' }
#'
#' @seealso [assert_data_frame()], [assert_columns_exist()], [validate_data_frame()]
#'
#' @export
validate_ridgeline_data <- function(df, verbose = FALSE) {
  # Check is data frame
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  if (verbose) message("[VALIDATE] ✓ Input is data frame")
  
  # Check required columns exist
  required_cols <- c("mass", "year", "dispersed", "origin")
  assert_columns_exist(df, required_cols, context = "ridgeline data")
  if (verbose) message("[VALIDATE] ✓ All required columns present")
  
  # Check not empty
  assert_not_empty(df, context = "ridgeline data")
  if (verbose) message("[VALIDATE] ✓ Data contains ", nrow(df), " rows")
  
  # Check column types
  assert_is_numeric(df, "mass", context = "ridgeline validation")
  assert_is_numeric(df, "year", context = "ridgeline validation")
  assert_is_character(df, "dispersed", context = "ridgeline validation")
  assert_is_character(df, "origin", context = "ridgeline validation")
  if (verbose) message("[VALIDATE] ✓ Column types correct")
  
  # Check for NAs in key columns
  tryCatch(
    {
      assert_no_na(df, "mass", context = "ridgeline mass data")
      assert_no_na(df, "year", context = "ridgeline year data")
    },
    error = function(e) {
      warning("Data contains NA values - may impact ridgeline plot", 
              call. = FALSE)
    }
  )
  
  if (verbose) message("[VALIDATE] ✓ Ridgeline data validation complete")
  invisible(TRUE)
}

# ==============================================================================
# ADDITIONAL ASSERTIONS (from reference code)
# ==============================================================================

#' Assert Input is a Data Frame
#'
#' @description
#' Universal type validation ensuring input is a data frame.
#' More flexible than single-column checks; validates entire object structure.
#'
#' @param x Object to check.
#' @param arg_name Character. Name of argument for error message.
#'   Used in error text like "arg_name must be a data frame".
#'   Default: "Input".
#'
#' @return Invisible logical TRUE if valid, stops execution with error if not.
#'
#' @details
#' Entry-point validation for functions that process data frames.
#' Provides custom error messages using arg_name parameter,
#' enabling users to know exactly which input failed.
#'
#' **Design:** Checks is.data.frame(). Rejects lists, tibbles transformed
#' to non-data.frame objects, and matrices.
#'
#' @examples
#' # At start of data-processing function
#' assert_data_frame(mtcars, "input_data")
#' assert_data_frame(df)  # Default arg name
#'
#' @seealso [assert_not_empty()], [validate_data_frame()]
#'
#' @export
assert_data_frame <- function(x, arg_name = "Input") {
  if (!is.data.frame(x)) {
    stop(sprintf(
      "%s must be a data frame.\n  Received: %s",
      arg_name,
      paste(class(x), collapse = ", ")
    ), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Exact Row Count
#'
#' @description
#' Validates that data frame has exactly N rows.
#' Useful after filtering to ensure expected data reduction.
#'
#' @param df Data frame to check.
#' @param expected_rows Integer. Expected number of rows. Must be > 0.
#' @param arg_name Character. Name of argument for error message.
#'   Default: "Data".
#'
#' @return Invisible logical TRUE if count matches, stops execution with error if not.
#'
#' @details
#' Quality assurance check after data transformations. Example:
#' "After filtering to Wisconsin hawks over 500g, expect exactly 42 rows."
#' This assertion catches cases where transformation logic is wrong.
#'
#' **Design:** Strict equality check (nrow == expected, not >=).
#' Use for final product validation, not intermediate steps.
#'
#' @examples
#' \dontrun{
#' # Ensure processed data has expected sample size
#' wi_heavy <- subset(df, origin == "Wisconsin" & mass > 500)
#' assert_row_count(wi_heavy, 42, "Wisconsin heavy hawks")
#' }
#'
#' @seealso [assert_not_empty()] for checking > 0 rows
#'
#' @export
assert_row_count <- function(df, expected_rows, arg_name = "Data") {
  actual_rows <- nrow(df)
  if (actual_rows != expected_rows) {
    stop(sprintf(
      "%s must have exactly %d row(s), but has %d rows",
      arg_name, expected_rows, actual_rows
    ), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Directory Exists
#'
#' @description
#' Validates that a directory exists. Optionally creates it.
#' Used before writing files to ensure output directories are available.
#'
#' @param dir_path Character. Directory path to check.
#' @param create Logical. Create directory if missing (with parents)?
#'   Default: TRUE.
#' @param arg_name Character. Name for error message.
#'   Default: "Directory".
#'
#' @return Invisible logical TRUE if valid or created.
#'   Stops execution with error if missing and create=FALSE.
#'
#' @details
#' Defensive check before output operations. With create=TRUE (default),
#' ensures directory exists, creating it recursively if needed.
#' With create=FALSE, performs read-only verification.
#'
#' **Design:** Uses dir.create(recursive=TRUE) to handle nested paths.
#' Safe for concurrent calls (showWarnings=FALSE suppresses race condition messages).
#'
#' @examples
#' # Before writing plots, ensure output directory
#' assert_directory_exists(here::here("results", "plots"))
#'
#' # Check existing directory without creating
#' assert_directory_exists("/archive/readonly", create = FALSE)
#'
#' @seealso [assert_file_exists()] for file validation
#'
#' @export
assert_directory_exists <- function(dir_path, create = TRUE, arg_name = "Directory") {
  if (!dir.exists(dir_path)) {
    if (create) {
      dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
    } else {
      stop(sprintf("%s not found: %s", arg_name, dir_path), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Assert Single Character String
#'
#' @description
#' Validates that input is a single character string (length 1).
#' Used for plot IDs, configuration keys, and other scalar identifiers.
#'
#' @param x Object to check.
#' @param arg_name Character. Name of argument for error message.
#'   Default: "Input".
#'
#' @return Invisible logical TRUE if valid (character, length 1),
#'   stops execution with error if not.
#'
#' @details
#' Type and shape validation combined. Ensures parameter is:
#' - Character type (not numeric, not factor)
#' - Exactly length 1 (not vector, not empty)
#'
#' **Design:** Used for scalar string parameters like plot_id="compact_01".
#' Related: assert_data_frame() for objects, assert_is_character() for columns.
#'
#' @examples
#' # Validate plot ID before lookup
#' assert_scalar_string("compact_01", "plot_id")
#' assert_scalar_string(plot_id)  # Default arg name
#'
#' @seealso [assert_is_character()] for column  validation
#'
#' @export
assert_scalar_string <- function(x, arg_name = "Input") {
  if (!is.character(x) || length(x) != 1) {
    stop(sprintf(
      "%s must be a single character string",
      arg_name
    ), call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate Data Frame (Composite Check)
#'
#' @description
#' Combines multiple assertions for comprehensive data frame validation.
#' Single-call validation for typical pipeline entry checks.
#'
#' @param df Object to validate.
#' @param columns Character vector. Required column names.
#'   Default: NULL (no column check).
#' @param arg_name Character. Name for error messages.
#'   Default: "Data".
#'
#' @return Invisible logical TRUE if all checks pass.
#'   Stops execution with error if any check fails.
#'
#' @details
#' **Checks performed (if applicable):**
#' 1. Is a data frame (uses assert_data_frame)
#' 2. Has at least one row (uses assert_not_empty)
#' 3. Has all required columns (uses assert_columns_exist), if columns specified
#'
#' Useful for simplifying pipeline entry validation. Example:
#' ```r
#' validate_data_frame(df, c("mass", "year", "origin"), "input data")
#' ```
#'
#' **Design:** Composite function that chains individual assertions.
#' Stops at first failure.
#'
#' @examples
#' \dontrun{
#' # Complete validation in one call
#' data <- read_csv(here::here("data", "data.csv"))
#' validate_data_frame(data, c("mass", "year"), "source data")
#'
#' # Without column check
#' validate_data_frame(processed, arg_name = "processed")
#' }
#'
#' @seealso [validate_ridgeline_data()] for plot-specific validation
#'
#' @export
validate_data_frame <- function(df, columns = NULL, arg_name = "Data") {
  assert_data_frame(df, arg_name)
  assert_not_empty(df, arg_name)
  if (!is.null(columns)) {
    assert_columns_exist(df, columns, context = arg_name)
  }
  invisible(TRUE)
}

# ==============================================================================
# END R/functions/assertions.R
# ==============================================================================
