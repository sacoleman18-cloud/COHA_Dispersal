# ==============================================================================
# R/core/palettes.R
# ==============================================================================
# UNIVERSAL COLOR PALETTE UTILITIES
#
# PURPOSE
# -------
# Provides consistent, reusable color palettes for all visualization modules.
# Not domain-specific - used by plot modules, reports, and any visualization code.
#
# DEPENDS ON
# ----------
# - viridis (for perceptually-uniform palettes)
# - ggplot2 (optional, for preview_palette)
#
# FUNCTIONS PROVIDED
# ------------------
# list_available_palettes() - List all available palettes
# get_palette_colors() - Get color vector from palette
# create_palette_map() - Map discrete values to colors
# preview_palette() - Visualize palette
# get_palette_info() - Get palette metadata
#
# USAGE
# -----
# source("R/core/palettes.R")
#
# # Get 10 colors from plasma palette
# colors <- get_palette_colors("plasma", n = 10)
#
# # Map species to colors
# species <- c("A", "B", "C")
# color_map <- create_palette_map(species, "viridis")
#
# # Preview palette before using
# p <- preview_palette("magma", n = 20)
#
# ==============================================================================

# Load viridis package (required)
require(viridis, quietly = TRUE) || 
  stop("viridis package required. Install with: install.packages('viridis')")

# Load RColorBrewer package (optional, for brewer palettes)
require(RColorBrewer, quietly = TRUE)

# ==============================================================================
# CORE PALETTE FUNCTIONS
# ==============================================================================

#' List Available Palettes
#'
#' @description
#' Returns list of all available color palettes.
#' All palettes are perceptually-uniform (viridis family).
#'
#' @return Character vector of palette names
#'
#' @details
#' **Available Palettes:**
#' - **plasma** - High contrast, distinct hues
#' - **viridis** - Default, perceptually-uniform, print-friendly
#' - **magma** - Muted, colorblind-friendly
#' - **inferno** - High contrast alternative
#' - **cividis** - Optimized for colorblind viewers
#' - **rocket** - Smooth, warm gradient
#' - **mako** - Cool, blue-green gradient
#' - **turbo** - High saturation, high contrast
#' - **set2** - Brewer qualitative palette
#' - **dark2** - Brewer qualitative palette
#'
#' @examples
#' palettes <- list_available_palettes()
#' # [1] "plasma" "viridis" "magma" "inferno" "cividis"
#'
#' @export
list_available_palettes <- function() {
  c(
    "plasma", "viridis", "magma", "inferno", "cividis",
    "rocket", "mako", "turbo",
    "set2", "dark2"
  )
}

#' Get Colors from Palette
#'
#' @description
#' Returns a vector of colors from a specified palette.
#' Uses viridis family for perceptually-uniform colors.
#'
#' @param palette_name Character. Name of palette ("plasma", "viridis", etc.)
#' @param n Integer. Number of colors to return (1-256). Default: 10.
#' @param reverse Logical. Reverse palette order. Default: FALSE.
#'
#' @return Character vector of hex color codes
#'
#' @details
#' Colors are generated dynamically for any n value.
#' Unknown palette names default to "viridis" with a warning.
#'
#' @examples
#' # Get 5 colors from plasma palette
#' colors <- get_palette_colors("plasma", n = 5)
#'
#' # Get 20 colors reversed
#' colors <- get_palette_colors("viridis", n = 20, reverse = TRUE)
#'
#' @export
get_palette_colors <- function(palette_name,
                               n = 10,
                               reverse = FALSE) {
  
  # Validate inputs
  palette_name <- tolower(trimws(palette_name))
  n <- max(2, min(as.integer(n), 256))
  
  # Brewer palettes (qualitative)
  if (palette_name %in% c("set2", "dark2")) {
    if (!requireNamespace("RColorBrewer", quietly = TRUE)) {
      warning("RColorBrewer not available, using viridis")
      colors <- viridis::viridis(n)
    } else {
      colors <- RColorBrewer::brewer.pal(min(n, 8), palette_name)
      if (n > length(colors)) {
        colors <- rep(colors, length.out = n)
      }
    }
  } else {
    # Viridis family palettes
    palette_fn <- switch(palette_name,
      "plasma" = viridis::plasma,
      "viridis" = viridis::viridis,
      "magma" = viridis::magma,
      "inferno" = viridis::inferno,
      "cividis" = viridis::cividis,
      "rocket" = viridis::rocket,
      "mako" = viridis::mako,
      "turbo" = viridis::turbo,
      NA
    )
    
    if (is.na(palette_fn)) {
      warning(sprintf("Unknown palette '%s', using viridis", palette_name))
      palette_fn <- viridis::viridis
    }
    
    colors <- palette_fn(n)
  }
  
  # Reverse if requested
  if (reverse) {
    colors <- rev(colors)
  }
  
  return(colors)
}

#' Create Discrete Color Mapping
#'
#' @description
#' Maps discrete values to colors from a palette.
#' Useful for ensuring consistent coloring across multiple plots.
#'
#' @param values Character/numeric/factor vector. Values to map to colors.
#' @param palette_name Character. Palette name. Default: "viridis".
#' @param reverse Logical. Reverse palette. Default: FALSE.
#'
#' @return Named character vector (values → hex colors).
#'   Names are unique values, values are hex color codes.
#'
#' @details
#' Values are sorted alphabetically before mapping to colors.
#' This ensures consistent mapping across plots.
#'
#' @examples
#' # Map species to colors
#' species <- c("lion", "tiger", "zebra")
#' colors <- create_palette_map(species, "plasma")
#' # lion → "#0D0887"
#' # tiger → "#CC4778"
#' # zebra → "#F0F921"
#'
#' @export
create_palette_map <- function(values,
                               palette_name = "viridis",
                               reverse = FALSE) {
  
  if (length(values) == 0) {
    return(NULL)
  }
  
  # Get unique values and convert to character
  unique_vals <- unique(as.character(values))
  n <- length(unique_vals)
  
  # Get colors
  colors <- get_palette_colors(palette_name, n, reverse)
  
  # Create named vector (names = sorted values, values = colors)
  names(colors) <- sort(unique_vals)
  
  return(colors)
}

# ==============================================================================
# VISUALIZATION AND METADATA FUNCTIONS
# ==============================================================================

#' Preview Palette
#'
#' @description
#' Generates a visual preview of a palette.
#' Useful for choosing palettes before using them in plots.
#'
#' @param palette_name Character. Palette to preview. Default: "viridis".
#' @param n Integer. Number of colors to show. Default: 10.
#' @param reverse Logical. Reverse palette. Default: FALSE.
#'
#' @return ggplot2 object showing palette colors as a bar chart.
#'
#' @details
#' Requires ggplot2. Returns a simple bar plot with each color as a tile.
#' Useful for:
#' - Choosing palettes visually
#' - Checking colorblind compatibility
#' - Previewing before applying to plots
#'
#' @examples
#' \dontrun{
#' # Preview plasma palette
#' p <- preview_palette("plasma", n = 20)
#' print(p)
#'
#' # Compare palettes
#' for (pal in list_available_palettes()) {
#'   p <- preview_palette(pal, n = 15)
#'   print(p)
#' }
#' }
#'
#' @export
preview_palette <- function(palette_name = "viridis",
                            n = 10,
                            reverse = FALSE) {
  
  require(ggplot2, quietly = TRUE) || 
    stop("ggplot2 required for preview_palette")
  
  colors <- get_palette_colors(palette_name, n, reverse)
  
  # Create data for bar plot
  df <- data.frame(
    color_num = seq_along(colors),
    color = colors,
    stringsAsFactors = FALSE
  )
  
  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = color_num, y = 1, fill = color)) +
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
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )
  
  return(p)
}

#' Get Palette Metadata
#'
#' @description
#' Returns information about a palette.
#' Includes description and recommended use cases.
#'
#' @param palette_name Character. Palette name.
#'
#' @return List with fields:
#'   - name: Display name
#'   - description: What the palette looks like
#'   - optimal_range: Recommended use case
#'
#' @examples
#' info <- get_palette_info("plasma")
#' cat(info$description)
#'
#' @export
get_palette_info <- function(palette_name) {
  
  palette_name <- tolower(trimws(palette_name))
  
  info_list <- list(
    "plasma" = list(
      name = "Plasma",
      description = "High contrast, distinct hues across range",
      optimal_range = "High contrast visualization, scientific plots"
    ),
    "viridis" = list(
      name = "Viridis",
      description = "Perceptually uniform, colorblind-friendly",
      optimal_range = "General purpose, default choice, publications"
    ),
    "magma" = list(
      name = "Magma",
      description = "Muted, subtle color transitions",
      optimal_range = "Colorblind-friendly, detailed visualizations"
    ),
    "inferno" = list(
      name = "Inferno",
      description = "High contrast alternative to plasma",
      optimal_range = "High contrast visualization alternative"
    ),
    "cividis" = list(
      name = "Cividis",
      description = "Optimized for colorblind viewers",
      optimal_range = "Accessibility, colorblind audience"
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
# PALETTE UTILITIES
# ==============================================================================

#' Get Palette Info for All Palettes
#'
#' @description
#' Returns a data frame with information about all available palettes.
#'
#' @return Data frame with columns:
#'   - palette: Palette name
#'   - display_name: Display name
#'   - description: Description
#'   - use_case: Recommended use
#'
#' @export
list_palette_info <- function() {
  palettes <- list_available_palettes()
  
  info <- lapply(palettes, function(pal) {
    meta <- get_palette_info(pal)
    list(
      palette = pal,
      display_name = meta$name,
      description = meta$description,
      use_case = meta$optimal_range
    )
  })
  
  # Convert to data frame
  do.call(rbind, lapply(info, as.data.frame))
}

# ==============================================================================
# PALETTE SCHEMES (COMMON COMBINATIONS)
# ==============================================================================

# Pre-defined palette schemes combining colors with other parameters
.PALETTE_SCHEMES <- list(
  
  # Compact scale schemes
  compact_plasma = list(
    palette = "plasma",
    scale = 0.85,
    description = "Tight spacing with high-contrast colors"
  ),
  compact_viridis = list(
    palette = "viridis",
    scale = 0.85,
    description = "Tight spacing with standard colors"
  ),
  
  # Regular scale schemes
  regular_magma = list(
    palette = "magma",
    scale = 1.0,
    description = "Standard spacing with muted colors"
  ),
  regular_viridis = list(
    palette = "viridis",
    scale = 1.0,
    description = "Standard spacing with standard colors"
  ),
  
  # Expanded scale schemes
  expanded_cividis = list(
    palette = "cividis",
    scale = 1.2,
    description = "Loose spacing with colorblind-friendly colors"
  ),
  expanded_viridis = list(
    palette = "viridis",
    scale = 1.2,
    description = "Loose spacing with standard colors"
  )
)

# ==============================================================================
# EOF
# ==============================================================================
