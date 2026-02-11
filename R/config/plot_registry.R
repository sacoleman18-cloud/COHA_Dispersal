# ==============================================================================
# R/config/plot_registry.R
# ==============================================================================
# PURPOSE
# -------
# Master plot registry: Single source of truth for all plot configurations.
# Replaces hardcoded assumptions about plot counts/names throughout codebase.
# 
# KEY PRINCIPLE: Add/modify plots here ONLY. Downstream code reads registry.
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
# plot_registry - List defining all plot types and variants
# Access: plot_registry$ridgeline$variants, plot_registry$boxplot$variants, etc.
#
# USAGE
# -----
# source("R/config/plot_registry.R")
# 
# # Query total plots of all types
# total_plots <- sum(sapply(plot_registry, function(x) length(x$variants)))
# 
# # Get all ridgeline plot IDs
# ridgeline_ids <- names(plot_registry$ridgeline$variants)
# 
# # Get plot by ID
# plot_config <- plot_registry$ridgeline$variants$compact_01
#
# ==============================================================================

# ==============================================================================
# MASTER PLOT REGISTRY
# ==============================================================================
# Structure: 
#   plot_registry$[PLOT_TYPE]$variants$[PLOT_ID] = list(config)
#
# Example: plot_registry$ridgeline$variants$compact_01
# ==============================================================================

plot_registry <- list(
  
  # ============================================================================
  # RIDGELINE PLOTS - Density distributions across time periods
  # ============================================================================
  ridgeline = list(
    
    # Metadata about this plot type
    type = "ridgeline",
    display_name = "Ridgeline Plots",
    description = "Density distributions of mass across 6-year generational periods",
    active = TRUE,
    grouping = c("scale", "palette"),  # How to organize in reports
    
    # All plot variants for this type
    variants = list(
      
      # -----------------------------------------------------------------------
      # COMPACT SCALE (0.85) - Tight vertical spacing
      # -----------------------------------------------------------------------
      
      compact_01 = list(
        id = "compact_01",
        display_name = "Variant 1: Compact + Plasma",
        scale = 0.85,
        line_height = 0.85,
        fill = "plasma",
        color = "plasma",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_02 = list(
        id = "compact_02",
        display_name = "Variant 2: Compact + Viridis",
        scale = 0.85,
        line_height = 0.85,
        fill = "viridis",
        color = "viridis",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_03 = list(
        id = "compact_03",
        display_name = "Variant 3: Compact + Magma",
        scale = 0.85,
        line_height = 0.85,
        fill = "magma",
        color = "magma",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_04 = list(
        id = "compact_04",
        display_name = "Variant 4: Compact + Inferno",
        scale = 0.85,
        line_height = 0.85,
        fill = "inferno",
        color = "inferno",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_05 = list(
        id = "compact_05",
        display_name = "Variant 5: Compact + Cividis",
        scale = 0.85,
        line_height = 0.85,
        fill = "cividis",
        color = "cividis",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_06 = list(
        id = "compact_06",
        display_name = "Variant 6: Compact + Rocket",
        scale = 0.85,
        line_height = 0.85,
        fill = "rocket",
        color = "rocket",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_07 = list(
        id = "compact_07",
        display_name = "Variant 7: Compact + Mako",
        scale = 0.85,
        line_height = 0.85,
        fill = "mako",
        color = "mako",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_08 = list(
        id = "compact_08",
        display_name = "Variant 8: Compact + Turbo",
        scale = 0.85,
        line_height = 0.85,
        fill = "turbo",
        color = "turbo",
        palette_type = "viridis",
        group = "compact"
      ),
      
      compact_09 = list(
        id = "compact_09",
        display_name = "Variant 9: Compact + Set2",
        scale = 0.85,
        line_height = 0.85,
        fill = "Set2",
        color = "Set2",
        palette_type = "brewer",
        group = "compact"
      ),
      
      compact_10 = list(
        id = "compact_10",
        display_name = "Variant 10: Compact + Dark2",
        scale = 0.85,
        line_height = 0.85,
        fill = "Dark2",
        color = "Dark2",
        palette_type = "brewer",
        group = "compact"
      ),
      
      compact_11 = list(
        id = "compact_11",
        display_name = "Variant 11: Compact + HawkO Natural",
        scale = 0.85,
        line_height = 0.85,
        fill = "hawkO_natural",
        fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
        color = "hawkO_natural",
        color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
        palette_type = "custom",
        group = "compact"
      ),
      
      compact_12 = list(
        id = "compact_12",
        display_name = "Variant 12: Compact + HawkO Vivid",
        scale = 0.85,
        line_height = 0.85,
        fill = "hawkO_vivid",
        fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
        color = "hawkO_vivid",
        color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
        palette_type = "custom",
        group = "compact"
      ),
      
      compact_13 = list(
        id = "compact_13",
        display_name = "Variant 13: Compact + Hawk Natural",
        scale = 0.85,
        line_height = 0.85,
        fill = "hawk_natural",
        fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
        color = "hawk_natural",
        color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
        palette_type = "custom",
        group = "compact"
      ),
      
      compact_14 = list(
        id = "compact_14",
        display_name = "Variant 14: Compact + Hawk Vivid",
        scale = 0.85,
        line_height = 0.85,
        fill = "hawk_vivid",
        fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
        color = "hawk_vivid",
        color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
        palette_type = "custom",
        group = "compact"
      ),
      
      # -----------------------------------------------------------------------
      # EXPANDED SCALE (2.25) - Loose vertical spacing
      # -----------------------------------------------------------------------
      
      expanded_01 = list(
        id = "expanded_01",
        display_name = "Variant 13: Expanded + Plasma",
        scale = 2.25,
        line_height = 1,
        fill = "plasma",
        color = "plasma",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_02 = list(
        id = "expanded_02",
        display_name = "Variant 14: Expanded + Viridis",
        scale = 2.25,
        line_height = 1,
        fill = "viridis",
        color = "viridis",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_03 = list(
        id = "expanded_03",
        display_name = "Variant 15: Expanded + Magma",
        scale = 2.25,
        line_height = 1,
        fill = "magma",
        color = "magma",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_04 = list(
        id = "expanded_04",
        display_name = "Variant 16: Expanded + Inferno",
        scale = 2.25,
        line_height = 1,
        fill = "inferno",
        color = "inferno",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_05 = list(
        id = "expanded_05",
        display_name = "Variant 17: Expanded + Cividis",
        scale = 2.25,
        line_height = 1,
        fill = "cividis",
        color = "cividis",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_06 = list(
        id = "expanded_06",
        display_name = "Variant 18: Expanded + Rocket",
        scale = 2.25,
        line_height = 1,
        fill = "rocket",
        color = "rocket",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_07 = list(
        id = "expanded_07",
        display_name = "Variant 19: Expanded + Mako",
        scale = 2.25,
        line_height = 1,
        fill = "mako",
        color = "mako",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_08 = list(
        id = "expanded_08",
        display_name = "Variant 20: Expanded + Turbo",
        scale = 2.25,
        line_height = 1,
        fill = "turbo",
        color = "turbo",
        palette_type = "viridis",
        group = "expanded"
      ),
      
      expanded_09 = list(
        id = "expanded_09",
        display_name = "Variant 21: Expanded + Set2",
        scale = 2.25,
        line_height = 1,
        fill = "Set2",
        color = "Set2",
        palette_type = "brewer",
        group = "expanded"
      ),
      
      expanded_10 = list(
        id = "expanded_10",
        display_name = "Variant 22: Expanded + Dark2",
        scale = 2.25,
        line_height = 1,
        fill = "Dark2",
        color = "Dark2",
        palette_type = "brewer",
        group = "expanded"
      ),
      
      expanded_11 = list(
        id = "expanded_11",
        display_name = "Variant 25: Expanded + HawkO Natural",
        scale = 2.25,
        line_height = 1,
        fill = "hawkO_natural",
        fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
        color = "hawkO_natural",
        color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27"),
        palette_type = "custom",
        group = "expanded"
      ),
      
      expanded_12 = list(
        id = "expanded_12",
        display_name = "Variant 26: Expanded + HawkO Vivid",
        scale = 2.25,
        line_height = 1,
        fill = "hawkO_vivid",
        fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
        color = "hawkO_vivid",
        color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EAD7B8", "#FF8C00"),
        palette_type = "custom",
        group = "expanded"
      ),
      
      expanded_13 = list(
        id = "expanded_13",
        display_name = "Variant 27: Expanded + Hawk Natural",
        scale = 2.25,
        line_height = 1,
        fill = "hawk_natural",
        fill_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
        color = "hawk_natural",
        color_colors = c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#F1E6D2"),
        palette_type = "custom",
        group = "expanded"
      ),
      
      expanded_14 = list(
        id = "expanded_14",
        display_name = "Variant 28: Expanded + Hawk Vivid",
        scale = 2.25,
        line_height = 1,
        fill = "hawk_vivid",
        fill_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
        color = "hawk_vivid",
        color_colors = c("#142033", "#4A5E78", "#7A6456", "#B9734F", "#EFE3C6"),
        palette_type = "custom",
        group = "expanded"
      )
    )
  ),
  
  # ============================================================================
  # BOXPLOT PLOTS - Future type (ready for expansion)
  # ============================================================================
  boxplot = list(
    
    type = "boxplot",
    display_name = "Box-Whisker Plots",
    description = "Distribution comparisons using box-whisker plots",
    active = FALSE,  # Enable when implementation is ready
    grouping = c("statistic", "grouping_var"),
    
    variants = list()
    # Future: boxplot_01, boxplot_02, etc.
  )
)

# ==============================================================================
# HELPER FUNCTIONS FOR REGISTRY ACCESS
# ==============================================================================

#' Get all plot IDs of a specific type
#' @param plot_type Character. "ridgeline", "boxplot", etc.
#' @return Character vector of plot IDs
#' @export
get_plot_ids <- function(plot_type = "ridgeline") {
  if (!plot_type %in% names(plot_registry)) {
    return(character(0))
  }
  names(plot_registry[[plot_type]]$variants)
}

#' Get total count of active plots
#' @param plot_type Character. "ridgeline", "boxplot", or NULL for all
#' @return Integer count of plots
#' @export
count_plots <- function(plot_type = NULL) {
  if (is.null(plot_type)) {
    # Count all active plot types
    sum(sapply(plot_registry, function(x) {
      if (isTRUE(x$active)) length(x$variants) else 0
    }))
  } else {
    if (!plot_type %in% names(plot_registry)) return(0)
    length(plot_registry[[plot_type]]$variants)
  }
}

#' Get plot configuration by ID
#' @param plot_id Character. Plot ID (e.g., "compact_01")
#' @param plot_type Character. Plot type to search (default: "ridgeline")
#' @return List with plot configuration
#' @export
get_plot_config <- function(plot_id, plot_type = "ridgeline") {
  if (!plot_type %in% names(plot_registry)) {
    return(NULL)
  }
  if (!plot_id %in% names(plot_registry[[plot_type]]$variants)) {
    return(NULL)
  }
  plot_registry[[plot_type]]$variants[[plot_id]]
}

#' Get all plots grouped by a specific field
#' @param group_by Character. Field to group by (e.g., "group", "palette", "scale")
#' @param plot_type Character. Plot type to query
#' @return Named list grouped by field value
#' @export
get_plots_grouped <- function(group_by = "group", plot_type = "ridgeline") {
  if (!plot_type %in% names(plot_registry)) {
    return(list())
  }
  
  variants <- plot_registry[[plot_type]]$variants
  if (length(variants) == 0) return(list())
  
  # Group by the specified field
  groups <- list()
  for (plot_id in names(variants)) {
    config <- variants[[plot_id]]
    group_value <- config[[group_by]] %||% "ungrouped"
    
    if (!group_value %in% names(groups)) {
      groups[[group_value]] <- character()
    }
    groups[[group_value]] <- c(groups[[group_value]], plot_id)
  }
  
  groups
}

# ==============================================================================
# END R/config/plot_registry.R
# ==============================================================================
