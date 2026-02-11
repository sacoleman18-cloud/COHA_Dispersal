# ==============================================================================
# R/functions/data_operations.R
# ==============================================================================
# PURPOSE
# -------
# Phase 3 data operations with structured returns and quality reporting.
# All functions return result objects with status, message, quality metrics.
#
# DEPENDS ON
# ----------
# - R/functions/assertions.R (validation)
# - R/functions/logging.R (audit trail)
# - R/functions/robustness.R (result objects)
# - R/functions/data_quality.R (quality metrics)
# - R/functions/utilities.R (safe I/O)
# - readr, dplyr
#
# INPUTS
# ------
# File paths, configuration objects, data frames
#
# OUTPUTS
# -------
# Structured result objects with status, data, quality scores
#
# USAGE
# -----
# source("R/functions/data_operations.R")
# result <- load_and_validate_data("data/data.csv", verbose = TRUE)
# if (result$status == "success") { df <- result$data }
#
# CHANGELOG
# ---------
# 2026-02-10 (v1.0.0): Phase 3 - Initial data operations
#   - load_and_validate_data() - Load CSV with quality assessment
#   - assess_data_quality() - Full quality analysis of loaded data
#
# ==============================================================================

#' Load and Validate Data with Quality Assessment
#'
#' @description
#' Loads CSV file, validates schema, computes quality metrics.
#' Returns structured result with status, data, and quality score.
#' Unlike Phase 1 safe_read_csv(), this returns comprehensive quality info.
#'
#' @param file_path Character. Path to CSV file.
#' @param required_columns Character vector. Expected columns.
#'   Default: c("mass", "year", "dispersed", "origin").
#' @param min_rows Integer. Minimum acceptable row count. Default: 10.
#' @param verbose Logical. Print progress messages. Default: FALSE.
#'
#' @return List. Structured result with fields:
#'   - status: "success", "partial", or "failed"
#'   - message: Human-readable status description
#'   - data: Data frame if status != "failed"
#'   - rows: Number of rows loaded
#'   - columns: Number of columns
#'   - quality_score: 0-100 quality assessment
#'   - quality_metrics: Detailed quality breakdown
#'   - errors: List of errors encountered
#'   - warnings: List of warnings (non-blocking issues)
#'   - timestamp: When operation completed
#'   - duration_secs: How long operation took
#'
#' @details
#' **Execution Steps:**
#' 1. Validate input file path exists
#' 2. Read CSV (returns NULL on read error)
#' 3. Validate required columns exist
#' 4. Compute quality metrics
#' 5. Calculate overall quality score
#' 6. Determine status based on quality
#'    - 90+: success
#'    - 50-89: partial (issues but usable)
#'    - <50: failed (too many issues)
#'
#' **Quality Assessment:**
#' - Completeness (30%): % of non-NA cells
#' - Schema (30%): % of correct columns/types
#' - Row count (20%): meets minimum threshold
#' - Outliers (20%): count of suspicious values
#'
#' **Verbose Output:** Shows each validation step with ✓/✗ indicators.
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' result <- load_and_validate_data(
#'   here::here("data", "data.csv"),
#'   verbose = TRUE
#' )
#'
#' # Check success
#' if (result$status == "success") {
#'   df <- result$data
#'   message(sprintf("Loaded %d records", result$rows))
#' } else if (result$status == "partial") {
#'   warning(sprintf("Quality score: %d, proceed with caution",
#'                  result$quality_score))
#'   df <- result$data  # Still available
#' } else {
#'   stop(sprintf("Load failed: %s", result$message))
#' }
#'
#' # Examine quality details
#' print(result$quality_metrics$warnings)
#' }
#'
#' @seealso [safe_read_csv()] for Phase 1 version,
#'   [calculate_quality_score()] for scoring details
#'
#' @export
load_and_validate_data <- function(file_path,
                                    required_columns = c(
                                      "mass", "year",
                                      "dispersed"
                                    ),
                                    min_rows = 10,
                                    verbose = FALSE) {

  # Initialize result
  result <- create_result("load_and_validate_data", verbose)
  start_time <- start_timer()

  if (verbose) {
    message(sprintf("[DATA] Loading from: %s", file_path))
  }

  # 1. Validate file exists
  tryCatch(
    {
      assert_file_exists(file_path, "data file")
    },
    error = function(e) {
      result <<- add_error(
        result,
        format_error_message(
          "load_data",
          sprintf("File not found: %s", basename(file_path)),
          sprintf("Check YAML config - ensure %s exists", basename(file_path))
        ),
        verbose
      )
    }
  )

  if (result$status == "failed") {
    result$duration_secs <- stop_timer(start_time)
    return(invisible(result))
  }

  # 2. Read CSV
  if (verbose) message("[DATA] Reading CSV...")

  df <- safe_read_csv(file_path, verbose = FALSE)

  # Coerce known columns to expected types
  if (!is.null(df)) {
    if ("mass" %in% names(df)) {
      df$mass <- suppressWarnings(as.numeric(df$mass))
    }
    if ("year" %in% names(df)) {
      df$year <- suppressWarnings(as.numeric(df$year))
    }
    if ("dispersed" %in% names(df)) {
      df$dispersed <- as.character(df$dispersed)
    }
  }

  if (is.null(df)) {
    result <- add_error(
      result,
      format_error_message(
        "load_data",
        sprintf("Failed to read CSV: %s", basename(file_path)),
        "Check file format - must be valid CSV. See logs/error_log.txt."
      ),
      verbose
    )
    result$duration_secs <- stop_timer(start_time)
    return(invisible(result))
  }

  if (verbose) {
    message(sprintf("[DATA] ✓ Read %d rows, %d columns",
                   nrow(df), ncol(df)))
  }

  # 3. Validate required columns
  tryCatch(
    {
      assert_columns_exist(df, required_columns, "ridgeline data")
      if (verbose) message("[DATA] ✓ All required columns present")
    },
    error = function(e) {
      result <<- add_error(
        result,
        format_error_message(
          "load_data",
          sprintf("Missing columns: %s", e$message),
          sprintf(
            "CSV must contain: %s",
            paste(required_columns, collapse = ", ")
          )
        ),
        verbose
      )
    }
  )

  if (result$status == "failed") {
    result$duration_secs <- stop_timer(start_time)
    return(invisible(result))
  }

  # 4. Compute quality metrics
  if (verbose) message("[DATA] Assessing data quality...")

  metrics <- compute_quality_metrics(df, required_columns, min_rows, verbose)

  # 5. Calculate quality score
  quality_score <- calculate_quality_score(metrics)

  if (verbose) {
    message(sprintf("[DATA] Quality score: %.0f/100", quality_score))
  }

  # 6. Set status based on quality
  if (quality_score >= 90) {
    result <- set_result_status(
      result,
      "success",
      sprintf("Data loaded successfully (quality: %.0f/100)", quality_score),
      verbose
    )
  } else if (quality_score >= 50) {
    result <- set_result_status(
      result,
      "partial",
      sprintf("Data loaded with warnings (quality: %.0f/100)", quality_score),
      verbose
    )
    # Add warnings from metrics
    for (warn in metrics$warnings) {
      result <- add_warning(result, warn, verbose)
    }
  } else {
    result <- add_error(
      result,
      format_error_message(
        "load_data",
        sprintf("Data quality too low (%.0f/100)", quality_score),
        sprintf(
          "Data has significant issues: %s. Consider data cleaning.",
          paste(metrics$warnings[1:min(2, length(metrics$warnings))], collapse="; ")
        )
      ),
      verbose
    )
  }

  # 7. Add data and metrics to result
  result$data <- df
  result$rows <- nrow(df)
  result$columns <- ncol(df)
  result$quality_score <- quality_score
  result$quality_metrics <- metrics

  # 8. Finalize
  result$duration_secs <- stop_timer(start_time)
  result$timestamp <- Sys.time()

  if (verbose) {
    message(sprintf("[DATA] Load complete (%.2f seconds)", result$duration_secs))
  }

  invisible(result)
}

#' Assess Loaded Data Quality
#'
#' @description
#' Full quality assessment of already-loaded data.
#' Returns structured result with quality score and detailed report.
#'
#' @param df Data frame. Data to assess.
#' @param required_columns Character vector. Expected columns.
#'   Default: c("mass", "year", "dispersed", "origin").
#' @param min_rows Integer. Minimum acceptable row count. Default: 10.
#' @param verbose Logical. Print detailed report. Default: TRUE.
#'
#' @return List. Structured result with:
#'   - status: Always "success" (assessment always completes)
#'   - quality_score: 0-100 overall score
#'   - quality_metrics: Detailed breakdown by component
#'   - interpretation: Text description of score
#'   - report: Full quality report text
#'
#' @details
#' Similar to load_and_validate_data() but operates on loaded data.
#' Useful for checking quality of transformed data mid-pipeline.
#'
#' @examples
#' \dontrun{
#' # After data transformation
#' df_filtered <- df %>% filter(year > 2000)
#'
#' # Check quality of filtered data
#' quality <- assess_data_quality(df_filtered, verbose = TRUE)
#' if (quality$quality_score < 50) {
#'   warning(quality$interpretation)
#' }
#' }
#'
#' @export
assess_data_quality <- function(df,
                                 required_columns = c(
                                   "mass", "year",
                                   "dispersed", "origin"
                                 ),
                                 min_rows = 10,
                                 verbose = TRUE) {

  result <- create_result("assess_data_quality")
  start_time <- start_timer()

  # Validate input
  tryCatch(
    {
      assert_data_frame(df, "data frame")
    },
    error = function(e) {
      result$status <<- "failed"
      result$message <<- e$message
      result$errors <<- list(e$message)
      return(result)
    }
  )

  # Compute metrics
  metrics <- compute_quality_metrics(df, required_columns, min_rows, verbose)
  quality_score <- calculate_quality_score(metrics)

  # Interpretation
  interpretation <- if (quality_score >= 90) {
    "Excellent data quality, ready for analysis"
  } else if (quality_score >= 75) {
    "Good quality with minor issues"
  } else if (quality_score >= 50) {
    "Acceptable but has quality concerns"
  } else {
    "Poor quality, not recommended"
  }

  # Generate report
  report <- generate_quality_report(metrics, quality_score, verbose = !verbose)

  # Finalize result
  result$status <- "success"
  result$message <- sprintf("Quality assessment complete (score: %.0f/100)",
                           quality_score)
  result$quality_score <- quality_score
  result$quality_metrics <- metrics
  result$interpretation <- interpretation
  result$report <- report
  result$duration_secs <- stop_timer(start_time)
  result$timestamp <- Sys.time()

  if (verbose) {
    message(report)
  }

  invisible(result)
}

# ==============================================================================
# END R/functions/phase3_data_operations.R
# ==============================================================================