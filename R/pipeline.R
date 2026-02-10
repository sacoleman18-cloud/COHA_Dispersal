# COHA Dispersal Analysis Pipeline
#
# This script orchestrates the generation of all ridgeline plots for the
# COHA dispersal analysis. It reads configurations from config.R and uses
# plot_function.R to generate and save all plots.
#
# Usage:
#   source("R/pipeline.R")
#   run_pipeline()
#
# Author: [Your name]
# Date: February 10, 2026

library(tidyverse)
library(ggridges)
library(ggplot2)

# Source dependencies
source("R/plot_function.R")
source("R/config.R")

#' Run the complete analysis pipeline
#'
#' Generates all ridgeline plots defined in config.R and saves them to
#' the results/png/ directory.
#'
#' @param data_path Character string path to data CSV (default: "data/data.csv")
#' @param output_dir Character string path to output directory (default: "results/png")
#' @param configs List of plot configurations (default: plot_configs from config.R)
#' @param save_plots Logical, whether to save plots to disk (default: TRUE)
#' @param verbose Logical, whether to print progress messages (default: TRUE)
#'
#' @return List of ggplot2 objects, invisibly
#'
#' @examples
#' # Run with defaults
#' plots <- run_pipeline()
#'
#' # Run without saving (for interactive exploration)
#' plots <- run_pipeline(save_plots = FALSE)
#'
run_pipeline <- function(data_path = "data/data.csv",
                         output_dir = "results/png",
                         configs = plot_configs,
                         save_plots = TRUE,
                         verbose = TRUE) {
  
  # Validate inputs
  if (!file.exists(data_path)) {
    stop("Data file not found: ", data_path)
  }
  
  if (save_plots && !dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    if (verbose) message("Created output directory: ", output_dir)
  }
  
  # Load data
  if (verbose) message("Loading data from: ", data_path)
  data <- read.csv(data_path)
  
  if (verbose) {
    message(sprintf("Data loaded: %d rows, %d columns", nrow(data), ncol(data)))
    message(sprintf("Generating %d plots...\n", length(configs)))
  }
  
  # Generate plots
  plots <- list()
  
  for (i in seq_along(configs)) {
    config <- configs[[i]]
    
    if (verbose) {
      message(sprintf("[%d/%d] Generating: %s", i, length(configs), config$name))
    }
    
    # Create plot
    p <- create_ridgeline_plot(
      data = data,
      scale_value = config$scale_value,
      line_height = config$line_height,
      fill_palette = config$fill_palette,
      color_palette = config$color_palette,
      palette_type = config$palette_type
    )
    
    # Add title if name is provided
    if (!is.null(config$name)) {
      p <- p + labs(title = config$name)
    }
    
    # Save plot
    if (save_plots) {
      output_path <- file.path(output_dir, paste0(config$id, ".png"))
      ggsave(
        filename = output_path,
        plot = p,
        width = 10,
        height = 7,
        dpi = 300
      )
      if (verbose) message("  Saved to: ", output_path)
    }
    
    # Store plot in list
    plots[[config$id]] <- p
  }
  
  if (verbose) {
    message("\n\u2714 Pipeline complete!")
    message(sprintf("Generated %d plots", length(plots)))
    if (save_plots) {
      message("Plots saved to: ", output_dir)
    }
  }
  
  invisible(plots)
}

#' Generate a single plot by ID
#'
#' Convenience function to generate one plot from the configuration
#'
#' @param plot_id Character string ID of the plot to generate
#' @param data_path Character string path to data CSV
#' @param configs List of plot configurations
#'
#' @return A ggplot2 object
#'
#' @examples
#' # Generate single plot
#' p <- generate_plot("compact_01")
#' print(p)
#'
generate_plot <- function(plot_id,
                          data_path = "data/data.csv",
                          configs = plot_configs) {
  
  # Find config
  config <- configs[sapply(configs, function(x) x$id == plot_id)]
  
  if (length(config) == 0) {
    stop("Plot ID not found: ", plot_id)
  }
  
  config <- config[[1]]
  
  # Load data
  data <- read.csv(data_path)
  
  # Create plot
  p <- create_ridgeline_plot(
    data = data,
    scale_value = config$scale_value,
    line_height = config$line_height,
    fill_palette = config$fill_palette,
    color_palette = config$color_palette,
    palette_type = config$palette_type
  )
  
  # Add title
  if (!is.null(config$name)) {
    p <- p + labs(title = config$name)
  }
  
  return(p)
}

#' List all available plot configurations
#'
#' @param configs List of plot configurations
#' @return Data frame with plot metadata
#'
list_plots <- function(configs = plot_configs) {
  do.call(rbind, lapply(configs, function(x) {
    data.frame(
      id = x$id,
      name = x$name,
      scale = x$scale_value,
      palette = x$fill_palette,
      stringsAsFactors = FALSE
    )
  }))
}
