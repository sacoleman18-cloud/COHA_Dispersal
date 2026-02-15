# ==============================================================================
# R/plot_modules/ridgeline/module.R
# ==============================================================================
# RIDGELINE PLOT MODULE - Plugin-based plot generator
#
# PURPOSE
# -------
# Implements the plot module interface for ridgeline plots.
# Discovered and loaded dynamically by engine.R plugin manager.
#
# INTERFACE CONTRACT
# ------------------
# ✓ get_module_metadata() - Module info
# ✓ get_available_plots() - Available plot IDs
# ✓ generate_plot() - Single plot generation
# ✓ generate_plots_batch() - Multiple plot generation
# ✓ (optional) module_init() - Initialization hook
# ✓ (optional) module_cleanup() - Cleanup hook
#
# USAGE
# -----
# # Direct sourcing
# source("R/plot_modules/ridgeline/module.R")
# metadata <- get_module_metadata()
# result <- generate_plot(data, "compact_01", config)
#
# # Via engine (recommended)
# source("R/core/engine.R")
# engine <- initialize_pipeline()
# load_module("ridgeline", "plot")
# result <- generate_plot(data, "compact_01", config)
#
# ==============================================================================

# Load required dependencies
require(ggplot2, quietly = TRUE) || stop("ggplot2 required")
require(ggridges, quietly = TRUE) || stop("ggridges required")
require(dplyr, quietly = TRUE) || stop("dplyr required")
require(here, quietly = TRUE) || stop("here required")

# Source helper modules
source(here::here("R", "core", "palettes.R"))  # Universal palette utilities
source(here::here("R", "plot_modules", "ridgeline", "ridgeline_generator.R"))

# ==============================================================================
# MODULE METADATA - Required by engine.R
# ==============================================================================

#' Get Module Metadata
#'
#' @description
#' Returns module identification and version information.
#' Required by engine.R discovery and validation system.
#'
#' @return List with fields:
#'   - name: Module name ("ridgeline")
#'   - type: Module type ("plot")
#'   - version: Semantic version
#'   - description: What the module does
#'   - author: Module creator
#'   - depends: Required packages
#'
#' @export
get_module_metadata <- function() {
  list(
    name = "ridgeline",
    type = "plot",
    version = "2.0.0",
    description = "Ridgeline plot generator with 28 scale/palette variants",
    author = "Project Team",
    depends = c("ggplot2", "ggridges", "dplyr", "viridis"),
    created_date = "2026-02-12",
    interface_version = "1.0",
    plots_available = 28
  )
}

# ==============================================================================
# INTERNAL PLOT CONFIGURATION - All 28 plot variants
# ==============================================================================

#' Get All Available Plot Variants (Internal)
#'
#' @keywords internal
#' @description
#' Returns the complete specification for all 28 plot variants.
#' This is the internal source of truth for ridgeline plot configurations.
#'
#' @return List of plot configurations, one per variant.
#'   Each config has: id, display_name, scale, line_height, fill, color,
#'   fill_colors (optional), color_colors (optional), palette_type, group
#'
#' @details
#' All 28 variants organized as:
#' - 14 COMPACT variants (scale=0.85):
#'   compact_01 to compact_10: viridis/brewer palettes (no custom colors)
#'   compact_11 to compact_14: custom hawk palettes (have fill_colors/color_colors)
#' - 14 EXPANDED variants (scale=2.25):
#'   expanded_01 to expanded_10: viridis/brewer palettes
#'   expanded_11 to expanded_14: custom hawk palettes
.get_plot_variants <- function() {
  list(
    # ========================================================================
    # COMPACT PLOTS (Scale 0.85 - tight vertical spacing)
    # ========================================================================
    
    list(id = "compact_01", display_name = "Compact + Plasma", scale = 0.85, 
         line_height = 0.85, fill = "plasma", color = "plasma", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_02", display_name = "Compact + Viridis", scale = 0.85, 
         line_height = 0.85, fill = "viridis", color = "viridis", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_03", display_name = "Compact + Magma", scale = 0.85, 
         line_height = 0.85, fill = "magma", color = "magma", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_04", display_name = "Compact + Inferno", scale = 0.85, 
         line_height = 0.85, fill = "inferno", color = "inferno", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_05", display_name = "Compact + Cividis", scale = 0.85, 
         line_height = 0.85, fill = "cividis", color = "cividis", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_06", display_name = "Compact + Rocket", scale = 0.85, 
         line_height = 0.85, fill = "rocket", color = "rocket", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_07", display_name = "Compact + Mako", scale = 0.85, 
         line_height = 0.85, fill = "mako", color = "mako", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_08", display_name = "Compact + Turbo", scale = 0.85, 
         line_height = 0.85, fill = "turbo", color = "turbo", 
         palette_type = "viridis", group = "compact"),
    
    list(id = "compact_09", display_name = "Compact + Set2", scale = 0.85, 
         line_height = 0.85, fill = "Set2", color = "Set2", 
         palette_type = "brewer", group = "compact"),
    
    list(id = "compact_10", display_name = "Compact + Dark2", scale = 0.85, 
         line_height = 0.85, fill = "Dark2", color = "Dark2", 
         palette_type = "brewer", group = "compact"),
    
    list(id = "compact_11", display_name = "Compact + HawkO Natural", scale = 0.85, 
         line_height = 0.85, fill = "hawkO_natural", color = "hawkO_natural",
         fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
         color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
         palette_type = "custom", group = "compact"),
    
    list(id = "compact_12", display_name = "Compact + HawkO Vivid", scale = 0.85, 
         line_height = 0.85, fill = "hawkO_vivid", color = "hawkO_vivid",
         fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
         color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
         palette_type = "custom", group = "compact"),
    
    list(id = "compact_13", display_name = "Compact + Hawk Natural", scale = 0.85, 
         line_height = 0.85, fill = "hawk_natural", color = "hawk_natural",
         fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
         color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
         palette_type = "custom", group = "compact"),
    
    list(id = "compact_14", display_name = "Compact + Hawk Vivid", scale = 0.85, 
         line_height = 0.85, fill = "hawk_vivid", color = "hawk_vivid",
         fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
         color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
         palette_type = "custom", group = "compact"),
    
    # ========================================================================
    # EXPANDED PLOTS (Scale 2.25 - loose vertical spacing)
    # ========================================================================
    
    list(id = "expanded_01", display_name = "Expanded + Plasma", scale = 2.25, 
         line_height = 1, fill = "plasma", color = "plasma", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_02", display_name = "Expanded + Viridis", scale = 2.25, 
         line_height = 1, fill = "viridis", color = "viridis", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_03", display_name = "Expanded + Magma", scale = 2.25, 
         line_height = 1, fill = "magma", color = "magma", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_04", display_name = "Expanded + Inferno", scale = 2.25, 
         line_height = 1, fill = "inferno", color = "inferno", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_05", display_name = "Expanded + Cividis", scale = 2.25, 
         line_height = 1, fill = "cividis", color = "cividis", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_06", display_name = "Expanded + Rocket", scale = 2.25, 
         line_height = 1, fill = "rocket", color = "rocket", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_07", display_name = "Expanded + Mako", scale = 2.25, 
         line_height = 1, fill = "mako", color = "mako", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_08", display_name = "Expanded + Turbo", scale = 2.25, 
         line_height = 1, fill = "turbo", color = "turbo", 
         palette_type = "viridis", group = "expanded"),
    
    list(id = "expanded_09", display_name = "Expanded + Set2", scale = 2.25, 
         line_height = 1, fill = "Set2", color = "Set2", 
         palette_type = "brewer", group = "expanded"),
    
    list(id = "expanded_10", display_name = "Expanded + Dark2", scale = 2.25, 
         line_height = 1, fill = "Dark2", color = "Dark2", 
         palette_type = "brewer", group = "expanded"),
    
    list(id = "expanded_11", display_name = "Expanded + HawkO Natural", scale = 2.25, 
         line_height = 1, fill = "hawkO_natural", color = "hawkO_natural",
         fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
         color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
         palette_type = "custom", group = "expanded"),
    
    list(id = "expanded_12", display_name = "Expanded + HawkO Vivid", scale = 2.25, 
         line_height = 1, fill = "hawkO_vivid", color = "hawkO_vivid",
         fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
         color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
         palette_type = "custom", group = "expanded"),
    
    list(id = "expanded_13", display_name = "Expanded + Hawk Natural", scale = 2.25, 
         line_height = 1, fill = "hawk_natural", color = "hawk_natural",
         fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
         color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
         palette_type = "custom", group = "expanded"),
    
    list(id = "expanded_14", display_name = "Expanded + Hawk Vivid", scale = 2.25, 
         line_height = 1, fill = "hawk_vivid", color = "hawk_vivid",
         fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
         color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
         palette_type = "custom", group = "expanded")
  )
}

# ==============================================================================
# PLOT INVENTORY - What plots this module provides
# ==============================================================================

#' Get Available Plot Types
#'
#' @description
#' Returns data frame of all plots this module can generate.
#' All 28 plots defined internally in .get_plot_variants().
#' Used by plot registry and discovery systems.
#'
#' @return Data frame with columns:
#'   - plot_id: Unique identifier (e.g., "compact_01")
#'   - display_name: Human-readable name
#'   - group: Grouping category ("compact", "expanded")
#'   - scale: Line spacing scale factor (0.85, 2.25)
#'   - palette: Primary palette name
#'   - active: Whether plot is enabled
#'   - description: What the plot shows
#'
#' @export
get_available_plots <- function() {
  # Get all internal variants
  variants <- .get_plot_variants()
  
  # Convert to data frame
  df <- data.frame(
    plot_id = sapply(variants, function(x) x$id),
    display_name = sapply(variants, function(x) x$display_name),
    group = sapply(variants, function(x) x$group),
    scale = sapply(variants, function(x) x$scale),
    palette = sapply(variants, function(x) x$fill),
    active = rep(TRUE, length(variants)),
    description = "Density distributions across 6-year generational periods",
    stringsAsFactors = FALSE
  )
  
  return(df)
}

# ==============================================================================
# PLOT GENERATION - Core functionality
# ==============================================================================

#' Generate Single Ridgeline Plot
#'
#' @description
#' Generates a single ridgeline plot with specified configuration.
#' Returns structured result with status, plot object, and metadata.
#'
#' @param data Data frame. Dispersal data with required columns
#'   (mass, year, dispersed, generation, etc.)
#' @param plot_id Character. Plot identifier from get_available_plots()
#'   Examples: "compact_01", "regular_02", "expanded_03"
#' @param config List. Execution configuration with:
#'   - output_dir: Where to save PNG
#'   - dpi: PNG resolution (default 300)
#'   - width: PNG width in inches (default 10)
#'   - height: PNG height in inches (default 6)
#'   - save_file: Whether to save PNG (default TRUE)
#'   - verbose: Print progress (default FALSE)
#'
#' @return List. Result object with fields:
#'   - status: "success", "partial", or "failed"
#'   - message: Human-readable status
#'   - plot_id: The plot that was generated
#'   - plot: ggplot object (if status != "failed")
#'   - output_path: Where PNG was saved (if saved)
#'   - file_size_mb: Size of PNG (if saved)
#'   - generation_time: Seconds to generate
#'   - quality_score: 0-100 rating
#'   - errors: List of errors
#'   - warnings: List of warnings
#'   - timestamp: When generated
#'   - data_n: Number of rows processed
#'
#' @details
#' **Error Handling:**
#' - If data missing/invalid: returns status="failed"
#' - If plot generation fails: returns status="failed"
#' - If PNG save fails: returns plot object anyway (status="partial")
#' - Never stops execution; caller decides what to do
#'
#' **Plot Selection:**
#' The plot_id determines scale and palette:
#' - "compact_*": scale=0.85 (tight vertical spacing)
#' - "regular_*": scale=1.0 (standard spacing)
#' - "expanded_*": scale=1.2 (loose spacing)
#' - "*_01": plasma palette
#' - "*_02": viridis palette
#' - "*_03": magma palette
#'
#' @examples
#' \dontrun{
#' # Load data
#' data <- read.csv("data/hawk_dispersal.csv")
#'
#' # Generate a plot
#' result <- generate_plot(
#'   data = data,
#'   plot_id = "compact_01",
#'   config = list(
#'     output_dir = "results/plots",
#'     verbose = TRUE
#'   )
#' )
#'
#' # Check result
#' if (result$status == "success") {
#'   cat("Plot saved:", result$output_path, "\n")
#' } else {
#'   cat("Error:", result$message, "\n")
#' }
#' }
#'
#' @export
generate_plot <- function(data,
                          plot_id,
                          config = list()) {
  
  # Start timer
  start_time <- Sys.time()
  
  # Initialize result
  result <- list(
    status = "failed",
    message = "",
    plot_id = plot_id,
    plot = NULL,
    output_path = NULL,
    file_size_mb = 0,
    generation_time = 0,
    quality_score = 0,
    errors = list(),
    warnings = list(),
    timestamp = Sys.time(),
    data_n = 0
  )
  
  # Default config
  config <- modifyList(
    list(
      output_dir = tempdir(),
      dpi = 300,
      width = 10,
      height = 6,
      save_file = TRUE,
      verbose = FALSE
    ),
    config
  )
  
  # ============================================================================
  # VALIDATION
  # ============================================================================
  
  # Check data
  if (!is.data.frame(data)) {
    result$errors[[length(result$errors) + 1]] <- "data must be data.frame"
    result$message <- "Invalid data type"
    return(result)
  }
  
  if (nrow(data) == 0) {
    result$errors[[length(result$errors) + 1]] <- "data is empty"
    result$message <- "No data to plot"
    return(result)
  }
  
  # Check plot_id
  available <- get_available_plots()
  if (!plot_id %in% available$plot_id) {
    result$errors[[length(result$errors) + 1]] <- 
      sprintf("plot_id '%s' not found", plot_id)
    result$message <- "Invalid plot ID"
    return(result)
  }
  
  # Parse plot_id
  config_from_id <- .parse_plot_id(plot_id)
  if (is.null(config_from_id)) {
    result$errors[[length(result$errors) + 1]] <- 
      sprintf("Cannot parse plot_id '%s'", plot_id)
    result$message <- "Invalid plot ID format"
    return(result)
  }
  
  # Update config from plot_id (includes custom colors if specified)
  config$scale <- config_from_id$scale
  config$palette <- config_from_id$palette
  config$color_palette <- config_from_id$color_palette %||% config_from_id$palette
  config$fill_colors <- config_from_id$fill_colors
  config$color_colors <- config_from_id$color_colors
  config$palette_type <- config_from_id$palette_type %||% "viridis"
  
  result$data_n <- nrow(data)
  
  if (config$verbose) {
    cat(sprintf("[%s] Generating plot: %s\n", 
                Sys.time(), plot_id))
  }
  
  # ============================================================================
  # PLOT GENERATION
  # ============================================================================
  
  tryCatch({
    # Generate the plot with full configuration
    plot_obj <- .generate_ridgeline_plot(
      data = data,
      scale = config$scale,
      palette = config$palette,
      color_palette = config$color_palette,
      fill_colors = config$fill_colors,
      color_colors = config$color_colors,
      palette_type = config$palette_type,
      title = sprintf("Ridgeline: %s (%s scale, %s palette)",
                      plot_id, config$scale, config$palette),
      verbose = config$verbose
    )
    
    result$plot <- plot_obj
    result$status <- "partial"  # Plot generated, but not saved yet
    result$message <- "Plot generated successfully"
    
  }, error = function(e) {
    result$errors[[length(result$errors) + 1]] <<- 
      sprintf("Plot generation failed: %s", e$message)
    result$message <<- "Plot generation failed"
    return(NULL)
  })
  
  # If plot generation failed, return early
  if (is.null(result$plot)) {
    result$status <- "failed"
    result$generation_time <- as.numeric(Sys.time() - start_time)
    return(result)
  }
  
  # ============================================================================
  # FILE SAVING (optional)
  # ============================================================================
  
  if (config$save_file && config$output_dir != tempdir()) {
    tryCatch({
      # Ensure output directory exists
      dir.create(config$output_dir, showWarnings = FALSE, recursive = TRUE)
      
      # Generate output filename
      filename <- sprintf("%s_plot_%s.png", 
                         format(Sys.Date(), "%Y%m%d"),
                         plot_id)
      output_path <- file.path(config$output_dir, filename)
      
      # Save PNG
      ggplot2::ggsave(
        filename = output_path,
        plot = result$plot,
        dpi = config$dpi,
        width = config$width,
        height = config$height,
        units = "in"
      )
      
      # Check if file was saved
      if (file.exists(output_path)) {
        file_info <- file.info(output_path)
        result$output_path <- output_path
        result$file_size_mb <- file_info$size / (1024^2)
        result$status <- "success"
        result$message <- "Plot generated and saved"
        
        if (config$verbose) {
          cat(sprintf("[%s] Saved: %s (%.2f MB)\n", 
                      Sys.time(), output_path, result$file_size_mb))
        }
      } else {
        result$warnings[[length(result$warnings) + 1]] <- 
          "PNG file not created despite no error"
      }
      
    }, error = function(e) {
      result$warnings[[length(result$warnings) + 1]] <<- 
        sprintf("Failed to save PNG: %s", e$message)
      result$message <<- "Plot generated but save failed"
      # status stays "partial" - plot object is still valid
    })
  } else if (!config$save_file) {
    result$status <- "success"
    result$message <- "Plot generated (not saved)"
  }
  
  # ============================================================================
  # QUALITY SCORING
  # ============================================================================
  
  result$generation_time <- as.numeric(Sys.time() - start_time)
  result$quality_score <- .calculate_quality_score(result)
  
  return(result)
}

#' Generate Multiple Ridgeline Plots
#'
#' @description
#' Generates multiple ridgeline plots in batch.
#' Continues on error; returns results for all plots.
#'
#' @param data Data frame. Dispersal data.
#' @param plot_ids Character vector. Plot IDs to generate.
#'   If NULL, generates all available plots.
#' @param config List. Config passed to generate_plot().
#' @param continue_on_error Logical. Continue if a plot fails. Default: TRUE.
#'
#' @return List of result objects (one per plot).
#'
#' @export
generate_plots_batch <- function(data,
                                 plot_ids = NULL,
                                 config = list(),
                                 continue_on_error = TRUE) {
  
  # Default to all available plots
  if (is.null(plot_ids)) {
    available <- get_available_plots()
    plot_ids <- available$plot_id
  }
  
  # Generate each plot
  results <- list()
  for (plot_id in plot_ids) {
    tryCatch({
      result <- generate_plot(data, plot_id, config)
      results[[plot_id]] <- result
    }, error = function(e) {
      if (!continue_on_error) {
        stop(e)
      }
      # Create error result
      results[[plot_id]] <<- list(
        status = "failed",
        message = sprintf("Batch error: %s", e$message),
        plot_id = plot_id,
        errors = list(e$message)
      )
    })
  }
  
  return(results)
}

# ==============================================================================
# LIFECYCLE HOOKS (optional but recommended)
# ==============================================================================

#' Initialize Module
#'
#' @description
#' Called when module is loaded by engine.R.
#' Sets up any module-level state.
#'
#' @param config List. Configuration passed by engine.
#'
#' @return List with module state information.
#'
#' @export
module_init <- function(config = list()) {
  list(
    initialized = TRUE,
    timestamp = Sys.time(),
    state = list(
      plots_generated = 0,
      total_errors = 0,
      total_warnings = 0
    )
  )
}

#' Clean Up Module
#'
#' @description
#' Called when module is shutting down.
#' Closes connections, frees resources, etc.
#'
#' @return NULL (invisibly)
#'
#' @export
module_cleanup <- function() {
  # Clean up any module-level resources
  invisible(NULL)
}

# ==============================================================================
# INTERNAL HELPERS
# ==============================================================================

#' Parse Plot ID to Extract Configuration
#'
#' @keywords internal
#' @description
#' Looks up plot configuration from internal variants (.get_plot_variants()).
#' No external dependencies or globalenv() scope issues.
.parse_plot_id <- function(plot_id) {
  # Get all internal variants
  variants <- .get_plot_variants()
  
  # Search for matching plot ID
  for (config in variants) {
    if (config$id == plot_id) {
      # Extract configuration
      fill_palette <- config$fill %||% "viridis"
      color_palette <- config$color %||% fill_palette
      
      return(list(
        scale = config$scale,
        palette = fill_palette,
        color_palette = color_palette,
        fill_colors = config$fill_colors %||% NULL,
        color_colors = config$color_colors %||% NULL,
        palette_type = config$palette_type %||% "viridis",
        group = config$group,
        line_height = config$line_height %||% 1
      ))
    }
  }
  
  # Not found
  return(NULL)
}

#' Calculate Quality Score for Plot
#'
#' @keywords internal
.calculate_quality_score <- function(result) {
  score <- 100
  
  # Deduct for errors
  score <- score - (10 * length(result$errors))
  
  # Deduct for warnings
  score <- score - (5 * length(result$warnings))
  
  # Deduct if not saved
  if (result$status == "partial") {
    score <- score - 20
  }
  
  # Deduct if failed
  if (result$status == "failed") {
    score <- 0
  }
  
  max(0, min(100, score))
}

# ==============================================================================
# MODULE INITIALIZATION
# ==============================================================================

# Module metadata (used by engine for validation)
.MODULE_METADATA <- get_module_metadata()

# Export all public functions
invisible(NULL)
