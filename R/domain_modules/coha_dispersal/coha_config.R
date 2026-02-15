# ==============================================================================
# R/domain_modules/coha_dispersal/coha_config.R
# ==============================================================================
# PURPOSE
# -------
# COHA domain-specific configuration and metadata.
# Defines domain constants, data specifications, and plot configurations
# specific to Cooper's Hawk natal dispersal analysis.
#
# ARCHITECTURE
# -----------
# This file provides domain layer configuration separate from universal core.
# Uses YAML or list-based config for portability and readability.
#
# DEPENDS ON
# ----------
# - here (path management)
# - yaml (config parsing)
#
# ==============================================================================

library(here)
library(yaml)

# ==============================================================================
# DOMAIN METADATA
# ==============================================================================

coha_domain_config <- list(
  
  # ============================================================================
  # DOMAIN IDENTITY
  # ============================================================================
  domain = list(
    name = "COHA Dispersal",
    full_name = "Cooper's Hawk (Accipiter cooperii) Natal Dispersal Analysis",
    abbreviation = "COHA",
    version = "2.0",
    description = "Publication-ready analyses of natal dispersal patterns"
  ),
  
  # ============================================================================
  # DATA SPECIFICATIONS
  # ============================================================================
  data = list(
    # Source data location
    source_file = "data/data.csv",
    source_format = "CSV",
    
    # Complete column specifications
    columns = list(
      mass = list(
        description = "Body mass in grams",
        type = "numeric",
        required = TRUE,
        units = "grams",
        valid_range = c(min = 100, max = 700)  # Realistic bounds for COHA
      ),
      year = list(
        description = "Study year or generational period",
        type = "numeric",
        required = TRUE,
        units = "years",
        valid_range = c(min = 1900, max = 2100)
      ),
      dispersed = list(
        description = "Dispersal status (Y/N or Yes/No)",
        type = "character",
        required = TRUE,
        valid_values = c("Y", "N", "Yes", "No", "Unknown")  # Updated to match actual data
      )
    ),
    
    # Data quality thresholds
    quality = list(
      min_rows = 10,
      max_missing_percent = 20,  # Allow up to 20% missing non-required columns
      require_complete_required = TRUE  # All required columns must be complete
    )
  ),
  
  # ============================================================================
  # PLOT CONFIGURATIONS
  # ============================================================================
  plot_modules = list(
    ridgeline = list(
      enabled = TRUE,
      name = "Ridgeline Density Plots",
      description = "Kernel density distributions of mass across 6-year periods",
      module_path = "R/plot_modules/ridgeline",
      
      # Ridgeline-specific parameters
      parameters = list(
        x_var = "mass",
        group_var = "year",
        stat = "density",
        fill_by_palette = TRUE,
        scale_options = c("compact", "regular", "expanded"),
        palette_options = c("plasma", "viridis", "magma", "inferno", "cividis")
      ),
      
      # Output defaults
      output_defaults = list(
        dpi = 300,
        width_inches = 8,
        height_inches = 5,
        format = "png"
      ),
      
      # Report template
      report_template = "inst/reports/ridgeline_comprehensive.qmd"
    ),
    
    boxplot = list(
      enabled = FALSE,
      name = "Box & Whisker Plots with Jitter",
      description = "Distribution of mass with individual observations",
      module_path = "R/plot_modules/boxplot",
      
      parameters = list(
        x_var = "year",
        y_var = "mass",
        fill_var = "dispersed",
        show_points = TRUE,
        jitter_width = 0.2
      ),
      
      output_defaults = list(
        dpi = 300,
        width_inches = 8,
        height_inches = 5,
        format = "png"
      ),
      
      report_template = "inst/reports/boxplot_comprehensive.qmd"
    )
  ),
  
  # ============================================================================
  # FILE PATHS (relative to project root)
  # ============================================================================
  paths = list(
    # Data
    data_source = "data/data.csv",
    data_processed = "data/processed",
    
    # Configuration
    config_dir = "inst/config",
    domain_config = "R/domain_modules/coha_dispersal",
    
    # Output
    plots_base = "results/plots",
    reports_base = "results/reports",
    cache_dir = "results/cache",
    rds_dir = "results/rds",
    
    # Logs
    logs_dir = "logs",
    domain_logs = "logs/domain"
  ),
  
  # ============================================================================
  # REPORTS
  # Domain-specific report templates and configurations
  # Reports are stored in R/domain_modules/coha_dispersal/reports/
  # ============================================================================
  reports = list(
    list(
      name = "Full Analysis Report",
      id = "full_analysis",
      template = "R/domain_modules/coha_dispersal/reports/full_analysis_report.qmd",
      format = "html",
      enabled = TRUE,
      description = "Complete analysis including data summary, plots, and results"
    ),
    list(
      name = "Data Quality Report",
      id = "data_quality",
      template = "R/domain_modules/coha_dispersal/reports/data_quality_report.qmd",
      format = "html",
      enabled = TRUE,
      description = "Assessment of data quality, completeness, and validity"
    ),
    list(
      name = "Plot Gallery",
      id = "plot_gallery",
      template = "R/domain_modules/coha_dispersal/reports/plot_gallery.qmd",
      format = "html",
      enabled = TRUE,
      description = "Visual summary of all generated plots by module"
    )
  ),
  
  # ============================================================================
  # ANALYSIS PARAMETERS
  # ============================================================================
  analysis = list(
    # Bins for ridgeline plots
    density_bins = 30,
    
    # Statistical methods
    stat_method = "kernel",  # kernel, histogram, etc.
    bandwidth = "scott",     # Bandwidth selection method
    
    # Filtering/subsetting
    filters = list(
      # Example: only include dispersed birds
      # dispersed_only = TRUE,
      # min_mass = 250,
      # max_mass = 550
    )
  ),
  
  # ============================================================================
  # PUBLICATION SPECIFICATIONS
  # ============================================================================
  publication = list(
    journal = "The Auk: Ornithological Advances",
    figure_style = "publication-ready",
    color_blind_safe = TRUE,
    palette_preference = "viridis"
  )
)

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

#' Get COHA Configuration
#'
#' @param section Character. Section of config to retrieve
#'   (e.g., "domain", "data", "plot_modules", NULL for all)
#'
#' @return List with requested configuration section
#'
#' @export
get_coha_config <- function(section = NULL) {
  if (is.null(section)) {
    return(coha_domain_config)
  }
  
  if (!section %in% names(coha_domain_config)) {
    stop(sprintf("Unknown config section: %s", section), call. = FALSE)
  }
  
  coha_domain_config[[section]]
}

#' Get COHA Data Path
#'
#' @param path_type Character. Which path to return
#'   (e.g., "data_source", "plots_base", "reports_base")
#'
#' @return Character path (absolute, using here::here())
#'
#' @export
get_coha_path <- function(path_type) {
  paths <- coha_domain_config$paths
  
  if (!path_type %in% names(paths)) {
    stop(sprintf("Unknown path type: %s", path_type), call. = FALSE)
  }
  
  here::here(paths[[path_type]])
}

#' List COHA Plot Modules
#'
#' @param enabled_only Logical. Return only enabled modules?
#'   Default: FALSE
#'
#' @return Character vector of module names
#'
#' @export
list_coha_plot_modules <- function(enabled_only = FALSE) {
  modules <- names(coha_domain_config$plot_modules)
  
  if (enabled_only) {
    modules <- modules[sapply(
      coha_domain_config$plot_modules,
      function(x) isTRUE(x$enabled)
    )]
  }
  
  modules
}

#' Get COHA Column Specifications
#'
#' @param column Character. Column name (NULL for all)
#'
#' @return List with column specifications
#'
#' @export
get_coha_column_spec <- function(column = NULL) {
  cols <- coha_domain_config$data$columns
  
  if (is.null(column)) {
    # Return all 3 columns: mass, year, dispersed
    return(cols)
  }
  
  if (!column %in% names(cols)) {
    stop(sprintf("Unknown column: %s (available: %s)", column, 
                 paste(names(cols), collapse = ", ")), call. = FALSE)
  }
  
  cols[[column]]
}

#' Get COHA Report Information
#'
#' @param report_id Character. Report ID (NULL for all)
#'   (e.g., "data_quality", "full_analysis", "plot_gallery")
#'
#' @return List with report information (template path, format, enabled status)
#'
#' @export
get_coha_report <- function(report_id = NULL) {
  reports <- coha_domain_config$reports
  
  if (is.null(report_id)) {
    return(reports)
  }
  
  # Search by ID field
  for (rep in reports) {
    if (isTRUE(rep$id == report_id)) {
      return(rep)
    }
  }
  
  stop(sprintf("Unknown report: %s", report_id), call. = FALSE)
}

#' Get COHA Reports Base Directory
#'
#' @return Character path to domain-specific reports directory (absolute)
#'
#' @export
get_coha_reports_dir <- function() {
  here::here("R", "domain_modules", "coha_dispersal", "reports")
}

# ==============================================================================
# EOF
# ==============================================================================
