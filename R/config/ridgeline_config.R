# ==============================================================================
# R/config/ridgeline_config.R
# ==============================================================================
# PURPOSE
# -------
# Complete specification of all 20 ridgeline plot variants.
# 10 compact (scale 0.85) + 10 expanded (scale 2.25)
# 10 different palette combinations covering viridis and brewer options
#
# DEPENDS ON
# ----------
# None (configuration only)
#
# INPUTS
# ------
# None
#
# OUTPUTS
# -------
# ridgeline_plot_configs - List of 20 plot configuration objects
#
# USAGE
# -----
# source("R/config/ridgeline_config.R")
# for (config in ridgeline_plot_configs) { ... }
#
# ==============================================================================

#' All Ridgeline Plot Configurations
#'
#' @description
#' Master configuration list defining 20 ridgeline plot variants.
#' Each configuration specifies a unique combination of:
#' - Scale value (0.85 = compact, 2.25 = expanded)
#' - Line height (0.85 = compact, 1 = expanded)
#' - Palette (fill and color both use same palette)
#' - Palette type (viridis or brewer)
#'
#' @format List of 20 configuration objects
#'
#' @details
#' Each configuration is a list with:
#' - id: Unique identifier (compact_01 to compact_10, expanded_01 to expanded_10)
#' - name: Human-readable name
#' - scale_value: Density ridge overlap (0.85 = tight, 2.25 = loose)
#' - line_height: Ridge height (0.85 = compact, 1 = normal)
#' - fill_palette: Viridis palette for fill (plasma, inferno, magma, etc.)
#' - color_palette: Same as fill for consistency
#' - palette_type: "viridis" or "brewer"
#'
#' @export
ridgeline_plot_configs <- list(
  # ===========================
  # COMPACT PLOTS (Scale 0.85)
  # ===========================
  
  list(
    id = "compact_01",
    name = "Plasma - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "plasma",
    color_palette = "plasma",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_02",
    name = "Viridis - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "viridis",
    color_palette = "viridis",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_03",
    name = "Magma - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "magma",
    color_palette = "magma",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_04",
    name = "Inferno - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "inferno",
    color_palette = "inferno",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_05",
    name = "Cividis - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "cividis",
    color_palette = "cividis",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_06",
    name = "Rocket - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "rocket",
    color_palette = "rocket",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_07",
    name = "Mako - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "mako",
    color_palette = "mako",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_08",
    name = "Turbo - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "turbo",
    color_palette = "turbo",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_09",
    name = "Set2 - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "Set2",
    color_palette = "Set2",
    palette_type = "brewer"
  ),
  
  list(
    id = "compact_10",
    name = "Dark2 - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "Dark2",
    color_palette = "Dark2",
    palette_type = "brewer"
  ),
  
  # =============================
  # EXPANDED PLOTS (Scale 2.25)
  # =============================
  
  list(
    id = "expanded_01",
    name = "Plasma - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "plasma",
    color_palette = "plasma",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_02",
    name = "Viridis - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "viridis",
    color_palette = "viridis",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_03",
    name = "Magma - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "magma",
    color_palette = "magma",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_04",
    name = "Inferno - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "inferno",
    color_palette = "inferno",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_05",
    name = "Cividis - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "cividis",
    color_palette = "cividis",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_06",
    name = "Rocket - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "rocket",
    color_palette = "rocket",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_07",
    name = "Mako - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "mako",
    color_palette = "mako",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_08",
    name = "Turbo - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "turbo",
    color_palette = "turbo",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_09",
    name = "Set2 - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "Set2",
    color_palette = "Set2",
    palette_type = "brewer"
  ),
  
  list(
    id = "expanded_10",
    name = "Dark2 - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "Dark2",
    color_palette = "Dark2",
    palette_type = "brewer"
  )
)

# ==============================================================================
# END R/config/ridgeline_config.R
# ==============================================================================
