# COHA Dispersal Ridgeline Plot
# 
# This script generates a single ridgeline plot showing Cooper's Hawk mass
# distributions across 6-year generational periods. The plot includes:
# - Unknown-dispersed bird mass distributions (ridgelines)
# - Wisconsin mean masses (dots with dashed lines)
# - Unknown mean masses (triangles with solid lines)
#
# Author: [Your name]
# Date: February 10, 2026

library(tidyverse)
library(ggridges)
library(ggplot2)

# Load data
data <- read.csv("data/data.csv")

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

# Calculate mean mass for each period (for the dots)
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
  geom_density_ridges(alpha = 0.7, scale = 2.25, show.legend = FALSE) +
  # Add Wisconsin mean lines for each period (dashed)
  geom_segment(
    data = period_means,
    aes(x = mean_mass, xend = mean_mass,
        y = as.numeric(period), yend = as.numeric(period) + 1),
    color = "black",
    linetype = "dashed",
    linewidth = 0.4,
    alpha = 0.7
  ) +
  # Add Unknown-dispersed mean lines for each period (solid)
  geom_segment(
    data = unknown_means,
    aes(x = mean_mass, xend = mean_mass,
        y = as.numeric(period), yend = as.numeric(period) + 1,
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
  scale_fill_viridis_d(option = "plasma") +
  scale_color_viridis_d(option = "plasma") +
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

# Display the plot
print(p)

# Save the plot
ggsave("ridgeline_plot.png", p, width = 10, height = 7, dpi = 300)

# Print summary statistics
cat("\nSummary Statistics by Period:\n")
print(period_means)
