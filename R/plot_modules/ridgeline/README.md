# Ridgeline Plot Module

**Version:** 1.0.0  
**Type:** Plot Module (Plugin)  
**Status:** Production-Ready  

## Overview

The ridgeline plot module is a plugin-based generator for ridgeline density plots. It implements the plot module interface and is discovered/loaded dynamically by the engine.R plugin manager.

## Module Structure

```
ridgeline/
├── module.R                 (Main interface, 600+ lines)
├── ridgeline_generator.R    (Plot generation logic, 150+ lines)
├── palettes.R               (Color utilities, 200+ lines)
└── README.md                (This file)
```

## Quick Start

### Direct Usage (Sourcing)

```r
# Load module directly
source("R/plot_modules/ridgeline/module.R")

# Get available plots
plots <- get_available_plots()
view(plots)

# Generate a single plot
result <- generate_plot(
  data = hawk_data,
  plot_id = "compact_01",
  config = list(
    output_dir = "results/plots",
    verbose = TRUE
  )
)

# Check result
if (result$status == "success") {
  cat("Saved:", result$output_path, "\n")
}
```

### Via Engine (Plugin Discovery)

```r
# Load engine
source("R/core/engine.R")

# Discover and load plugin
engine <- initialize_pipeline()
module <- load_module("ridgeline", "plot")

# Generate plot
result <- generate_plot(
  data = hawk_data,
  plot_id = "regular_02",
  config = list(output_dir = "results/plots")
)
```

## Available Plots

The module provides **9 predefined plot variants**:

### Compact Scale (0.85)
- `compact_01` - Compact + Plasma
- `compact_02` - Compact + Viridis
- `compact_03` - Compact + Magma

### Regular Scale (1.0)
- `regular_01` - Regular + Plasma
- `regular_02` - Regular + Viridis
- `regular_03` - Regular + Magma

### Expanded Scale (1.2)
- `expanded_01` - Expanded + Plasma
- `expanded_02` - Expanded + Viridis
- `expanded_03` - Expanded + Magma

**Scale Definition:**
- **Compact (0.85):** Tight vertical spacing, more compact
- **Regular (1.0):** Standard spacing, balanced
- **Expanded (1.2):** Loose spacing, maximum clarity

## Core Functions

### Required Interface Functions

#### `get_module_metadata()`

Returns module identification and version information.

```r
metadata <- get_module_metadata()
# Returns:
# $name: "ridgeline"
# $type: "plot"
# $version: "1.0.0"
# $description: "Ridgeline plot generator..."
# $author: "Project Team"
# $depends: c("ggplot2", "ggridges", "dplyr", "viridis")
```

#### `get_available_plots()`

Lists all plots this module can generate.

```r
plots <- get_available_plots()
# Returns data frame:
# plot_id          display_name          group    scale palette
# compact_01       Compact + Plasma      compact  0.85  plasma
# compact_02       Compact + Viridis     compact  0.85  viridis
# ...
```

#### `generate_plot(data, plot_id, config = list())`

Generates a single ridgeline plot.

**Parameters:**
- `data` (data.frame): Input data with required columns
- `plot_id` (character): Plot identifier (e.g., "compact_01")
- `config` (list): Execution options
  - `output_dir`: Where to save PNG
  - `dpi`: PNG resolution (default: 300)
  - `width`: PNG width in inches (default: 10)
  - `height`: PNG height in inches (default: 6)
  - `save_file`: Save PNG? (default: TRUE)
  - `verbose`: Print progress? (default: FALSE)

**Returns:** Result object with fields:
```r
result <- list(
  status = "success",           # "success", "partial", or "failed"
  message = "Plot generated...",
  plot_id = "compact_01",
  plot = ggplot_object,         # ggplot object
  output_path = "/path/to/png", # Where saved
  file_size_mb = 2.5,
  generation_time = 1.23,       # Seconds
  quality_score = 95,           # 0-100
  errors = list(),              # Error messages
  warnings = list(),            # Warning messages
  timestamp = Sys.time(),
  data_n = 1000                 # Rows processed
)
```

#### `generate_plots_batch(data, plot_ids = NULL, config = list())`

Generates multiple plots in batch.

```r
# Generate all available plots
results <- generate_plots_batch(
  data = hawk_data,
  plot_ids = NULL,  # NULL = all plots
  config = list(output_dir = "results/plots"),
  continue_on_error = TRUE
)

# Check results
for (plot_id in names(results)) {
  result <- results[[plot_id]]
  cat(sprintf("%s: %s\n", plot_id, result$status))
}
```

### Optional Lifecycle Functions

#### `module_init(config = list())`

Called when module is loaded. Sets up module state.

```r
state <- module_init(list())
# Returns list with:
# $initialized: TRUE
# $timestamp: When initialized
# $state: Module-level state storage
```

#### `module_cleanup()`

Called when module is shutting down. Cleans up resources.

```r
module_cleanup()  # Frees resources
```

## Data Requirements

Input data must be a data frame with at least:

- **generation** (character/factor): Generational grouping (required)
- **mass** (numeric, optional): Object mass in grams

### Data Quality Notes

- Empty data → returns `status="failed"`
- Missing `generation` → returns `status="failed"`
- Mass values are filtered to range (0, 10000]
- NAs are automatically removed
- Minimum 1 row required after cleaning

## Color Palettes

The module uses viridis perceptually-uniform palettes:

- **plasma** - High contrast, distinct hues
- **viridis** - Perceptually-uniform, print-friendly
- **magma** - Muted, colorblind-friendly
- **inferno** - High contrast alternative
- **cividis** - Optimized for colorblind readers

Access palette utilities via `palettes.R`:

```r
# List available palettes
palettes <- list_available_palettes()

# Get colors from palette
colors <- get_palette_colors(
  palette_name = "plasma",
  n = 10,           # Number of colors
  reverse = FALSE   # Reverse order?
)

# Preview palette
preview_plot <- preview_palette("viridis", n = 20)
ggsave("palette_preview.png", preview_plot)

# Get palette metadata
info <- get_palette_info("plasma")
```

## Error Handling

The module uses structured error handling. Errors don't stop execution:

```r
result <- generate_plot(bad_data, "compact_01", config)

if (result$status == "success") {
  # Use result$plot and result$output_path
} else if (result$status == "partial") {
  # Plot generated but not saved
  # Use result$plot, check warnings
} else {
  # result$status == "failed"
  # Check result$errors for details
  for (error in result$errors) {
    warning(error)
  }
}
```

## Quality Scoring

Each result includes a quality score (0-100):

- **100:** Perfect (plot generated + saved)
- **80+:** Good (plot generated, minor issues)
- **50-79:** Partial (plot generated, not saved)
- **1-49:** Problematic (errors or warnings)
- **0:** Failed (no plot generated)

Quality calculation:
- Base: 100 points
- -10 per error
- -5 per warning
- -20 if not saved (status="partial")
- = 0 if failed

## Performance

Typical performance on COHA dataset (1000+ rows):

- Single plot generation: 0.5-2 seconds
- Batch (9 plots): 5-15 seconds
- PNG save: 0.1-0.3 seconds per plot
- Memory: ~50-100 MB per plot object

## Integration with Pipeline

The module is automatically discovered by engine.R:

```r
# In pipeline.R
discovered <- discover_modules(
  base_dir = "R/plot_modules",
  type = "plot"
)
# Returns: list(ridgeline = "R/plot_modules/ridgeline/module.R", ...)

# Validate interface
plot_module <- load_module("ridgeline", "plot")
is_valid <- validate_module_interface(plot_module, "plot")
# TRUE if has required functions

# Register with engine
register_module("ridgeline", plot_module, "plot")
# Now available via engine
```

## Examples

### Example 1: Single Plot Generation

```r
source("R/plot_modules/ridgeline/module.R")

# Load data
hawks <- read.csv("data/hawk_data.csv")

# Generate plot
result <- generate_plot(
  data = hawks,
  plot_id = "compact_01",
  config = list(
    output_dir = "results/plots/ridgeline",
    dpi = 300,
    verbose = TRUE
  )
)

# Check result
cat(sprintf("Status: %s\nFile: %s\nSize: %.2f MB\n",
            result$status,
            result$output_path,
            result$file_size_mb))
```

### Example 2: Batch Processing All Variants

```r
# Generate all 9 variants
results <- generate_plots_batch(
  data = hawks,
  plot_ids = NULL,  # Generate all
  config = list(
    output_dir = "results/plots/ridgeline/batch_2026",
    dpi = 150,  # Lower DPI for speed
    verbose = TRUE
  )
)

# Summary
passed <- sum(sapply(results, function(r) r$status == "success"))
cat(sprintf("Generated %d / 9 plots\n", passed))

# Check quality scores
scores <- sapply(results, function(r) r$quality_score)
cat(sprintf("Average quality: %.1f\n", mean(scores)))
```

### Example 3: Error Handling

```r
result <- generate_plot(
  data = data.frame(),  # Empty data
  plot_id = "compact_01",
  config = list()
)

if (result$status == "failed") {
  cat("Plot generation failed:\n")
  for (error in result$errors) {
    cat(sprintf("  - %s\n", error))
  }
}
```

## Dependencies

**Required R Packages:**
- `ggplot2` - Plot creation
- `ggridges` - Ridgeline geom
- `dplyr` - Data manipulation
- `viridis` - Color palettes
- `here` - Path management

All are typically installed as part of tidyverse ecosystem.

## Troubleshooting

### "generation column missing"
Ensure data has a `generation` column (factor or character).

### "No valid data after removing NAs"
Data may have all NAs in mass column. Check data quality first.

### "Plot is blank"
Likely missing required grouping column or all-NA values.

### "PNG save failed but plot generated"
Check output directory permissions and disk space. Result will have `status="partial"`.

## Future Enhancements

Planned improvements:
- [ ] Support additional data columns (e.g., species, sex)
- [ ] Themeing system for customization
- [ ] Annotation utilities (mean lines, arrows, etc.)
- [ ] Export formats beyond PNG (PDF, SVG)
- [ ] Interactive Shiny dashboard

## References

- **Viridis Palettes:** https://cran.r-project.org/package=viridis
- **ggridges:** https://cran.r-project.org/package=ggridges
- **ggplot2:** https://cran.r-project.org/package=ggplot2

## Contact & Support

For issues or questions:
1. Check troubleshooting section above
2. Review error messages in result$errors
3. Enable verbose=TRUE in config for debug output
