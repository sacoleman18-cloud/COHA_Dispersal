# PIPELINE_GUIDE.md
**A Comprehensive Guide to the COHA Dispersal Analysis Pipeline**

---

## Quick Start

### 1. **Load the Pipeline**
```r
source(here::here("R", "pipeline", "pipeline.R"))
```

### 2. **Run the Complete Analysis**
```r
result <- run_pipeline(verbose = TRUE)
```

### 3. **Check Output**
```r
# View generated plots
list.files(here::here("results", "plots", "ridgeline", "variants"))

# View log file
show_log( 50)  # Last 50 lines

# View results
result$plots_generated    # Number of plots created
result$output_dir         # Where plots are saved
result$timestamp          # When it ran
result$duration_seconds   # How long it took
```

---

## Understanding the Pipeline Execution

### Pipeline Phases

The pipeline executes in 3 main phases:

#### **Phase 1: Load & Validate Data**
```
Initialize logging → Load YAML config → Read CSV data → Validate schema
```
- Creates log file in `logs/pipeline_YYYY-MM-DD.log`
- Loads configuration from `inst/config/study_parameters.yaml`
- Reads raw data from `data/data.csv`
- Validates columns: mass, year, dispersed, origin
- Validates data types and checks for missing values

**Output:** Validated data frame ready for plotting

#### **Phase 2: Generate Ridgeline Plots**
```
Load plot configurations → For each enabled plot type:
  For each variant: Generate plot → Save to disk → Log result
```
- Loads 20 ridgeline plot specifications from `R/config/ridgeline_config.R`
- For each plot:
  - Applies plot configuration (scale, palette, etc.)
  - Creates ggplot with ggridges geom
  - Saves PNG to output directory
  - Logs completion with timestamp

**Output:** 20 PNG files in `results/plots/ridgeline/variants/`

#### **Phase 3: Finalize & Report**
```
Compile statistics → Create completion summary → Log success → Return results
```
- Counts total plots generated
- Records execution time
- Prints completion message to console
- Returns structured results object

**Output:** Completion message + structured return value

### Console Output Example

When you run the pipeline with `verbose = TRUE`, you'll see:

```
+-------------------------------------------------------------------+
|             STAGE 1: Load & Validate Data                         |
+-------------------------------------------------------------------+

[CONFIG] Loading from /path/to/project/inst/config/study_parameters.yaml
[CONFIG] ✓ YAML parsed successfully
[VALIDATE] ✓ Input is data frame
[VALIDATE] ✓ All required columns present
[VALIDATE] ✓ Data contains 847 rows
[VALIDATE] ✓ Column types correct
[VALIDATE] ✓ Ridgeline data validation complete

+-------------------------------------------------------------------+
|             STAGE 2: Generate Ridgeline Plots                     |
+-------------------------------------------------------------------+

[INFO] [START] Generating compact_01 (plasma palette)
[COMPLETE] Generated compact_01 (847 observations, scale 0.85)
[INFO] [START] Generating compact_02 (viridis palette)
[COMPLETE] Generated compact_02 (847 observations, scale 0.85)
... (18 more plots) ...

===================================================================
✓ PIPELINE COMPLETE
  Plots generated: 20
  Output directory: results/plots/ridgeline/variants/
  Time elapsed: 45.2 seconds
  Status: success
===================================================================
```

---

## Configuration System

### Overview

All pipeline behavior configured via `inst/config/study_parameters.yaml`:

```yaml
project:
  name: "COHA Dispersal Analysis"
  version: "1.0.0"

data:
  source_file: "data/data.csv"
  required_columns:
    - mass
    - year
    - dispersed
    - origin

plot_types:
  ridgeline:
    enabled: true
    variants: 20          # 10 compact + 10 expanded
  boxplot:
    enabled: false        # Disabled for future use

defaults:
  verbose: false
  dpi: 300              # Plot resolution
```

### Customizing Behavior

#### **Change Data Source**
Edit `inst/config/study_parameters.yaml`:
```yaml
data:
  source_file: "data/custom_data.csv"   # Change this line
```

#### **Adjust Plot Output Settings**
```yaml
defaults:
  dpi: 600              # Higher resolution
  save_plots: true      # Must be true to save
```

#### **Enable/Disable Plot Types**
```yaml
plot_types:
  ridgeline:
    enabled: true       # Generate ridgeline plots
  boxplot:
    enabled: false      # Skip boxplot generation (add later)
```

#### **Change Output Paths**
```yaml
paths:
  plots_base: "results/plots"      # Where plots go
  logs_dir: "logs"                  # Where logs go
  reports_base: "results/reports"   # Where reports go
```

### Loading Configuration in Code

```r
# Load configuration
config <- load_study_config(verbose = TRUE)

# Access nested values
source_file <- config$data$source_file
dpi <- config$defaults$dpi
enabled_types <- get_enabled_plot_types(config)

# Validate paths exist (creates if missing)
validate_config_paths(config, create = TRUE, verbose = TRUE)

# Print summary to console
print_config_summary(config)
```

---

## Output Structure

### Directory Layout After Running Pipeline

```
project_root/
├── data/
│   └── data.csv                                    (input)
├── inst/config/
│   └── study_parameters.yaml                       (configuration)
├── logs/
│   └── pipeline_2026-02-10.log                     (audit trail)
├── results/
│   └── plots/
│       └── ridgeline/
│           └── variants/
│               ├── compact_01_<timestamp>.png     (output: scale 0.85, plasma)
│               ├── compact_02_<timestamp>.png     (output: scale 0.85, viridis)
│               ├── compact_03_<timestamp>.png     (output: scale 0.85, magma)
│               ├── ... (10 compact variants)
│               ├── expanded_01_<timestamp>.png    (output: scale 2.25, plasma)
│               ├── expanded_02_<timestamp>.png    (output: scale 2.25, viridis)
│               ├── ... (10 expanded variants)
│               └── manifest.json                  (plot metadata)
└── R/
    ├── functions/                                 (all utility modules)
    ├── pipeline/
    │   └── pipeline.R                             (main orchestrator)
    └── config/
        └── ridgeline_config.R                     (plot specifications)
```

### Log File Format

File: `logs/pipeline_YYYY-MM-DD.log`

```
[2026-02-10 14:30:45] [INFO] Pipeline initialized
[2026-02-10 14:30:45] [INFO] [START] Loading data
[2026-02-10 14:30:46] [INFO] [COMPLETE] Loading data (847 rows)
[2026-02-10 14:30:46] [INFO] [START] Generating plots
[2026-02-10 14:30:47] [DEBUG] Generating compact_01 (plasma)
[2026-02-10 14:30:47] [INFO] [COMPLETE] compact_01 (847 observations)
[2026-02-10 14:30:48] [DEBUG] Generating compact_02 (viridis)
[2026-02-10 14:30:48] [INFO] [COMPLETE] compact_02 (847 observations)
... (continue for all 20 plots) ...
[2026-02-10 14:31:32] [INFO] Pipeline complete: 20 plots, 47.3 seconds
```

### Return Value (result)

The `run_pipeline()` function returns a structured list:

```r
result <- run_pipeline(verbose = TRUE)

# Examine results
result$status                 # "success" or "failed"
result$plots_generated        # Integer: 20
result$output_dir             # Character: "results/plots/ridgeline/variants/"
result$timestamp              # POSIXct: when pipeline ran
result$duration_seconds       # Numeric: 47.3 seconds
result$log_file               # Character: path to log file
result$errors                 # Character vector: errors if status="failed"
```

---

## Error Handling

### Understanding Errors

#### **Missing Data File**
```
Error: File not found: /path/to/data/data.csv (source data)
```
**Solution:** Ensure data exists at path specified in YAML config

#### **Missing Required Column**
```
Error: Missing columns: mass (ridgeline data)
```
**Solution:** Check CSV has required columns: mass, year, dispersed, origin

#### **Missing Configuration**
```
Error: Columns missing NA values
```
**Solution:** Check for empty cells in data; use `convert_empty_to_na()` if needed

#### **No Plots Generated**
```
Warning: No plot types enabled in configuration
```
**Solution:** Check YAML - set `plot_types.ridgeline.enabled: true`

### Troubleshooting With Verbose Output

Enable verbosity for detailed logging:

```r
# Maximum detail
result <- run_pipeline(verbose = TRUE)

# Shows:
# - Which files are being loaded
# - Data validation checks passing
# - Each plot being generated
# - Final summary with timing

# Also check log file
show_log()  # Display last 50 lines of log
show_log(100)  # Last 100 lines
show_log(NULL) # All lines
```

### Recovering from Failures

If pipeline stops mid-execution:

1. **Check the log file** for error message
2. **Fix the issue** (missing file, bad data, etc.)
3. **Add @details to understand why** function failed
4. **Re-run pipeline** - idempotent, safe to restart

---

## Extending the Pipeline

### Adding a New Plot Type (Box-Whisker Example)

To add box-whisker plots alongside ridgeline plots:

#### Step 1: Create Configuration File
Create `R/config/boxplot_config.R`:
```r
# All boxplot specifications
boxplot_plot_configs <- list(
  bw_compact_01 = list(
    plot_id = "bw_compact_01",
    title = "Mass by Year (Compact)",
    # ... other settings
  )
  # ... more variants
)
```

#### Step 2: Create Generation Function
Create `R/functions/boxplot_generation.R`:
```r
generate_boxplot_plot <- function(df, config, verbose = FALSE) {
  # Implementation...
}
```

#### Step 3: Enable in YAML
Edit `inst/config/study_parameters.yaml`:
```yaml
plot_types:
  ridgeline:
    enabled: true
  boxplot:
    enabled: true      # Now enabled
```

#### Step 4: No Pipeline Changes Needed!
The generic `run_pipeline()` automatically detects enabled plot types and generates them all.

**Design Philosophy:** Pipeline is agnostic to plot type. Add new types by:
- Adding config file
- Adding generation function  
- Enabling in YAML

No changes to `pipeline.R` required!

---

## Advanced Usage

### Custom Plot Parameters

Modify plot specifications in `R/config/ridgeline_config.R`:

```r
ridgeline_plot_configs$compact_01$scale <- 1.0   # Change size
ridgeline_plot_configs$compact_01$fill <- "plasma"  # Change palette
ridgeline_plot_configs$compact_01$alpha <- 0.7   # Change transparency
```

Then re-run pipeline.

### Scripting Pipeline Runs

```r
# Automate multiple configurations
for (palette in c("plasma", "viridis", "magma")) {
  # Modify config in memory
  config <- load_study_config()
  config$defaults$palette <- palette
  
  # Run pipeline
  result <- run_pipeline(
    data_path = here::here("data", "data.csv"),
    configs = config,
    verbose = TRUE
  )
  
  # Check results
  if (result$status == "success") {
    message(sprintf("Generated %d plots with %s", 
                   result$plots_generated, palette))
  }
}
```

### Checking Pipeline Success

```r
result <- run_pipeline()

# Method 1: Check status field
if (result$status == "success") {
  message("Pipeline completed successfully")
} else {
  message("Pipeline failed with errors:")
  print(result$errors)
}

#Method 2: Check plot count
if (result$plots_generated == 20) {
  message("All plots generated")
} else {
  warning(paste("Expected 20 plots but got", result$plots_generated))
}

# Method 3: Check timing
execution_time <- result$duration_seconds
if (execution_time > 120) {
  warning("Pipeline took longer than expected")
}
```

---

## Performance Tips

### Speed Up Pipeline

1. **Reduce verbose output** (logging overhead)
   ```r
   result <- run_pipeline(verbose = FALSE)  # Silent mode
   ```

2. **Use parallel execution** (future work)
   - Current: Serial plot generation
   - Future: Generate plots in parallel for 5-10x speedup

3. **Cache data** (if using same data repeatedly)
   ```r
   df <- safe_read_csv("data/data.csv")
   # Re-use df in multiple pipeline runs
   ```

### Memory Usage

Each plot ~2-3 MB (PNG at 300 DPI). With 20 plots:
- ~50-60 MB for all variants
- ~10 MB for data + config + logs
- **Total: ~70-80 MB during execution**

---

## FAQ

### Q: Where do my plots go?
**A:** Check `results/plots/ridgeline/variants/` (or path in YAML config)

### Q: How do I see what happened?
**A:** Check log: `show_log()` shows last 50 lines, `show_log(NULL)` shows all

### Q: Can I change how plots look?
**A:** Yes! Edit configurations in `R/config/ridgeline_config.R` or YAML

### Q: What if pipeline stops halfway?
**A:** Check error in log, fix issue, re-run. Pipeline is idempotent.

### Q: How long does it take?
**A:** ~45-60 seconds for 20 plots (depends on data size and machine)

### Q: Can I use different data?
**A:** Yes! Change `data.source_file` in YAML and re-run

### Q: How do I add new plot types?
**A:** See "Extending the Pipeline" section above

### Q: Is the pipeline reproducible?
**A:** Yes! Uses `here::here()` for paths, seeds for randomness, YAML for config

---

## Document History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-10 | 1.0.0 | Initial Phase 2 pipeline guide |

---

**For detailed function documentation, see:**
- `?run_pipeline` - Main orchestrator
- `?load_study_config` - Configuration loading
- `?validate_ridgeline_data` - Data validation
- `show_log()` - View pipeline logs
