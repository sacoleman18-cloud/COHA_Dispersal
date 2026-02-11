# Plot Configuration
# 
# This file defines all plot specifications for the COHA dispersal analysis.
# Each plot configuration includes scale, line height, and palette parameters.
#
# To add a new plot, append to the plot_configs list with the same structure.

# Define plot configurations
plot_configs <- list(
  # Compact plots (scale = 0.85)
  list(
    id = "compact_01",
    name = "Plasma & Inferno - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "plasma",
    color_palette = "plasma",
    palette_type = "viridis"
  ),
  list(
    id = "compact_02",
    name = "Viridis & Magma - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "viridis",
    color_palette = "viridis",
    palette_type = "viridis"
  ),
  list(
    id = "compact_03",
    name = "Magma & Plasma - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "magma",
    color_palette = "magma",
    palette_type = "viridis"
  ),
  list(
    id = "compact_04",
    name = "Inferno & Viridis - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "inferno",
    color_palette = "inferno",
    palette_type = "viridis"
  ),
  list(
    id = "compact_05",
    name = "Cividis & Rocket - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "cividis",
    color_palette = "cividis",
    palette_type = "viridis"
  ),
  list(
    id = "compact_06",
    name = "Rocket & Mako - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "rocket",
    color_palette = "rocket",
    palette_type = "viridis"
  ),
  list(
    id = "compact_07",
    name = "Mako & Turbo - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "mako",
    color_palette = "mako",
    palette_type = "viridis"
  ),
  list(
    id = "compact_08",
    name = "Turbo & Cividis - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "turbo",
    color_palette = "turbo",
    palette_type = "viridis"
  ),
  list(
    id = "compact_09",
    name = "Set2 & Dark2 - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "Set2",
    color_palette = "Set2",
    palette_type = "brewer"
  ),
  list(
    id = "compact_10",
    name = "Spectral & RdYlBu - Compact",
    scale_value = 0.85,
    line_height = 0.85,
    fill_palette = "Spectral",
    color_palette = "Spectral",
    palette_type = "brewer"
  ),
  
  # Expanded plots (scale = 2.25)
  list(
    id = "expanded_01",
    name = "Plasma & Inferno - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "plasma",
    color_palette = "plasma",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_02",
    name = "Viridis & Magma - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "viridis",
    color_palette = "viridis",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_03",
    name = "Magma & Plasma - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "magma",
    color_palette = "magma",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_04",
    name = "Inferno & Viridis - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "inferno",
    color_palette = "inferno",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_05",
    name = "Cividis & Rocket - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "cividis",
    color_palette = "cividis",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_06",
    name = "Rocket & Mako - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "rocket",
    color_palette = "rocket",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_07",
    name = "Mako & Turbo - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "mako",
    color_palette = "mako",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_08",
    name = "Turbo & Cividis - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "turbo",
    color_palette = "turbo",
    palette_type = "viridis"
  ),
  list(
    id = "expanded_09",
    name = "Set2 & Dark2 - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "Set2",
    color_palette = "Set2",
    palette_type = "brewer"
  ),
  list(
    id = "expanded_10",
    name = "Spectral & RdYlBu - Expanded",
    scale_value = 2.25,
    line_height = 1,
    fill_palette = "Spectral",
    color_palette = "Spectral",
    palette_type = "brewer"
  )
)
