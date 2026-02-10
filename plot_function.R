# Function to create ridgeline plot with customizable parameters
#
# This function generates ridgeline density plots for COHA dispersal data,
# showing mass distributions across 6-year generational periods.
#
# @param data Data frame containing mass, year, and dispsersed columns
# @param scale_value Numeric value controlling ridge overlap (default: 2.25)
# @param line_height Numeric value for mean line height (default: 1)
# @param fill_palette Character string for fill palette name (default: "plasma")
# @param color_palette Character string for color palette name (default: "inferno")
# @param palette_type Character string: "viridis" or "brewer" (default: "viridis")
#
# @return A ggplot2 object
#
# @examples
# data <- read.csv("data/data.csv")
# create_ridgeline_plot(data, scale_value = 0.85, line_height = 0.85,
#                       fill_palette = "plasma", palette_type = "viridis")
#
create_ridgeline_plot <- function(data, 
                                   scale_value = 2.25, 
                                   line_height = 1,
                                   fill_palette = "plasma",
                                   color_palette = "inferno",
                                   palette_type = "viridis") {
  
  # Create 6-year periods starting from 1980
  data <- data %>%
    mutate(
      disp_lower = tolower(dispsersed),
      period = case_when(
        year >= 1980 & year <= 1985 ~ "1980-1985",
        year >= 1986 & year <= 1991 ~ "1986-1991",
        year >= 1992 & year <= 1997 ~ "1992-1997",
        year >= 1998 & year <= 2003 ~ "1998-2003",
        year >= 2004 & year <= 2009 ~ "2004-2009",
        year >= 2010 & year <= 2015 ~ "2010-2015",
        year >= 2016 & year <= 2021 ~ "2016-2021",
        year >= 2022 & year <= 2027 ~ "2022-2027",
        TRUE ~ NA_character_
      )
    )
  
  # Filter for Unknown dispersed birds only (ridgeline)
  data_unknown <- data %>%
    filter(dispsersed == "Unknown", !is.na(period))
  
  # Calculate mean mass for Wisconsin dispersed birds only (mean dots)
  period_means <- data %>%
    filter(disp_lower == "wisconsin", !is.na(period)) %>%
    group_by(period) %>%
    summarise(mean_mass = mean(mass, na.rm = TRUE),
              .groups = "drop")
  
  # Calculate mean mass for Unknown dispersed birds only (mean lines)
  unknown_means <- data_unknown %>%
    group_by(period) %>%
    summarise(mean_mass = mean(mass, na.rm = TRUE),
              .groups = "drop")
  
  # Convert period to ordered factor for proper plotting
  period_levels <- c(
    "1980-1985", "1986-1991", "1992-1997", "1998-2003",
    "2004-2009", "2010-2015", "2016-2021", "2022-2027"
  )
  
  data_unknown <- data_unknown %>%
    mutate(period = factor(period, levels = period_levels, ordered = TRUE))
  
  period_means <- period_means %>%
    mutate(period = factor(period, levels = period_levels, ordered = TRUE))
  
  unknown_means <- unknown_means %>%
    mutate(period = factor(period, levels = period_levels, ordered = TRUE))
  
  # Create ridgeline plot
  p <- ggplot(data_unknown, aes(x = mass, y = period, fill = period)) +
    geom_density_ridges(alpha = 0.7, scale = scale_value, show.legend = FALSE, bandwidth = 6.96) +
    # Add Wisconsin mean lines for each period (dashed)
    geom_segment(
      data = period_means,
      aes(x = mean_mass, xend = mean_mass,
          y = as.numeric(period), yend = as.numeric(period) + line_height),
      color = "black",
      linetype = "dashed",
      linewidth = 0.4,
      alpha = 0.7
    ) +
    # Add Unknown-dispersed mean lines for each period (solid)
    geom_segment(
      data = unknown_means,
      aes(x = mean_mass, xend = mean_mass,
          y = as.numeric(period), yend = as.numeric(period) + line_height,
          color = period),
      linetype = "solid",
      linewidth = 0.8,
      alpha = 1
    ) +
    # Add mean masses as dots colored by period
    geom_point(
      data = period_means,
      aes(x = mean_mass, y = period, fill = period),
      shape = 21,
      size = 3,
      stroke = 0.6,
      color = "black",
      inherit.aes = FALSE
    ) +
    # Add Unknown mean masses as triangles at base
    geom_point(
      data = unknown_means,
      aes(x = mean_mass, y = period, fill = period),
      shape = 24,
      size = 3,
      stroke = 0.6,
      color = "black",
      inherit.aes = FALSE
    ) +
    labs(
      x = "Mass (g)",
      y = "Period"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.title.y = element_text(margin = margin(r = 8)),
      axis.title.x = element_text(margin = margin(t = 8)),
      legend.position = "none"
    )
  
  # Apply color scales based on palette type
  if (palette_type == "viridis") {
    p <- p +
      scale_fill_viridis_d(option = fill_palette) +
      scale_color_viridis_d(option = fill_palette)
  } else if (palette_type == "brewer") {
    p <- p +
      scale_fill_brewer(palette = fill_palette) +
      scale_color_brewer(palette = fill_palette)
  }
  
  return(p)
}
