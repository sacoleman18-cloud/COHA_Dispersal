# ==============================================================================
# R/pipeline/pipeline.R
# ==============================================================================
# PURPOSE
# -------
# Main orchestrator for COHA dispersal analysis pipeline.
# Loads config, data, and plot specifications; generates all variants.
# This is the primary public interface for running the analysis.
#
# DEPENDS ON
# ----------
# - tidyverse (data manipulation)
# - ggplot2 (plotting)
# - ggridges (ridgeline geoms)
# - here (path management)
# - yaml (config parsing)
# - R/functions/assertions.R
# - R/functions/logging.R
# - R/functions/config_loader.R
# - R/functions/plot_function.R
# - R/config/ridgeline_config.R
#
# ==============================================================================

# Load required packages
required_packages <- c("tidyverse", "ggridges", "ggplot2", "here", "yaml", "readr", "dplyr")
for (pkg in required_packages) {
  if (!require(pkg, quietly = TRUE, character.only = TRUE)) {
    stop(sprintf("Package '%s' required. Install with: install.packages('%s')",
                 pkg, pkg), call. = FALSE)
  }
}

# Source helper functions from R/functions/ (in order of dependency)
source(here::here("R", "functions", "utilities.R"))
source(here::here("R", "functions", "console.R"))
source(here::here("R", "functions", "assertions.R"))
source(here::here("R", "functions", "logging.R"))
source(here::here("R", "functions", "config_loader.R"))
source(here::here("R", "functions", "plot_function.R"))

# Phase 3 modules: robustness infrastructure (Phase 3A)
source(here::here("R", "functions", "robustness.R"))
source(here::here("R", "functions", "data_quality.R"))
source(here::here("R", "functions", "phase3_data_operations.R"))
source(here::here("R", "functions", "phase3_plot_operations.R"))

# Source plot type configurations
source(here::here("R", "config", "ridgeline_config.R"))

#' Run Complete COHA Dispersal Analysis Pipeline
#'
#' @description
#' Orchestrates generation of all configured ridgeline plot variants with
#' Phase 3 robustness. Loads data with quality assessment, validates schema,
#' generates plots with error recovery, and aggregates comprehensive results.
#' If data loads or plots fail, continues gracefully with partial results.
#'
#' @param config_path Character. Path to study_parameters.yaml.
#'   Default: "inst/config/study_parameters.yaml".
#' @param verbose Logical. Print progress messages. Default: FALSE.
#'
#' @return invisibly returns comprehensive list with:
#'   - pipeline_name: Character
#'   - status: "success", "partial", or "failed"
#'   - phase_results: List with data_load, plot_generation results
#'   - data_quality_score: 0-100 data quality
#'   - plots_generated: Numeric count
#'   - plots_failed: Numeric count
#'   - output_dir: Character path
#'   - quality_score: 0-100 overall quality
#'   - timestamp: POSIXct
#'   - duration_seconds: Total time
#'   - log_file: Character path
#'   - errors: Character vector (if any)
#'   - warnings: Character vector (if any)
#'
#' @examples
#' # Run with defaults
#' result <- run_pipeline(verbose = TRUE)
#'
#' @export
run_pipeline <- function(data_path = "data/data.csv",
                         output_dir = "results/png",
                         configs = plot_configs,
                         verbose = TRUE) {
  
  # Initialize tracking
  start_time <- Sys.time()
  log_file <- initialize_pipeline_log(verbose = verbose)
  
  # Phase 3C: Initialize comprehensive result object
  pipeline_result <- create_result("run_pipeline", verbose)
  pipeline_result$phase_results <- list()
  
  if (verbose) print_stage_header("1", "Load & Validate Data")
  if (verbose) log_message("PIPELINE START", "INFO", verbose = TRUE)
  
  # ============================================================================
  # PHASE 1: Data Load & Validation (Phase 3A integration)
  # ============================================================================
  
  tryCatch(
    {
      # Load configuration (Phase 1 standard: use here::here())
      config <- load_study_config(verbose = verbose)
      
      # Validate config paths exist/can be created
      validate_config_paths(config, create = TRUE, verbose = verbose)
      
      # Phase 3C: Use Phase 3A load_and_validate_data with quality assessment
      data_path_full <- here::here(config$data$source_file)\n      \n      if (verbose) log_message(\n        sprintf(\"Loading data from: %s\", data_path_full),\n        \"INFO\", verbose = TRUE\n      )\n      \n      # Load and validate - returns structured result\n      data_result <- load_and_validate_data(\n        file_path = data_path_full,\n        required_columns = c(\"mass\", \"year\", \"dispersed\", \"origin\"),\n        min_rows = 10,\n        verbose = FALSE\n      )\n      \n      # Phase 3D: Log data quality results\n      if (verbose) {\n        log_message(\n          sprintf(\"Data quality assessment: %.0f/100\",\n                 data_result$quality_score),\n          \"INFO\", verbose = TRUE\n        )\n        \n        log_message(\n          sprintf(\"  - Completeness: %.1f%%\",\n                 data_result$quality_metrics$completeness),\n          \"DEBUG\", verbose = TRUE\n        )\n        \n        log_message(\n          sprintf(\"  - Schema match: %.1f%%\",\n                 data_result$quality_metrics$schema_match),\n          \"DEBUG\", verbose = TRUE\n        )\n        \n        log_message(\n          sprintf(\"  - Rows: %d\",\n                 data_result$rows),\n          \"DEBUG\", verbose = TRUE\n        )\n      }\n      \n      # Store data result for final aggregation\n      pipeline_result$phase_results$data_load <- data_result\n      pipeline_result$data_quality_score <- data_result$quality_score\n      \n      # Collect data load warnings and errors\n      if (length(data_result$warnings) > 0) {\n        pipeline_result$warnings <- c(\n          pipeline_result$warnings,\n          paste(\"[DATA]\", data_result$warnings)\n        )\n      }\n      \n      if (length(data_result$errors) > 0) {\n        pipeline_result$errors <- c(\n          pipeline_result$errors,\n          paste(\"[DATA]\", data_result$errors)\n        )\n      }\n      \n      # Check if we can proceed\n      if (data_result$status == \"failed\") {\n        stop(sprintf(\"Data load failed: %s\", data_result$message))\n      }\n      \n      # Extract dataframe for plotting\n      df <- data_result$data\n      \n      if (verbose) {\n        log_message(\n          sprintf(\"✓ Data loaded: %d rows, %d columns\",\n                 data_result$rows, data_result$columns),\n          \"INFO\", verbose = TRUE\n        )\n      }\n    },\n    error = function(e) {\n      pipeline_result <<- add_error(\n        pipeline_result,\n        format_error_message(\n          \"data_load\",\n          e$message,\n          \"Check data file path and format\"\n        ),\n        verbose\n      )\n    }\n  )\n  \n  # If data load failed completely, stop pipeline\n  if (pipeline_result$status == \"failed\") {\n    end_time <- Sys.time()\n    pipeline_result$status <- \"failed\"\n    pipeline_result$duration_secs <- as.numeric(difftime(end_time, start_time, units = \"secs\"))\n    pipeline_result$timestamp <- end_time\n    pipeline_result$log_file <- log_file\n    \n    if (verbose) {\n      log_message(\"PIPELINE FAILED at data load stage\", \"ERROR\", verbose = TRUE)\n      print_pipeline_complete(\"✗ PIPELINE FAILED\", \n                              c(sprintf(\"Error: %s\", pipeline_result$message)))\n    }\n    \n    return(invisible(pipeline_result))\n  }\n  \n  # ============================================================================\n  # PHASE 2: Generate Ridgeline Plots (Phase 3B integration)\n  # ============================================================================\n  \n  if (verbose) print_stage_header(\"2\", \"Generate Ridgeline Plots\")\n  if (verbose) log_message(\"Starting plot generation\", \"INFO\", verbose = TRUE)\n  \n  tryCatch(\n    {\n      # Get enabled plot types from config\n      enabled_types <- get_enabled_plot_types(config)\n      \n      if (\"ridgeline\" %in% enabled_types) {\n        # Load ridgeline configurations\n        plot_configs_active <- ridgeline_plot_configs\n        \n        # Create output directory\n        ridgeline_output_dir <- here::here(\n          config$paths$plots_base,\n          config$plot_types$ridgeline$output_subdir,\n          \"variants\"\n        )\n        dir.create(ridgeline_output_dir, recursive = TRUE, showWarnings = FALSE)\n        \n        if (verbose) {\n          log_message(\n            sprintf(\"Output directory: %s\",\n                   ridgeline_output_dir),\n            \"DEBUG\", verbose = TRUE\n          )\n        }\n        \n        # Phase 3C: Use Phase 3B generate_all_plots_safe for batch generation\n        if (verbose) {\n          log_message(\n            sprintf(\"Generating %d plot configurations\",\n                   length(plot_configs_active)),\n            \"INFO\", verbose = TRUE\n          )\n        }\n        \n        plot_result <- generate_all_plots_safe(\n          df = df,\n          plot_configs = plot_configs_active,\n          output_dir = ridgeline_output_dir,\n          verbose = FALSE,  # Individual plot verbosity handled separately\n          dpi = config$plot_types$ridgeline$defaults$dpi %||% 300\n        )\n        \n        # Phase 3D: Log plot generation results\n        if (verbose) {\n          log_message(\n            sprintf(\"Plot generation complete: %d/%d successful (%.0f%% success rate)\",\n                   plot_result$plots_generated,\n                   plot_result$plots_total,\n                   plot_result$success_rate),\n            \"INFO\", verbose = TRUE\n          )\n          \n          log_message(\n            sprintf(\"Average plot quality: %.0f/100\",\n                   plot_result$quality_score),\n            \"INFO\", verbose = TRUE\n          )\n          \n          log_message(\n            sprintf(\"Total generation time: %.1f seconds\",\n                   plot_result$duration_secs),\n            \"DEBUG\", verbose = TRUE\n          )\n        }\n        \n        # Store plot result for aggregation\n        pipeline_result$phase_results$plot_generation <- plot_result\n        pipeline_result$plots_generated <- plot_result$plots_generated\n        pipeline_result$plots_failed <- plot_result$plots_failed\n        pipeline_result$output_dir <- ridgeline_output_dir\n        \n        # Collect plot warnings and errors\n        if (length(plot_result$warnings) > 0) {\n          pipeline_result$warnings <- c(\n            pipeline_result$warnings,\n            paste(\"[PLOTS]\", plot_result$warnings)\n          )\n        }\n        \n        if (length(plot_result$errors) > 0) {\n          pipeline_result$errors <- c(\n            pipeline_result$errors,\n            paste(\"[PLOTS]\", plot_result$errors)\n          )\n        }\n        \n        # Log individual plot results\n        if (verbose && length(plot_result$results) > 0) {\n          for (i in seq_along(plot_result$results)) {\n            res <- plot_result$results[[i]]\n            status_symbol <- if (res$status == \"success\") \"✓\" else \"✗\"\n            log_message(\n              sprintf(\"%s Plot %d/%d - %s (quality: %.0f/100, time: %.2fs)\",\n                     status_symbol,\n                     i,\n                     length(plot_result$results),\n                     res$plot_id %||% sprintf(\"plot_%d\", i),\n                     res$quality_score %||% 0,\n                     res$duration_secs %||% 0),\n              \"DEBUG\", verbose = TRUE\n            )\n          }\n        }\n      } else {\n        if (verbose) {\n          log_message(\"Ridgeline plots disabled in config\", \"INFO\", verbose = TRUE)\n        }\n      }\n    },\n    error = function(e) {\n      pipeline_result <<- add_error(\n        pipeline_result,\n        format_error_message(\n          \"plot_generation\",\n          e$message,\n          \"Check plot configurations and data structure\"\n        ),\n        verbose\n      )\n    }\n  )\n  \n  # ============================================================================\n  # PHASE 3: Comprehensive Result Aggregation (Phase 3C final)\n  # ============================================================================\n  \n  if (verbose) print_stage_header(\"3\", \"Aggregate Results\")\n  \n  # Determine overall pipeline status\n  if (pipeline_result$status == \"failed\") {\n    # Already failed, keep status\n  } else if (is.null(pipeline_result$plots_generated)) {\n    pipeline_result$status <- \"failed\"\n    pipeline_result <- add_error(\n      pipeline_result,\n      \"No plots were generated\",\n      verbose\n    )\n  } else if (pipeline_result$plots_failed == 0 && \n             (is.null(pipeline_result$data_quality_score) || \n              pipeline_result$data_quality_score >= 90)) {\n    pipeline_result <- set_result_status(\n      pipeline_result,\n      \"success\",\n      sprintf(\"Pipeline complete: %d plots generated\",\n             pipeline_result$plots_generated),\n      verbose\n    )\n  } else if (pipeline_result$plots_generated > 0) {\n    pipeline_result <- set_result_status(\n      pipeline_result,\n      \"partial\",\n      sprintf(\"Pipeline partial: %d plots, %d failed\",\n             pipeline_result$plots_generated,\n             pipeline_result$plots_failed %||% 0),\n      verbose\n    )\n  } else {\n    pipeline_result <- add_error(\n      pipeline_result,\n      \"Pipeline failed: no plots generated\",\n      verbose\n    )\n  }\n  \n  # Compute overall quality score (weighted)\n  quality_components <- list(\n    data = pipeline_result$data_quality_score %||% 0,\n    plots = if (!is.null(pipeline_result$phase_results$plot_generation)) {\n      pipeline_result$phase_results$plot_generation$quality_score\n    } else {\n      0\n    }\n  )\n  \n  # Weight: data 40%, plots 60%\n  overall_quality <- (quality_components$data * 0.4) + \n                     (quality_components$plots * 0.6)\n  pipeline_result$quality_score <- overall_quality\n  \n  if (verbose) {\n    log_message(\n      sprintf(\"Overall pipeline quality score: %.0f/100\",\n             overall_quality),\n      \"INFO\", verbose = TRUE\n    )\n  }\n  \n  # ============================================================================\n  # FINALIZE: Print summary and return comprehensive result\n  # ============================================================================\n  \n  end_time <- Sys.time()\n  pipeline_result$timestamp <- end_time\n  pipeline_result$duration_secs <- as.numeric(difftime(end_time, start_time, units = \"secs\"))\n  pipeline_result$log_file <- log_file\n  pipeline_result$pipeline_name <- \"COHA Dispersal Ridgeline Analysis (Phase 3)\"\n  \n  if (verbose) {\n    summary_lines <- c(\n      sprintf(\"Overall Status: %s\", toupper(pipeline_result$status)),\n      sprintf(\"Data Quality: %.0f/100\", pipeline_result$data_quality_score %||% 0),\n      sprintf(\"Plots Generated: %d/%d\",\n             pipeline_result$plots_generated %||% 0,\n             (pipeline_result$plots_generated %||% 0) + (pipeline_result$plots_failed %||% 0)),\n      sprintf(\"Average Plot Quality: %.0f/100\",\n             if (!is.null(pipeline_result$phase_results$plot_generation)) \n               pipeline_result$phase_results$plot_generation$quality_score else 0),\n      sprintf(\"Pipeline Quality: %.0f/100\", pipeline_result$quality_score),\n      sprintf(\"Time Elapsed: %.1f seconds\", pipeline_result$duration_secs),\n      sprintf(\"Output: %s\", pipeline_result$output_dir %||% \"N/A\")\n    )\n    \n    if (pipeline_result$status == \"success\") {\n      print_pipeline_complete(\"✓ PIPELINE COMPLETE\", summary_lines)\n    } else if (pipeline_result$status == \"partial\") {\n      print_pipeline_complete(\"⚠ PIPELINE PARTIAL\", summary_lines)\n    } else {\n      print_pipeline_complete(\"✗ PIPELINE FAILED\", summary_lines)\n    }\n    \n    log_message(\n      sprintf(\"PIPELINE COMPLETE - %s in %.1f sec\",\n             pipeline_result$status, pipeline_result$duration_secs),\n      \"INFO\", verbose = TRUE\n    )\n  }\n  \n  invisible(pipeline_result)\n}

#' Generate Single Plot by Configuration ID
#'
#' @description
#' Directly generate one plot without running full pipeline.
#' Useful for interactive exploration and Quarto reports.
#'
#' @param plot_id Character. Plot ID (e.g., "compact_01").
#' @param verbose Logical. Print progress. Default: FALSE.
#'
#' @return ggplot2 object
#'
#' @examples
#' p <- generate_plot("compact_01")
#' print(p)
#'
#' @export
generate_plot <- function(plot_id,
                          data_path = "data/data.csv",
                          configs = ridgeline_plot_configs,
                          verbose = FALSE) {
  
  if (verbose) {
    log_message(sprintf("Generating %s", plot_id), "INFO", verbose = TRUE)
  }
  
  # Load data
  data_path_full <- here::here(data_path)
  df <- readr::read_csv(data_path_full, show_col_types = FALSE)
  
  # Find config
  config_item <- NULL
  for (cfg in configs) {
    if (cfg$id == plot_id) {
      config_item <- cfg
      break
    }
  }
  
  if (is.null(config_item)) {
    stop(sprintf("Plot ID not found: %s", plot_id), call. = FALSE)
  }
  
  # Create and return plot
  create_ridgeline_plot(
    data = df,
    scale_value = config_item$scale_value,
    line_height = config_item$line_height,
    fill_palette = config_item$fill_palette,
    color_palette = config_item$color_palette,
    palette_type = config_item$palette_type,
    verbose = verbose
  )
}

#' List All Available Plot Configurations
#'
#' @description
#' Returns data frame describing all ridgeline plot variants.
#'
#' @return Data frame with columns: id, name, scale_value, line_height, palette, palette_type
#'
#' @examples
#' plots_df <- list_plots()
#' head(plots_df)
#'
#' @export
list_plots <- function() {
  do.call(rbind, lapply(ridgeline_plot_configs, function(x) {
    data.frame(
      id = x$id,
      name = x$name,
      scale_value = x$scale_value,
      line_height = x$line_height,
      palette = x$fill_palette,
      palette_type = x$palette_type,
      stringsAsFactors = FALSE
    )
  }))
}
