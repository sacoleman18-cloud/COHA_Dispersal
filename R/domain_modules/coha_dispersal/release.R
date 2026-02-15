# ==============================================================================
# R/functions/core/coha_release.R
# ==============================================================================
# PURPOSE
# -------
# COHA-specific release management functions for artifact registry system.
# Simplified from KPro release.R for single-study use case.
#
# PROVIDES
# --------
# - create_release_bundle(): Create portable zip bundle with plots/reports
# - cleanup_old_artifacts(): Remove old plot files to prevent disk bloat
#
# ==============================================================================

#' Create COHA Release Bundle
#'
#' @description
#' Creates a portable ZIP bundle containing analysis outputs with manifest.
#' Designed for sharing complete analysis with collaborators.
#'
#' @param study_name Character. Study identifier (default: "COHA_Dispersal")
#' @param include_raw_data Logical. Include source data.csv? (default: TRUE)
#' @param include_plots Logical. Include all 20 plot PNG files? (default: TRUE)
#' @param include_reports Logical. Include rendered HTML reports? (default: TRUE)
#' @param include_config Logical. Include artifact registry YAML? (default: TRUE)
#' @param output_dir Character. Where to save ZIP (default: "results/releases")
#' @param quiet Logical. Suppress messages? (default: FALSE)
#'
#' @return Character. Full path to created ZIP file.
#'
#' @export
create_release_bundle <- function(study_name = "COHA_Dispersal",
                                  include_raw_data = TRUE,
                                  include_plots = TRUE,
                                  include_reports = TRUE,
                                  include_config = TRUE,
                                  output_dir = here::here("results", "releases"),
                                  quiet = FALSE) {
  
  if (!quiet) cat("\n=== Creating COHA Release Bundle ===\n\n")
  
  # 1. Create staging directory
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  staging_name <- sprintf("coha_release_%s", timestamp)
  staging_dir <- file.path(tempdir(), staging_name)
  dir.create(staging_dir, recursive = TRUE)
  
  if (!quiet) cat(sprintf("Staging: %s\n", staging_dir))
  
  files_included <- 0
  
  # 2. Copy raw data
  if (include_raw_data) {
    data_src <- here::here("data", "data.csv")
    if (file.exists(data_src)) {
      data_dest_dir <- file.path(staging_dir, "data")
      dir.create(data_dest_dir, recursive = TRUE)
      file.copy(data_src, file.path(data_dest_dir, "data.csv"))
      files_included <- files_included + 1
      if (!quiet) cat("  ✓ Raw data (data.csv)\n")
    } else {
      if (!quiet) cat("  ⚠ Raw data not found - skipping\n")
    }
  }
  
  # 3. Copy plots
  if (include_plots) {
    plots_src <- here::here("results", "plots", "ridgeline", "variants")
    if (dir.exists(plots_src)) {
      plots_dest_dir <- file.path(staging_dir, "plots")
      dir.create(plots_dest_dir, recursive = TRUE)
      
      plot_files <- list.files(plots_src, pattern = "\\.png$", full.names = TRUE)
      if (length(plot_files) > 0) {
        file.copy(plot_files, plots_dest_dir)
        files_included <- files_included + length(plot_files)
        if (!quiet) cat(sprintf("  ✓ %d plot PNG files\n", length(plot_files)))
      }
    } else {
      if (!quiet) cat("  ⚠ Plots directory not found - skipping\n")
    }
  }
  
  # 4. Copy reports
  if (include_reports) {
    reports_src <- here::here("results", "reports")
    if (dir.exists(reports_src)) {
      reports_dest_dir <- file.path(staging_dir, "reports")
      dir.create(reports_dest_dir, recursive = TRUE)
      
      report_files <- list.files(reports_src, pattern = "\\.html$", full.names = TRUE)
      if (length(report_files) > 0) {
        file.copy(report_files, reports_dest_dir)
        files_included <- files_included + length(report_files)
        if (!quiet) cat(sprintf("  ✓ %d HTML reports\n", length(report_files)))
      }
    } else {
      if (!quiet) cat("  ⚠ Reports directory not found - skipping\n")
    }
  }
  
  # 5. Copy artifact registry
  if (include_config) {
    registry_src <- here::here("R", "config", "artifact_registry.yaml")
    if (file.exists(registry_src)) {
      config_dest_dir <- file.path(staging_dir, "config")
      dir.create(config_dest_dir, recursive = TRUE)
      file.copy(registry_src, file.path(config_dest_dir, "artifact_registry.yaml"))
      files_included <- files_included + 1
      if (!quiet) cat("  ✓ Artifact registry (artifact_registry.yaml)\n")
    } else {
      if (!quiet) cat("  ⚠ Artifact registry not found - skipping\n")
    }
  }
  
  # 6. Create manifest
  manifest <- list(
    release_name = staging_name,
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    pipeline_version = "1.0",
    study = study_name,
    includes = list(
      raw_data = include_raw_data,
      plots = include_plots,
      reports = include_reports,
      config = include_config
    ),
    file_count = files_included
  )
  
  manifest_path <- file.path(staging_dir, "manifest.yaml")
  yaml::write_yaml(manifest, manifest_path)
  if (!quiet) cat("  ✓ Manifest (manifest.yaml)\n")
  
  # 7. Create ZIP
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  zip_filename <- sprintf("coha_release_%s.zip", timestamp)
  zip_path <- file.path(output_dir, zip_filename)
  
  # Get all files in staging dir (relative paths)
  old_wd <- getwd()
  setwd(staging_dir)
  all_files <- list.files(".", recursive = TRUE, all.files = TRUE)
  setwd(old_wd)
  
  zip::zip(zipfile = zip_path, files = file.path(staging_dir, all_files), mode = "cherry-pick")
  
  zip_size_mb <- file.info(zip_path)$size / 1024^2
  
  if (!quiet) {
    cat(sprintf("\n✓ Release bundle created: %s\n", zip_filename))
    cat(sprintf("  Location: %s\n", zip_path))
    cat(sprintf("  Size: %.2f MB\n", zip_size_mb))
    cat(sprintf("  Files: %d\n\n", files_included + 1))  # +1 for manifest
  }
  
  invisible(zip_path)
}


#' Clean Up Old Artifact Files
#'
#' @description
#' Removes old plot files from disk to prevent accumulation.
#' Keeps most recent N runs, deletes older files.
#' Updates artifact registry to reflect deletions.
#'
#' @param keep_count Integer. Number of recent runs to keep (default: 3)
#' @param registry_path Character. Path to registry (default: auto-detect)
#' @param dry_run Logical. Preview deletions without executing? (default: FALSE)
#' @param quiet Logical. Suppress messages? (default: FALSE)
#'
#' @return List with deleted file count and freed space.
#'
#' @export
cleanup_old_artifacts <- function(keep_count = 3,
                                  registry_path = here::here("R", "config", "artifact_registry.yaml"),
                                  dry_run = FALSE,
                                  quiet = FALSE) {
  
  if (!quiet) cat("\n=== Artifact Cleanup ===\n\n")
  
  if (!file.exists(registry_path)) {
    stop(sprintf("Registry not found: %s", registry_path))
  }
  
  # Load registry
  registry <- yaml::read_yaml(registry_path)
  
  if (is.null(registry$artifacts)) {
    if (!quiet) cat("No artifacts in registry - nothing to clean.\n")
    return(invisible(list(deleted = 0, freed_mb = 0)))
  }
  
  # Get all plot artifacts sorted by creation time
  plot_artifacts <- Filter(function(x) x$type == "ridgeline_plots", registry$artifacts)
  
  if (length(plot_artifacts) == 0) {
    if (!quiet) cat("No plot artifacts found - nothing to clean.\n")
    return(invisible(list(deleted = 0, freed_mb = 0)))
  }
  
  # Sort by created_utc (newest first)
  plot_names <- names(plot_artifacts)
  creation_times <- sapply(plot_artifacts, function(x) x$created_utc %||% "")
  plot_names_sorted <- plot_names[order(creation_times, decreasing = TRUE)]
  
  # Determine which to keep (most recent keep_count)
  plot_groups <- unique(gsub("_\\d{8}_\\d{6}\\.png$", "", 
                             sapply(plot_artifacts[plot_names_sorted], 
                                   function(x) basename(x$file_path))))
  
  # Keep newest keep_count runs
  to_keep <- plot_names_sorted[1:min(keep_count * 20, length(plot_names_sorted))]
  to_delete <- setdiff(plot_names_sorted, to_keep)
  
  if (length(to_delete) == 0) {
    if (!quiet) cat(sprintf("All %d plots are recent - nothing to delete.\n", length(plot_names_sorted)))
    return(invisible(list(deleted = 0, freed_mb = 0)))
  }
  
  # Calculate space to free
  space_freed <- 0
  deleted_count <- 0
  
  if (!quiet) {
    cat(sprintf("Found %d plots total\n", length(plot_names_sorted)))
    cat(sprintf("Keeping %d most recent\n", length(to_keep)))
    cat(sprintf("Deleting %d old plots\n\n", length(to_delete)))
  }
  
  for (artifact_name in to_delete) {
    artifact <- registry$artifacts[[artifact_name]]
    file_path <- artifact$file_path
    
    if (file.exists(file_path)) {
      file_size <- file.info(file_path)$size
      
      if (!dry_run) {
        unlink(file_path)
        registry$artifacts[[artifact_name]] <- NULL
        space_freed <- space_freed + file_size
        deleted_count <- deleted_count + 1
      }
      
      if (!quiet) {
        action <- if (dry_run) "[DRY RUN]" else "[DELETED]"
        cat(sprintf("%s %s (%.2f MB)\n", 
                   action, basename(file_path), file_size / 1024^2))
      }
    } else {
      # File already gone, just remove from registry
      if (!dry_run) {
        registry$artifacts[[artifact_name]] <- NULL
      }
      if (!quiet) {
        cat(sprintf("[MISSING] %s (already deleted)\n", artifact_name))
      }
    }
  }
  
  # Save updated registry
  if (!dry_run) {
    registry$last_modified_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    yaml::write_yaml(registry, registry_path)
  }
  
  if (!quiet) {
    cat(sprintf("\n✓ Cleanup complete\n"))
    cat(sprintf("  Files deleted: %d\n", deleted_count))
    cat(sprintf("  Space freed: %.2f MB\n", space_freed / 1024^2))
    if (dry_run) cat("\n(DRY RUN - no changes made)\n")
  }
  
  invisible(list(
    deleted = deleted_count,
    freed_mb = space_freed / 1024^2
  ))
}

# ==============================================================================
# END R/functions/core/coha_release.R
# ==============================================================================
