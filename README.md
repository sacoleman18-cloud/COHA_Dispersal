# COHA Dispersal Analysis

Analysis of Cooper's Hawk (COHA) dispersal patterns and mass distributions across generational periods.

## Overview

This repository contains code and analysis for examining natal dispersal patterns in Cooper's Hawks, with a focus on:
- Mass distributions across 6-year generational periods (1980-2027)
- Comparison between Unknown-dispersed and Wisconsin-dispersed individuals
- Visual analysis using ridgeline density plots

## Project Structure

```
COHA_Dispersal/
├── R/
│   ├── plot_function.R          # Reusable ridgeline plot function
│   └── ridgeline_plot.R         # Single plot generation script
├── inst/
│   └── ridgeline_report.qmd     # Quarto report with 20 plots
├── data/
│   └── data.csv                 # Raw dispersal and mass data
├── docs/
│   └── Natal Dispersal and Mass Analysis Notes.md
├── results/
│   ├── png/                     # Generated plot images
│   └── report/                  # Rendered HTML reports
├── .gitignore
├── COHA_Dispersal.Rproj
└── README.md                    # This file
```

## Requirements

### R Packages

```r
install.packages(c("tidyverse", "ggridges", "ggplot2", "quarto"))
```

### Software

- R (≥ 4.0)
- RStudio (recommended)
- Quarto CLI (for rendering reports)

## Usage

### Generate a Single Plot

```r
source("R/ridgeline_plot.R")
```

This creates a ridgeline plot showing:
- Frequency distributions of Unknown-dispersed bird masses
- Wisconsin-dispersed mean masses (dots and dashed lines)
- Unknown-dispersed mean masses (triangles and solid lines)

### Generate Full Report

Render the complete Quarto report with 20 plots:

```r
quarto::quarto_render("inst/ridgeline_report.qmd")
```

Or via terminal:

```bash
quarto render inst/ridgeline_report.qmd
```

Reports are saved to `results/report/`

### Use Plot Function

```r
source("R/plot_function.R")
data <- read.csv("data/data.csv")

# Compact plot
create_ridgeline_plot(data, scale_value = 0.85, line_height = 0.85,
                      fill_palette = "plasma", color_palette = "inferno",
                      palette_type = "viridis")

# Expanded plot
create_ridgeline_plot(data, scale_value = 2.25, line_height = 1,
                      fill_palette = "viridis", color_palette = "magma",
                      palette_type = "viridis")
```

## Data Format

The `data/data.csv` file contains:

| Column | Description |
|--------|-------------|
| `mass` | Bird mass in grams |
| `year` | Year of observation |
| `dispsersed` | Dispersal status (Unknown, Wisconsin, etc.) |

## Plot Components

Each ridgeline plot includes:

- **Ridgeline densities**: Distribution of Unknown-dispersed bird masses by period
- **Colored triangles**: Mean mass of Unknown-dispersed birds (at baseline)
- **Colored dots**: Mean mass of Wisconsin-dispersed birds
- **Solid colored lines**: Unknown dispersal mean indicators
- **Dashed black lines**: Wisconsin dispersal mean indicators

## Customization

### Available Palettes

**Viridis options**: `viridis`, `plasma`, `inferno`, `magma`, `cividis`, `rocket`, `mako`, `turbo`

**Brewer options**: `Set2`, `Dark2`, `Spectral`, `RdYlBu`, and others

### Parameters

- `scale_value`: Controls ridge overlap (0.85 = compact, 2.25 = expanded)
- `line_height`: Height of mean indicator lines
- `fill_palette`: Color palette for ridges/dots/triangles
- `color_palette`: Color palette for mean lines
- `palette_type`: Either `"viridis"` or `"brewer"`

## Analysis Notes

See `docs/Natal Dispersal and Mass Analysis Notes.md` for detailed analysis methodology and predictions.

## License

[Add your license here]

## Contact

[Add your contact information]

## Citation

[Add citation information if publishing]
