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
# - core/assertions.R
# - core/logging.R
# - core/config.R
# - core/report.R
# - R/functions/plot_function.R
# - R/config/plot_registry.R (master plot configuration)
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

# Source core utilities (in order of dependency)
source(here::here("core", "utilities.R"))
source(here::here("core", "console.R"))
source(here::here("core", "logging.R"))
source(here::here("core", "assertions.R"))
source(here::here("core", "config.R"))

# Phase 0b modules: Artifact registry system
source(here::here("R", "functions", "core", "artifacts.R"))
source(here::here("core", "report.R"))

# Phase 3 modules: robustness infrastructure (Phase 3A)
source(here::here("core", "robustness.R"))
source(here::here("core", "data_quality.R"))
source(here::here("R", "functions", "data_operations.R"))
source(here::here("R", "functions", "plot_operations.R"))

# Domain-specific utilities
source(here::here("domain_modules", "coha_dispersal", "data_loader.R"))

# Source plot type configurations
# Load plot registry (master configuration for all plot types)
source(here::here("R", "config", "plot_registry.R"))

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
                         verbose = TRUE,
                         use_registry = TRUE) {
  
  # Initialize tracking
  start_time <- Sys.time()
  log_file <- initialize_pipeline_log(verbose = verbose)
  
  # Phase 3C: Initialize comprehensive result object
  pipeline_result <- create_result("run_pipeline", verbose)
  pipeline_result$phase_results <- list()
  
  # Phase 1: Initialize artifact registry
  if (use_registry) {
    if (verbose) log_message("Initializing artifact registry", "DEBUG", verbose = TRUE)
    registry <- tryCatch(
      init_artifact_registry(),
      error = function(e) {
        if (verbose) log_message(
          sprintf("Registry init failed: %s", e$message),
          "WARNING", verbose = TRUE
        )
        NULL
      }
    )
  } else {
    registry <- NULL
  }
  
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
      data_path_full <- here::here(config$data$source_file)
      
      if (verbose) log_message(
        sprintf("Loading data from: %s", data_path_full),
        "INFO", verbose = TRUE
      )
      
      # Load and validate - returns structured result
      data_result <- load_and_validate_data(
        file_path = data_path_full,
        required_columns = c("mass", "year", "dispersed"),
        min_rows = 10,
        verbose = FALSE
      )
      
      # Phase 3D: Log data quality results
      if (verbose) {
        log_message(
          sprintf("Data quality assessment: %.0f/100 (%s)",
                 data_result$quality_score,
                 toupper(data_result$status)),
          "INFO", verbose = TRUE
        )
        
        log_message(
          sprintf("  - Completeness: %.1f%%",
                 data_result$quality_metrics$completeness),
          "DEBUG", verbose = TRUE
        )
        
        log_message(
          sprintf("  - Schema match: %.1f%%",
                 data_result$quality_metrics$schema_match),
          "DEBUG", verbose = TRUE
        )
        
        log_message(
          sprintf("  - Rows: %d",
                 data_result$rows),
          "DEBUG", verbose = TRUE
        )

        log_message(
          sprintf("  - Warnings: %d", length(data_result$warnings)),
          "DEBUG", verbose = TRUE
        )
      }
      
      # Store data result for final aggregation
      pipeline_result$phase_results$data_load <- data_result
      pipeline_result$data_quality_score <- data_result$quality_score
      
      # Collect data load warnings and errors
      if (length(data_result$warnings) > 0) {
        pipeline_result$warnings <- c(
          pipeline_result$warnings,
          paste("[DATA]", data_result$warnings)
        )
      }
      
      if (length(data_result$errors) > 0) {
        pipeline_result$errors <- c(
          pipeline_result$warnings,
          paste("[DATA]", data_result$errors)
        )
      }
      
      # Check if we can proceed
      if (data_result$status == "failed") {
        stop(sprintf("Data load failed: %s", data_result$message))
      }
      
      # Extract dataframe for plotting
      df <- data_result$data
      
      if (verbose) {
        log_message(
          sprintf("✓ Data loaded: %d rows, %d columns",
                 data_result$rows, data_result$columns),
          "INFO", verbose = TRUE
        )
      }
      
      # Phase 1: Register data artifact
      if (use_registry && !is.null(registry)) {
        registry <- tryCatch(
          register_artifact(
            registry = registry,
            artifact_name = "coha_dispersal_data",
            artifact_type = "raw_data",
            workflow = "data_load",
            file_path = data_path_full,
            input_artifacts = NULL,
            metadata = list(
              rows = data_result$rows,
              columns = data_result$columns,
              quality_score = data_result$quality_score
            ),
            data_hash = hash_dataframe(df),
            quiet = !verbose
          ),
          error = function(e) {
            if (verbose) log_message(
              sprintf("Data registration failed: %s", e$message),
              "WARNING", verbose = TRUE
            )
            registry
          }
        )
      }
    },
    error = function(e) {
      pipeline_result <<- add_error(
        pipeline_result,
        format_error_message(
          "data_load",
          e$message,
          "Check data file path and format"
        ),
        verbose
      )
    }
  )
  
  # If data load failed completely, stop pipeline
  if (pipeline_result$status == "failed") {
    end_time <- Sys.time()
    pipeline_result$status <- "failed"
    pipeline_result$duration_secs <- as.numeric(difftime(end_time, start_time, units = "secs"))
    pipeline_result$timestamp <- end_time
    pipeline_result$log_file <- log_file
    
    if (verbose) {
      log_message("PIPELINE FAILED at data load stage", "ERROR", verbose = TRUE)
      print_pipeline_complete("✗ PIPELINE FAILED", 
                              c(sprintf("Error: %s", pipeline_result$message)))
    }
    
    return(invisible(pipeline_result))
  }
  
  # ============================================================================
  # PHASE 2: Generate Ridgeline Plots (Phase 3B integration)
  # ============================================================================
  
  if (verbose) print_stage_header("2", "Generate Ridgeline Plots")
  if (verbose) log_message("Starting plot generation", "INFO", verbose = TRUE)
  
  tryCatch(
    {
      # Get enabled plot types from config
      enabled_types <- get_enabled_plot_types(config)
      
      if ("ridgeline" %in% enabled_types) {
        # Get ridgeline plot configurations from registry
        ridgeline_variants <- plot_registry$ridgeline$variants
        plot_configs_active <- ridgeline_variants
        
        # Create output directory
        ridgeline_output_dir <- here::here(
          config$paths$plots_base,
          config$plot_types$ridgeline$output_subdir,
          "variants"
        )
        dir.create(ridgeline_output_dir, recursive = TRUE, showWarnings = FALSE)
        
        if (verbose) {
          log_message(
            sprintf("Output directory: %s",
                   ridgeline_output_dir),
            "DEBUG", verbose = TRUE
          )
        }
        
        # Phase 3C: Use Phase 3B generate_all_plots_safe for batch generation
        if (verbose) {
          log_message(
            sprintf("Generating %d plot configurations",
                   length(plot_configs_active)),
            "INFO", verbose = TRUE
          )
        }
        
        plot_result <- generate_all_plots_safe(
          df = df,
          plot_configs = plot_configs_active,
          output_dir = ridgeline_output_dir,
          verbose = FALSE,  # Individual plot verbosity handled separately
          dpi = config$plot_types$ridgeline$defaults$dpi %||% 300
        )
        
        # Phase 3D: Log plot generation results
        if (verbose) {
          log_message(
            sprintf(
              "Plot generation complete: %d/%d successful, %d failed (%.0f%% success rate)",
              plot_result$plots_generated,
              plot_result$plots_total,
              plot_result$plots_failed,
              plot_result$success_rate
            ),
            "INFO", verbose = TRUE
          )
          
          log_message(
            sprintf("Average plot quality: %.0f/100",
                   plot_result$quality_score),
            "INFO", verbose = TRUE
          )
          
          log_message(
            sprintf("Total generation time: %.1f seconds",
                   plot_result$duration_secs),
            "DEBUG", verbose = TRUE
          )
        }
        
        # Store plot result for aggregation
        pipeline_result$phase_results$plot_generation <- plot_result
        pipeline_result$plots_generated <- plot_result$plots_generated
        pipeline_result$plots_failed <- plot_result$plots_failed
        pipeline_result$output_dir <- ridgeline_output_dir
        
        # Collect plot warnings and errors
        if (length(plot_result$warnings) > 0) {
          pipeline_result$warnings <- c(
            pipeline_result$warnings,
            paste("[PLOTS]", plot_result$warnings)
          )
        }
        
        if (length(plot_result$errors) > 0) {
          pipeline_result$errors <- c(
            pipeline_result$errors,
            paste("[PLOTS]", plot_result$errors)
          )
        }
        
        # Log individual plot results
        if (verbose && length(plot_result$results) > 0) {
          for (i in seq_along(plot_result$results)) {
            res <- plot_result$results[[i]]
            status_symbol <- if (res$status == "success") "✓" else "✗"
            log_message(
              sprintf("%s Plot %d/%d - %s (quality: %.0f/100, time: %.2fs)",
                     status_symbol,
                     i,
                     length(plot_result$results),
                     res$plot_id %||% sprintf("plot_%d", i),
                     res$quality_score %||% 0,
                     res$duration_secs %||% 0),
              "DEBUG", verbose = TRUE
            )
          }
        }
        
        # Phase 1: Register plot artifacts
        if (use_registry && !is.null(registry) && length(plot_result$results) > 0) {
          if (verbose) log_message(
            "Registering plot artifacts", "DEBUG", verbose = TRUE
          )
          
          for (i in seq_along(plot_result$results)) {
            res <- plot_result$results[[i]]
            if (res$status == "success" && !is.null(res$output_path)) {
              registry <- tryCatch(
                register_artifact(
                  registry = registry,
                  artifact_name = res$plot_id %||% sprintf("plot_%d", i),
                  artifact_type = "ridgeline_plots",
                  workflow = "plot_generation",
                  file_path = res$output_path,
                  input_artifacts = "coha_dispersal_data",
                  metadata = list(
                    scale_value = res$metadata$scale_value,
                    palette = res$metadata$palette,
                    quality_score = res$quality_score,
                    generation_time = res$generation_time
                  ),
                  quiet = TRUE
                ),
                error = function(e) {
                  if (verbose) log_message(
                    sprintf("Plot registration failed for %s: %s",
                           res$plot_id, e$message),
                    "WARNING", verbose = TRUE
                  )
                  registry
                }
              )
            }
          }
          
          if (verbose) log_message(
            sprintf("Registered %d plot artifacts", plot_result$plots_generated),
            "INFO", verbose = TRUE
          )
        }
        
        # Phase 2: RDS Caching - Save plot results for report access
        if (use_registry && !is.null(registry) && plot_result$plots_generated > 0) {
          if (verbose) log_message(
            "Caching plot results to RDS", "DEBUG", verbose = TRUE
          )
          
          # Create RDS directory if needed
          rds_dir <- here::here("results", "rds")
          if (!dir.exists(rds_dir)) {
            dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
          }
          
          # Generate RDS path with timestamp
          timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
          rds_path <- file.path(rds_dir, sprintf("plot_results_%s.rds", timestamp))
          
          # Save and register RDS
          registry <- tryCatch(
            save_and_register_rds(
              object = plot_result$results,
              file_path = rds_path,
              artifact_type = "plot_objects",
              workflow = "plot_generation",
              registry = registry,
              metadata = list(
                n_plots = plot_result$plots_generated,
                plots_failed = plot_result$plots_failed,
                avg_quality = plot_result$quality_score,
                generation_time_sec = plot_result$duration_secs
              ),
              verbose = verbose
            ),
            error = function(e) {
              if (verbose) log_message(
                sprintf("RDS caching failed: %s", e$message),
                "WARNING", verbose = TRUE
              )
              registry
            }
          )
          
          if (verbose && file.exists(rds_path)) {
            rds_size_mb <- file.info(rds_path)$size / (1024 * 1024)
            log_message(
              sprintf("Cached plot results to RDS (%.2f MB)", rds_size_mb),
              "INFO", verbose = TRUE
            )
          }
        }
      } else {
        if (verbose) {
          log_message("Ridgeline plots disabled in config", "INFO", verbose = TRUE)
        }
      }
    },
    error = function(e) {
      pipeline_result <<- add_error(
        pipeline_result,
        format_error_message(
          "plot_generation",
          e$message,
          "Check plot configurations and data structure"
        ),
        verbose
      )
    }
  )
  
  # ============================================================================
  # PHASE 3: Comprehensive Result Aggregation (Phase 3C final)
  # ============================================================================
  
  if (verbose) print_stage_header("3", "Aggregate Results")
  
  # Determine overall pipeline status
  if (pipeline_result$status == "failed") {
    # Already failed, keep status
  } else if (is.null(pipeline_result$plots_generated)) {
    pipeline_result$status <- "failed"
    pipeline_result <- add_error(
      pipeline_result,
      "No plots were generated",
      verbose
    )
  } else if (pipeline_result$plots_failed == 0 && 
             (is.null(pipeline_result$data_quality_score) || 
              pipeline_result$data_quality_score >= 90)) {
    pipeline_result <- set_result_status(
      pipeline_result,
      "success",
      sprintf("Pipeline complete: %d plots generated",
             pipeline_result$plots_generated),
      verbose
    )
  } else if (pipeline_result$plots_generated > 0) {
    pipeline_result <- set_result_status(
      pipeline_result,
      "partial",
      sprintf("Pipeline partial: %d plots, %d failed",
             pipeline_result$plots_generated,
             pipeline_result$plots_failed %||% 0),
      verbose
    )
  } else {
    pipeline_result <- add_error(
      pipeline_result,
      "Pipeline failed: no plots generated",
      verbose
    )
  }
  
  # Compute overall quality score (weighted)
  quality_components <- list(
    data = pipeline_result$data_quality_score %||% 0,
    plots = if (!is.null(pipeline_result$phase_results$plot_generation)) {
      pipeline_result$phase_results$plot_generation$quality_score
    } else {
      0
    }
  )
  
  # Weight: data 40%, plots 60%
  overall_quality <- (quality_components$data * 0.4) + 
                     (quality_components$plots * 0.6)
  pipeline_result$quality_score <- overall_quality
  
  if (verbose) {
    log_message(
      sprintf("Overall pipeline quality score: %.0f/100",
             overall_quality),
      "INFO", verbose = TRUE
    )
  }
  
  # ============================================================================
  # FINALIZE: Print summary and return comprehensive result
  # ============================================================================
  
  end_time <- Sys.time()
  pipeline_result$timestamp <- end_time
  pipeline_result$duration_secs <- as.numeric(difftime(end_time, start_time, units = "secs"))
  pipeline_result$log_file <- log_file
  pipeline_result$pipeline_name <- "COHA Dispersal Ridgeline Analysis (Phase 3)"
  
  # Phase 1: Store registry in result
  if (use_registry && !is.null(registry)) {
    pipeline_result$registry <- registry
    if (verbose) log_message(
      sprintf("Artifact registry contains %d artifacts",
             length(registry$artifacts)),
      "INFO", verbose = TRUE
    )
  }
  
  if (verbose) {
    plots_generated <- pipeline_result$plots_generated %||% 0
    plots_failed <- pipeline_result$plots_failed %||% 0
    plots_total <- plots_generated + plots_failed
    success_rate <- if (plots_total > 0) (plots_generated / plots_total) * 100 else 0

    summary_lines <- c(
      sprintf("Overall Status: %s", toupper(pipeline_result$status)),
      sprintf("Data Quality: %.0f/100", pipeline_result$data_quality_score %||% 0),
      sprintf("Plots: %d/%d generated, %d failed (%.0f%% success)",
             plots_generated,
             plots_total,
             plots_failed,
             success_rate),
      sprintf("Average Plot Quality: %.0f/100",
             if (!is.null(pipeline_result$phase_results$plot_generation)) 
               pipeline_result$phase_results$plot_generation$quality_score else 0),
      sprintf("Pipeline Quality: %.0f/100", pipeline_result$quality_score),
      sprintf("Time Elapsed: %.1f seconds", pipeline_result$duration_secs),
      sprintf("Output: %s", pipeline_result$output_dir %||% "N/A"),
      sprintf("Log File: %s", pipeline_result$log_file %||% "N/A")
    )
    
    if (pipeline_result$status == "success") {
      print_pipeline_complete("✓ PIPELINE COMPLETE", summary_lines)
    } else if (pipeline_result$status == "partial") {
      print_pipeline_complete("⚠ PIPELINE PARTIAL", summary_lines)
    } else {
      print_pipeline_complete("✗ PIPELINE FAILED", summary_lines)
    }
    
    log_message(
      sprintf("PIPELINE COMPLETE - %s in %.1f sec",
             pipeline_result$status, pipeline_result$duration_secs),
      "INFO", verbose = TRUE
    )
  }
  
  invisible(pipeline_result)
}


