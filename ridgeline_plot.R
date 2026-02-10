library(tidyverse)
library(ggridges)
library(ggplot2)

# Load data
data <- read.csv("data/data.csv")

# Create 6-year periods starting from 1980
data <- data %>%
  mutate(
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
  ) %>%
  # Filter for Unknown dispersed birds only
  filter(dispsersed == "Unknown", !is.na(period))

# Calculate mean mass for each period (for the dots)
period_means <- data %>%
  group_by(period) %>%
  summarise(mean_mass = mean(mass, na.rm = TRUE),
            .groups = "drop")

# Convert period to ordered factor for proper plotting
period_levels <- c(
  "1980-1985", "1986-1991", "1992-1997", "1998-2003",
  "2004-2009", "2010-2015", "2016-2021", "2022-2027"
)

data <- data %>%
  mutate(period = factor(period, levels = period_levels, ordered = TRUE))

period_means <- period_means %>%
  mutate(period = factor(period, levels = period_levels, ordered = TRUE))

# Create ridgeline plot
p <- ggplot(data, aes(x = mass, y = period, fill = period)) +
  geom_density_ridges(alpha = 0.7, show.legend = FALSE) +
  # Add mean masses as black dots
  geom_point(
    data = period_means,
    aes(x = mean_mass, y = period),
    color = "black",
    size = 3,
    inherit.aes = FALSE
  ) +
  labs(
    title = "Distribution of Unknown Dispersed Bird Masses by 6-Year Period",
    x = "Mass (g)",
    y = "Period"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10)
  )

# Display the plot
print(p)

# Save the plot
ggsave("ridgeline_plot.png", p, width = 10, height = 7, dpi = 300)

# Print summary statistics
cat("\nSummary Statistics by Period:\n")
print(period_means)
