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
│   ├── run_project.R                 # Single entrypoint (run + reports)
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
├── reports/                          # Quarto report sources
├── tests/                            # Test scripts
│   ├── helpers/                      # Helper tests moved from root
│   └── run_all_tests.R               # Test runner
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

### Phase 3: Robustness ✅ Complete
- ✅ Structured error returns
- ✅ Enhanced logging for all operations
- ✅ Defensive checks in plot generation
- ✅ Data quality reporting
- ✅ Artifact registry system
- ✅ Registry-based report integration

### Phase 4: Release Management ✅ Complete
- ✅ Release bundle creation (`create_release_bundle()`)
- ✅ Artifact cleanup utility (`cleanup_old_artifacts()`)
- ✅ Integrated release workflow
- ✅ Documentation and usage examples
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

### 1. Run Complete Analysis
```r
source("R/run_project.R")
# Runs pipeline, generates plots, and renders HTML reports
# Reports available in: results/reports/
```

### 2. Create Release Bundle (Optional)
```bash
# From command line:
Rscript R/run_project.R --bundle

# Or from R console:
source("R/functions/core/coha_release.R")
bundle_path <- create_release_bundle(
  include_raw_data = TRUE,
  include_plots = TRUE,
  include_reports = TRUE,
  include_config = TRUE
)
# Creates: results/releases/coha_release_YYYYMMDD_HHMMSS.zip
```

### 3. Clean Up Old Artifacts
```r
source("R/functions/core/coha_release.R")

# Preview what would be deleted (dry run)
cleanup_old_artifacts(keep_count = 3, dry_run = TRUE)

# Delete old plot files (keeps 3 most recent runs)
cleanup_old_artifacts(keep_count = 3)
```

## Artifact Registry & Release Management

The project uses an artifact registry to track all generated outputs and ensure reproducibility.

### What Gets Tracked

The artifact registry (`R/config/artifact_registry.yaml`) tracks:
- **Raw data**: `data.csv` with SHA256 hash for integrity verification
- **Plot artifacts**: All 20 ridgeline plot PNG files with metadata
- **Plot objects**: RDS cache files for faster report rendering
- **Reports**: Generated HTML reports with dependencies

### Benefits

1. **Reproducibility**: Every output linked to its inputs with timestamps
2. **Report consistency**: Reports always load exactly 20 plots from current run (no accumulation)
3. **Release bundles**: One-command creation of shareable ZIP packages
4. **Disk management**: Cleanup utility prevents plot file accumulation

### Advanced Operations

#### View Registry Contents
```r
library(yaml)
registry <- read_yaml("R/config/artifact_registry.yaml")

# Count artifacts by type
table(sapply(registry$artifacts, function(x) x$type))

# List all ridgeline plots
plot_artifacts <- Filter(function(x) x$type == "ridgeline_plots", registry$artifacts)
names(plot_artifacts)
```

#### Manual Artifact Registration
```r
source("R/functions/core/artifacts.R")

registry <- init_artifact_registry()
registry <- register_artifact(
  registry = registry,
  artifact_name = "my_custom_plot",
  artifact_type = "plot",
  workflow = "custom_analysis",
  file_path = "path/to/plot.png",
  metadata = list(description = "Custom analysis plot")
)
save_registry(registry)
```

#### Release Bundle Contents
When you run `create_release_bundle()`, the ZIP contains:
- `data/data.csv` - Original source data
- `plots/` - All 20 ridgeline plot PNG files
- `reports/` - Rendered HTML reports
- `config/artifact_registry.yaml` - Full provenance tracking
- `manifest.yaml` - Release metadata and summary

## Usage

### Quick Start

See `R/run_project.R` for the single entrypoint script.

### Run Complete Pipeline

Generate all plots at once using the automated pipeline:

```r
source("R/pipeline/pipeline.R")

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

Render the Quarto reports:

```r
quarto::quarto_render("reports/full_analysis_report.qmd", output_dir = "results/reports")
quarto::quarto_render("reports/plot_gallery.qmd", output_dir = "results/reports")
```

Or via terminal:

```bash
quarto render reports/full_analysis_report.qmd --output-dir results/reports
quarto render reports/plot_gallery.qmd --output-dir results/reports
```

Reports are saved to `results/reports/`

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

1. **Edit `R/config/ridgeline_config.R`**: Add a new configuration to the `ridgeline_plot_configs` list

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
source("R/pipeline/pipeline.R")
run_pipeline()
```

3. **Add to report** (optional): Include in `reports/plot_gallery.qmd`

```r
generate_plot("custom_01")
```

## Data Format

The `data/data.csv` file contains:

| Column | Description |
|--------|-------------|
| `mass` | Bird mass in grams |
| `year` | Year of observation |
| `dispersed` | Dispersal status (Unknown, Wisconsin, etc.) |

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

1. **`R/config/ridgeline_config.R`** - Defines all plot specifications in a structured list
2. **`R/functions/plot_function.R`** - Core plotting function (reusable)
3. **`R/pipeline/pipeline.R`** - Orchestrates plot generation from configs
4. **`reports/full_analysis_report.qmd`** - Quarto report references plots by ID

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
