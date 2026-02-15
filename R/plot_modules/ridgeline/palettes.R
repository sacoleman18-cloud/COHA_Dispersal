# ==============================================================================
# R/plot_modules/ridgeline/palettes.R
# ==============================================================================
# Color palette utilities for ridgeline plots
#
# Handles viridis palettes and custom color selections
#
# ==============================================================================

# Load viridis package
require(viridis, quietly = TRUE) || 
  stop("viridis package required for color palettes")

#' List Available Palettes
#'
#' @description
#' Returns list of palettes available for ridgeline plots.
#'
#' @return Character vector of palette names
#'
#' @examples
#' palettes <- list_available_palettes()
#' # [1] "plasma" "viridis" "magma" "inferno" "cividis"
#'
#' @export
list_available_palettes <- function() {
  c("plasma", "viridis", "magma", "inferno", "cividis")
}

#' Get Palette Colors
#'
#' @description
#' Returns color vector from specified palette.
#'
#' @param palette_name Character. Name of palette ("plasma", "viridis", etc.)
#' @param n Integer. Number of colors to return (1-256)
#' @param reverse Logical. Reverse palette order. Default: FALSE
#'
#' @return Character vector of hex color codes
#'
#' @export
get_palette_colors <- function(palette_name,
                               n = 10,
                               reverse = FALSE) {
  
  # Validate inputs
  palette_name <- tolower(trimws(palette_name))
  n <- max(2, min(as.integer(n), 256))
  
  # Get palette function
  palette_fn <- switch(palette_name,
    "plasma" = viridis::plasma,
    "viridis" = viridis::viridis,
    "magma" = viridis::magma,
    "inferno" = viridis::inferno,
    "cividis" = viridis::cividis,
    NA  # Unknown palette
  )
  
  if (is.na(palette_fn)) {
    warning(sprintf("Unknown palette '%s', using viridis", palette_name))
    palette_fn <- viridis::viridis
  }
  
  # Generate colors
  colors <- palette_fn(n)
  
  # Reverse if requested
  if (reverse) {
    colors <- rev(colors)
  }
  
  return(colors)
}

#' Create Color Palette Map
#'
#' @description
#' Creates mapping of discrete values to colors from palette.
#'
#' @param values Character/numeric vector. Values to map to colors.
#' @param palette_name Character. Palette name.
#' @param reverse Logical. Reverse palette.
#'
#' @return Named character vector (values → hex colors)
#'
#' @export
create_palette_map <- function(values,
                               palette_name = "viridis",
                               reverse = FALSE) {
  
  if (length(values) == 0) {
    return(NULL)
  }
  
  # Get unique values
  unique_vals <- unique(as.character(values))
  n <- length(unique_vals)
  
  # Get colors
  colors <- get_palette_colors(palette_name, n, reverse)
  
  # Create named vector
  names(colors) <- sort(unique_vals)
  
  return(colors)
}

#' Preview Palette
#'
#' @description
#' Generates a simple preview plot of palette colors.
#'
#' @param palette_name Character. Palette to preview.
#' @param n Integer. Number of colors to show (default: 10).
#' @param reverse Logical. Reverse palette.
#'
#' @return ggplot object showing palette
#'
#' @export
preview_palette <- function(palette_name = "viridis",
                            n = 10,
                            reverse = FALSE) {
  
  colors <- get_palette_colors(palette_name, n, reverse)
  
  # Create data for bar plot
  df <- data.frame(
    color_num = seq_along(colors),
    color = colors,
    stringsAsFactors = FALSE
  )
  
  # Create plot
  p <- ggplot2::ggplot(df, aes(x = color_num, y = 1, fill = color)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_x_continuous(breaks = seq_along(colors)) +
    ggplot2::labs(
      title = sprintf("Palette: %s (%d colors)", palette_name, n),
      x = "Color Index",
      y = ""
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid = element_blank()
    )
  
  return(p)
}

#' Get Palette Info
#'
#' @description
#' Returns metadata about a palette.
#'
#' @param palette_name Character. Palette name.
#'
#' @return List with palette information
#'
#' @export
get_palette_info <- function(palette_name) {
  
  palette_name <- tolower(trimws(palette_name))
  
  info_list <- list(
    "plasma" = list(
      name = "Plasma",
      description = "Inferno-based perceptually-uniform palette",
      optimal_range = "high contrast visualization"
    ),
    "viridis" = list(
      name = "Viridis",
      description = "Perceptually-uniform palette",
      optimal_range = "general purpose, print-friendly"
    ),
    "magma" = list(
      name = "Magma",
      description = "Muted colorblind-friendly palette",
      optimal_range = "colorblind-friendly visualization"
    ),
    "inferno" = list(
      name = "Inferno",
      description = "High-contrast perceptually-uniform palette",
      optimal_range = "high contrast visualization"
    ),
    "cividis" = list(
      name = "Cividis",
      description = "Colorblind-optimized palette",
      optimal_range = "colorblind-friendly visualization"
    )
  )
  
  if (!(palette_name %in% names(info_list))) {
    return(list(
      name = palette_name,
      description = "Unknown palette",
      optimal_range = NA
    ))
  }
  
  return(info_list[[palette_name]])
}

# ==============================================================================
# PALETTE CONSTANTS
# ==============================================================================

# Common palette configurations
.PALETTE_SCHEMES <- list(
  
  # Default schemes (palette + scale)
  compact_plasma = list(
    palette = "plasma",
    scale = 0.85,
    description = "Tight spacing with plasma colors"
  ),
  compact_viridis = list(
    palette = "viridis",
    scale = 0.85,
    description = "Tight spacing with viridis colors"
  ),
  regular_magma = list(
    palette = "magma",
    scale = 1.0,
    description = "Standard spacing with magma colors"
  ),
  expanded_cividis = list(
    palette = "cividis",
    scale = 1.2,
    description = "Loose spacing with colorblind-friendly palette"
  )
)
