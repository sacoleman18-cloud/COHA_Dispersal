# Modular Pipeline Architecture Specification
**Version:** 2.0  
**Date:** February 12, 2026  
**Status:** Design Phase  
**Project:** COHA Dispersal Analysis → Universal Plot Generation Pipeline

---

## Executive Summary

Transform the current COHA-specific pipeline into a **universal, modular plot generation engine** with three distinct architectural layers:

1. **Core Engine** - Universal orchestration, data I/O, artifact tracking, report generation
2. **Plot Type Modules** - Reusable plot generators (ridgeline, boxplot, etc.)
3. **Domain Modules** - Analysis-specific configurations (COHA dispersal, future analyses)

**Key Benefit:** Add new plot types OR new analyses by creating small, focused modules without touching core code.

---

## Current vs. Target Architecture

### Current State (Monolithic)
```
R/pipeline/pipeline.R
├── Hard-coded for COHA dispersal only
├── Ridgeline logic embedded in pipeline
├── Manual report updates when adding plots
└── Cannot reuse for other analyses
```

### Target State (Modular)
```
[Core Engine] ←→ [Plot Modules] ←→ [Domain Module]
    ↓                   ↓                  ↓
Universal sys      Ridgeline          COHA Dispersal
                   Boxplot            (your data)
                   Heatmap
                   etc.
```

---

## Architecture Layers

### Layer 1: Core Engine (Universal)
**Location:** `core/`  
**Purpose:** Framework-level functionality usable by ANY analysis  
**Never Changes:** Unless adding universal features

```
core/
├── engine.R                    # Main orchestrator
│   └── initialize_pipeline()
│   └── run_analysis()
│   └── register_module()
│
├── data_io.R                   # Generic data operations
│   └── load_data()
│   └── validate_schema()
│   └── cache_data()
│
├── artifact_registry.R         # Track ALL outputs
│   └── register_artifact()
│   └── get_artifact()
│   └── list_artifacts()
│
├── report_builder.R            # HTML generation
│   └── render_report()
│   └── build_gallery()
│   └── embed_plots()
│
├── plugin_manager.R            # Module discovery
│   └── discover_modules()
│   └── load_module()
│   └── validate_module()
│
├── error_handler.R             # Robust error handling
│   └── create_result()
│   └── add_error()
│   └── set_status()
│
└── config/
    └── core_config.yaml        # Core system settings
```

**Core Responsibilities:**
- ✅ Load and validate data (any schema)
- ✅ Discover and load modules
- ✅ Orchestrate plot generation
- ✅ Track artifacts
- ✅ Render reports
- ✅ Error handling and logging
- ❌ NO plot-specific logic
- ❌ NO analysis-specific logic

---

### Layer 2: Plot Type Modules (Generic, Reusable)
**Location:** `plot_modules/`  
**Purpose:** Self-contained plot generators usable across analyses  
**Interface:** Standardized contract all modules follow

```
plot_modules/
├── ridgeline/
│   ├── ridgeline_generator.R       # Main generation function
│   ├── config_schema.yaml          # What configs accepted
│   ├── defaults.yaml               # Default parameters
│   ├── INTERFACE.md                # Module documentation
│   └── tests/
│       └── test_ridgeline.R
│
├── boxplot/
│   ├── boxplot_generator.R
│   ├── config_schema.yaml
│   ├── defaults.yaml
│   └── INTERFACE.md
│
└── [future modules...]
    ├── heatmap/
    ├── histogram/
    ├── scatter/
    └── violin/
```

**Module Interface (Standard Contract):**

Every plot module MUST implement these functions:

```r
# 1. Generate variants
generate_variants <- function(data, config, output_dir) {
  # Input: pre-processed data from domain
  # Input: list of variant configurations
  # Input: where to save outputs
  # Output: artifact registry with paths and metadata
}

# 2. Module metadata
get_module_info <- function() {
  list(
    name = "Ridgeline Density Plots",
    version = "1.0.0",
    author = "Your Name",
    description = "High-density ridgeline plots for distributions",
    data_requirements = list(
      columns = c("x_continuous", "group_categorical"),
      min_rows = 10
    ),
    parameters = list(
      palette = "color palette name or hex array",
      scale = "numeric: y-axis scaling factor",
      alpha = "numeric 0-1: fill transparency",
      line_height = "numeric: spacing between ridges"
    ),
    outputs = c("png", "svg")  # What formats supported
  )
}

# 3. Validate configuration
validate_config <- function(config) {
  # Check if config has all required fields
  # Return list(valid = TRUE/FALSE, errors = c(...))
}

# 4. Get default configuration
get_default_config <- function() {
  # Return sensible defaults for all parameters
}
```

**Module Configuration Schema:**

```yaml
# plot_modules/ridgeline/config_schema.yaml
name: "Ridgeline Density Plots"
version: "1.0.0"

parameters:
  # Required parameters
  required:
    x_var: 
      type: "string"
      description: "Column name for x-axis (continuous)"
    group_var:
      type: "string"
      description: "Column name for grouping (categorical)"
  
  # Optional parameters with defaults
  optional:
    palette:
      type: "string|array"
      default: "viridis"
      description: "Color palette name or hex array"
    scale:
      type: "numeric"
      default: 0.85
      range: [0.1, 5.0]
      description: "Y-axis scaling factor"
    alpha:
      type: "numeric"
      default: 0.7
      range: [0, 1]
      description: "Fill transparency"
    line_height:
      type: "numeric"
      default: 0.85
      range: [0.1, 2.0]
      description: "Ridge line spacing"

output_formats:
  - "png"
  - "svg"

data_requirements:
  min_rows: 10
  required_column_types:
    x_var: "numeric"
    group_var: "factor|character"
```

---

### Layer 3: Domain Modules (Analysis-Specific)
**Location:** `domain_modules/`  
**Purpose:** Configure core + plot modules for specific analyses  
**Example:** COHA Dispersal is one domain module

```
domain_modules/
└── coha_dispersal/
    ├── domain_config.yaml          # What plots to use
    ├── data/
    │   └── data.csv                # Domain-specific data
    ├── data_loader.R               # COHA-specific preprocessing
    ├── plot_specs/
    │   ├── ridgeline_spec.R        # How to configure ridgeline for COHA
    │   ├── boxplot_spec.R          # How to configure boxplot for COHA
    │   └── plot_registry.R         # All variant definitions (current!)
    ├── reports/
    │   ├── full_analysis_report.qmd
    │   ├── plot_gallery.qmd
    │   └── data_quality_report.qmd
    └── README.md                   # Domain documentation
```

**Domain Configuration:**

```yaml
# domain_modules/coha_dispersal/domain_config.yaml
domain:
  name: "COHA Dispersal Analysis"
  version: "1.0"
  description: "Cooper's Hawk natal dispersal patterns and mass distributions"
  created: "2026-02-10"
  authors: ["Research Team"]

data:
  source: "data/data.csv"
  loader: "data_loader.R"  # Custom preprocessing function
  required_columns:
    - "mass"
    - "year"
    - "dispersed"
    - "origin"
  
  # Domain-specific transformations
  preprocessing:
    - create_period_bins:
        width: 6
        start_year: 1980
        end_year: 2027

plot_types:
  ridgeline:
    enabled: true
    module: "ridgeline"                      # References plot_modules/ridgeline/
    spec_file: "plot_specs/ridgeline_spec.R" # COHA-specific configuration
    output_subdir: "ridgeline/variants"
    
  boxplot:
    enabled: false
    module: "boxplot"
    spec_file: "plot_specs/boxplot_spec.R"
    output_subdir: "boxplot/variants"

reports:
  enabled: true
  templates:
    - input: "reports/full_analysis_report.qmd"
      output: "full_analysis_report.html"
      type: "comprehensive"
    - input: "reports/plot_gallery.qmd"
      output: "plot_gallery.html"
      type: "gallery"
    - input: "reports/data_quality_report.qmd"
      output: "data_quality_report.html"
      type: "qa"

output:
  base_dir: "results"
  subdirs:
    plots: "plots"
    reports: "reports"
    data: "processed"
    logs: "logs"
```

**Domain Plot Specification:**

```r
# domain_modules/coha_dispersal/plot_specs/ridgeline_spec.R

#' Configure Ridgeline Module for COHA Analysis
#' 
#' Bridges generic ridgeline module with COHA-specific requirements
get_ridgeline_spec <- function() {
  list(
    # How to prepare COHA data for ridgeline module
    data_prep = function(df) {
      df %>%
        filter(!is.na(mass), !is.na(year)) %>%
        mutate(
          period = cut(year, 
                      breaks = seq(1980, 2027, by = 6),
                      include.lowest = TRUE,
                      labels = c("1980-1985", "1986-1991", ...))
        )
    },
    
    # Module parameters (what ridgeline needs)
    module_params = list(
      x_var = "mass",
      group_var = "period",
      facet_var = NULL,  # or "dispersed" if want faceting
      quantile_lines = TRUE,
      state_mean_lines = TRUE
    ),
    
    # Variants to generate (imported from plot_registry.R)
    variants = plot_registry$ridgeline$variants,
    
    # Output settings
    output = list(
      dpi = 300,
      width = 8,
      height = 5,
      format = "png"
    )
  )
}
```

---

## Module Communication Flow

### Execution Sequence

```
1. User runs: run_analysis("coha_dispersal")
                    ↓
2. Core Engine loads domain config
   - domain_modules/coha_dispersal/domain_config.yaml
                    ↓
3. Engine discovers required plot modules
   - plot_types: ridgeline, boxplot
                    ↓
4. Engine loads plot modules
   - plot_modules/ridgeline/ → registers in engine
   - plot_modules/boxplot/  → registers in engine
                    ↓
5. Engine loads domain data
   - Calls: domain_modules/coha_dispersal/data_loader.R
   - Returns: preprocessed data frame
                    ↓
6. For each plot type:
   a. Load domain plot spec
      - plot_specs/ridgeline_spec.R
   
   b. Prepare data for plot module
      - Run spec$data_prep(df)
   
   c. Call plot module
      - ridgeline_generator(data, spec$variants, output_dir)
   
   d. Module generates all variants
      - Returns artifact registry
   
   e. Engine registers artifacts
      - Tracks paths, metadata, hashes
                    ↓
7. Engine renders reports
   - For each template in domain_config$reports
   - Quarto render with artifact paths injected
                    ↓
8. Engine returns results
   - Comprehensive result object
   - All artifacts tracked
   - Quality metrics
```

### Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│ Domain Module: coha_dispersal                                │
│                                                               │
│  ┌─────────────┐                                            │
│  │ data.csv    │──────────────────────┐                     │
│  └─────────────┘                      │                     │
│                                        ↓                     │
│                              ┌──────────────────┐           │
│  ┌──────────────────┐        │ data_loader.R    │           │
│  │ domain_config    │───────→│ (preprocessing)  │           │
│  │ - ridgeline ON   │        └────────┬─────────┘           │
│  │ - boxplot OFF    │                 │                     │
│  └──────────────────┘                 │                     │
│                                        ↓                     │
│                              ┌──────────────────┐           │
│                              │ Preprocessed DF  │           │
│                              └────────┬─────────┘           │
└───────────────────────────────────────┼──────────────────────┘
                                        │
                    ┌───────────────────┴────────────────┐
                    ↓                                     ↓
         ┌──────────────────────┐           ┌──────────────────────┐
         │ Plot Module:         │           │ Plot Module:         │
         │ ridgeline            │           │ boxplot (disabled)   │
         │                      │           │                      │
         │ ┌─────────────────┐ │           │ (skipped)            │
         │ │ ridgeline_spec  │←┤           │                      │
         │ │ (from domain)   │ │           │                      │
         │ └────────┬────────┘ │           │                      │
         │          ↓           │           │                      │
         │ ┌─────────────────┐ │           │                      │
         │ │ generate_       │ │           │                      │
         │ │ variants()      │ │           │                      │
         │ └────────┬────────┘ │           │                      │
         │          ↓           │           │                      │
         │ ┌─────────────────┐ │           │                      │
         │ │ 28 PNG files    │ │           │                      │
         │ └────────┬────────┘ │           │                      │
         └──────────┼──────────┘           └──────────────────────┘
                    │
                    ↓
         ┌──────────────────────┐
         │ Core Engine:         │
         │ Artifact Registry    │
         │                      │
         │ ├─ compact_01.png   │
         │ ├─ compact_02.png   │
         │ ├─ ...               │
         │ └─ expanded_14.png  │
         └──────────┬───────────┘
                    │
                    ↓
         ┌──────────────────────┐
         │ Report Builder       │
         │                      │
         │ ┌────────────────┐  │
         │ │ plot_gallery   │  │
         │ │ (auto-injects  │  │
         │ │  all 28 plots) │  │
         │ └────────────────┘  │
         └──────────┬───────────┘
                    │
                    ↓
              ┌──────────┐
              │ HTML     │
              │ Reports  │
              └──────────┘
```

---

## Implementation Plan

### Phase 0: Preparation (1 week)
**Goal:** Design validation, no code changes

- [ ] Review current codebase structure
- [ ] Identify all dependencies between components
- [ ] Create backward compatibility strategy
- [ ] Document migration risks
- [ ] Get stakeholder approval

**Deliverables:**
- Dependency map
- Risk assessment document
- Migration checklist

---

### Phase 1: Core Engine Extraction (2 weeks)
**Goal:** Extract universal functionality into core/

**Week 1: Foundation**
- [ ] Create `core/` directory structure
- [ ] Extract data I/O functions → `core/data_io.R`
  - `load_and_validate_data()`
  - `validate_schema()`
  - Generic helpers
- [ ] Extract artifact registry → `core/artifact_registry.R`
  - `init_artifact_registry()`
  - `register_artifact()`
  - `get_artifact()`
- [ ] Extract error handling → `core/error_handler.R`
  - `create_result()`
  - `add_error()`
  - `set_result_status()`

**Week 2: Orchestration**
- [ ] Create plugin manager → `core/plugin_manager.R`
  - `discover_modules()`
  - `load_module()`
  - `validate_module_interface()`
- [ ] Create core engine → `core/engine.R`
  - `initialize_pipeline()`
  - `register_plot_module()`
  - `run_analysis()`
- [ ] Create report builder → `core/report_builder.R`
  - `render_report()`
  - `inject_artifacts()`
- [ ] Write core tests → `tests/test_core/`

**Testing:**
- [ ] Core functions work in isolation
- [ ] Existing pipeline still works (via shim layer)

**Deliverables:**
- Working `core/` module
- Test suite
- Shim layer maintaining compatibility

---

### Phase 2: Ridgeline Module Creation (2 weeks)
**Goal:** Convert ridgeline logic to standalone module

**Week 1: Module Structure**
- [ ] Create `plot_modules/ridgeline/` structure
- [ ] Move plot generation logic → `ridgeline_generator.R`
- [ ] Create module interface functions:
  - `generate_variants()`
  - `get_module_info()`
  - `validate_config()`
  - `get_default_config()`
- [ ] Write `config_schema.yaml`
- [ ] Write `defaults.yaml`
- [ ] Write `INTERFACE.md`

**Week 2: Integration**
- [ ] Integrate with core engine
- [ ] Test module discovery
- [ ] Test module loading
- [ ] Test artifact registration
- [ ] Write module tests → `plot_modules/ridgeline/tests/`

**Testing:**
- [ ] Module loads via plugin manager
- [ ] Generates 28 variants correctly
- [ ] Returns valid artifact registry
- [ ] Works with COHA data

**Deliverables:**
- Working ridgeline module
- Complete test suite
- Documentation

---

### Phase 3: COHA Domain Module (2 weeks)
**Goal:** Convert COHA analysis to domain module

**Week 1: Structure**
- [ ] Create `domain_modules/coha_dispersal/` structure
- [ ] Move data → `data/data.csv`
- [ ] Create `domain_config.yaml`
- [ ] Move plot_registry.R → `plot_specs/plot_registry.R`
- [ ] Create `plot_specs/ridgeline_spec.R`
- [ ] Move reports → `reports/`

**Week 2: Data Loader**
- [ ] Create `data_loader.R` with COHA preprocessing
- [ ] Test data loading through core engine
- [ ] Test plot spec integration
- [ ] Test report rendering
- [ ] Update `run_analysis.R` entrypoint

**Testing:**
- [ ] Full pipeline runs via domain module
- [ ] Generates identical outputs to current system
- [ ] All 3 reports render correctly
- [ ] Artifacts tracked properly

**Deliverables:**
- Working domain module
- Updated entrypoint
- Test suite

---

### Phase 4: Boxplot Module (1 week)
**Goal:** Prove modularity by adding new plot type

- [ ] Create `plot_modules/boxplot/` structure
- [ ] Implement boxplot_generator.R
- [ ] Write config schema and defaults
- [ ] Create `plot_specs/boxplot_spec.R` in COHA domain
- [ ] Enable in `domain_config.yaml`
- [ ] Test full pipeline with both plot types

**Testing:**
- [ ] Boxplots generate correctly
- [ ] Both ridgeline and boxplot work together
- [ ] Gallery includes both plot types
- [ ] No code changes needed in core

**Deliverables:**
- Working boxplot module
- Proof of modularity

---

### Phase 5: Documentation & Polish (1 week)
**Goal:** Complete documentation, migrate legacy code

- [ ] Write comprehensive README for each layer
- [ ] Create developer guide for adding modules
- [ ] Create user guide for domain modules
- [ ] Migrate remaining legacy code
- [ ] Clean up old files
- [ ] Update GitHub Pages gallery

**Testing:**
- [ ] Full integration test
- [ ] Performance benchmarking
- [ ] User acceptance testing

**Deliverables:**
- Complete documentation
- Clean codebase
- Performance report

---

## File Organization Reference

### New Directory Structure
```
COHA_Dispersal/
├── core/                               # ⭐ Layer 1: Universal engine
│   ├── engine.R
│   ├── data_io.R
│   ├── artifact_registry.R
│   ├── report_builder.R
│   ├── plugin_manager.R
│   ├── error_handler.R
│   ├── logging.R
│   └── config/
│       └── core_config.yaml
│
├── plot_modules/                       # ⭐ Layer 2: Plot type modules
│   ├── ridgeline/
│   │   ├── ridgeline_generator.R
│   │   ├── config_schema.yaml
│   │   ├── defaults.yaml
│   │   ├── INTERFACE.md
│   │   └── tests/
│   │       └── test_ridgeline.R
│   │
│   ├── boxplot/
│   │   ├── boxplot_generator.R
│   │   ├── config_schema.yaml
│   │   ├── defaults.yaml
│   │   ├── INTERFACE.md
│   │   └── tests/
│   │       └── test_boxplot.R
│   │
│   └── _module_template/               # Template for new modules
│       └── README.md
│
├── domain_modules/                     # ⭐ Layer 3: Analysis-specific
│   └── coha_dispersal/
│       ├── domain_config.yaml
│       ├── README.md
│       ├── data/
│       │   └── data.csv
│       ├── data_loader.R
│       ├── plot_specs/
│       │   ├── plot_registry.R         # Current variant definitions
│       │   ├── ridgeline_spec.R
│       │   └── boxplot_spec.R
│       └── reports/
│           ├── full_analysis_report.qmd
│           ├── plot_gallery.qmd
│           └── data_quality_report.qmd
│
├── results/                            # Generated outputs
│   ├── plots/
│   ├── reports/
│   └── logs/
│
├── tests/                              # Test suites
│   ├── test_core/
│   ├── test_modules/
│   └── test_integration/
│
├── docs/                               # Documentation
│   ├── MODULAR_PIPELINE_ARCHITECTURE.md  # This document
│   ├── CORE_API_REFERENCE.md
│   ├── MODULE_DEVELOPER_GUIDE.md
│   ├── DOMAIN_USER_GUIDE.md
│   └── MIGRATION_GUIDE.md
│
├── run_analysis.R                      # ⭐ New entrypoint
├── README.md                           # Updated project README
├── .gitignore
└── COHA_Dispersal.Rproj
```

### Legacy Files (To Be Migrated/Removed)
```
R/                                      # → migrate to core/
├── functions/
│   ├── core/                          # → core/
│   ├── data_operations.R              # → core/data_io.R
│   └── plot_operations.R              # → plot_modules/ridgeline/
├── config/
│   └── plot_registry.R                # → domain_modules/.../plot_specs/
├── pipeline/
│   └── pipeline.R                     # → core/engine.R
└── run_project.R                      # → run_analysis.R

inst/
└── config/
    └── study_parameters.yaml          # → multiple configs

reports/                               # → domain_modules/.../reports/
```

---

## Module Interface Specification

### Required Functions (Every Plot Module)

```r
# ==============================================================================
# FUNCTION 1: generate_variants()
# ==============================================================================
#' Generate Plot Variants
#'
#' @param data Data frame. Pre-processed by domain module.
#' @param config List. Variant configurations from domain plot spec.
#' @param output_dir Character. Directory path for saving outputs.
#' @param verbose Logical. Print progress messages.
#'
#' @return List with structure:
#'   - status: "success" | "partial" | "failed"
#'   - message: Character description
#'   - variants: List of artifact metadata
#'   - summary: Generation statistics
#'
#' @examples
#' result <- generate_variants(
#'   data = coha_data,
#'   config = list(
#'     variant_01 = list(palette = "viridis", scale = 0.85, ...),
#'     variant_02 = list(palette = "plasma", scale = 0.85, ...)
#'   ),
#'   output_dir = "results/plots/ridgeline",
#'   verbose = TRUE
#' )
generate_variants <- function(data, config, output_dir, verbose = FALSE) {
  # Implementation here
}


# ==============================================================================
# FUNCTION 2: get_module_info()
# ==============================================================================
#' Get Module Metadata
#'
#' @return List with module information:
#'   - name: Character. Human-readable name
#'   - version: Character. Semantic version (e.g., "1.0.0")
#'   - author: Character. Module maintainer
#'   - description: Character. What this module does
#'   - data_requirements: List. What data format expected
#'   - parameters: List. All configurable parameters
#'   - outputs: Character vector. Supported output formats
#'
#' @examples
#' info <- get_module_info()
#' cat(info$name, "version", info$version)
get_module_info <- function() {
  list(
    name = "Ridgeline Density Plots",
    version = "1.0.0",
    author = "Your Name",
    description = "High-density ridgeline plots for visualizing distributions",
    data_requirements = list(
      columns = c("x_continuous", "group_categorical"),
      min_rows = 10,
      max_groups = 50
    ),
    parameters = list(
      palette = list(
        type = "string|array",
        required = FALSE,
        default = "viridis",
        description = "Color palette name or hex array"
      ),
      scale = list(
        type = "numeric",
        required = FALSE,
        default = 0.85,
        range = c(0.1, 5.0),
        description = "Y-axis scaling factor"
      )
      # ... more parameters
    ),
    outputs = c("png", "svg")
  )
}


# ==============================================================================
# FUNCTION 3: validate_config()
# ==============================================================================
#' Validate Configuration
#'
#' @param config List. Configuration to validate.
#'
#' @return List with validation result:
#'   - valid: Logical. TRUE if valid, FALSE if errors found
#'   - errors: Character vector. Error messages if invalid
#'   - warnings: Character vector. Non-fatal warnings
#'
#' @examples
#' result <- validate_config(my_config)
#' if (!result$valid) {
#'   stop(paste(result$errors, collapse = "\n"))
#' }
validate_config <- function(config) {
  errors <- character()
  warnings <- character()
  
  # Check required parameters
  # Check parameter types
  # Check parameter ranges
  
  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings
  )
}


# ==============================================================================
# FUNCTION 4: get_default_config()
# ==============================================================================
#' Get Default Configuration
#'
#' @return List. Default configuration with all parameters set to sensible values.
#'
#' @examples
#' config <- get_default_config()
#' config$palette <- "plasma"  # Override specific value
get_default_config <- function() {
  list(
    palette = "viridis",
    scale = 0.85,
    alpha = 0.7,
    line_height = 0.85
    # ... all parameters with defaults
  )
}
```

---

## Configuration Schema Examples

### Core Configuration
```yaml
# core/config/core_config.yaml
core:
  version: "2.0"
  log_level: "INFO"
  parallel: false
  max_workers: 4
  
paths:
  modules_dir: "plot_modules"
  domains_dir: "domain_modules"
  output_base: "results"
  temp_dir: "temp"
  
artifact_registry:
  enabled: true
  persistence: "yaml"
  hash_algorithm: "sha256"
  
error_handling:
  stop_on_first_error: false
  retry_failed: true
  max_retries: 3
  
reports:
  engine: "quarto"
  default_format: "html"
  embed_resources: false
```

### Module Configuration Schema
```yaml
# plot_modules/ridgeline/config_schema.yaml
metadata:
  name: "Ridgeline Density Plots"
  version: "1.0.0"
  author: "Your Name"
  description: "High-density ridgeline plots for distribution visualization"
  
interface_version: "1.0"  # Which interface version this module implements

data_requirements:
  min_rows: 10
  max_groups: 50
  required_columns:
    x_var:
      type: "numeric"
      description: "Continuous variable for x-axis"
    group_var:
      type: ["factor", "character"]
      description: "Categorical grouping variable"
  optional_columns:
    facet_var:
      type: ["factor", "character"]
      description: "Optional faceting variable"

parameters:
  required: []  # No required parameters beyond data
  
  optional:
    palette:
      type: ["string", "array"]
      default: "viridis"
      allowed_values:
        string: ["viridis", "plasma", "magma", "inferno", "cividis", 
                "rocket", "mako", "turbo", "Set2", "Dark2"]
        array: "hex_colors"
      description: "Color palette name or custom hex array"
      
    scale:
      type: "numeric"
      default: 0.85
      range: [0.1, 5.0]
      description: "Y-axis scaling factor (larger = more overlap)"
      
    alpha:
      type: "numeric"
      default: 0.7
      range: [0, 1]
      description: "Fill transparency (0 = transparent, 1 = opaque)"
      
    line_height:
      type: "numeric"
      default: 0.85
      range: [0.1, 2.0]
      description: "Spacing between ridge lines"
      
    quantile_lines:
      type: "logical"
      default: true
      description: "Draw quantile lines at 25%, 50%, 75%"
      
    state_mean_lines:
      type: "logical"
      default: false
      description: "Draw state-specific mean lines"

output:
  formats: ["png", "svg"]
  default_format: "png"
  default_dpi: 300
  default_width: 8
  default_height: 5

dependencies:
  r_packages:
    - name: "ggplot2"
      version: ">= 3.4.0"
    - name: "ggridges"
      version: ">= 0.5.0"
    - name: "dplyr"
      version: ">= 1.1.0"
```

### Domain Configuration
```yaml
# domain_modules/coha_dispersal/domain_config.yaml
domain:
  name: "COHA Dispersal Analysis"
  version: "1.0"
  description: "Cooper's Hawk natal dispersal patterns and mass distributions"
  type: "ornithology"
  created: "2026-02-10"
  authors:
    - name: "Research Team"
      email: "team@example.org"

data:
  source: "data/data.csv"
  loader: "data_loader.R"
  format: "csv"
  encoding: "UTF-8"
  
  required_columns:
    mass:
      type: "numeric"
      units: "grams"
      description: "Body mass measurement"
    year:
      type: "numeric"
      range: [1980, 2027]
      description: "Sample year"
    dispersed:
      type: "character"
      allowed_values: ["Dispersed", "Non-dispersed"]
      description: "Dispersal status"
    origin:
      type: "character"
      description: "Sample origin location"
  
  preprocessing:
    - name: "create_period_bins"
      function: "cut"
      params:
        breaks: "seq(1980, 2027, by = 6)"
        include.lowest: true
        labels: ["1980-1985", "1986-1991", "1992-1997", 
                 "1998-2003", "2004-2009", "2010-2015", 
                 "2016-2021", "2022-2027"]

plot_types:
  ridgeline:
    enabled: true
    module: "ridgeline"
    version: ">= 1.0.0"
    spec_file: "plot_specs/ridgeline_spec.R"
    output_subdir: "ridgeline/variants"
    variants: 28
    
  boxplot:
    enabled: false
    module: "boxplot"
    version: ">= 1.0.0"
    spec_file: "plot_specs/boxplot_spec.R"
    output_subdir: "boxplot/variants"
    variants: 10

reports:
  enabled: true
  engine: "quarto"
  output_dir: "results/reports"
  
  templates:
    full_analysis:
      input: "reports/full_analysis_report.qmd"
      output: "full_analysis_report.html"
      type: "comprehensive"
      priority: 1
      
    plot_gallery:
      input: "reports/plot_gallery.qmd"
      output: "plot_gallery.html"
      type: "gallery"
      priority: 2
      github_pages: true  # Use as landing page
      
    data_quality:
      input: "reports/data_quality_report.qmd"
      output: "data_quality_report.html"
      type: "qa"
      priority: 3

output:
  base_dir: "results"
  structure:
    plots: "plots"
    reports: "reports"
    data: "processed"
    logs: "logs"
    cache: "cache"
  
  artifacts:
    track: true
    registry_file: "artifact_registry.yaml"
    versioning: false

github_pages:
  enabled: true
  landing_page: "plot_gallery.html"
  deploy_on_run: false  # Manual deployment
```

---

## API Reference

### Core Engine API

```r
# ==============================================================================
# Core Engine Initialization
# ==============================================================================

#' Initialize Pipeline Engine
#'
#' @param config_path Path to core configuration YAML
#' @param verbose Print initialization messages
#'
#' @return Engine object with methods:
#'   - $register_plot_module()
#'   - $load_domain()
#'   - $run_analysis()
#'   - $get_results()
#'
#' @examples
#' engine <- initialize_pipeline(
#'   config_path = "core/config/core_config.yaml",
#'   verbose = TRUE
#' )
initialize_pipeline <- function(config_path = NULL, verbose = FALSE)


# ==============================================================================
# Plot Module Registration
# ==============================================================================

#' Register Plot Module
#'
#' @param engine Engine object from initialize_pipeline()
#' @param module_name Character. Name of module (e.g., "ridgeline")
#' @param module_path Path to module directory
#'
#' @return Updated engine object
#'
#' @examples
#' engine$register_plot_module(
#'   module_name = "ridgeline",
#'   module_path = "plot_modules/ridgeline"
#' )
engine$register_plot_module(module_name, module_path)


# ==============================================================================
# Domain Loading
# ==============================================================================

#' Load Domain Module
#'
#' @param engine Engine object
#' @param domain_name Character. Name of domain (e.g., "coha_dispersal")
#' @param domain_path Path to domain directory
#'
#' @return Domain object with:
#'   - $config
#'   - $data
#'   - $plot_specs
#'   - $reports
#'
#' @examples
#' domain <- engine$load_domain(
#'   domain_name = "coha_dispersal",
#'   domain_path = "domain_modules/coha_dispersal"
#' )
engine$load_domain(domain_name, domain_path)


# ==============================================================================
# Analysis Execution
# ==============================================================================

#' Run Analysis
#'
#' @param engine Engine object
#' @param domain Domain object from load_domain()
#' @param dry_run Logical. If TRUE, validate without generating outputs
#' @param verbose Logical. Print progress
#'
#' @return Result object with:
#'   - status: "success" | "partial" | "failed"
#'   - data_quality: 0-100 score
#'   - plots_generated: Count
#'   - plots_failed: Count
#'   - reports_rendered: Count
#'   - artifacts: Registry of all outputs
#'   - duration_secs: Total time
#'   - errors: Error messages
#'   - warnings: Warning messages
#'
#' @examples
#' result <- engine$run_analysis(
#'   domain = domain,
#'   dry_run = FALSE,
#'   verbose = TRUE
#' )
engine$run_analysis(domain, dry_run = FALSE, verbose = TRUE)
```

---

## Usage Examples

### Example 1: Run Existing COHA Analysis

```r
# run_analysis.R
library(here)
source(here("core", "engine.R"))

# Initialize core engine
engine <- initialize_pipeline(
  config_path = "core/config/core_config.yaml",
  verbose = TRUE
)

# Load COHA domain
domain <- engine$load_domain(
  domain_name = "coha_dispersal",
  domain_path = "domain_modules/coha_dispersal"
)

# Run analysis (engine auto-discovers and loads plot modules)
result <- engine$run_analysis(
  domain = domain,
  verbose = TRUE
)

# Check results
if (result$status == "success") {
  cat("✓ Analysis complete!\n")
  cat(sprintf("  Generated %d plots\n", result$plots_generated))
  cat(sprintf("  Rendered %d reports\n", result$reports_rendered))
  cat(sprintf("  Time: %.1f seconds\n", result$duration_secs))
} else {
  cat("✗ Analysis failed:\n")
  cat(paste(result$errors, collapse = "\n"))
}
```

### Example 2: Add New Plot Type to COHA

```r
# 1. Create boxplot module (once)
# plot_modules/boxplot/boxplot_generator.R already exists

# 2. Create COHA boxplot specification
# domain_modules/coha_dispersal/plot_specs/boxplot_spec.R
get_boxplot_spec <- function() {
  list(
    data_prep = function(df) {
      df %>% filter(!is.na(mass))
    },
    module_params = list(
      x_var = "period",
      y_var = "mass",
      color_var = "dispersed"
    ),
    variants = list(
      boxplot_01 = list(
        palette = "Set2",
        show_outliers = TRUE,
        jitter = 0.2
      )
      # ... more variants
    )
  )
}

# 3. Enable in domain config
# domain_modules/coha_dispersal/domain_config.yaml
plot_types:
  boxplot:
    enabled: true  # Just flip this!

# 4. Run - boxplots auto-generate
source("run_analysis.R")
```

### Example 3: Create New Domain Module

```r
# New analysis: COHA migration patterns

# 1. Create domain structure
domain_modules/coha_migration/
├── domain_config.yaml      # Configure plot types to use
├── data/
│   └── migration_data.csv
├── data_loader.R           # Migration-specific preprocessing
├── plot_specs/
│   └── ridgeline_spec.R    # Reuse ridgeline module!
└── reports/
    └── migration_report.qmd

# 2. Configure domain
# domain_config.yaml
domain:
  name: "COHA Migration Patterns"
  
plot_types:
  ridgeline:
    enabled: true
    module: "ridgeline"  # Same module, different config!

# 3. Run
engine <- initialize_pipeline()
domain <- engine$load_domain(
  domain_name = "coha_migration",
  domain_path = "domain_modules/coha_migration"
)
result <- engine$run_analysis(domain)
```

---

## Testing Strategy

### Unit Tests (Per Layer)

**Core Engine Tests:**
```r
# tests/test_core/test_engine.R
test_that("Engine initializes with valid config", {
  engine <- initialize_pipeline("core/config/core_config.yaml")
  expect_s3_class(engine, "pipeline_engine")
  expect_true(engine$initialized)
})

test_that("Engine discovers modules", {
  engine <- initialize_pipeline()
  modules <- engine$discover_modules("plot_modules")
  expect_true("ridgeline" %in% names(modules))
})
```

**Plot Module Tests:**
```r
# plot_modules/ridgeline/tests/test_ridgeline.R
test_that("Ridgeline module generates variants", {
  data <- data.frame(x = rnorm(100), group = rep(1:5, 20))
  config <- get_default_config()
  
  result <- generate_variants(data, list(v1 = config), tempdir())
  
  expect_equal(result$status, "success")
  expect_equal(length(result$variants), 1)
  expect_true(file.exists(result$variants$v1$path))
})
```

**Domain Module Tests:**
```r
# domain_modules/coha_dispersal/tests/test_coha.R
test_that("COHA data loads correctly", {
  data <- source("data_loader.R")$load_coha_data()
  expect_true("period" %in% colnames(data))
  expect_equal(nrow(data), 847)
})
```

### Integration Tests

```r
# tests/test_integration/test_full_pipeline.R
test_that("Full COHA pipeline runs end-to-end", {
  engine <- initialize_pipeline(verbose = FALSE)
  domain <- engine$load_domain("coha_dispersal", 
                               "domain_modules/coha_dispersal")
  result <- engine$run_analysis(domain, verbose = FALSE)
  
  expect_equal(result$status, "success")
  expect_equal(result$plots_generated, 28)
  expect_equal(result$reports_rendered, 3)
  expect_true(result$data_quality >= 90)
})
```

---

## Migration Checklist

### Pre-Migration
- [ ] Full backup of current codebase
- [ ] Create migration branch
- [ ] Document all current functionality
- [ ] Identify breaking changes
- [ ] Create rollback plan

### Phase 1: Core
- [ ] Create `core/` directory
- [ ] Extract and test data I/O functions
- [ ] Extract and test artifact registry
- [ ] Extract and test error handling
- [ ] Create plugin manager
- [ ] Create core engine
- [ ] Create report builder
- [ ] Write core tests
- [ ] Verify existing pipeline still works

### Phase 2: Ridgeline Module
- [ ] Create `plot_modules/ridgeline/`
- [ ] Move generation logic
- [ ] Implement module interface
- [ ] Create config schema
- [ ] Write documentation
- [ ] Write tests
- [ ] Test via plugin manager
- [ ] Verify output identical to current

### Phase 3: COHA Domain
- [ ] Create `domain_modules/coha_dispersal/`
- [ ] Move data and configs
- [ ] Create domain config
- [ ] Create plot specs
- [ ] Move reports
- [ ] Create data loader
- [ ] Write tests
- [ ] Test full pipeline
- [ ] Verify reports identical

### Phase 4: Boxplot Module
- [ ] Create `plot_modules/boxplot/`
- [ ] Implement generator
- [ ] Create interface
- [ ] Add to COHA domain
- [ ] Test integration
- [ ] Verify modularity

### Phase 5: Cleanup
- [ ] Remove legacy code
- [ ] Update all documentation
- [ ] Update README
- [ ] Clean up gitignore
- [ ] Final integration test
- [ ] Merge to main

### Post-Migration
- [ ] Performance benchmark
- [ ] User acceptance testing
- [ ] Update GitHub Pages
- [ ] Announce changes
- [ ] Monitor for issues

---

## Success Criteria

### Functional Requirements
- [ ] All 28 ridgeline variants generate correctly
- [ ] All 3 reports render with embedded plots
- [ ] GitHub Pages gallery updates automatically
- [ ] Data quality validation works
- [ ] Artifact registry tracks all outputs
- [ ] Error handling is robust

### Non-Functional Requirements
- [ ] Pipeline runs in same time as current (±10%)
- [ ] Memory usage comparable to current
- [ ] Code coverage ≥ 80%
- [ ] All tests pass
- [ ] Documentation complete
- [ ] Backward compatible (via shim layer)

### Modularity Validations
- [ ] Can add new plot type in < 1 hour
- [ ] Can add new domain in < 2 hours
- [ ] Plot modules work in isolation
- [ ] Core engine has zero plot-specific code
- [ ] Configs are declarative (no code)

---

## Risk Assessment

### High Risk
1. **Breaking existing functionality**
   - Mitigation: Comprehensive test suite, shim layer, feature flags
   
2. **Performance regression**
   - Mitigation: Benchmarking at each phase, optimize hot paths

3. **Incomplete migration**
   - Mitigation: Clear phase boundaries, incremental delivery

### Medium Risk
1. **Complex module dependencies**
   - Mitigation: Explicit dependency declaration, version pinning

2. **Report rendering issues**
   - Mitigation: Test report generation early and often

3. **Configuration complexity**
   - Mitigation: Sensible defaults, validation, clear error messages

### Low Risk
1. **Learning curve for new architecture**
   - Mitigation: Comprehensive documentation, examples

2. **Git history complexity**
   - Mitigation: Good commit messages, preserve file history

---

## Future Enhancements

### Short Term (Next 3 months)
- [ ] Histogram module
- [ ] Scatter plot module
- [ ] Heatmap module
- [ ] Parallel plot generation
- [ ] Caching layer for expensive operations

### Medium Term (6 months)
- [ ] Web UI for configuration
- [ ] Interactive plot gallery
- [ ] Module marketplace/registry
- [ ] Auto-documentation generation
- [ ] CI/CD pipeline

### Long Term (1 year)
- [ ] Cloud execution (AWS/Azure)
- [ ] Real-time data streaming
- [ ] Machine learning integration
- [ ] Shiny dashboard
- [ ] Multi-language support (Python modules)

---

## References

### Design Patterns
- **Plugin Architecture**: Core + dynamically loaded modules
- **Strategy Pattern**: Plot modules implement common interface
- **Factory Pattern**: Module discovery and instantiation
- **Registry Pattern**: Artifact tracking
- **Template Method**: Report rendering workflow

### Similar Systems
- **R Packages**: targets, drake (workflow management)
- **Python**: Plotly Dash, Streamlit (modular dashboards)
- **Build Systems**: Make, Bazel (dependency management)

### Documentation Resources
- R Package Development (Hadley Wickham)
- Software Architecture Patterns (O'Reilly)
- Clean Architecture (Robert Martin)

---

## Appendix A: Glossary

**Core Engine** - Universal orchestration layer, reusable across any analysis

**Plot Module** - Self-contained plot generator implementing standard interface

**Domain Module** - Analysis-specific configuration and data

**Artifact Registry** - System tracking all generated outputs

**Plugin Manager** - Discovers and loads modules dynamically

**Plot Spec** - Bridge between domain requirements and plot module

**Variant** - Single configured version of a plot (e.g., "ridgeline with viridis palette, scale 0.85")

**Interface** - Contract defining required functions/structure

**Shim Layer** - Compatibility wrapper preserving legacy API

---

## Appendix B: Design Decisions Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2026-02-12 | 3-layer architecture | Clear separation of concerns | 2-layer (no domain), 4-layer (add UI) |
| 2026-02-12 | YAML for configuration | Human-readable, widely supported | JSON, TOML, pure R |
| 2026-02-12 | Plugin manager approach | Dynamic module loading | Static imports, package dependencies |
| 2026-02-12 | Standard module interface | Enforces consistency | Free-form modules |
| 2026-02-12 | Domain-specific plot specs | Flexibility per analysis | Generic specs only |

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-12 | AI Assistant | Initial architecture specification |

---

**Document Status:** ✅ Design Complete - Ready for Implementation  
**Next Action:** Review with stakeholders → Begin Phase 0 (Preparation)  
**Estimated Timeline:** 8 weeks to full implementation

---

*End of Modular Pipeline Architecture Specification v2.0*
