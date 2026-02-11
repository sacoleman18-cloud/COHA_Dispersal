# ===================================================================================
# COHA DISPERSAL ANALYSIS: PROJECT STANDARDS
# ===================================================================================
# VERSION: 1.0
# LAST UPDATED: 2026-02-10
# PURPOSE: Master standards for publication-ready ridgeline analysis
# ===================================================================================

## PROJECT VISION

Generate publication-ready multi-plot analyses across different visualization types:
- **Ridgeline plots** (original 20 + variants)
- **Box and whisker + jitter** (future)
- **Additional plot types** (TBD)

Each plot type gets its own comprehensive Quarto report showcasing:
- All variants (different scales, palettes, aesthetics)
- Methodology explanation
- Visual comparisons
- Team decision framework for final style selection

---

## 1. PIPELINE DETERMINISM GUARANTEES

All phases must be **deterministic**: Same inputs → Same outputs, every time.

### Rules:
- ✅ Configuration stored in `inst/config/study_parameters.yaml`
- ✅ No interactive prompts or user decisions during execution
- ✅ All randomness controlled (set seed if needed)
- ✅ All paths relative (use `here::here()`)
- ✅ No global environment modification
- ✅ Every function returns explicit values or invisibly(TRUE)

### Validation:
```r
# Test determinism
result1 <- run_pipeline()
result2 <- run_pipeline()
# result1 should == result2
```

---

## 2. PUBLICATION-READY OUTPUT STANDARDS

### Plot Quality Requirements
- **DPI:** 300 (publication standard)
- **Format:** PNG + SVG (vector for papers)
- **Color:** Colorblind-friendly palettes
- **Font:** Clear, readable at 5pt minimum
- **Legends:** Integrated, not separate
- **Data:** All axis labels included, units specified

### File Organization
```
results/
├── plots/
│   ├── ridgeline/
│   │   ├── variants/
│   │   │   ├── 01_compact_plasma.png
│   │   │   ├── 02_compact_viridis.png
│   │   │   └── ...
│   │   └── final/
│   │       └── ridgeline_analysis_final.png
│   ├── boxplot/
│   │   ├── variants/
│   │   └── final/
│   └── [future_plot_types]/
├── reports/
│   ├── ridgeline_comprehensive.html
│   ├── boxplot_comprehensive.html
│   └── [future_reports]/
└── data/
    └── processed/
        └── [generated datasets]
```

---

## 3. REPORT STRUCTURE STANDARDS

Each plot type gets a **comprehensive report** with structure:

```
1. Executive Summary
   - What question answered
   - Key findings
   
2. Plot Type Overview
   - Use case and interpretation
   - Data requirements
   
3. Gallery Section
   Section 3.1: Compact Plots (Scale 0.85)
   - 10 variants side-by-side
   - Palette descriptions
   
   Section 3.2: Expanded Plots (Scale 2.25)
   - 10 variants side-by-side
   - Palette descriptions
   
4. Technical Appendix
   - Data schema
   - Methods
   - Configuration used
   
5. Decision Framework
   - Table: Palette vs. Use Case
   - Recommendation for publication
```

---

## 4. CONFIGURATION HIERARCHY

### Level 1: Global (inst/config/study_parameters.yaml)
```yaml
pipeline:
  name: "COHA Dispersal Analysis"
  
report:
  generate_variants: true    # Generate all 20 variants?
  generate_report: true      # Generate comprehensive report?
  
plot_types:
  ridgeline:
    enabled: true
    num_variants: 20
  boxplot:
    enabled: false  # Add when ready
```

### Level 2: Plot Type (R/config/[plot_type]_config.R)
```r
# R/config/ridgeline_config.R
ridgeline_plot_configs <- list(
  # ... all 20 configs
)
```

### Level 3: Individual Plot
```r
list(
  id = "compact_01",
  name = "Compact: Plasma & Inferno",
  scale_value = 0.85,
  plot_type = "ridgeline"
)
```

---

## 5. FUNCTION ARCHITECTURE

### Naming Convention: [action]_[plot_type]_[scope]

```
create_ridgeline_plot()        # Single plot
generate_ridgeline_variants()  # All variants
render_ridgeline_report()      # Full report
```

### Function Layers

**Layer 1: Core Plotting**
- `create_ridgeline_plot(data, config, verbose = FALSE)`
- Lowest level, pure function, returns ggplot object

**Layer 2: Batch Generation**
- `generate_ridgeline_variants(data, configs, save = TRUE, verbose = FALSE)`
- Generates all plots from config list
- Returns list of plot objects + metadata

**Layer 3: Reporting**
- `render_ridgeline_report(data, configs, output_path, verbose = FALSE)`
- Generates comprehensive Quarto report
- Calls Layer 2 internally

**Layer 4: Pipeline Orchestration**
- `run_pipeline(config, verbose = FALSE)`
- Coordinates all phases
- Returns structured result

---

## 6. DATA FLOW DIAGRAM

```
data/data.csv
    ↓
[Phase 1: Load & Validate]
    ├─ Load CSV
    ├─ Validate schema
    └─ Return tibble
    ↓
[Phase 2: Generate Variants]
    ├─ For each plot_type in config:
    │   ├─ Create plots folder structure
    │   ├─ Generate all variants (generate_[type]_variants)
    │   └─ Save to results/plots/[type]/variants/
    └─ Collect all completed types
    ↓
[Phase 3: Create Reports]
    ├─ For each plot_type:
    │   ├─ Generate comprehensive Quarto
    │   └─ Render to HTML
    └─ Save to results/reports/
    ↓
[Phase 4: Validation & Return]
    ├─ Verify all outputs exist
    ├─ Generate manifest
    └─ Return structured summary
```

---

## 7. LOGGING STANDARDS

### What to Always Log
```
[START] Pipeline initialization
[LOAD] Data source: path, rows, columns
[VALIDATE] Schema check: pass/fail
[GENERATE] Plot type: 20 variants starting
[SAVE] Each plot: ID, path, dimensions
[RENDER] Report generation: start/success
[COMPLETE] Pipeline summary: total time, outputs
```

### Log File Location
- `logs/pipeline_YYYY-MM-DD.log`
- Append mode (accumulate through day)
- Timestamp each entry: `[HH:MM:SS]`

---

## 8. ERROR HANDLING STANDARDS

### Defensive Checks (Entry Point)
```r
validate_data <- function(df) {
  assert_is_dataframe(df)
  assert_columns_exist(df, c("mass", "year", "dispsersed"))
  assert_not_empty(df)
  invisible(TRUE)
}
```

### Error Messages (User-Friendly)
```
✗ BAD: "Column missing"
✓ GOOD: "Column 'mass' required but not found in data"

✗ BAD: "NA detected"
✓ GOOD: "Found 5 NA values in 'mass' column. Use na.omit() or investigate"
```

### Recovery Strategy
- Never stop mid-pipeline (batch continue with logging)
- Always save partial results
- Return summary of what succeeded/failed

---

## 9. CODE STYLE CHECKLIST

Before committing, verify:

- [ ] All paths use `here::here()`
- [ ] All functions have `verbose = FALSE` parameter
- [ ] All functions have Roxygen2 `@export`, `@param`, `@return`
- [ ] All functions < 50 lines (ideal < 30)
- [ ] All loops have logging statements
- [ ] No `print()` statements (use `message()` if verbose)
- [ ] No global variables created
- [ ] No hardcoded values (use config)
- [ ] File header present with PURPOSE, INPUTS, OUTPUTS
- [ ] Comments explain WHY, not WHAT

---

## 10. PUBLICATION-READY CHECKLIST

Before finalizing plot:

- [ ] All axes labeled with units
- [ ] Legend clear and integrated
- [ ] DPI = 300 for raster
- [ ] Font size ≥ 5pt at publication size
- [ ] Colorblind friendly (test with Okabe-Ito palette)
- [ ] Data source documented
- [ ] Method documented in report
- [ ] Uncertainty shown (if applicable)
- [ ] No suspicious outliers without annotation
- [ ] Matches journal style guide

---

## 11. TESTING & VALIDATION

### Unit Test Level
- ✅ `create_ridgeline_plot(test_data)` returns ggplot
- ✅ `validate_data(bad_data)` throws appropriate error
- ✅ `generate_ridgeline_variants(data, 20_configs)` returns list of 20

### Integration Test Level
- ✅ `run_pipeline()` creates all outputs
- ✅ All PNG files have correct dimensions
- ✅ Log file contains all expected entries
- ✅ Report HTML renders without errors

### Determinism Test
- ✅ Run pipeline twice, get identical results
- ✅ Same file sizes and modified times
- ✅ Same plot contents (visual inspection)

---

## 12. DOCUMENTATION STANDARDS

### File Header Template
```r
# ==============================================================================
# R/[category]/[file].R
# ==============================================================================
# PURPOSE
# -------
# [One paragraph description]
#
# DEPENDS ON
# ----------
# - R/functions/[dependency].R
# - inst/config/[config].yaml
#
# INPUTS
# ------
# - [Source]: [Description]
#
# OUTPUTS
# -------
# - [Output]: [Description]
#
# USAGE
# -----
# source("R/[path]/[file].R")
# result <- my_function(data, verbose = TRUE)
#
# ==============================================================================
```

### Roxygen2 Template
```r
#' [Function Title]
#'
#' @description
#' [Detailed description of what function does]
#'
#' @param data Data frame. Must contain columns: mass, year, dispsersed.
#' @param verbose Logical. Print progress messages. Default: FALSE.
#'
#' @return [Describe return value structure]
#'
#' @examples
#' data <- read.csv(here::here("data", "data.csv"))
#' result <- my_function(data, verbose = TRUE)
#'
#' @export
my_function <- function(data, verbose = FALSE) { ... }
```

---

## 13. DEPLOYMENT CHECKLIST

### Before Release Package:
- [ ] All tests pass
- [ ] Determinism verified (run 3x)
- [ ] README updated with new structure
- [ ] PIPELINE_GUIDE.md written
- [ ] examples.R updated
- [ ] No TODO comments remaining
- [ ] Git history clean with conventional commits
- [ ] CHANGELOG updated

---

## 14. FUTURE-PROOFING

### Adding New Plot Type (e.g., Boxplot)

1. Create plot config: `R/config/boxplot_config.R`
2. Create generation function: `R/functions/boxplot_generation.R`
   - `create_boxplot_plot()`
   - `generate_boxplot_variants()`
   - `render_boxplot_report()`
3. Update `inst/config/study_parameters.yaml` to enable boxplot
4. No changes needed to pipeline orchestrator (generic by plot_type loop)
5. Quarto report auto-renders from config

---

## 15. REPOSITORY STRUCTURE (FINAL)

```
COHA_Dispersal/
├── R/
│   ├── pipeline.R                    # Main orchestrator
│   ├── config.R                      # DEPRECATED: Move configs to config/
│   ├── config/
│   │   ├── ridgeline_config.R        # All 20 ridgeline configs
│   │   └── [future_plot_configs]/
│   ├── functions/
│   │   ├── assertions.R              # Validation functions
│   │   ├── logging.R                 # File logging
│   │   ├── config_loader.R           # Load YAML config
│   │   ├── ridgeline_generation.R    # create_, generate_, render_
│   │   └── [future_plot_functions]/
│   └── DEPRECATED/
│       ├── ridgeline_plot.R
│       └── plot_function.R
├── inst/
│   ├── config/
│   │   └── study_parameters.yaml
│   └── reports/
│       ├── ridgeline_comprehensive.qmd
│       └── [future_reports]/
├── data/
│   └── data.csv
├── results/
│   ├── plots/
│   │   ├── ridgeline/
│   │   │   ├── variants/
│   │   │   │   ├── 01_compact_plasma.png
│   │   │   │   └── ...
│   │   │   └── final/
│   │   │       └── ridgeline_analysis_final.png
│   │   └── [future_plot_types]/
│   ├── reports/
│   │   ├── ridgeline_comprehensive.html
│   │   └── [future_reports]/
│   └── data/
│       └── processed/
├── docs/
│   ├── COHA_PROJECT_STANDARDS.md     # THIS FILE
│   ├── PIPELINE_GUIDE.md             # How to run
│   └── ARCHITECTURE.md               # Detailed architecture
├── logs/
│   └── pipeline_YYYY-MM-DD.log
├── examples.R
├── .gitignore
├── README.md
└── CHANGELOG.md
```

---

## SUMMARY

This standards document ensures:
1. ✅ **Publication-Ready Outputs** - DPI, format, quality standards
2. ✅ **Scalable Architecture** - Generic pipeline handles all plot types
3. ✅ **Deterministic Execution** - Same inputs, same outputs
4. ✅ **Comprehensive Reports** - All variants compared in one place
5. ✅ **Maintainability** - Clear standards for code and documentation
6. ✅ **Team Collaboration** - Framework for style decisions

Use this document as reference while implementing the 4 phases.
