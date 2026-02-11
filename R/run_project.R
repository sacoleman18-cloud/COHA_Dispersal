#!/usr/bin/env Rscript
# ==============================================================================
# R/run_project.R
# ==============================================================================
# Single entrypoint to run the pipeline and render reports.
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(callr)
})

setwd(here::here())

cat("\n")
cat("================================================================================\n")
cat("COHA DISPERSAL ANALYSIS - RUN PIPELINE + REPORTS\n")
cat("================================================================================\n")
cat("\n")

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
create_bundle <- "--bundle" %in% args

if (create_bundle) {
  cat("[INFO] Release bundle will be created after rendering\n\n")
}

# Execute pipeline and reports in separate R process (non-blocking)
cat("[INFO] Running pipeline and reports in separate process...\n")
cat("[INFO] This may take several minutes. RStudio console remains responsive.\n\n")

result <- callr::r(
  func = function(create_bundle = FALSE) {
    library(here)
    setwd(here::here())

    source(here::here("R", "pipeline", "pipeline.R"))

    # Run pipeline with registry
    result <- run_pipeline(verbose = TRUE, use_registry = TRUE)
    
    # Extract registry from pipeline result
    registry <- result$registry

    render_reports <- function(report_names, output_dir = "results/reports", registry = NULL) {
      quarto_bin <- Sys.which("quarto")
      if (!nzchar(quarto_bin)) {
        cat("[ERROR] Quarto CLI not found in PATH\n")
        cat("        Install from https://quarto.org/\n")
        cat("        Or add Quarto to your PATH\n")
        return(list(success = FALSE, rendered = character(), registry = registry))
      }
      
      cat(sprintf("[INFO] Using Quarto: %s\n", quarto_bin))

      # Phase 2: Validate registry before rendering (from original plan Phase 2)
      if (!is.null(registry)) {
        cat("[VALIDATE] Checking artifact registry before rendering reports...\n")
        
        validation <- validate_artifact_registry(
          registry = registry,
          required_types = c("raw_data", "ridgeline_plots"),
          check_hashes = FALSE,  # Skip hash check for speed (files just created)
          verbose = TRUE
        )
        
        if (!validation$valid) {
          warning_msg <- sprintf(
            "Registry validation failed:\n  %s",
            paste(validation$errors, collapse = "\n  ")
          )
          cat(sprintf("[WARNING] %s\n", warning_msg))
          cat("[INFO] Reports will still attempt to render, but may fail\n")
          
          # Log but don't fail - graceful degradation
          if (length(validation$missing_files) > 0) {
            cat(sprintf("[WARNING] Missing %d artifact files\n", 
                       length(validation$missing_files)))
          }
        } else {
          cat(sprintf("[OK] Registry validated: %d artifacts verified\n",
                     length(registry$artifacts)))
        }
        
        # Check for RDS cache specifically
        rds_artifacts <- Filter(function(x) x$type == "plot_objects", registry$artifacts)
        if (length(rds_artifacts) > 0) {
          latest_rds <- rds_artifacts[[length(rds_artifacts)]]
          if (file.exists(latest_rds$file_path)) {
            cat(sprintf("[OK] Plot RDS cache available: %s\n", 
                       basename(latest_rds$file_path)))
          } else {
            cat(sprintf("[WARNING] Plot RDS cache missing: %s\n",
                       basename(latest_rds$file_path)))
          }
        }
      } else {
        cat("[INFO] No registry provided - skipping validation\n")
      }

      # Use absolute paths to avoid Quarto changing working directory
      output_dir_abs <- here::here(output_dir)
      dir.create(output_dir_abs, recursive = TRUE, showWarnings = FALSE)

      rendered_reports <- character()
      failed_reports <- character()
      
      for (report_name in report_names) {
        qmd_file_abs <- here::here("reports", paste0(report_name, ".qmd"))
        
        if (!file.exists(qmd_file_abs)) {
          cat(sprintf("[WARNING] Report source file not found: %s\n", qmd_file_abs))
          next
        }

        cat(sprintf("[REPORT] Rendering %s\n", report_name))
        cat(sprintf("  Input: %s\n", qmd_file_abs))
        cat(sprintf("  Output: %s\n", output_dir_abs))
        
        # Render report with proper error handling
        output <- system2(quarto_bin, 
                         c("render", shQuote(qmd_file_abs), 
                           "--output-dir", shQuote(output_dir_abs)),
                         stdout = TRUE, stderr = TRUE)
        
        exit_code <- attr(output, "status")
        if (is.null(exit_code)) exit_code <- 0  # NULL means success
        
        # Show output if there was an error
        if (exit_code != 0) {
          cat(sprintf("  [ERROR] Quarto rendering failed with exit code %d\n", exit_code))
          cat("  Output:\n")
          cat(paste("   ", output, collapse = "\n"), "\n")
          failed_reports <- c(failed_reports, report_name)
          next
        }
        
        # Determine output file path
        output_file <- file.path(output_dir_abs, paste0(report_name, ".html"))
        
        if (file.exists(output_file)) {
          rendered_reports <- c(rendered_reports, output_file)
          cat(sprintf("  [OK] Report saved: %s\n", basename(output_file)))
          
          # Register report artifact
          if (!is.null(registry)) {
            registry <- tryCatch(
              register_artifact(
                registry = registry,
                artifact_name = report_name,
                artifact_type = "report",
                workflow = "reporting",
                file_path = output_file,
                input_artifacts = c("coha_dispersal_data", 
                                   grep("^(compact|expanded)_", names(registry$artifacts), value = TRUE)),
                metadata = list(
                  format = "HTML",
                  self_contained = TRUE,
                  template = basename(qmd_file_abs)
                ),
                quiet = FALSE
              ),
              error = function(e) {
                cat(sprintf("  [WARNING] Report registration failed: %s\n", e$message))
                registry
              }
            )
          }
        } else {
          cat(sprintf("  [ERROR] Report output not found: %s\n", output_file))
          failed_reports <- c(failed_reports, report_name)
        }
      }
      
      # Summary
      if (length(failed_reports) > 0) {
        cat("\n[WARNING] Failed reports:\n")
        for (name in failed_reports) {
          cat(sprintf("  ✗ %s\n", name))
        }
      }

      list(success = length(rendered_reports) > 0, 
           rendered = rendered_reports,
           failed = failed_reports,
           registry = registry)
    }

    report_names <- c(
      "full_analysis_report",
      "plot_gallery",
      "data_quality_report"
    )

    cat("\n")
    cat("================================================================================\n")
    cat("RENDERING REPORTS\n")
    cat("================================================================================\n")
    cat(sprintf("Reports to render: %s\n", paste(report_names, collapse = ", ")))
    cat("\n")

    report_result <- render_reports(report_names, registry = registry)
    
    # Update result with report info
    result$rendered_reports <- report_result$rendered
    result$failed_reports <- report_result$failed
    result$registry <- report_result$registry
    
    # Optionally create release bundle
    if (create_bundle) {
      cat("\n")
      cat("================================================================================\n")
      cat("CREATING RELEASE BUNDLE\n")
      cat("================================================================================\n")
      
      source(here::here("R", "functions", "core", "coha_release.R"))
      
      bundle_path <- tryCatch(
        create_release_bundle(
          study_name = "COHA_Dispersal",
          include_raw_data = TRUE,
          include_plots = TRUE,
          include_reports = TRUE,
          include_config = TRUE,
          quiet = FALSE
        ),
        error = function(e) {
          cat(sprintf("[ERROR] Bundle creation failed: %s\n", e$message))
          NULL
        }
      )
      
      result$bundle_path <- bundle_path
    }

    invisible(result)
  },
  args = list(create_bundle = create_bundle),
  show = TRUE,
  spinner = TRUE
)

cat("\n")
cat("================================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("================================================================================\n")
cat(sprintf("Pipeline Status: %s\n", result$status))
cat(sprintf("Plots Generated: %d/%d\n", result$plots_generated, result$plots_total))
cat("\n")

# Report rendering summary
total_reports <- 3
successful_reports <- length(result$rendered_reports)
failed_reports_count <- length(result$failed_reports)

cat(sprintf("Reports Rendered: %d/%d\n", successful_reports, total_reports))

if (successful_reports > 0) {
  cat("  ✓ Successful:\n")
  for (report in result$rendered_reports) {
    cat(sprintf("    - %s\n", basename(report)))
  }
}

if (failed_reports_count > 0) {
  cat("  ✗ Failed:\n")
  for (report_name in result$failed_reports) {
    cat(sprintf("    - %s\n", report_name))
  }
}

if (successful_reports == 0) {
  cat("  [WARNING] No reports were rendered successfully\n")
}

cat("\n")
cat("Report directory: results/reports/\n")
if (!is.null(result$bundle_path)) {
  cat(sprintf("Release bundle: %s\n", basename(result$bundle_path)))
}
cat("================================================================================\n")
cat("\n")

# Print usage instructions if no args provided
if (length(args) == 0 && interactive()) {
  cat("TIP: Run with --bundle flag to create a release ZIP:\n")
  cat("     source('R/run_project.R'); # or Rscript R/run_project.R --bundle\n\n")
}
