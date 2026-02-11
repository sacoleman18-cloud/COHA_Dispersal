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
│   ├── functions/                    # Utility modules (Phase 1)
│   │   ├── assertions.R              # 12 input validation functions
│   │   ├── logging.R                 # 8 file/console logging functions
│   │   ├── utilities.R               # 5 core utilities with safe I/O
│   │   ├── console.R                 # 4 format console output functions
│   │   ├── config_loader.R           # 6 YAML configuration functions
│   │   └── plot_function.R           # Ridgeline plot generation
│   ├── config/
│   │   └── ridgeline_config.R        # 20 ridgeline plot specifications
│   ├── pipeline/
│   │   └── pipeline.R                # Main pipeline orchestrator
│   └── [legacy scripts if any]
├── inst/
│   └── config/
│       └── study_parameters.yaml     # Project configuration (single source of truth)
├── data/
│   └── data.csv                      # Raw dispersal and mass data (847 records)
├── logs/
│   └── pipeline_YYYY-MM-DD.log      # Audit trail (auto-created)
├── results/
│   └── plots/ridgeline/variants/     # Generated plot images
├── docs/
│   ├── README.md                     # This file
│   ├── COHA_PROJECT_STANDARDS.md     # Master standards document (Phase 1)
│   ├── PHASE_1_FOUNDATION_STANDARDS.md  # Phase 1 implementation guide
│   ├── PHASE_2_DOCUMENTATION_STANDARDS.md  # Phase 2 documentation guide
│   ├── REFERENCE_CODE_INTEGRATION_PLAN.md  # Reference code analysis
│   ├── STANDARDS_ADOPTION_AUDIT.md   # KPro standards audit (45 applicable)
│   ├── PIPELINE_GUIDE.md             # Complete usage guide (Phase 2)
│   └── Natal Dispersal and Mass Analysis Notes.md
├── .gitignore
├── COHA_Dispersal.Rproj
└── README.md                         # This file
```

## Phase Status

### Phase 1: Foundation ✅ Complete
- ✅ Comprehensive assertions module (12 functions)
- ✅ File/console logging system (8 functions)
- ✅ Safe I/O utilities (5 functions)
- ✅ Console formatting (4 functions)
- ✅ YAML configuration system (6 functions)
- ✅ Pipeline orchestrator with professional output
- ✅ 20 ridgeline plot specifications
- ✅ Standards documents (3 files)

### Phase 2: Documentation ✅ Complete
- ✅ Comprehensive Roxygen2 documentation (39+ functions)
- ✅ File headers with PURPOSE, DEPENDS ON, INPUTS, OUTPUTS, USAGE, CHANGELOG
- ✅ PHASE_2_DOCUMENTATION_STANDARDS.md
- ✅ PIPELINE_GUIDE.md (comprehensive usage guide)
- ⏳ Package documentation generation (roxygen2::roxygenise)

### Phase 3: Robustness (Pending)
- Structured error returns
- Enhanced logging for all operations
- Defensive checks in plot generation
- Data quality reporting

### Phase 4: Polish (Pending)
- E2E testing across all 20 plots
- Examples gallery
- Code cleanup and optimization
- GitHub release preparation
```

## Requirements

### R Packages

```r
install.packages(c(
  "tidyverse", "ggplot2", "ggridges", # Visualization
  "yaml", "readr",                     # Configuration and I/O
  "here"                               # Path management
))
```

### Software

- R (≥ 4.0)
- RStudio (recommended)
- Quarto (optional, for reports)

## Quick Start

### 1. Load Pipeline
```r
source(here::here("R", "pipeline", "pipeline.R"))
```

### 2. Run Complete Analysis
```r
# Generates all 20 ridgeline plots with status output
result <- run_pipeline(verbose = TRUE)
```

### 3. Check Results
```r
# View plots
list.files(here::here("results", "plots", "ridgeline", "variants"))

# View log file
show_log()  # Last 50 lines

# Check execution summary
result$plots_generated      # 20
result$duration_seconds     # ~45-60 seconds
result$status               # "success"
```

## Usage

### Quick Start

See `examples.R` for detailed usage examples:

```r
source("examples.R")
```

### Run Complete Pipeline

Generate all plots at once using the automated pipeline:

```r
source("R/pipeline.R")

# Run pipeline (generates all 20 plots)
plots <- run_pipeline()

# List available plots
list_plots()

# Generate a specific plot by ID
p <- generate_plot("compact_01")
print(p)
```

### Pipeline Functions

**`run_pipeline()`** - Main function to generate all plots
- `data_path`: Path to data CSV (default: "data/data.csv")
- `output_dir`: Output directory (default: "results/png")
- `configs`: Plot configurations (default: from config.R)
- `save_plots`: Whether to save plots (default: TRUE)
- `verbose`: Print progress messages (default: TRUE)

**`generate_plot(plot_id)`** - Generate a single plot by ID

**`list_plots()`** - List all available plot configurations

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

For custom plots beyond the configured set:

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

## Adding New Plots

To add a new plot to the pipeline:

1. **Edit `R/config.R`**: Add a new configuration to the `plot_configs` list

```r
list(
  id = "custom_01",
  name = "My Custom Plot",
  scale_value = 1.5,
  line_height = 0.9,
  fill_palette = "plasma",
  color_palette = "plasma",
  palette_type = "viridis"
)
```

2. **Run the pipeline**: Your new plot will be automatically generated

```r
source("R/pipeline.R")
run_pipeline()
```

3. **Add to report** (optional): Include in `inst/ridgeline_report.qmd`

```r
generate_plot("custom_01")
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

### Pipeline Architecture

The analysis uses a modular pipeline architecture:

1. **`R/config.R`** - Defines all plot specifications in a structured list
2. **`R/plot_function.R`** - Core plotting function (reusable)
3. **`R/pipeline.R`** - Orchestrates plot generation from configs
4. **`inst/ridgeline_report.qmd`** - Quarto report references plots by ID

This design allows you to:
- Add new plots by editing only `config.R`
- Reuse the plot function for ad-hoc analysis
- Generate all plots with a single command
- Maintain consistency across all outputs

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
