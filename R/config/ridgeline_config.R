# ==============================================================================
# R/config/ridgeline_config.R
# ==============================================================================
# PURPOSE
# -------
# Complete specification of all 24 ridgeline plot variants.
# 12 compact (scale 0.85) + 12 expanded (scale 2.25)
# 12 different palette combinations covering viridis, brewer, and custom hawk palettes
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
# ridgeline_plot_configs - List of 24 plot configuration objects
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
#' Master configuration list defining 24 ridgeline plot variants.
#' Each configuration specifies a unique combination of:
#' - Scale value (0.85 = compact, 2.25 = expanded)
#' - Line height (0.85 = compact, 1 = expanded)
#' - Palette (fill and color both use same palette)
#' - Palette type (viridis or brewer)
#'
#' @format List of 24 configuration objects
#'
#' @details
#' Each configuration is a list with:
#' - id: Unique identifier (compact_01 to compact_12, expanded_01 to expanded_12)
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
    scale = 0.85,
    line_height = 0.85,
    fill = "plasma",
    color = "plasma",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_02",
    name = "Viridis - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "viridis",
    color = "viridis",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_03",
    name = "Magma - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "magma",
    color = "magma",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_04",
    name = "Inferno - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "inferno",
    color = "inferno",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_05",
    name = "Cividis - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "cividis",
    color = "cividis",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_06",
    name = "Rocket - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "rocket",
    color = "rocket",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_07",
    name = "Mako - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "mako",
    color = "mako",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_08",
    name = "Turbo - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "turbo",
    color = "turbo",
    palette_type = "viridis"
  ),
  
  list(
    id = "compact_09",
    name = "Set2 - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "Set2",
    color = "Set2",
    palette_type = "brewer"
  ),
  
  list(
    id = "compact_10",
    name = "Dark2 - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "Dark2",
    color = "Dark2",
    palette_type = "brewer"
  ),
  
  list(
    id = "compact_11",
    name = "Hawk Natural - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "hawk_natural",
    fill_colors = c("#F1E6D2", "#C98C63", "#8C6A54", "#56677F", "#1F2A3A"),
    color = "hawk_natural",
    color_colors = c("#F1E6D2", "#C98C63", "#8C6A54", "#56677F", "#1F2A3A"),
    palette_type = "custom"
  ),
  
  list(
    id = "compact_12",
    name = "Hawk Vivid - Compact",
    scale = 0.85,
    line_height = 0.85,
    fill = "hawk_vivid",
    fill_colors = c("#EFE3C6", "#B9734F", "#7A6456", "#4A5E78", "#142033"),
    color = "hawk_vivid",
    color_colors = c("#EFE3C6", "#B9734F", "#7A6456", "#4A5E78", "#142033"),
    palette_type = "custom"
  ),
  
  # =============================
  # EXPANDED PLOTS (Scale 2.25)
  # =============================
  
  list(
    id = "expanded_01",
    name = "Plasma - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "plasma",
    color = "plasma",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_02",
    name = "Viridis - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "viridis",
    color = "viridis",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_03",
    name = "Magma - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "magma",
    color = "magma",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_04",
    name = "Inferno - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "inferno",
    color = "inferno",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_05",
    name = "Cividis - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "cividis",
    color = "cividis",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_06",
    name = "Rocket - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "rocket",
    color = "rocket",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_07",
    name = "Mako - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "mako",
    color = "mako",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_08",
    name = "Turbo - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "turbo",
    color = "turbo",
    palette_type = "viridis"
  ),
  
  list(
    id = "expanded_09",
    name = "Set2 - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "Set2",
    color = "Set2",
    palette_type = "brewer"
  ),
  
  list(
    id = "expanded_10",
    name = "Dark2 - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "Dark2",
    color = "Dark2",
    palette_type = "brewer"
  ),
  
  list(
    id = "expanded_11",
    name = "Hawk Natural - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "hawk_natural",
    fill_colors = c("#F1E6D2", "#C98C63", "#8C6A54", "#56677F", "#1F2A3A"),
    color = "hawk_natural",
    color_colors = c("#F1E6D2", "#C98C63", "#8C6A54", "#56677F", "#1F2A3A"),
    palette_type = "custom"
  ),
  
  list(
    id = "expanded_12",
    name = "Hawk Vivid - Expanded",
    scale = 2.25,
    line_height = 1,
    fill = "hawk_vivid",
    fill_colors = c("#EFE3C6", "#B9734F", "#7A6456", "#4A5E78", "#142033"),
    color = "hawk_vivid",
    color_colors = c("#EFE3C6", "#B9734F", "#7A6456", "#4A5E78", "#142033"),
    palette_type = "custom"
  )
)

# ==============================================================================
# END R/config/ridgeline_config.R
# ==============================================================================
