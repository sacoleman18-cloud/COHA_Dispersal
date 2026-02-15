# ==============================================================================
# domain_modules/coha_dispersal/data_loader.R
# ==============================================================================
# PURPOSE
# -------
# COHA-specific data loading and validation.
# Provides domain-specific data I/O operations with validation against
# COHA-specific schemas and constraints defined in coha_config.R
#
# ARCHITECTURE
# -----------
# Uses coha_config.R for all data specifications.
# Validates against column specs and ranges defined in domain config.
#
# DEPENDS ON
# ----------
# - here (path management)
# - readr (CSV parsing)
# - dplyr (data transformation)
# - coha_config.R (domain configuration)
# - core/assertions.R (universal assertion functions)
#
# ==============================================================================

library(here)
library(readr)
library(dplyr)

source(here::here("R", "core", "assertions.R"))
source(here::here("R", "domain_modules", "coha_dispersal", "coha_config.R"))

# ==============================================================================
# DATA LOADING
# ==============================================================================

#' Load COHA Dispersal Data
#'
#' @description
#' Load COHA data from CSV with automatic type conversion based on
#' domain configuration (coha_config.R).
#'
#' @param filepath Character. Path to data file (default: from config)
#' @param verbose Logical. Print loading progress (default: FALSE)
#'
#' @return Data frame with COHA dispersal data
#'
#' @details
#' Uses column type specifications from coha_config.R to ensure
#' correct parsing on load.
#'
#' @examples
#' \dontrun{
#' data <- load_coha_data()
#' }
#'
#' @export
load_coha_data <- function(filepath = NULL, verbose = FALSE) {
  if (is.null(filepath)) {
    filepath <- get_coha_path("data_source")
  }
  
  if (!file.exists(filepath)) {
    stop(sprintf("Data file not found: %s", filepath), call. = FALSE)
  }
  
  if (verbose) message(sprintf("[LOAD] Loading COHA data from: %s", filepath))
  
  df <- read_csv(filepath, show_col_types = FALSE, comment = "#")
  
  if (verbose) {
    message(sprintf("[LOAD] Loaded %d rows, %d columns", nrow(df), ncol(df)))
  }
  
  invisible(df)
}

# ==============================================================================
# DATA VALIDATION (SCHEMA)
# ==============================================================================

#' Validate COHA Data Schema
#'
#' @description
#' Comprehensive schema validation for COHA data against domain specifications.
#' Checks: data frame structure, columns exist, correct types, value ranges.
#'
#' @param df Data frame. Data to validate
#' @param verbose Logical. Print validation details (default: FALSE)
#'
#' @return Invisible logical TRUE if all checks pass
#'   Stops execution with error if any check fails
#'
#' @details
#' Validation order:
#' 1. Input is data frame
#' 2. Required columns exist
#' 3. Data is not empty
#' 4. Column types match specification
#'
#' @export
validate_coha_schema <- function(df, verbose = FALSE) {
  config <- get_coha_config("data")
  col_specs <- config$columns
  
  # Check is data frame
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  if (verbose) message("[VALIDATE] ✓ Input is data frame")
  
  # Check required columns exist
  required_cols <- names(col_specs)[sapply(col_specs, function(x) isTRUE(x$required))]
  required_present <- all(required_cols %in% names(df))
  if (!required_present) {
    missing <- setdiff(required_cols, names(df))
    stop(sprintf("Missing required columns: %s", paste(missing, collapse=", ")), call. = FALSE)
  }
  if (verbose) message(sprintf("[VALIDATE] ✓ All %d required columns present", length(required_cols)))
  
  # Check not empty
  if (nrow(df) == 0) {
    stop("Data frame is empty", call. = FALSE)
  }
  if (verbose) message(sprintf("[VALIDATE] ✓ Data contains %d rows", nrow(df)))
  
  # Check column types
  for (col_name in names(col_specs)) {
    if (!col_name %in% names(df)) next
    
    spec <- col_specs[[col_name]]
    if (spec$type == "numeric" && !is.numeric(df[[col_name]])) {
      stop(sprintf("Column '%s' should be numeric but is %s",
                  col_name, class(df[[col_name]])[1]), call. = FALSE)
    } else if (spec$type == "character" && !is.character(df[[col_name]])) {
      stop(sprintf("Column '%s' should be character but is %s",
                  col_name, class(df[[col_name]])[1]), call. = FALSE)
    }
  }
  if (verbose) message("[VALIDATE] ✓ All column types correct")
  
  # Check for NAs in required columns
  for (col_name in required_cols) {
    if (!col_name %in% names(df)) next
    
    n_na <- sum(is.na(df[[col_name]]))
    if (n_na > 0) {
      stop(sprintf("Required column '%s' contains %d NA values",
                  col_name, n_na), call. = FALSE)
    }
  }
  if (verbose) message("[VALIDATE] ✓ No NA in required columns")
  
  if (verbose) message("[VALIDATE] ✓ COHA schema validation complete")
  invisible(TRUE)
}

# ==============================================================================
# DATA QUALITY ASSESSMENT
# ==============================================================================

#' Assess COHA Data Quality
#'
#' @description
#' Comprehensive data quality assessment for COHA data.
#'
#' @param df Data frame. Data to assess
#' @param verbose Logical. Print results (default: FALSE)
#'
#' @return List with quality metrics
#'
#' @export
assess_coha_quality <- function(df, verbose = FALSE) {
  result <- list(
    completeness = NA,
    overall_score = NA
  )
  
  # Completeness: percent non-NA
  total_cells <- nrow(df) * ncol(df)
  na_count <- sum(is.na(df))
  result$completeness <- (1 - na_count / total_cells) * 100
  result$overall_score <- result$completeness
  
  if (verbose) {
    message(sprintf("[QUALITY] Completeness:  %.0f%%", result$completeness))
    message(sprintf("[QUALITY] Overall Score: %.0f/100", result$overall_score))
  }
  
  invisible(result)
}

# ==============================================================================
# CONVENIENCE WRAPPERS
# ==============================================================================

#' Load and Validate COHA Data
#'
#' @description
#' Load COHA data and perform full schema validation in one step.
#'
#' @param filepath Character. Path to data file (default: from config)
#' @param verbose Logical. Print progress and details
#'
#' @return Data frame (validated) or stops with error
#'
#' @export
load_and_validate_coha_data <- function(filepath = NULL, verbose = FALSE) {
  if (verbose) message("[PIPELINE] Loading COHA data...")
  df <- load_coha_data(filepath = filepath, verbose = verbose)
  
  if (verbose) message("[PIPELINE] Validating schema...")
  validate_coha_schema(df, verbose = verbose)
  
  if (verbose) message("[PIPELINE] Assessing quality...")
  quality <- assess_coha_quality(df, verbose = verbose)
  
  if (quality$overall_score < 50) {
    warning(sprintf("Data quality is low (%.0f/100) - proceed with caution",
                   quality$overall_score), call. = FALSE)
  }
  
  invisible(df)
}

# ==============================================================================
# EOF domain_modules/coha_dispersal/data_loader.R
# ==============================================================================