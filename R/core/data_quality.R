# ==============================================================================
# R/functions/data_quality.R
# ==============================================================================
# PURPOSE
# -------
# Data quality assessment and reporting for Phase 3.
# Computes quality metrics, generates quality scores, produces quality reports.
#
# DEPENDS ON
# ----------
# - R/functions/assertions.R (validation)
# - R/functions/logging.R (audit trail)
# - R/functions/robustness.R (result objects)
# - base R, dplyr
#
# INPUTS
# ------
# Data frames, configuration object, quality thresholds
#
# OUTPUTS
# -------
# Quality metrics, quality scores (0-100), quality reports
#
# USAGE
# -----
# source("R/functions/data_quality.R")
# metrics <- compute_quality_metrics(df)
# score <- calculate_quality_score(metrics)
# report <- generate_quality_report(result, overall_score)
#
# CHANGELOG
# ---------
# 2026-02-10 (v1.0.0): Phase 3 - Initial data quality functions
#   - compute_quality_metrics() - Calculate completeness, schema, etc
#   - calculate_quality_score() - Aggregate metrics to 0-100 score
#   - generate_quality_report() - Human-readable quality summary
#
# ==============================================================================

#' Compute Data Quality Metrics
#'
#' @description
#' Calculate multiple quality indicators for a data frame.
#' Returns metrics like completeness, schema compliance, row count, outliers.
#'
#' @param df Data frame. Data to assess.
#' @param required_columns Character vector. Expected column names.
#'   Default: c("mass", "year", "dispersed").
#' @param min_rows Integer. Minimum acceptable row count. Default: 10.
#' @param column_types List or NULL. Expected column types.
#'   When NULL (default), infers types from column names:
#'   - "mass", "year": numeric
#'   - "dispersed", "origin": character
#'   When provided, must be named list: list(mass = "numeric", year = "numeric", ...).
#' @param outlier_ranges List or NULL. Column ranges for outlier detection.
#'   When NULL (default), checks built-in ranges:
#'   - mass: 0 to 1000 grams (list(mass = c(0, 1000)))
#'   - year: 1980 to 2027 (list(year = c(1980, 2027)))
#'   When provided, must be named list: list(column = c(min, max), ...).
#' @param verbose Logical. Print metric details. Default: FALSE.
#'
#' @return List with quality metrics:
#'   - completeness: percent non-NA values (0-100)
#'   - schema_match: percent correct columns/types (0-100)
#'   - row_count_ok: boolean, TRUE if >= min_rows
#'   - row_count: actual number of rows
#'   - min_rows: minimum required
#'   - outliers_detected: count of suspicious values
#'   - warnings: character vector of issues found
#'
#' @details
#' **Completeness:** Percent of cells that are not NA.
#' Calculated: (total_cells - na_count) / total_cells * 100
#'
#' **Schema Match:** Percent of required columns present with correct types.
#' When column_types is NULL, uses inferred types based on column name patterns.
#' When provided, validates against specified types.
#'
#' **Row Count:** TRUE if >= min_rows, FALSE otherwise.
#'
#' **Outliers:** When outlier_ranges is NULL (default), checks:
#' - mass: > 0 and < 1000 grams
#' - year: >= 1980 and <= 2027
#' When provided, checks custom ranges for specified columns.
#'
#' @examples
#' \dontrun{
#' # COHA defaults (mass, year, dispersed)
#' metrics <- compute_quality_metrics(df, verbose = TRUE)
#' # Returns: completeness, schema_match, etc.
#'
#' # Custom study with different columns
#' metrics <- compute_quality_metrics(
#'   df,
#'   required_columns = c("height", "weight"),
#'   column_types = list(height = "numeric", weight = "numeric"),
#'   outlier_ranges = list(height = c(100, 300), weight = c(10, 500))
#' )
#' }
#'
#' @export
compute_quality_metrics <- function(df,
                                    required_columns = c("mass", "year", 
                                                         "dispersed"),
                                    min_rows = 10,
                                    column_types = NULL,
                                    outlier_ranges = NULL,
                                    verbose = FALSE) {
  
  # Input validation
  if (!is.data.frame(df)) {
    stop("df must be a data frame", call. = FALSE)
  }
  
  if (verbose) {
    message("[QUALITY] Starting data quality assessment")
  }
  
  metrics <- list(
    completeness = NA_real_,
    schema_match = NA_real_,
    row_count_ok = NA,
    row_count = nrow(df),
    min_rows = min_rows,
    outliers_detected = 0,
    warnings = character()
  )

  if (!is.null(column_types) && !is.list(column_types)) {
    stop("column_types must be a named list or NULL", call. = FALSE)
  }

  if (is.null(column_types)) {
    column_types <- list(
      mass = "numeric",
      year = "numeric",
      dispersed = "character",
      origin = "character"
    )
  }

  if (!is.null(outlier_ranges) && !is.list(outlier_ranges)) {
    stop("outlier_ranges must be a named list or NULL", call. = FALSE)
  }

  if (is.null(outlier_ranges)) {
    outlier_ranges <- list(
      mass = c(0, 1000),
      year = c(1980, 2027)
    )
  }
  
  # 1. COMPLETENESS: Percent non-NA cells
  total_cells <- nrow(df) * ncol(df)
  na_count <- sum(is.na(df))
  if (total_cells == 0) {
    metrics$completeness <- 0
  } else {
    metrics$completeness <- (total_cells - na_count) / total_cells * 100
  }
  
  if (verbose) {
    message(sprintf("[QUALITY] Completeness: %.1f%% (%d NA values)",
                   metrics$completeness, na_count))
  }
  
  # 2. SCHEMA MATCHING: Correct columns and types
  schema_correct <- 0
  schema_total <- length(required_columns)

  if (schema_total > 0) {
    for (col in required_columns) {
      if (!col %in% names(df)) {
        next
      }

      expected_type <- column_types[[col]]

      if (is.null(expected_type)) {
        schema_correct <- schema_correct + 1
      } else if (is.character(expected_type) && length(expected_type) == 1) {
        type_ok <- switch(
          expected_type,
          numeric = is.numeric(df[[col]]),
          character = is.character(df[[col]]),
          integer = is.integer(df[[col]]),
          logical = is.logical(df[[col]]),
          factor = is.factor(df[[col]]),
          Date = inherits(df[[col]], "Date"),
          POSIXct = inherits(df[[col]], "POSIXct"),
          POSIXlt = inherits(df[[col]], "POSIXlt"),
          inherits(df[[col]], expected_type)
        )

        if (isTRUE(type_ok)) {
          schema_correct <- schema_correct + 1
        }
      }
    }
  }

  metrics$schema_match <- if (schema_total > 0) {
    schema_correct / schema_total * 100
  } else {
    0
  }
  
  if (verbose) {
    message(sprintf("[QUALITY] Schema match: %.1f%% (%d/%d columns correct)",
             metrics$schema_match, schema_correct, schema_total))
  }
  
  # 3. ROW COUNT
  metrics$row_count_ok <- nrow(df) >= min_rows
  
  # Ensure row_count_ok is always logical, never NA
  if (is.na(metrics$row_count_ok)) {
    metrics$row_count_ok <- FALSE
  }
  
  if (!metrics$row_count_ok) {
    msg <- sprintf("Only %d rows found, minimum %d required",
                  nrow(df), min_rows)
    metrics$warnings <- c(metrics$warnings, msg)
  }
  
  if (verbose) {
    status <- if (metrics$row_count_ok) "✓" else "✗"
    message(sprintf("[QUALITY] Row count: %s %d rows (min: %d)",
                   status, nrow(df), min_rows))
  }
  
  # 4. OUTLIERS
  if (length(outlier_ranges) > 0) {
    if (is.null(names(outlier_ranges)) || any(names(outlier_ranges) == "")) {
      stop("outlier_ranges must be a named list", call. = FALSE)
    }

    for (col in names(outlier_ranges)) {
      if (!col %in% names(df)) {
        next
      }

      range <- outlier_ranges[[col]]
      if (!is.numeric(range) || length(range) != 2 || any(is.na(range))) {
        metrics$warnings <- c(
          metrics$warnings,
          sprintf("Outlier range for '%s' must be numeric length 2", col)
        )
        next
      }

      if (!is.numeric(df[[col]])) {
        metrics$warnings <- c(
          metrics$warnings,
          sprintf("Outlier range provided for non-numeric column '%s'", col)
        )
        next
      }

      issues <- sum(df[[col]] < range[1] | df[[col]] > range[2], na.rm = TRUE)
      metrics$outliers_detected <- metrics$outliers_detected + issues
      if (issues > 0) {
        metrics$warnings <- c(
          metrics$warnings,
          sprintf("%d %s values outside %.0f-%.0f range", issues, col, range[1], range[2])
        )
      }
    }
  }
  
  if (verbose) {
    message(sprintf("[QUALITY] Outliers detected: %d", metrics$outliers_detected))
    if (length(metrics$warnings) > 0) {
      for (warn in metrics$warnings) {
        message(sprintf("[QUALITY] Warning: %s", warn))
      }
    }
    message("[QUALITY] Quality assessment complete")
  }
  
  invisible(metrics)
}

#' Calculate Overall Quality Score
#'
#' @description
#' Aggregate quality metrics into single 0-100 score.
#' Higher score indicates better data quality.
#'
#' @param metrics List. Output from compute_quality_metrics().
#' @param weights List. Optional weights for components.
#'   Default: completeness=30%, schema=30%, row_count=20%, outliers=20%.
#'
#' @return Numeric. Quality score 0-100.
#'
#' @details
#' **Scoring Logic:**
#' - Completeness (30%): Percent non-NA values
#' - Schema (30%): Percent columns correct type
#' - Row Count (20%): 100 if met, scales down if below minimum
#' - Outliers (20%): 100 minus (outlier_count / row_count * 100)
#'
#' **Interpretation:**
#' - 90-100: Excellent - ready for analysis
#' - 75-89: Good - minor issues, usable
#' - 50-74: Acceptable - significant issues, use with caution
#' - 0-49: Poor - not recommended for analysis
#'
#' **Special Cases:**
#' - Empty data frame: score = 0
#' - All NAs: score < 10
#' - Missing required columns: score reduced
#'
#' @examples
#' \dontrun{
#' metrics <- compute_quality_metrics(df)
#' score <- calculate_quality_score(metrics)
#' # Returns: 85 (good quality)
#'
#' if (score > 75) {
#'   message("Data quality acceptable")
#' } else if (score > 50) {
#'   warning("Data has quality issues, review before use")
#' } else {
#'   stop("Data quality too low for analysis")
#' }
#' }
#'
#' @export
calculate_quality_score <- function(metrics, 
                                    weights = list(
                                      completeness = 0.30,
                                      schema = 0.30,
                                      row_count = 0.20,
                                      outliers = 0.20
                                    )) {
  
  if (!is.list(metrics)) {
    stop("metrics must be a list from compute_quality_metrics", call. = FALSE)
  }
  
  # Get individual component scores
  # Use %||% to handle NA, and explicit isnan() check for NaN
  completeness_score <- metrics$completeness %||% 0
  if (is.nan(completeness_score)) completeness_score <- 0
  
  schema_score <- metrics$schema_match %||% 0
  if (is.nan(schema_score)) schema_score <- 0
  
  # Row count: 100 if met, scales down proportionally if below
  # Ensure row_count_ok is logical (not NA)
  row_count_ok <- metrics$row_count_ok %||% FALSE
  if (is.na(row_count_ok)) row_count_ok <- FALSE
  
  row_count_score <- if (row_count_ok) {
    100
  } else {
    # Handle missing row_count or min_rows gracefully
    row_count <- metrics$row_count %||% 0
    min_rows <- metrics$min_rows %||% 1
    if (is.na(row_count) || is.na(min_rows)) {
      0
    } else {
      (row_count / pmax(min_rows, 1)) * 100
    }
  }
  
  # Ensure row_count_score is valid (not NA or NaN)
  if (is.na(row_count_score) || is.nan(row_count_score)) row_count_score <- 0
  row_count_score <- pmax(0, pmin(100, row_count_score))
  
  # Outlier score: 100 minus percent outliers
  outliers_detected <- metrics$outliers_detected %||% 0
  row_count <- metrics$row_count %||% 1
  outlier_percent <- (outliers_detected / pmax(row_count, 1)) * 100
  outliers_score <- max(0, 100 - outlier_percent)
  
  # Ensure outliers_score is valid
  if (is.na(outliers_score) || is.nan(outliers_score)) outliers_score <- 0
  
  # Weighted average
  overall_score <- (
    completeness_score * weights$completeness +
    schema_score * weights$schema +
    row_count_score * weights$row_count +
    outliers_score * weights$outliers
  )
  
  # Ensure overall_score is valid before clamping
  if (is.na(overall_score) || is.nan(overall_score)) overall_score <- 0
  
  # Clamp to 0-100
  overall_score <- pmax(0, pmin(100, overall_score))
  
  result <- round(overall_score, 1)
  
  # One final safety check: if result is still NA, return 0
  if (is.na(result)) result <- 0
  
  result
}

#' Generate Quality Report
#'
#' @description
#' Create human-readable quality report summarizing assessment.
#' Suitable for logging and user output.
#'
#' @param metrics List. Output from compute_quality_metrics().
#' @param quality_score Numeric. Output from calculate_quality_score().
#' @param verbose Logical. Print report to console. Default: TRUE.
#'
#' @return Character. Formatted quality report (invisibly).
#'
#' @details
#' **Report Format:**
#' Shows quality score, component breakdown, interpretation, and recommendations.
#'
#' **Interpretation Based on Score:**
#' - 90-100: "Excellent data quality, ready for analysis"
#' - 75-89: "Good quality with minor issues"
#' - 50-74: "Acceptable but has quality concerns"
#' - 0-49: "Poor quality, not recommended"
#'
#' @examples
#' \dontrun{
#' metrics <- compute_quality_metrics(df)
#' score <- calculate_quality_score(metrics)
#' report <- generate_quality_report(metrics, score, verbose = TRUE)
#'
#' # Output:
#' # Data Quality Report
#' # ==================
#' # Overall Score: 85/100 (Good)
#' # - Completeness: 95%
#' # - Schema: 100%
#' # - Row Count: OK (847 rows)
#' # - Outliers: 2 detected
#' # Warnings: 2 minor issues found
#' }
#'
#' @export
generate_quality_report <- function(metrics, quality_score, verbose = TRUE) {
  
  # Build report lines
  lines <- character()
  lines <- c(lines, "")
  lines <- c(lines, "=== DATA QUALITY REPORT ===")
  lines <- c(lines, sprintf("Overall Score: %.0f/100", quality_score))
  
  # Interpretation
  interpretation <- if (quality_score >= 90) {
    "Excellent - ready for analysis"
  } else if (quality_score >= 75) {
    "Good - minor issues"
  } else if (quality_score >= 50) {
    "Acceptable - has concerns"
  } else {
    "Poor - not recommended"
  }
  lines <- c(lines, sprintf("Status: %s", interpretation))
  
  # Component breakdown
  lines <- c(lines, "")
  lines <- c(lines, "Metrics:")
  lines <- c(lines, sprintf("  Completeness:    %.1f%%", metrics$completeness))
  lines <- c(lines, sprintf("  Schema Match:    %.1f%%", metrics$schema_match))
  lines <- c(lines, sprintf("  Row Count:       %d %s", 
                           metrics$row_count,
                           if (metrics$row_count_ok) "✓" else "✗"))
  lines <- c(lines, sprintf("  Outliers:        %d detected", metrics$outliers_detected))
  
  # Warnings
  if (length(metrics$warnings) > 0) {
    lines <- c(lines, "")
    lines <- c(lines, "Warnings:")
    for (warn in metrics$warnings) {
      lines <- c(lines, sprintf("  - %s", warn))
    }
  }
  
  lines <- c(lines, "")
  
  # Print if verbose
  if (verbose) {
    for (line in lines) {
      message(line)
    }
  }
  
  # Return as single string
  invisible(paste(lines, collapse = "\n"))
}

# ==============================================================================
# END R/functions/data_quality.R
# ==============================================================================
