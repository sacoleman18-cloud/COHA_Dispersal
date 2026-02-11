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

# Execute pipeline and reports in separate R process (non-blocking)
cat("[INFO] Running pipeline and reports in separate process...\n")
cat("[INFO] This may take several minutes. RStudio console remains responsive.\n\n")

result <- callr::r(
  func = function() {
    library(here)
    setwd(here::here())

    source(here::here("R", "pipeline", "pipeline.R"))

    result <- run_pipeline(verbose = TRUE)

    render_reports <- function(report_names, output_dir = "results/reports") {
      quarto_bin <- Sys.which("quarto")
      if (!nzchar(quarto_bin)) {
        warning("Quarto CLI not found. Install from https://quarto.org/ to render reports.")
        return(invisible(FALSE))
      }

      # Use absolute paths to avoid Quarto changing working directory
      output_dir_abs <- here::here(output_dir)
      dir.create(output_dir_abs, recursive = TRUE, showWarnings = FALSE)

      for (report_name in report_names) {
        qmd_file_abs <- here::here("reports", paste0(report_name, ".qmd"))
        
        if (!file.exists(qmd_file_abs)) {
          warning(sprintf("Report not found: %s", qmd_file_abs))
          next
        }

        cat(sprintf("[REPORT] Rendering %s\n", report_name))
        cat(sprintf("  Input: %s\n", qmd_file_abs))
        cat(sprintf("  Output: %s\n", output_dir_abs))
        # Pass absolute paths to Quarto
        system2(quarto_bin, c("render", shQuote(qmd_file_abs), "--output-dir", shQuote(output_dir_abs)))
      }

      invisible(TRUE)
    }

    report_names <- c(
      "full_analysis_report",
      "plot_gallery",
      "data_quality_report"
    )

    render_reports(report_names)

    invisible(result)
  },
  show = TRUE,
  spinner = TRUE
)

cat("\n")
cat("================================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("Reports available in: results/reports/\n")
cat("================================================================================\n")
cat("\n")
