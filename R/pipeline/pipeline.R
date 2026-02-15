# ==============================================================================
# R/pipeline/pipeline.R
# ==============================================================================
# PURPOSE
# -------
# Main orchestrator for COHA dispersal analysis pipeline.
# Loads config, data, and uses plugin-based plot system for extensibility.
# This is the primary public interface for running the analysis.
#
# ARCHITECTURE: PHASE 2.1 PLUGIN-BASED PLOTS
# -------------------------------------------
# Pipeline is plot-type agnostic. Plot generation is fully pluggable:
# 1. discover_modules() finds all R/plot_modules/[type]/module.R
# 2. load_module() dynamically loads each module
# 3. orchestrate_plot_generation() calls module's generate_plots_batch()
#
# To add a new plot type:
#  → Create R/plot_modules/[new_type]/module.R
#  → Implement required interface (get_module_metadata, generate_plot, etc.)
#  → Pipeline auto-discovers and executes - NO downstream code changes!
#
# DEPENDS ON
# ----------
# - tidyverse (data manipulation)
# - ggplot2 (plotting)
# - here (path management)
# - yaml (config parsing)
# - core/assertions.R
# - core/logging.R
# - core/config.R
# - core/engine.R (orchestrate_plot_generation)
# - R/config/plot_registry.R (optional - for backward compatibility)
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
source(here::here("R", "core", "utilities.R"))
source(here::here("R", "core", "console.R"))
source(here::here("R", "core", "logging.R"))
source(here::here("R", "core", "assertions.R"))
source(here::here("R", "core", "config.R"))

# Universal visualization utilities
source(here::here("R", "core", "palettes.R"))  # Color palettes (universal)

# Phase 0b modules: Artifact registry system
source(here::here("R", "core", "artifacts.R"))
source(here::here("R", "core", "report.R"))

# Phase 1.12 modules: Critical connectors (Result & Config interfaces)
source(here::here("R", "core", "module_result.R"))
source(here::here("R", "core", "module_schema.R"))

# Phase 1.13 modules: Important connectors (Data & Error interfaces)
source(here::here("R", "core", "error_interface.R"))
source(here::here("R", "core", "data_interface.R"))

# Phase 1.14 modules: Advanced connectors (Dependencies, Lifecycle, Events)
source(here::here("R", "core", "module_dependencies.R"))
source(here::here("R", "core", "module_lifecycle.R"))
source(here::here("R", "core", "module_events.R"))

# Core pipeline engine (orchestrator and plugin manager)
source(here::here("R", "core", "engine.R"))

# Phase 3 modules: robustness infrastructure (Phase 3A)
source(here::here("R", "core", "robustness.R"))
source(here::here("R", "core", "data_quality.R"))
source(here::here("R", "functions", "data_operations.R"))
source(here::here("R", "functions", "plot_operations.R"))

# Domain-specific utilities
source(here::here("R", "domain_modules", "coha_dispersal", "data_loader.R"))

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
                         use_registry = TRUE,
                         include_reports = TRUE) {
  
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
          "WARN", verbose = TRUE
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
              "WARN", verbose = TRUE
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
  # PHASE 2: Generate Plots via Plugin System (Phase 2.1 integration)
  # ============================================================================
  # Phase 2.1: Plugin-based plot generation
  # - Auto-discovers all plot modules in R/plot_modules/
  # - Dynamically loads and executes each module
  # - No hardcoding of plot types - truly extensible
  # - Add new plot module → pipeline auto-discovers it
  
  if (verbose) print_stage_header("2", "Generate Plots (Plugin System)")
  if (verbose) log_message("Starting plugin-based plot generation", "INFO", verbose = TRUE)
  
  tryCatch(
    {
      # Create base output directory for all plots
      plots_output_base <- here::here(
        config$paths$plots_base %||% "data/plots"
      )
      dir.create(plots_output_base, recursive = TRUE, showWarnings = FALSE)
      
      if (verbose) {
        log_message(
          sprintf("Plot output base: %s", plots_output_base),
          "DEBUG", verbose = TRUE
        )
      }
      
      # PHASE 2.1: Use plugin-based orchestration
      plot_result <- orchestrate_plot_generation(
        data = df,
        base_dir = here::here(),
        output_base = plots_output_base,
        verbose = verbose,
        dpi = config$plot_types$default_dpi %||% 300,
        continue_on_error = TRUE
      )
      
      # Log orchestration results
      if (verbose) {
        log_message(
          sprintf(
            "Plot modules: %d discovered, %d loaded, %d failed",
            plot_result$modules_found,
            plot_result$modules_loaded,
            plot_result$modules_failed
          ),
          "INFO", verbose = TRUE
        )
        
        log_message(
          sprintf(
            "Plot generation: %d successful, %d failed",
            plot_result$plots_generated,
            plot_result$plots_failed
          ),
          "INFO", verbose = TRUE
        )
        
        log_message(
          sprintf("Generation time: %.1f seconds", plot_result$duration_secs),
          "DEBUG", verbose = TRUE
        )
      }
      
      # Store plot result for aggregation
      pipeline_result$phase_results$plot_generation <- plot_result
      pipeline_result$plots_generated <- plot_result$plots_generated
      pipeline_result$plots_failed <- plot_result$plots_failed
      pipeline_result$output_dir <- plots_output_base
      
      # Collect plot warnings and errors
      if (length(plot_result$errors) > 0) {
        pipeline_result$errors <- c(
          pipeline_result$errors,
          paste("[PLOTS]", plot_result$errors)
        )
      }
      
      # Register all plot artifacts across all modules
      if (use_registry && !is.null(registry) && plot_result$plots_generated > 0) {
        if (verbose) log_message(
          "Registering plot artifacts from all modules", "DEBUG", verbose = TRUE
        )
        
        artifacts_registered <- 0
        
        # Iterate through all modules and their results
        for (module_name in names(plot_result$results)) {
          module_results <- plot_result$results[[module_name]]
          
          if (!is.list(module_results) || length(module_results) == 0) next
          
          # Each item in module_results is a plot result
          for (i in seq_along(module_results)) {
            res <- module_results[[i]]
            
            if (!is.list(res) || res$status != "success" || is.null(res$output_path)) {
              next
            }
            
            # Register as generic plot artifact
            registry <- tryCatch(
              register_artifact(
                registry = registry,
                artifact_name = res$plot_id %||% sprintf("%s_plot_%d", module_name, i),
                artifact_type = "plot",
                workflow = "plot_generation",
                file_path = res$output_path,
                input_artifacts = "coha_dispersal_data",
                metadata = list(
                  module = module_name,
                  plot_id = res$plot_id,
                  quality_score = res$quality_score %||% 0,
                  generation_time = res$duration_secs %||% 0
                ),
                quiet = TRUE
              ),
              error = function(e) {
                if (verbose) log_message(
                  sprintf("Plot registration failed for %s: %s",
                         res$plot_id %||% "unknown", e$message),
                  "WARN", verbose = TRUE
                )
                registry
              }
            )
            
            artifacts_registered <- artifacts_registered + 1
          }
        }
        
        if (verbose && artifacts_registered > 0) {
          log_message(
            sprintf("Registered %d plot artifacts", artifacts_registered),
            "INFO", verbose = TRUE
          )
        }
        
        # Cache all plot results to RDS
        if (plot_result$plots_generated > 0) {
          if (verbose) log_message(
            "Caching plot results to RDS", "DEBUG", verbose = TRUE
          )
          
          rds_dir <- here::here("results", "rds")
          if (!dir.exists(rds_dir)) {
            dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
          }
          
          timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
          rds_path <- file.path(rds_dir, sprintf("plot_results_%s.rds", timestamp))
          
          registry <- tryCatch(
            save_and_register_rds(
              object = plot_result$results,
              file_path = rds_path,
              artifact_type = "plot_objects",
              workflow = "plot_generation",
              registry = registry,
              metadata = list(
                n_modules = plot_result$modules_loaded,
                n_plots = plot_result$plots_generated,
                plots_failed = plot_result$plots_failed,
                generation_time_sec = plot_result$duration_secs
              ),
              verbose = verbose
            ),
            error = function(e) {
              if (verbose) log_message(
                sprintf("RDS caching failed: %s", e$message),
                "WARN", verbose = TRUE
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
      }
    },
    error = function(e) {
      pipeline_result <<- add_error(
        pipeline_result,
        format_error_message(
          "plot_generation",
          e$message,
          "Check plot module definitions and data structure"
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
  # STAGE 4: Generate & Render Reports
  # ============================================================================
  
  if (include_reports && verbose) print_stage_header("4", "Generate & Render Reports")
  
  pipeline_result$rendered_reports <- character()
  pipeline_result$report_generation_status <- "skipped"
  
  if (include_reports) {
    # Check if Quarto is available
    quarto_bin <- Sys.which("quarto")
    
    if (!nzchar(quarto_bin)) {
      if (verbose) {
        log_message(
          "Quarto CLI not found - skipping report generation",
          "WARN", verbose = TRUE
        )
      }
      pipeline_result$report_generation_status <- "quarto_unavailable"
    } else {
      report_names <- c(
        "full_analysis_report",
        "plot_gallery",
        "data_quality_report"
      )
      
      # Use absolute path for output directory
      output_dir_abs <- normalizePath(file.path(pipeline_result$output_dir %||% "results/plots", "..", "reports"), winslash="/", mustWork=FALSE)
      dir.create(output_dir_abs, recursive = TRUE, showWarnings = FALSE)
      
      rendered_reports <- character()
      failed_reports <- character()
      
      for (report_name in report_names) {
        # Core/mothership templates live in the top-level reports/ folder
        qmd_file <- file.path("reports", sprintf("%s.qmd", report_name))
        if (!file.exists(qmd_file)) {
          qmd_file <- NULL
        }
        
        if (!is.null(qmd_file)) {
          qmd_file_abs <- normalizePath(qmd_file, winslash="/", mustWork=TRUE)
          output_file <- file.path(output_dir_abs, sprintf("%s.html", report_name))
          
          if (verbose) {
            log_message(
              sprintf("Rendering report: %s", report_name),
              "INFO", verbose = TRUE
            )
          }
          
          # Render using quarto CLI via system2
          output <- system2(quarto_bin, 
                           c("render", shQuote(qmd_file_abs), 
                             "--output-dir", shQuote(output_dir_abs)),
                           stdout = TRUE, stderr = TRUE)
          
          exit_code <- attr(output, "status")
          if (is.null(exit_code)) exit_code <- 0
          
          if (exit_code == 0 && file.exists(output_file)) {
            rendered_reports <- c(rendered_reports, output_file)
            if (verbose) {
              log_message(
                sprintf("Report rendered: %s", basename(output_file)),
                "INFO", verbose = TRUE
              )
            }
            
            # Register report artifact if registry exists
            if (use_registry && !is.null(registry)) {
              tryCatch({
                registry <- register_artifact(
                  registry = registry,
                  artifact_name = report_name,
                  artifact_type = "report",
                  workflow = "reporting",
                  file_path = output_file,
                  input_artifacts = c("coha_dispersal_data"),
                  metadata = list(
                    format = "HTML",
                    template = basename(qmd_file)
                  ),
                  quiet = !verbose
                )
              }, error = function(e) {
                if (verbose) {
                  log_message(
                    sprintf("Report registration failed: %s", e$message),
                    "WARN", verbose = TRUE
                  )
                }
              })
            }
          } else {
            failed_reports <- c(failed_reports, report_name)
            if (verbose) {
              log_message(
                sprintf("Report rendering failed: %s", report_name),
                "WARN", verbose = TRUE
              )
            }
          }
        } else {
          if (verbose) {
            log_message(
              sprintf("Report template not found: %s", report_name),
              "WARN", verbose = TRUE
            )
          }
          failed_reports <- c(failed_reports, report_name)
        }
      }
      
      pipeline_result$rendered_reports <- rendered_reports
      pipeline_result$failed_reports <- failed_reports
      pipeline_result$report_generation_status <- 
        if (length(rendered_reports) > 0) "success" else "failed"
      
      if (verbose) {
        reports_generated <- length(rendered_reports)
        reports_failed <- length(failed_reports)
        log_message(
          sprintf("Reports: %d rendered, %d failed",
                 reports_generated, reports_failed),
          "INFO", verbose = TRUE
        )
      }
    }
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
    reports_generated <- length(pipeline_result$rendered_reports %||% character())

    summary_lines <- c(
      sprintf("Overall Status: %s", toupper(pipeline_result$status)),
      sprintf("Data Quality: %.0f/100", pipeline_result$data_quality_score %||% 0),
      sprintf("Plots: %d/%d generated, %d failed (%.0f%% success)",
             plots_generated,
             plots_total,
             plots_failed,
             success_rate),
      sprintf("Reports: %d rendered", reports_generated),
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



