# ==============================================================================
# domain_modules/coha_dispersal/artifacts_coha.R
# ==============================================================================
# PURPOSE
# -------
# COHA-specific connector for artifact registry system (core/artifacts.R).
# Defines COHA artifact types and provides wrapper functions that call
# universal core functions with COHA-specific configuration.
#
# This is the MODULAR PATTERN:
# - core/artifacts.R: Universal functions (no domain logic)
# - artifacts_coha.R: COHA configuration + wrapper functions
# - Future systems: Create new artifacts_[domain].R modules as needed
#
# DEPENDS ON
# ----------
# - core/artifacts.R (universal registry functions)
#
# KEY DESIGN
# ----------
# Instead of duplicating registry code, this module acts as a CONNECTOR:
# 1. Defines COHA-SPECIFIC ARTIFACT_TYPES constant
# 2. Provides register_coha_artifact() wrapper that passes COHA types to core
# 3. Provides discover_coha_rds() with COHA-specific RDS naming patterns
# 4. Provides validate_coha_artifacts() with COHA-specific validation rules
#
# ==============================================================================

# Must source core artifacts first
source(here::here("core", "artifacts.R"))

# ==============================================================================
# COHA-SPECIFIC CONSTANTS
# ==============================================================================

# COHA artifact types (adapted from KPro Reference_code)
# These are COHA-specific and would differ for other domains
COHA_ARTIFACT_TYPES <- c(
  "raw_data",           # Raw CSV from data/ folder
  "checkpoint",         # Phase-by-phase checkpoints
  "processed_data",     # Standardized/cleaned data
  "ridgeline_plots",    # 24 plot variants (PNG files)
  "summary_stats",      # Dispersal metrics, summaries
  "plot_objects",       # ggplot2 ridgeline objects (RDS)
  "report",             # HTML reports
  "release_bundle",     # Portable zip archive
  "validation_report"   # Data quality report
)

# ==============================================================================
# COHA WRAPPER FUNCTIONS
# ==============================================================================

#' Register a COHA Artifact
#'
#' @description
#' Wrapper around core::register_artifact() that automatically applies
#' COHA_ARTIFACT_TYPES validation. Simplifies COHA-specific calls.
#'
#' @param registry List. Registry object from init_artifact_registry()
#' @param artifact_name Character. Unique name for this artifact
#' @param artifact_type Character. One of COHA_ARTIFACT_TYPES
#' @param workflow Character. Workflow that produced this
#' @param file_path Character. Path to artifact file
#' @param input_artifacts Character vector. Names of input artifacts (for lineage)
#' @param metadata List. Additional metadata to store
#' @param data_hash Character. Optional SHA256 hash of data frame content
#' @param quiet Logical. Suppress messages if TRUE
#'
#' @return List. Updated registry object (also saved to disk)
#'
#' @export
#' @examples
#' \dontrun{
#' registry <- init_artifact_registry()
#' registry <- register_coha_artifact(
#'   registry,
#'   artifact_name = "dispersal_data_v1",
#'   artifact_type = "processed_data",
#'   workflow = "data_processing",
#'   file_path = "results/rds/processed_data.rds"
#' )
#' }
register_coha_artifact <- function(registry,
                                  artifact_name,
                                  artifact_type,
                                  workflow,
                                  file_path,
                                  input_artifacts = NULL,
                                  metadata = list(),
                                  data_hash = NULL,
                                  quiet = FALSE) {
  # Call core function with COHA_ARTIFACT_TYPES
  register_artifact(
    registry = registry,
    artifact_name = artifact_name,
    artifact_type = artifact_type,
    workflow = workflow,
    file_path = file_path,
    input_artifacts = input_artifacts,
    metadata = metadata,
    data_hash = data_hash,
    allowed_types = COHA_ARTIFACT_TYPES,
    quiet = quiet
  )
}


#' Discover COHA Pipeline RDS Files
#'
#' @description
#' Finds the most recent COHA-specific summary_data and plot_objects RDS files.
#'
#' @param rds_dir Character. Path to RDS directory (usually results/rds/)
#'
#' @return List with:
#'   - valid: Logical. TRUE if both files found
#'   - summary_path: Character. Path to summary RDS (or NULL)
#'   - plots_path: Character. Path to plot_objects RDS (or NULL)
#'   - errors: Character vector. Error messages if any
#'
#' @export
discover_coha_rds <- function(rds_dir) {
  
  errors <- character()
  
  # Check directory exists
  if (!dir.exists(rds_dir)) {
    return(list(
      valid = FALSE,
      summary_path = NULL,
      plots_path = NULL,
      errors = sprintf("RDS directory not found: %s", rds_dir)
    ))
  }
  
  # Find summary file (COHA naming patterns)
  summary_files <- list.files(
    rds_dir,
    pattern = "^(summary_data|summary)_.*\\.rds$",
    full.names = TRUE
  )
  
  if (length(summary_files) == 0) {
    errors <- c(errors,
                sprintf("Summary RDS not found in: %s", rds_dir))
    summary_path <- NULL
  } else {
    # Use most recent
    file_info <- file.info(summary_files)
    summary_path <- rownames(file_info)[which.max(file_info$mtime)]
  }
  
  # Find plot objects file (COHA naming patterns)
  plot_files <- list.files(
    rds_dir,
    pattern = "^(plot_results|plot_objects|ridgeline)_.*\\.rds$",
    full.names = TRUE
  )
  
  if (length(plot_files) == 0) {
    errors <- c(errors,
                sprintf("Plot RDS not found in: %s", rds_dir))
    plots_path <- NULL
  } else {
    # Use most recent
    file_info <- file.info(plot_files)
    plots_path <- rownames(file_info)[which.max(file_info$mtime)]
  }
  
  list(
    valid = length(errors) == 0,
    summary_path = summary_path,
    plots_path = plots_path,
    errors = errors
  )
}


#' Validate COHA Artifact Requirements
#'
#' @description
#' Wrapper around core::validate_artifact_registry() with COHA-specific defaults.
#'
#' @param registry List. Registry object from init_artifact_registry()
#' @param required_types Character vector. COHA artifact types that must exist.
#'   Default: c("raw_data", "ridgeline_plots")
#' @param check_hashes Logical. Verify SHA256 hashes? Default: FALSE
#' @param verbose Logical. Print validation details? Default: FALSE
#'
#' @return List with validation results
#'
#' @export
validate_coha_artifacts <- function(registry,
                                   required_types = c("raw_data", "ridgeline_plots"),
                                   check_hashes = FALSE,
                                   verbose = FALSE) {
  
  # Call core function (required_types defaults already set to COHA)
  validate_artifact_registry(
    registry = registry,
    required_types = required_types,
    check_hashes = check_hashes,
    verbose = verbose
  )
}

# ==============================================================================
# EOF
# ==============================================================================
