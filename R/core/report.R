# ==============================================================================
# R/functions/output/report.R
# ==============================================================================
# PURPOSE
# -------
# Quarto report generation for COHA dispersal analysis.
# Renders .qmd templates with pre-computed summaries and plot objects.
# Adapted from KPro Reference_code for COHA use.
#
# DEPENDS ON
# ----------
# R Packages:
#   - quarto: Report rendering
#   - yaml: Parameter handling
#   - here: Path management
#
# Internal Dependencies:
#   - R/functions/core/artifacts.R (for RDS validation)
#
# FUNCTIONS PROVIDED
# ------------------
# - generate_quarto_report(): Render .qmd template to HTML
#
# CHANGELOG
# ---------
# 2026-02-11: Phase 0b - Adapted from KPro Reference_code
#             - Changed output filename prefix to COHA-specific
#             - Simplified validation for COHA structure
#             - Kept execute_dir pattern (critical for load_all.R sourcing)
# ==============================================================================

library(here)

# Check for quarto package
if (!requireNamespace("quarto", quietly = TRUE)) {
  stop("Package 'quarto' is required for report generation.\n",
       "  Install with: install.packages('quarto')\n",
       "  Also requires Quarto CLI: https://quarto.org/docs/get-started/")
}

library(quarto)

#' Generate Quarto Report
#'
#' @description
#' Renders the Quarto report template with pre-computed summary and plot
#' objects. This function is read-only with respect to analytical results—
#' no computation or transformation occurs.
#'
#' @param all_summaries List. Summary data (or RDS path)
#' @param all_plots List. Plot objects (or RDS path)
#' @param study_params_path Character. Path to study_parameters.yaml
#' @param template_path Character. Path to .qmd template
#' @param output_dir Character. Directory for rendered output
#' @param output_prefix Character. Filename prefix for generated report.
#'   Default: "coha_dispersal_report".
#'   The final filename will be: {output_prefix}_{YYYYMMDD}.html
#' @param quiet Logical. Suppress rendering messages if TRUE
#'
#' @return Character. Path to rendered HTML report
#'
#' @section CONTRACT:
#' - Does not compute any statistics
#' - Does not generate any new plots
#' - Uses only pre-computed objects
#' - Produces self-contained HTML file
#'
#' @section IMPORTANT IMPLEMENTATION NOTE:
#' This function sets `execute_dir = here::here()` when calling quarto_render().
#' This is CRITICAL because:
#' 1. The .qmd template may source custom functions via load_all.R in setup chunk
#' 2. Plot objects contain lazy evaluation of custom functions
#' 3. Without setting execute_dir, Quarto may execute from a different working directory
#' 4. This causes "function not found" errors when plots are rendered
#'
#' @examples
#' \dontrun{
#' # With objects
#' report_path <- generate_quarto_report(
#'   all_summaries = summary_list,
#'   all_plots = plot_list,
#'   template_path = "reports/full_analysis_report.qmd"
#' )
#'
#' # With RDS paths
#' report_path <- generate_quarto_report(
#'   all_summaries = "results/rds/summary_20260211.rds",
#'   all_plots = "results/rds/plots_20260211.rds"
#' )
#' }
#'
#' @export
generate_quarto_report <- function(all_summaries,
                                   all_plots,
                                   study_params_path = here::here("inst", "config", "study_parameters.yaml"),
                                   template_path = here::here("reports", "full_analysis_report.qmd"),
                                   output_dir = here::here("results", "reports"),
                                   output_prefix = "coha_dispersal_report",
                                   quiet = FALSE) {
  
  # -------------------------
  # Resolve RDS paths if strings provided
  # -------------------------
  
  if (is.character(all_summaries)) {
    if (!file.exists(all_summaries)) {
      stop(sprintf("Summary RDS not found: %s", all_summaries))
    }
    summary_rds_path <- all_summaries
    all_summaries <- readRDS(all_summaries)
  } else {
    # Save to temp RDS for Quarto params
    summary_rds_path <- tempfile(fileext = ".rds")
    saveRDS(all_summaries, summary_rds_path)
  }
  
  if (is.character(all_plots)) {
    if (!file.exists(all_plots)) {
      stop(sprintf("Plots RDS not found: %s", all_plots))
    }
    plots_rds_path <- all_plots
    all_plots <- readRDS(all_plots)
  } else {
    # Save to temp RDS for Quarto params
    plots_rds_path <- tempfile(fileext = ".rds")
    saveRDS(all_plots, plots_rds_path)
  }
  
  # -------------------------
  # Validate inputs
  # -------------------------
  
  if (!file.exists(template_path)) {
    stop(sprintf("Quarto template not found: %s", template_path))
  }
  
  # Flexible validation for COHA structure
  if (!is.null(all_summaries) && !is.list(all_summaries)) {
    warning("all_summaries should be a list")
  }
  
  if (!is.null(all_plots) && !is.list(all_plots)) {
    warning("all_plots should be a list")
  }
  
  # -------------------------
  # Setup output
  # -------------------------
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  timestamp <- format(Sys.Date(), "%Y%m%d")
  output_file <- sprintf("%s_%s.html", output_prefix, timestamp)
  
  if (!quiet) {
    message("Rendering Quarto report...")
    message(sprintf("  Template: %s", basename(template_path)))
    message(sprintf("  Output: %s", output_file))
  }
  
  # -------------------------
  # Render
  # -------------------------
  
  render_start <- Sys.time()
  
  # CRITICAL: Set execute_dir to project root so that load_all.R can be found
  # when the Quarto document sources custom functions in its setup chunk.
  # Without this, Quarto's working directory may not be the project root,
  # causing "function not found" errors when rendering plots.
  quarto::quarto_render(
    input = template_path,
    output_file = output_file,
    output_format = "html",
    execute_dir = here::here(),  # Execute from project root
    execute_params = list(
      summary_rds = summary_rds_path,
      plots_rds = plots_rds_path,
      study_params_path = study_params_path
    ),
    quiet = quiet
  )
  
  render_end <- Sys.time()
  render_time <- round(difftime(render_end, render_start, units = "secs"), 1)
  
  # -------------------------
  # Move to output directory
  # -------------------------
  
  rendered_path <- file.path(dirname(template_path), output_file)
  final_path <- file.path(output_dir, output_file)
  
  if (file.exists(rendered_path) && rendered_path != final_path) {
    file.rename(rendered_path, final_path)
  }
  
  # Verify output
  if (!file.exists(final_path)) {
    stop("Report generation failed - output file not found.")
  }
  
  file_size <- round(file.info(final_path)$size / 1024, 1)
  
  if (!quiet) {
    message(sprintf("✓ Report generated: %s (%.1f KB, %.1fs)",
                    basename(final_path), file_size, render_time))
  }
  
  final_path
}

# ==============================================================================
# END OF FILE
# ==============================================================================
