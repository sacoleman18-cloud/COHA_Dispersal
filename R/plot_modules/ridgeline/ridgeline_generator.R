# ==============================================================================
# R/plot_modules/ridgeline/ridgeline_generator.R
# ==============================================================================
# Core ridgeline plot generation logic
#
# Required by: module.R
# Depends on: R/core/palettes.R, ggplot2, ggridges, dplyr
#
# ==============================================================================

#' Generate Ridgeline Plot Object
#'
#' @keywords internal
#' @description
#' Creates ggplot ridgeline object (does not save to disk).
#' Used by module.R's generate_plot().
#'
#' @param data Data frame with columns: mass, year, dispersed (and optionally generation)
#' @param scale Numeric. Line height scale (0.85, 1.0, 1.2, 2.25, etc.)
#' @param palette Character. Color palette ("plasma", "viridis", "magma", "hawk_natural", etc.)
#' @param color_palette Character. Color palette for outlines (optional, defaults to palette)
#' @param fill_colors Character vector. Custom fill colors (overrides palette if provided)
#' @param color_colors Character vector. Custom color/outline colors (overrides palette if provided)
#' @param palette_type Character. "viridis", "brewer", or "custom"
#' @param title Character. Plot title
#' @param verbose Logical. Print status messages
#'
#' @return ggplot object
#'
.generate_ridgeline_plot <- function(data,
                                      scale = 1.0,
                                      palette = "viridis",
                                      color_palette = NULL,
                                      fill_colors = NULL,
                                      color_colors = NULL,
                                      palette_type = "viridis",
                                      title = "Ridgeline Plot",
                                      verbose = FALSE) {
  
  if (verbose) {
    cat(sprintf("[ridgeline] Creating plot with scale=%.2f, palette=%s, type=%s\n",
                scale, palette, palette_type))
  }
  
  # If generation doesn't exist, create from year in 6-year bins
  if (!("generation" %in% names(data))) {
    if ("year" %in% names(data)) {
      # Bin years into 6-year periods
      data$generation <- sprintf("%d-%d", 
                                 floor(data$year / 6) * 6,
                                 floor(data$year / 6) * 6 + 5)
      if (verbose) {
        cat("[ridgeline] Created generation column from year (6-year bins)\n")
      }
    } else {
      stop("Data must have either 'generation' or 'year' column")
    }
  }
  
  # Validate data only needs generation now (since we created it)
  required_cols <- c("generation")
  missing <- setdiff(required_cols, names(data))
  if (length(missing) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing, collapse=", ")))
  }
  
  # Ensure generation is factor or character for grouping
  if (!is.factor(data$generation) && !is.character(data$generation)) {
    data$generation <- as.character(data$generation)
  }
  
  # Handle missing values
  data_clean <- data %>%
    dplyr::filter(!is.na(generation))
  
  if (nrow(data_clean) == 0) {
    stop("No valid data after removing NAs")
  }
  
  if (verbose) {
    cat(sprintf("[ridgeline] Using %d rows (%d generations)\n",
                nrow(data_clean), n_distinct(data_clean$generation)))
  }
  
  # Determine if we have mass column
  has_mass <- "mass" %in% names(data_clean)
  
  if (has_mass) {
    # Filter mass data (reasonable range)
    data_plot <- data_clean %>%
      dplyr::filter(!is.na(mass), mass > 0, mass < 10000)
  } else {
    data_plot <- data_clean
  }
  
  if (nrow(data_plot) == 0) {
    stop("No valid data for plotting")
  }
  
  n_gens <- n_distinct(data_plot$generation)
  
  # Get color palette - support custom colors
  if (!is.null(fill_colors) && length(fill_colors) > 0) {
    # Use custom fill colors
    palette_colors_fill <- fill_colors
    if (verbose) {
      cat(sprintf("[ridgeline] Using custom fill colors (%d colors)\n", length(fill_colors)))
    }
  } else {
    # Get from core palette utilities
    palette_colors_fill <- get_palette_colors(palette, n_gens)
  }
  
  # Get outline colors
  if (!is.null(color_colors) && length(color_colors) > 0) {
    palette_colors_outline <- color_colors
  } else if (!is.null(color_palette) && color_palette != palette) {
    palette_colors_outline <- get_palette_colors(color_palette, n_gens)
  } else {
    palette_colors_outline <- palette_colors_fill
  }
  
  # Create base plot
  if (has_mass) {
    p <- ggplot2::ggplot(data_plot, 
                         aes(x = mass, y = generation, fill = generation)) +
      ggridges::geom_density_ridges(
        scale = scale,
        alpha = 0.7,
        color = NA
      )
  } else {
    # Fallback if no mass column - use count ridgeline
    p <- ggplot2::ggplot(data_plot,
                         aes(y = generation, fill = generation)) +
      ggridges::geom_density_ridges(
        scale = scale,
        alpha = 0.7,
        color = NA
      )
  }
  
  # Apply colors
  p <- p +
    ggplot2::scale_fill_manual(
      values = palette_colors_fill,
      guide = "none"
    )
  
  # Add theme and labels
  p <- p +
    ggplot2::labs(
      title = title,
      x = if (has_mass) "Mass (grams)" else "Count",
      y = "Generation",
      subtitle = sprintf("n=%d, scale=%.2f", nrow(data_plot), scale)
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "gray50"),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      panel.grid.major = element_line(color = "gray90"),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = "white", color = NA)
    )
  
  if (verbose) {
    cat("[ridgeline] Plot object created\n")
  }
  
  return(p)
}

