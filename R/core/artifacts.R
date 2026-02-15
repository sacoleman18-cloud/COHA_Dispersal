# ==============================================================================
# R/functions/core/artifacts.R
# ==============================================================================
# PURPOSE
# -------
# Universal artifact registry & file provenance tracking system.
# Provides domain-agnostic functions for managing pipeline artifacts.
# Domain implementations should create connectors to define specific artifact types.
#
# DEPENDS ON
# ----------
# R Packages: 
#   - yaml:  Registry file I/O
#   - digest: SHA256 hashing
#   - here: Path management
#
# Internal Dependencies:
#   - R/functions/core/utilities.R (ensure_dir_exists)
#
# FUNCTIONS PROVIDED
# ------------------
# Registry Management:
#   - init_artifact_registry(): Create/load registry YAML
#   - register_artifact(): Add artifact with hash + metadata
#   - get_artifact(): Retrieve artifact metadata
#   - list_artifacts(): List all artifacts (filterable)
#   - get_latest_artifact(): Get most recent by type
#
# Hashing & Provenance:
#   - hash_file(): SHA256 file hash
#   - hash_dataframe(): Content-based data frame hash
#   - verify_artifact(): Check hash integrity
#
# RDS Management:
#   - save_and_register_rds(): Atomic RDS save + register
#   - discover_pipeline_rds(): Find summary/plot RDS files
#   - validate_rds_structure(): Validate RDS contents
#
# CHANGELOG
# ---------
# 2026-02-11: Phase 0b - Adapted from KPro Reference_code
#             - Changed ARTIFACT_TYPES for COHA (ridgeline_plots, etc.)
#             - Changed REGISTRY_PATH to R/config/
#             - Adapted discover_pipeline_rds() for COHA naming
#             - Adapted validate_rds_structure() for COHA schema
#             - Kept all core functions as-is (proven implementations)
# ==============================================================================

library(yaml)
library(digest)
library(here)

# ==============================================================================
# CONSTANTS
# ==============================================================================

REGISTRY_PATH <- here::here("R", "config", "artifact_registry.yaml")
PIPELINE_VERSION <- "1.0"

# Default artifact types - can be overridden by domain-specific implementations
DEFAULT_ARTIFACT_TYPES <- c(
  "raw_data",
  "checkpoint",
  "processed_data",
  "intermediate",
  "results",
  "report",
  "validation_report"
)

# ==============================================================================
# REGISTRY MANAGEMENT
# ==============================================================================

#' Initialize or Load Artifact Registry
#'
#' @description
#' Creates a new artifact registry or loads an existing one. The registry
#' is a YAML file that tracks all pipeline artifacts with metadata. 
#'
#' @param registry_path Character. Path to registry file.  
#'   Defaults to R/config/artifact_registry.yaml
#'
#' @return List. Registry object with artifacts and metadata.
#'
#' @section CONTRACT:
#' - Creates registry file if it doesn't exist
#' - Returns valid registry structure even if empty
#' - Never overwrites existing registry
#'
#' @export
init_artifact_registry <- function(registry_path = REGISTRY_PATH) {
  
  # Ensure directory exists
  registry_dir <- dirname(registry_path)
  if (!dir.exists(registry_dir)) {
    dir.create(registry_dir, recursive = TRUE)
  }
  
  # Load existing or create new
  if (file.exists(registry_path)) {
    registry <- yaml::read_yaml(registry_path)
    message(sprintf("[OK] Loaded artifact registry: %d artifacts", 
                    length(registry$artifacts)))
  } else {
    registry <- list(
      registry_version = "1.0",
      created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      pipeline_version = PIPELINE_VERSION,
      artifacts = list()
    )
    yaml::write_yaml(registry, registry_path)
    message("[OK] Created new artifact registry")
  }
  
  # Attach path for later saves
  attr(registry, "path") <- registry_path
  
  registry
}


#' Register an Artifact
#'
#' @description
#' Adds an artifact to the registry with full provenance metadata including
#' file hash, optional data hash for reproducibility, source workflow, and timestamps.
#'
#' @param registry List. Registry object from init_artifact_registry()
#' @param artifact_name Character. Unique name for this artifact
#' @param artifact_type Character. Artifact type (validated against allowed_types)
#' @param workflow Character. Workflow that produced this (e.g., "plot_generation", "data_processing")
#' @param file_path Character. Path to artifact file
#' @param input_artifacts Character vector. Names of input artifacts (for lineage)
#' @param metadata List. Additional metadata to store
#' @param data_hash Character. Optional SHA256 hash of data frame content for
#'   deterministic reproducibility. If provided, stored as data_hash_sha256. Default: NULL
#' @param allowed_types Character vector. Valid artifact types for this domain.
#'   Defaults to DEFAULT_ARTIFACT_TYPES. Domain implementations should override.
#' @param quiet Logical. Suppress messages if TRUE
#'
#' @return List. Updated registry object (also saved to disk)
#'
#' @section CONTRACT:
#' - Computes SHA256 hash of file automatically
#' - Stores data_hash if provided for reproducibility tracking
#' - Adds timestamp and pipeline version
#' - Saves registry to disk
#' - Returns updated registry invisibly
#'
#' @export
register_artifact <- function(registry, 
                              artifact_name,
                              artifact_type,
                              workflow,
                              file_path,
                              input_artifacts = NULL,
                              metadata = list(),
                              data_hash = NULL,
                              allowed_types = DEFAULT_ARTIFACT_TYPES,
                              quiet = FALSE) {
  
  # Validate artifact type
  if (!artifact_type %in% allowed_types) {
    stop(sprintf(
      "Invalid artifact_type '%s'. Must be one of: %s",
      artifact_type,
      paste(allowed_types, collapse = ", ")
    ))
  }
  
  # Validate file exists
  if (!file.exists(file_path)) {
    stop(sprintf("Artifact file not found: %s", file_path))
  }
  
  # Compute hash
  file_hash <- hash_file(file_path)
  
  # Build artifact entry
  artifact_entry <- list(
    name = artifact_name,
    type = artifact_type,
    workflow = workflow,
    file_path = file_path,
    file_hash_sha256 = file_hash,
    file_size_bytes = file.info(file_path)$size,
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    pipeline_version = PIPELINE_VERSION,
    input_artifacts = input_artifacts,
    metadata = metadata
  )
  
  # Add data hash if provided (for reproducibility tracking)
  if (!is.null(data_hash)) {
    artifact_entry$data_hash_sha256 <- data_hash
  }
  
  # Add to registry
  registry$artifacts[[artifact_name]] <- artifact_entry
  registry$last_modified_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  
  # Save to disk
  registry_path <- attr(registry, "path")
  if (is.null(registry_path)) registry_path <- REGISTRY_PATH
  yaml::write_yaml(registry, registry_path)
  
  if (!quiet) {
    message(sprintf("[OK] Registered artifact: %s (%s)", artifact_name, artifact_type))
  }
  
  invisible(registry)
}


#' Get Artifact Metadata
#'
#' @description
#' Retrieves metadata for a specific artifact from the registry.
#'
#' @param registry List. Registry object
#' @param artifact_name Character. Name of artifact to retrieve
#'
#' @return List. Artifact metadata, or NULL if not found
#'
#' @export
get_artifact <- function(registry, artifact_name) {
  registry$artifacts[[artifact_name]]
}


#' List All Artifacts
#'
#' @description
#' Returns a data frame summary of all artifacts in the registry,
#' with optional filtering by type or workflow.
#'
#' @param registry List. Registry object
#' @param type Character. Optional filter by artifact type
#' @param workflow Character. Optional filter by workflow
#'
#' @return Data frame. Summary of matching artifacts
#'
#' @export
list_artifacts <- function(registry, type = NULL, workflow = NULL) {
  
  if (length(registry$artifacts) == 0) {
    return(data.frame(
      name = character(),
      type = character(),
      workflow = character(),
      created_utc = character(),
      stringsAsFactors = FALSE
    ))
  }
  
  # Convert to data frame
  df <- do.call(rbind, lapply(registry$artifacts, function(a) {
    data.frame(
      name = a$name,
      type = a$type,
      workflow = a$workflow,
      created_utc = a$created_utc,
      file_path = a$file_path,
      file_hash = substr(a$file_hash_sha256, 1, 8),  # Truncated for display
      stringsAsFactors = FALSE
    )
  }))
  
  # Apply filters
  if (!is.null(type)) {
    df <- df[df$type == type, ]
  }
  
  if (!is.null(workflow)) {
    df <- df[df$workflow == workflow, ]
  }
  
  df
}


#' Get Most Recent Artifact by Type
#'
#' @description
#' Finds and returns the most recently created artifact of a given type.
#'
#' @param registry List. Registry object
#' @param type Character. Artifact type to find
#'
#' @return List. Most recent artifact of that type, or NULL if none found
#'
#' @export
get_latest_artifact <- function(registry, type) {
  
  matching <- Filter(function(x) x$type == type, registry$artifacts)
  
  if (length(matching) == 0) return(NULL)
  
  # Sort by created_utc descending
  sorted <- matching[order(sapply(matching, `[[`, "created_utc"), decreasing = TRUE)]
  
  sorted[[1]]
}


# ==============================================================================
# HASHING FUNCTIONS
# ==============================================================================

#' Compute SHA256 Hash of File
#'
#' @description
#' Computes a SHA256 hash of a file for integrity verification.
#'
#' @param file_path Character. Path to file
#'
#' @return Character. SHA256 hash string (64 hex characters)
#'
#' @export
hash_file <- function(file_path) {
  if (!file.exists(file_path)) {
    stop(sprintf("File not found: %s", file_path))
  }
  
  digest::digest(file_path, algo = "sha256", file = TRUE)
}


#' Compute Hash of Data Frame
#'
#' @description
#' Computes a content-based hash of a data frame for deterministic
#' reproducibility tracking. Ensures same data produces same hash
#' regardless of row order when sort_by is specified.
#'
#' @param df Data frame to hash
#' @param sort_by Character vector. Column names to sort by for deterministic
#'   order. If NULL, uses existing row order (not recommended). Default: NULL
#'
#' @return Character. SHA256 hash string (64 hex characters)
#'
#' @section RECOMMENDED USAGE:
#' ```r
#' # For COHA dispersal data: sort by key columns
#' hash <- hash_dataframe(coha_data, sort_by = c("year", "origin", "mass"))
#' ```
#'
#' @export
hash_dataframe <- function(df, sort_by = NULL) {
  
  if (!is.data.frame(df)) {
    stop("Input must be a data frame")
  }
  
  # Sort for deterministic order
  if (!is.null(sort_by)) {
    df <- df[do.call(order, df[sort_by]), ]
  }
  
  # Hash the serialized content
  digest::digest(df, algo = "sha256")
}


#' Verify Artifact Integrity
#'
#' @description
#' Checks if a file's current hash matches its registered hash.
#'
#' @param registry List. Registry object
#' @param artifact_name Character. Name of artifact to verify
#'
#' @return Logical. TRUE if hashes match, FALSE otherwise
#'
#' @export
verify_artifact <- function(registry, artifact_name) {
  
  artifact <- get_artifact(registry, artifact_name)
  
  if (is.null(artifact)) {
    warning(sprintf("Artifact not found in registry: %s", artifact_name))
    return(FALSE)
  }
  
  if (!file.exists(artifact$file_path)) {
    warning(sprintf("Artifact file not found: %s", artifact$file_path))
    return(FALSE)
  }
  
  current_hash <- hash_file(artifact$file_path)
  matches <- current_hash == artifact$file_hash_sha256
  
  if (!matches) {
    warning(sprintf(
      "Hash mismatch for %s:\n  Registered: %s\n  Current:    %s",
      artifact_name,
      artifact$file_hash_sha256,
      current_hash
    ))
  }
  
  matches
}


#' Validate Artifact Registry Before Rendering
#'
#' @description
#' Comprehensive validation of artifact registry before report rendering.
#' Checks that required artifacts exist, files are present on disk, and
#' hashes match. Returns detailed validation result for graceful error handling.
#'
#' @param registry List. Registry object from init_artifact_registry()
#' @param required_types Character vector. Artifact types that must exist.
#'   Default: c("raw_data", "results") - override in domain implementations
#' @param check_hashes Logical. Verify SHA256 hashes match? Can be slow for
#'   many files. Default: FALSE
#' @param verbose Logical. Print validation details. Default: FALSE
#'
#' @return List with fields:
#'   - valid: Logical. TRUE if all checks passed
#'   - errors: Character vector. Error messages (empty if valid)
#'   - warnings: Character vector. Warning messages
#'   - missing_types: Character vector. Types with no artifacts
#'   - missing_files: Character vector. Artifact names with missing files
#'   - hash_mismatches: Character vector. Artifact names with hash mismatches
#'
#' @section USAGE:
#' ```r
#' validation <- validate_artifact_registry(registry)
#' if (!validation$valid) {
#'   stop(sprintf("Registry validation failed:\n  %s",
#'               paste(validation$errors, collapse = "\n  ")))
#' }
#' ```
#'
#' @export
validate_artifact_registry <- function(registry,
                                       required_types = c("raw_data", "results"),
                                       check_hashes = FALSE,
                                       verbose = FALSE) {
  
  result <- list(
    valid = TRUE,
    errors = character(),
    warnings = character(),
    missing_types = character(),
    missing_files = character(),
    hash_mismatches = character()
  )
  
  if (verbose) message("[VALIDATE] Checking artifact registry...")
  
  # Check 1: Registry exists and has artifacts
  if (is.null(registry) || length(registry$artifacts) == 0) {
    result$valid <- FALSE
    result$errors <- c(result$errors, "Registry is empty or NULL")
    return(result)
  }
  
  if (verbose) {
    message(sprintf("[VALIDATE] Registry contains %d artifacts", 
                   length(registry$artifacts)))
  }
  
  # Check 2: Required artifact types exist
  existing_types <- unique(sapply(registry$artifacts, function(x) x$type))
  
  for (req_type in required_types) {
    if (!req_type %in% existing_types) {
      result$missing_types <- c(result$missing_types, req_type)
      result$errors <- c(result$errors,
                        sprintf("No artifacts of required type: %s", req_type))
      result$valid <- FALSE
    }
  }
  
  if (verbose && length(result$missing_types) > 0) {
    message(sprintf("[VALIDATE] Missing types: %s",
                   paste(result$missing_types, collapse = ", ")))
  }
  
  # Check 3: Artifact files exist on disk
  for (name in names(registry$artifacts)) {
    artifact <- registry$artifacts[[name]]
    
    if (!file.exists(artifact$file_path)) {
      result$missing_files <- c(result$missing_files, name)
      result$errors <- c(result$errors,
                        sprintf("File not found for artifact '%s': %s",
                               name, artifact$file_path))
      result$valid <- FALSE
    }
  }
  
  if (verbose && length(result$missing_files) > 0) {
    message(sprintf("[VALIDATE] Missing files: %d artifacts",
                   length(result$missing_files)))
  }
  
  # Check 4: Hash verification (optional, can be slow)
  if (check_hashes) {
    if (verbose) message("[VALIDATE] Verifying SHA256 hashes...")
    
    for (name in names(registry$artifacts)) {
      artifact <- registry$artifacts[[name]]
      
      # Only check if file exists
      if (file.exists(artifact$file_path)) {
        current_hash <- hash_file(artifact$file_path)
        
        if (current_hash != artifact$file_hash_sha256) {
          result$hash_mismatches <- c(result$hash_mismatches, name)
          result$warnings <- c(result$warnings,
                              sprintf("Hash mismatch for '%s'", name))
          # Hash mismatch is warning, not error (file might have been updated)
        }
      }
    }
    
    if (verbose && length(result$hash_mismatches) > 0) {
      message(sprintf("[VALIDATE] Hash mismatches: %d artifacts",
                     length(result$hash_mismatches)))
    }
  }
  
  # Summary
  if (verbose) {
    if (result$valid) {
      message("[VALIDATE] ✓ Registry validation passed")
    } else {
      message(sprintf("[VALIDATE] ✗ Registry validation failed: %d errors",
                     length(result$errors)))
    }
  }
  
  result
}


# ==============================================================================
# RDS MANAGEMENT
# ==============================================================================

#' Save RDS File and Register Artifact
#'
#' @description
#' Atomically saves an R object as RDS file and registers it in the artifact
#' registry with SHA256 hash. Consolidates the RDS save + register pattern.
#'
#' @param object Any R object to save as RDS.
#' @param file_path Character. Full path to RDS file.
#' @param artifact_type Character. Type identifier for registry (e.g.,
#'   "summary_stats", "plot_objects").
#' @param workflow Character. Workflow name for registry (e.g., "plot_generation",
#'   "data_processing").
#' @param registry List. Current artifact registry from init_artifact_registry().
#' @param metadata List. Additional metadata for registry entry. Default: list().
#' @param verbose Logical. Print confirmation message to console? Default: FALSE.
#'
#' @return List. Updated artifact registry with new entry.
#'
#' @export
save_and_register_rds <- function(object,
                                  file_path,
                                  artifact_type,
                                  workflow,
                                  registry,
                                  metadata = list(),
                                  verbose = FALSE) {
  
  # Ensure output directory exists
  output_dir <- dirname(file_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    if (verbose) {
      message(sprintf("Created directory: %s", output_dir))
    }
  }
  
  # Save RDS file
  saveRDS(object, file_path)
  
  # Generate artifact ID from type and timestamp
  timestamp <- format(Sys.time(), "%Y%m%d")
  artifact_id <- sprintf("%s_%s", artifact_type, timestamp)
  
  # Register artifact (computes hash automatically)
  registry <- register_artifact(
    registry = registry,
    artifact_name = artifact_id,
    artifact_type = artifact_type,
    workflow = workflow,
    file_path = file_path,
    metadata = metadata,
    quiet = !verbose
  )
  
  # Print confirmation if verbose
  if (verbose) {
    message(sprintf("  [OK] Saved: %s", basename(file_path)))
  }
  
  registry
}


# ==============================================================================
# RDS DISCOVERY & VALIDATION (domain-specific extension point)
# ==============================================================================

#' Discover Pipeline RDS Files
#'
#' @description
#' Generic template for RDS discovery. Domain implementations should override
#' this function to define their own file patterns and naming conventions.
#' 
#' Default behavior: Looks for summary_*.rds and results_*.rds patterns
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
discover_pipeline_rds <- function(rds_dir) {
  
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
  
  # Find summary file (generic patterns - override in domain module)
  summary_files <- list.files(
    rds_dir,
    pattern = "^summary.*\\.rds$",
    full.names = TRUE
  )
  
  if (length(summary_files) == 0) {
    errors <- c(errors, 
                "No summary RDS file found. Expected: summary_data_*.rds or summary_*.rds")
    summary_path <- NULL
  } else {
    # Get most recent by modification time
    summary_times <- file.info(summary_files)$mtime
    summary_path <- summary_files[which.max(summary_times)]
  }
  
  # Find plot objects file (flexible patterns for COHA)
  plots_files <- list.files(
    rds_dir,
    pattern = "^(plot_objects|plot_results)_.*\\.rds$",
    full.names = TRUE
  )
  
  if (length(plots_files) == 0) {
    errors <- c(errors,
                "No plot_objects RDS file found. Expected: plot_objects_*.rds or plot_results_*.rds")
    plots_path <- NULL
  } else {
    # Get most recent by modification time
    plots_times <- file.info(plots_files)$mtime
    plots_path <- plots_files[which.max(plots_times)]
  }
  
  list(
    valid = length(errors) == 0,
    summary_path = summary_path,
    plots_path = plots_path,
    errors = errors
  )
}


#' Validate RDS Structure
#'
#' @description
#' Validates that loaded RDS objects contain required elements for
#' report generation. Checks structure specific to COHA dispersal analysis.
#'
#' COHA Adaptation: Validates ridgeline plot structure, not bat-specific elements
#'
#' @param all_summaries List. Summary data
#' @param all_plots List. Plot objects (ggplot2 ridgeline plots)
#'
#' @return List with:
#'   - valid: Logical. TRUE if structure is valid
#'   - errors: Character vector. Error messages if any
#'   - warnings: Character vector. Warning messages if any
#'   - plot_counts: Named list. Count of plots
#'   - total_plots: Integer. Total number of plots
#'
#' @export
validate_rds_structure <- function(all_summaries, all_plots) {
  
  errors <- character()
  warnings <- character()
  
  # -------------------------
  # Validate summary structure (flexible for COHA)
  # -------------------------
  
  if (!is.null(all_summaries) && !is.list(all_summaries)) {
    errors <- c(errors, "all_summaries must be a list")
  }
  
  # -------------------------
  # Validate plot structure
  # -------------------------
  
  if (is.null(all_plots)) {
    errors <- c(errors, "all_plots is NULL")
  } else if (!is.list(all_plots)) {
    errors <- c(errors, "all_plots must be a list")
  }
  
  # -------------------------
  # Count plots
  # -------------------------
  
  total_plots <- 0
  plot_counts <- list()
  
  if (is.list(all_plots)) {
    # If all_plots is a simple list of plots (COHA pattern)
    if (all(sapply(all_plots, function(x) inherits(x, "ggplot")))) {
      total_plots <- length(all_plots)
      plot_counts$ridgeline <- total_plots
    } else if (all(sapply(all_plots, is.list))) {
      # If all_plots has categories (more complex structure)
      for (category in names(all_plots)) {
        count <- length(all_plots[[category]])
        plot_counts[[category]] <- count
        total_plots <- total_plots + count
      }
    }
  }
  
  if (total_plots == 0) {
    warnings <- c(warnings, "No plots found in all_plots")
  }
  
  # -------------------------
  # Return validation result
  # -------------------------
  
  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings,
    plot_counts = plot_counts,
    total_plots = total_plots
  )
}

# ==============================================================================
# END OF FILE
# ==============================================================================
