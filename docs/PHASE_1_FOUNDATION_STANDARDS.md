# PHASE 1: FOUNDATION STANDARDS
# =============================
# Duration: Week 1
# Focus: Core infrastructure, paths, config, validation, logging

## PHASE 1 OBJECTIVES

1. **Path Determinism** - All paths use `here::here()`
2. **Validation Layer** - Assertions for defensive programming
3. **Configuration System** - YAML-driven, no hardcoding
4. **Logging Framework** - Pipeline audit trail
5. **Function Organization** - R/functions/ structure established
6. **Defensive Checks** - Input validation at all entry points

---

## 1.1: PATH MANAGEMENT (ST_path_management)

### Standard: Use `here::here()` Exclusively

**Rule:** Every file path in code must use `here::here()`.

```r
# ✗ BAD
df <- read.csv("../data/data.csv")
ggsave("results/plots/plot.png")

# ✓ GOOD
df <- read.csv(here::here("data", "data.csv"))
ggsave(here::here("results", "plots", "plot.png"))
```

**Why:** Relative paths break when project moved; `here::here()` finds project root automatically.

**Validation:**
```r
# In pipeline.R:
assert_project_root_exists <- function() {
  root <- here::here()
  assert(dir.exists(root), "Project root not found")
}
```

---

## 1.2: CONFIGURATION SYSTEM (ST_config_driven_design)

### Standard: Single Source of Truth

**Core Config:** `inst/config/study_parameters.yaml`

```yaml
# inst/config/study_parameters.yaml
---
project_name: "COHA Dispersal Analysis"
version: "1.0"

# Data
data:
  source_file: "data/data.csv"
  required_columns:
    - "mass"
    - "year"
    - "dispersed"
    - "origin"

# Output Paths
paths:
  plots_dir: "results/plots"
  reports_dir: "results/reports"
  logs_dir: "logs"
  config_dir: "inst/config"

# Plot Types
plot_types:
  ridgeline:
    enabled: true
    config_file: "R/config/ridgeline_config.R"
    report_file: "inst/reports/ridgeline_comprehensive.qmd"
    variants: 20
  boxplot:
    enabled: false
    config_file: "R/config/boxplot_config.R"
    report_file: "inst/reports/boxplot_comprehensive.qmd"
    variants: 10

# Defaults
defaults:
  verbose: false
  save_plots: true
  dpi: 300
```

**Loading Config:**
```r
# R/functions/config_loader.R
load_study_config <- function(verbose = FALSE) {
  config_path <- here::here("inst", "config", "study_parameters.yaml")
  assert_file_exists(config_path)
  
  config <- yaml::read_yaml(config_path)
  if (verbose) message("[CONFIG] Loaded from ", config_path)
  
  config
}
```

---

## 1.3: ASSERTION FUNCTIONS (ST_input_validation)

### Standard: Fail Fast with Clear Messages

**Create:** `R/functions/assertions.R`

```r
# ==============================================================================
# R/functions/assertions.R
# ==============================================================================
# PURPOSE: Input validation and defensive assertions
# ==============================================================================

#' Assert File Exists
#' @param file_path Character. Path to check.
assert_file_exists <- function(file_path) {
  if (!file.exists(file_path)) {
    stop(sprintf("File not found: %s", file_path), call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Column in Data Frame
#' @param df Data frame.
#' @param columns Character vector. Required column names.
assert_columns_exist <- function(df, columns) {
  missing <- setdiff(columns, names(df))
  if (length(missing) > 0) {
    stop(sprintf("Missing columns: %s", paste(missing, collapse = ", ")), 
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Data Frame Not Empty
#' @param df Data frame.
assert_not_empty <- function(df) {
  if (nrow(df) == 0) {
    stop("Data frame is empty", call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert Column Has No NA
#' @param df Data frame.
#' @param col_name Character. Column name.
assert_no_na <- function(df, col_name) {
  n_na <- sum(is.na(df[[col_name]]))
  if (n_na > 0) {
    stop(sprintf("Column '%s' has %d NA values", col_name, n_na), 
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate Ridgeline Data
#' Comprehensive check for ridgeline plot requirements
validate_ridgeline_data <- function(df, verbose = FALSE) {
  if (verbose) message("[VALIDATE] Checking ridgeline data schema...")
  
  assert_is_dataframe(df)
  assert_columns_exist(df, c("mass", "year", "dispersed", "origin"))
  assert_not_empty(df)
  
  # Check types
  if (!is.numeric(df$mass)) {
    stop("Column 'mass' must be numeric", call. = FALSE)
  }
  if (!is.numeric(df$year)) {
    stop("Column 'year' must be numeric", call. = FALSE)
  }
  
  if (verbose) message("[VALIDATE] ✓ Data schema valid")
  invisible(TRUE)
}
```

**Usage:**
```r
validate_ridgeline_data(data, verbose = TRUE)
# If invalid: error with clear message
# If valid: invisible(TRUE)
```

---

## 1.4: LOGGING SYSTEM (ST_logging_standards)

### Standard: Audit Trail to File + Console

**Create:** `R/functions/logging.R`

```r
# ==============================================================================
# R/functions/logging.R
# ==============================================================================
# PURPOSE: File-based logging for pipeline operations
# ==============================================================================

#' Initialize Pipeline Log
#' Creates logs/ directory and returns log file path
initialize_pipeline_log <- function(verbose = FALSE) {
  log_dir <- here::here("logs")
  
  # Create logs directory if needed
  if (!dir.exists(log_dir)) {
    dir.create(log_dir, showWarnings = FALSE)
  }
  
  log_file <- file.path(log_dir, 
                        sprintf("pipeline_%s.log", 
                                format(Sys.Date(), "%Y-%m-%d")))
  
  if (verbose) message("[LOGGING] Initialized: ", log_file)
  log_file
}

#' Log Message to File and Console
#' @param message Character. Message to log.
#' @param level Character. ERROR, WARN, INFO, DEBUG
#' @param verbose Logical. Also print to console?
log_message <- function(message, level = "INFO", verbose = FALSE) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  formatted <- sprintf("[%s] [%s] %s", timestamp, level, message)
  
  log_file <- here::here("logs", 
                         sprintf("pipeline_%s.log", 
                                 format(Sys.Date(), "%Y-%m-%d")))
  
  # Write to file
  if (file.exists(file.path(here::here("logs")))) {
    cat(formatted, "\n", file = log_file, append = TRUE)
  }
  
  # Optionally print to console
  if (verbose) {
    cat(formatted, "\n")
  }
  
  invisible(TRUE)
}
```

**Usage:**
```r
log_message("Pipeline started", "INFO", verbose = TRUE)
log_message("Generated ridgeline_01", "DEBUG", verbose = FALSE)
log_message("Missing data detected", "WARN", verbose = TRUE)
```

**Output:**
```
logs/pipeline_2026-02-10.log:
[2026-02-10 09:15:23] [INFO] Pipeline started
[2026-02-10 09:15:24] [DEBUG] Generated ridgeline_01
[2026-02-10 09:15:25] [WARN] Missing data detected
```

---

## 1.5: DIRECTORY STRUCTURE

**Create these directories:**

```bash
# From workspace root
mkdir -p R/config
mkdir -p R/functions
mkdir -p inst/config
mkdir -p inst/reports
mkdir -p logs
mkdir -p results/plots/ridgeline/variants
mkdir -p results/plots/ridgeline/final
mkdir -p results/reports
mkdir -p results/data/processed
mkdir -p docs
```

**Update .gitignore:**
```
# Add these lines
logs/
results/plots/**/*.png
results/plots/**/*.svg
results/reports/**/*.html
results/data/processed/
```

---

## 1.6: CONFIG FILE LOCATIONS

**Primary Config:**
- `inst/config/study_parameters.yaml` - Project settings, paths, enabled plot types

**Per-Plot-Type Configs:**
- `R/config/ridgeline_config.R` - 20 ridgeline plot specifications
- `R/config/boxplot_config.R` - Future boxplot specifications

**How It Works:**
1. `inst/config/study_parameters.yaml` lists which plot types enabled
2. Pipeline loads YAML via `load_study_config()`
3. For each enabled plot type, loads corresponding R config file
4. Pipeline iterates through configs and generates plots

---

## 1.7: FUNCTION ORGANIZATION STANDARD

**R/functions/ Directory:**
```
R/functions/
├── assertions.R           # validate_ridgeline_data(), assert_*()
├── logging.R              # log_message(), initialize_pipeline_log()
├── config_loader.R        # load_study_config()
└── ridgeline_generation.R # create_ridgeline_plot(), etc.
```

**Principle:** One responsibility per file.
- Assertions: All validation functions
- Logging: All audit trail functions
- Config: All YAML/configuration loading
- Generation: All plot creation functions

---

## 1.8: ENTRY POINT VALIDATION

**EVERY public function must:**

1. Accept `verbose = FALSE` parameter
2. Call validation on inputs first
3. Log entry/exit if verbose

**Template:**
```r
#' Generate All Ridgeline Variants
#' @param data Data frame. Ridgeline plot data.
#' @param configs List. Plot configurations.
#' @param verbose Logical. Print progress. Default: FALSE.
#' @return List of ggplot objects.
#' @export
generate_ridgeline_variants <- function(data, configs, verbose = FALSE) {
  # 1. VALIDATION
  if (verbose) log_message("Starting ridgeline variant generation", 
                           "INFO", verbose = TRUE)
  validate_ridgeline_data(data, verbose = verbose)
  
  # 2. MAIN LOGIC
  plots <- lapply(configs, function(config) {
    plot <- create_ridgeline_plot(data, config, verbose = verbose)
    if (verbose) log_message(sprintf("Generated %s", config$id), 
                             "DEBUG", verbose = TRUE)
    plot
  })
  
  # 3. RETURN
  if (verbose) log_message("Ridgeline variant generation complete", 
                           "INFO", verbose = TRUE)
  invisible(plots)
}
```

---

## 1.9: PHASE 1 CHECKLIST

Before moving to Phase 2:

- [ ] `R/functions/assertions.R` created with all assert_*() functions
- [ ] `R/functions/logging.R` created with log_message() system
- [ ] `R/functions/config_loader.R` created with load_study_config()
- [ ] `inst/config/study_parameters.yaml` created with full config
- [ ] All directories in 1.5 created
- [ ] `.gitignore` updated with Phase 1 patterns
- [ ] `R/pipeline.R` updated to use here::here() throughout
- [ ] `R/config/ridgeline_config.R` moved from `R/config.R`
- [ ] All plot-related functions updated with verbose parameter
- [ ] Test: `validate_ridgeline_data(readr::read_csv(here::here("data", "data.csv")))` works

---

## PHASE 1 SUCCESS CRITERIA

✅ Project paths independent of working directory
✅ Configuration in single YAML file
✅ Validation catches bad inputs with clear errors
✅ Logging creates audit trail
✅ All functions have verbose gating
✅ No hardcoded paths or values remaining

→ **When complete, proceed to Phase 2: Documentation**
