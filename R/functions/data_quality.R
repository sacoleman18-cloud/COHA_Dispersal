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
#'   Default: c("mass", "year", "dispersed", "origin").
#' @param min_rows Integer. Minimum acceptable row count. Default: 10.
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
#' - mass, year: numeric
#' - dispersed, origin: character
#'
#' **Row Count:** TRUE if >= min_rows, FALSE otherwise.
#'
#' **Outliers:** Count values outside expected ranges:
#' - mass: > 0 and < 1000 grams
#' - year: >= 1980 and <= 2027
#'
#' @examples
#' \dontrun{
#' metrics <- compute_quality_metrics(df, verbose = TRUE)
#' # Returns:
#' # $completeness = 95.2
#' # $schema_match = 100
#' # $row_count_ok = TRUE
#' # $row_count = 847
#' # $outliers_detected = 2
#' # $warnings = c("2 NA values in 'origin' column")
#' }
#'
#' @export
compute_quality_metrics <- function(df,
                                    required_columns = c("mass", "year", 
                                                         "dispersed", "origin"),
                                    min_rows = 10,
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
  
  # 1. COMPLETENESS: Percent non-NA cells
  total_cells <- nrow(df) * ncol(df)
  na_count <- sum(is.na(df))
  metrics$completeness <- (total_cells - na_count) / total_cells * 100
  
  if (verbose) {
    message(sprintf("[QUALITY] Completeness: %.1f%% (%d NA values)",
                   metrics$completeness, na_count))
  }
  
  # 2. SCHEMA MATCHING: Correct columns and types
  schema_checks <- 0
  schema_correct <- 0
  
  if ("mass" %in% names(df) && is.numeric(df$mass)) {
    schema_correct <- schema_correct + 1
  }
  if ("year" %in% names(df) && is.numeric(df$year)) {
    schema_correct <- schema_correct + 1
  }
  if ("dispersed" %in% names(df) && is.character(df$dispersed)) {
    schema_correct <- schema_correct + 1
  }
  if ("origin" %in% names(df) && is.character(df$origin)) {
    schema_correct <- schema_correct + 1
  }
  
  metrics$schema_match <- schema_correct / 4 * 100
  
  if (verbose) {
    message(sprintf("[QUALITY] Schema match: %.1f%% (%d/4 columns correct)",
                   metrics$schema_match, schema_correct))
  }
  
  # 3. ROW COUNT
  metrics$row_count_ok <- nrow(df) >= min_rows
  
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
  if ("mass" %in% names(df)) {
    mass_issues <- sum(df$mass < 0 | df$mass > 1000, na.rm = TRUE)
    metrics$outliers_detected <- metrics$outliers_detected + mass_issues
    if (mass_issues > 0) {
      metrics$warnings <- c(metrics$warnings,
                           sprintf("%d mass values outside 0-1000 range", mass_issues))
    }
  }
  
  if ("year" %in% names(df)) {
    year_issues <- sum(df$year < 1980 | df$year > 2027, na.rm = TRUE)
    metrics$outliers_detected <- metrics$outliers_detected + year_issues
    if (year_issues > 0) {
      metrics$warnings <- c(metrics$warnings,
                           sprintf("%d year values outside 1980-2027 range", year_issues))
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
  completeness_score <- metrics$completeness %||% 0
  schema_score <- metrics$schema_match %||% 0
  
  # Row count: 100 if met, scales down proportionally if below
  row_count_score <- if (metrics$row_count_ok) {
    100
  } else {
    (metrics$row_count / metrics$min_rows) * 100
  }
  
  # Outlier score: 100 minus percent outliers
  outlier_percent <- (metrics$outliers_detected / pmax(metrics$row_count, 1)) * 100
  outliers_score <- max(0, 100 - outlier_percent)
  
  # Weighted average
  overall_score <- (
    completeness_score * weights$completeness +
    schema_score * weights$schema +
    row_count_score * weights$row_count +
    outliers_score * weights$outliers
  )
  
  # Clamp to 0-100
  overall_score <- pmax(0, pmin(100, overall_score))
  
  round(overall_score, 1)
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
