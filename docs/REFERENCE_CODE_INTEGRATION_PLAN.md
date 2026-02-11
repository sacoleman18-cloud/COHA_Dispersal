# REFERENCE R CODE ANALYSIS - COHA Integration Plan
# =========================================================================
# Analysis of utility/helper functions from reference project
# Target: Enhance COHA's Phase 1 Foundation with proven patterns
# =========================================================================

## SUMMARY OF FINDINGS

**Total Functions Analyzed:** 40+ across core/ and validation/
**High-Priority Recommendations:** 18 functions to integrate
**Medium-Priority Enhancements:** 8 functions to adapt
**Not Applicable:** 5+ functions (domain-specific to reference project)

**Integration Impact:**
- ✅ Strengthen assertions.R (add 6 universal assert_* functions)
- ✅ Enhance logging.R (add better formatting + console output separation)
- ✅ New utilities.R module (null coalescing, safe I/O, path generation)
- ✅ New console.R module (stage headers, workflow summaries)
- ✅ Enhance config_loader.R (better config management patterns)

---

## ANALYSIS BY MODULE

### MODULE 1: core/utilities.R (1369 lines total)

**PURPOSE:** Foundational utilities with ZERO internal dependencies.
Provides safe I/O, file discovery, path generation, and template utilities.

#### HIGH-PRIORITY INTEGRATIONS (Implement First)

**1. `%||%` Operator - Null Coalescing**
```r
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
```
- **Status:** ⭐ HIGH PRIORITY
- **Complexity:** Trivial (1 function, 2 lines)
- **Impact:** Enables clean default value handling throughout COHA
- **COHA Use Cases:**
  - `script_name %||% "default_script"`
  - `config_option %||% default_option`
  - `user_value %||% computed_default`
- **Recommended Location:** R/functions/utilities.R (new file)
- **Implementation:** Direct copy

---

**2. `ensure_dir_exists()` - Safe Directory Creation**
```r
ensure_dir_exists <- function(dir_path) {
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  invisible(TRUE)
}
```
- **Status:** ⭐ HIGH PRIORITY
- **Complexity:** Trivial (1 function)
- **Current State in COHA:** Partially implemented inline in various places
- **Improvement:** Single reusable function with consistent behavior
- **COHA Use Cases:**
  - Before saving plots: `ensure_dir_exists("results/plots/ridgeline/variants")`
  - Before logging: `ensure_dir_exists("logs")`
  - Pipeline setup: `ensure_dir_exists(output_dir)`
- **Recommended Location:** R/functions/utilities.R
- **Enhancement Opportunity:** Combine with here::here() for full paths

---

**3. `safe_read_csv()` - File I/O Without Stopping**
```r
safe_read_csv <- function(file_path,
                          error_log_path = "logs/error_log.txt",
                          verbose = FALSE,
                          ...) {
  # Returns tibble or NULL (never errors)
  # Logs read errors with timestamps
}
```
- **Status:** ⭐ HIGH PRIORITY
- **Complexity:** Moderate (20+ lines)
- **Current State in COHA:** Not implemented
- **Impact:** Allows pipeline to continue if data loading fails
- **COHA Use Cases:**
  - Load ridgeline data with fallback
  - Try reading processed cache, fall back to raw data
  - Multi-file ingestion with partial success handling
- **Recommended Location:** R/functions/utilities.R
- **COHA Adaptation Needed:**
  - Use here::here() for file paths
  - Use existing log_message() from logging.R instead of writeLines()
  - Return readr::read_csv (already in your code)

---

**4. `convert_empty_to_na()` - Clean String Data**
```r
convert_empty_to_na <- function(df, columns) {
  df %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(columns),
        ~ ifelse(trimws(.) == "", NA, .)
      )
    )
}
```
- **Status:** ⭐ MEDIUM PRIORITY
- **Complexity:** Trivial (uses dplyr pipe)
- **Current State in COHA:** Not implemented
- **Impact:** Cleans data after CSV import (empty strings → NA)
- **COHA Use Cases:**
  - Clean dispersal origin column (Unknown vs empty)
  - Standardize missing value representation
  - Pre-validation cleaning step
- **Recommended Location:** R/functions/utilities.R
- **Implementation:** Direct copy (already uses tidyverse)

---

**5. `find_most_recent_file()` - Checkpoint Discovery**
```r
find_most_recent_file <- function(directory,
                                  pattern,
                                  error_if_none = TRUE,
                                  hint = NULL) {
  # Finds file matching pattern with most recent YYYYMMDD_HHMMSS timestamp
}
```
- **Status:** ⭐ MEDIUM PRIORITY (Future implementation)
- **Complexity:** Moderate (uses filename timestamps, not mtime)
- **Current State in COHA:** Not needed yet
- **Impact:** Deterministic cache/checkpoint loading (critical for reproducibility)
- **COHA Use Cases (Future):**
  - Load most recent processed data cache
  - Find latest report version
  - Resume from checkpoint
- **Recommended Location:** R/functions/utilities.R
- **COHA Adaptation:** Not immediately needed; plan for Phase 2+

---

**6. `make_output_path()` - Timestamped Output Paths**
```r
make_output_path <- function(workflow_num,
                             base_name,
                             extension = "csv",
                             output_dir = "outputs") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- sprintf("%s_%s_%s.%s", workflow_num, base_name, timestamp, extension)
  file.path(output_dir, filename)
}
```
- **Status:** ⭐ MEDIUM PRIORITY
- **Complexity:** Trivial (3 lines)
- **Current State in COHA:** Partially implemented (ggsave uses timestamps)
- **Impact:** Deterministic audit trail for all outputs
- **COHA Use Cases:**
  - Generate timestamped plot filenames
  - Create versioned report filenames
  - Track pipeline outputs with timestamps
- **Recommended Location:** R/functions/utilities.R
- **COHA Simplification:** Simplified version without workflow_num prefix

---

**7. `make_versioned_path()` - Auto-Incrementing Versions**
```r
make_versioned_path <- function(workflow_num,
                                base_name,
                                extension = "csv",
                                output_dir = "outputs") {
  # Scans output_dir for existing versions
  # Returns path with next available version (v1, v2, v3...)
}
```
- **Status:** 🟡 LOW PRIORITY (Future enhancement)
- **Complexity:** Moderate (file scanning)
- **Current State in COHA:** Not needed
- **Use Case:** When plots shouldn't have timestamps but need versioning
- **Implementation:** Plan for Phase 3+

---

#### REFERENCE FUNCTIONS NOT NEEDED BY COHA

These are implemented in reference project but NOT needed by COHA:
- `fill_readme_template()` - Template processing (handled by Quarto instead)
- `save_summary_csv()` - Domain-specific output (we use ggsave instead)
- `build_excel_from_csv()` - Excel conversion (not in COHA scope)
- `verify_rds_artifacts()` - RDS validation (we use PNG/HTML)
- `render_report()` - R Markdown rendering (we use Quarto instead)
- `create_and_register_release()` - Release bundling (not in Phase 1-4)

---

### MODULE 2: core/logging.R (150 lines total)

**STATUS:** Already implemented in COHA with matching design!

**Comparison:**
| Feature | Reference | COHA | Status |
|---------|-----------|------|--------|
| log_message() | ✅ | ✅ | Identical pattern |
| initialize_pipeline_log() | ✅ | ✅ | Identical pattern |
| Append-only | ✅ | ✅ | ✅ Both use append=TRUE |
| ISO 8601 timestamps | ✅ | ✅ | ✅ Both use Sys.time() |
| Silent operation | ✅ | ✅ | ✅ Returns invisibly |

**Enhancement Opportunities:**

**1. Extract Log Directory Constant**
```r
# Instead of hardcoding "logs" everywhere:
DEFAULT_LOG_DIR <- "logs"

# Use:
log_file <- file.path(DEFAULT_LOG_DIR, "pipeline_20260210.log")
```
- **Location:** Top of logging.R
- **Benefit:** Single source of truth for log directory

**2. Better Log File Naming**
```r
# Current (COHA): pipeline_YYYY-MM-DD.log
# Reference: pipeline_log.txt (single file, appended)
# Recommendation: Use COHA's approach (better isolation) but add time:
# pipeline_YYYY-MM-DD_HHmmss.log (daily + start time)
```

**3. Add `show_log()` - Display Log Contents**
```r
show_log <- function(n_lines = 50) {
  log_file <- get_log_file()
  lines <- readLines(log_file)
  if (!is.null(n_lines) && n_lines < length(lines)) {
    start_idx <- length(lines) - n_lines + 1
    lines <- lines[start_idx:length(lines)]
  }
  for (i in seq_along(lines)) {
    cat(sprintf("%4d: %s\n", i, lines[i]))
  }
}
```
- **Status:** 🟢 EASY ADD
- **Location:** logging.R
- **Benefit:** Quick inspection of logs from R console

---

### MODULE 3: core/console.R (445 lines total)

**STATUS:** NOT IMPLEMENTED IN COHA - High value to add

#### HIGH-PRIORITY INTEGRATIONS

**1. `center_text()` - Text Centering Utility**
```r
center_text <- function(text, width) {
  pad_total <- width - nchar(text)
  pad_left <- floor(pad_total / 2)
  pad_right <- ceiling(pad_total / 2)
  sprintf("%s%s%s", strrep(" ", pad_left), text, strrep(" ", pad_right))
}
```
- **Status:** ⭐ HIGH PRIORITY
- **Complexity:** Trivial (4 lines)
- **Impact:** Foundation for formatted console output
- **COHA Use Cases:**
  - Center stage headers
  - Format pipeline completion messages
  - Create visual section dividers
- **Recommended Location:** R/functions/console.R (new file)

---

**2. `print_stage_header()` - ASCII Box Stage Headers**
```r
print_stage_header <- function(stage_num, title, width = 65) {
  stage_text <- sprintf("STAGE %s: %s", stage_num, title)
  centered <- center_text(stage_text, width)
  message(sprintf("\n+%s+", strrep("-", width)))
  message(sprintf("|%s|", centered))
  message(sprintf("+%s+\n", strrep("-", width)))
  invisible(NULL)
}
```
- **Status:** ⭐ HIGH PRIORITY
- **Complexity:** Trivial (6 lines)
- **Impact:** Professional-looking progress output
- **COHA Adaptation:**
  - Output format: `+---+ |STAGE 01: Load Ridgeline Data| +---+`
  - Useful for `run_pipeline()` major milestones
  - Call in pipeline_generation.R when starting phase
- **Recommended Location:** R/functions/console.R
- **Example in Context:**
  ```r
  print_stage_header("1", "Load & Validate Data")
  print_stage_header("2", "Generate Ridgeline Plots")
  print_stage_header("3", "Save Results")
  ```

---

**3. `print_workflow_summary()` - Multi-line Completion Summary**
```r
print_workflow_summary <- function(workflow_name, stage_results, width = 65) {
  # Prints double-line box with workflow results
}
```
- **Status:** ⭐ MEDIUM PRIORITY
- **Complexity:** Moderate
- **COHA Use Cases:**
  - Summary of `run_pipeline()` results
  - List all 20 plots generated
  - Display timing and file locations
- **Recommended Location:** R/functions/console.R

---

**4. `print_pipeline_complete()` - Final Completion Message**
```r
print_pipeline_complete <- function(workflow_name, summary_stats) {
  # Large, prominent final completion display
}
```
- **Status:** 🟡 MEDIUM PRIORITY
- **Complexity:** Moderate
- **COHA Use Cases:**
  - Final message from `run_pipeline()`
  - Display: plots generated, location, time elapsed
- **Recommended Location:** R/functions/console.R

---

## MODULE 4: core/config.R (1015 lines total)

**STATUS:** Partially relevant - some patterns to adopt

**Applicable Patterns:**

**1. `ensure_study_parameters()` - One-Call Setup**
```r
# Reference pattern: Load → Validate → Create if missing → Save
ensure_study_parameters <- function(yaml_path) {
  cfg <- load_study_parameters(yaml_path)
  if (is.null(cfg)) {
    cfg <- build_study_config()  # Create defaults
    save_study_parameters(cfg, yaml_path)
  }
  validate_study_config(cfg)
  cfg
}
```
- **Status:** 🟡 MEDIUM PRIORITY
- **COHA Adaptation:**
  - Combine load_study_config() + validate_config_paths() + init logging into one call
  - Useful in `run_pipeline()` startup
- **Recommended Addition:** config_loader.R

**2. `get_schedule_config()` - Parameter Extraction**
```r
# Reference pattern: Extract subset of config with normalization
get_schedule_config <- function(config) {
  list(
    detector_specific = config$processing$schedules$detector_specific,
    recording_start = config$processing$recording_start,
    # ... normalize booleans from YAML
  )
}
```
- **Status:** 🟡 MEDIUM PRIORITY (Future)
- **COHA Adaptation:** Extract plot generation parameters by type
- **Implementation:** Not for Phase 1; plan for Phase 3+

---

### MODULE 5: validation/validation.R (1217 lines total)

**STATUS:** Partial implementation in COHA - Major enhancement opportunity

#### CURRENT COHA STATE (assertions.R)
✅ assert_file_exists()
✅ assert_columns_exist()
✅ assert_not_empty()
✅ assert_no_na()
✅ assert_is_numeric()
✅ assert_is_character()
✅ validate_ridgeline_data()

#### MISSING HIGH-PRIORITY ASSERTIONS

**1. `assert_data_frame()` - Type Validation**
```r
assert_data_frame <- function(x, arg_name = "Input") {
  if (!is.data.frame(x)) {
    stop(sprintf("%s must be a data frame.\n  Received: %s",
                 arg_name, paste(class(x), collapse = ", ")))
  }
  invisible(TRUE)
}
```
- **Status:** ⭐ ADD TO COHA
- **Location:** R/functions/assertions.R
- **Impact:** Consistent type checking at function entry points

---

**2. `assert_row_count()` - Exact Row Count**
```r
assert_row_count <- function(df, expected_rows, arg_name = "Data") {
  actual_rows <- nrow(df)
  if (actual_rows != expected_rows) {
    stop(sprintf("%s must have exactly %d row(s), but has %d rows",
                 arg_name, expected_rows, actual_rows))
  }
  invisible(TRUE)
}
```
- **Status:** 🟡 ADD TO COHA
- **Location:** R/functions/assertions.R
- **COHA Use Case:** Verify processed data hasn't been accidentally filtered

---

**3. `assert_date_range()` - Temporal Validation**
```r
assert_date_range <- function(start_date, end_date) {
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  if (end_date < start_date) {
    stop(sprintf("end_date (%s) cannot be before start_date (%s)",
                 end_date, start_date))
  }
  invisible(TRUE)
}
```
- **Status:** 🟡 ADD TO COHA (Future)
- **Location:** R/functions/assertions.R
- **COHA Use Case (Future):** Validate year ranges for period calculations

---

**4. `assert_time_format()` - Time String Validation**
```r
assert_time_format <- function(time_string, arg_name = "Time") {
  if (!grepl("^\\d{2}:\\d{2}:\\d{2}$", time_string)) {
    stop(sprintf("%s must be in HH:MM:SS format. Received: '%s'",
                 arg_name, time_string))
  }
  invisible(TRUE)
}
```
- **Status:** 🟡 ADD TO COHA (Future)
- **Location:** R/functions/assertions.R
- **COHA Use Case (Future):** Validate time parameters in config

---

**5. `assert_directory_exists()` - Directory Validation**
```r
assert_directory_exists <- function(dir_path, create = TRUE, arg_name = NULL) {
  if (!dir.exists(dir_path)) {
    if (create) {
      dir.create(dir_path, recursive = TRUE)
    } else {
      stop(sprintf("Directory not found: %s", dir_path))
    }
  }
  invisible(TRUE)
}
```
- **Status:** ⭐ ADD TO COHA
- **Location:** R/functions/assertions.R
- **Improvement:** Combine with ensure_dir_exists() pattern

---

**6. `assert_scalar_string()` - Input Type Validation**
```r
assert_scalar_string <- function(x, arg_name = "Input") {
  if (!is.character(x) || length(x) != 1) {
    stop(sprintf("%s must be a single character string", arg_name))
  }
  invisible(TRUE)
}
```
- **Status:** 🟡 ADD TO COHA
- **Location:** R/functions/assertions.R
- **COHA Use Case:** Validate plot IDs, palette names, etc.

---

#### COMPOSITE VALIDATORS (Not Essential for Phase 1)

**1. `validate_data_frame()` - Combined Checks**
```r
validate_data_frame <- function(df, columns = NULL, min_rows = 0,
                                arg_name = "Data") {
  assert_data_frame(df, arg_name)
  assert_not_empty(df, arg_name)
  if (!is.null(columns)) assert_columns_exist(df, columns)
  invisible(TRUE)
}
```
- **Status:** 🟡 MEDIUM PRIORITY
- **Benefit:** Reduce boilerplate in validation
- **Location:** R/functions/assertions.R

---

**2. Quality Check Functions (Low Priority for Phase 1)**
```r
check_column_completeness()   # Report NA% per column
check_duplicates()              # Report duplicate rows
validate_calls_per_night()      # Domain-specific consistency
```
- **Status:** 🟡 LOW PRIORITY
- **Timeline:** Phase 3+
- **Location:** R/functions/validation_checks.R (new file, future)

---

## SUMMARY TABLE: INTEGRATION RECOMMENDATIONS

| Function | Module | Priority | Complexity | COHA Status | Location |
|----------|--------|----------|------------|-------------|----------|
| `%\|\|%` | utilities | ⭐ HIGH | Trivial | Add | utilities.R |
| `ensure_dir_exists()` | utilities | ⭐ HIGH | Trivial | Add/Enhance | utilities.R |
| `safe_read_csv()` | utilities | ⭐ HIGH | Moderate | Add | utilities.R |
| `convert_empty_to_na()` | utilities | 🟡 MEDIUM | Trivial | Add | utilities.R |
| `find_most_recent_file()` | utilities | 🟡 MEDIUM | Moderate | Plan Phase 2+ | utilities.R |
| `make_output_path()` | utilities | 🟡 MEDIUM | Trivial | Add | utilities.R |
| `log_message()` | logging | ✅ EXISTS | - | - | logging.R |
| `show_log()` | logging | 🟡 MEDIUM | Trivial | Add | logging.R |
| `center_text()` | console | ⭐ HIGH | Trivial | Add | console.R |
| `print_stage_header()` | console | ⭐ HIGH | Trivial | Add | console.R |
| `print_workflow_summary()` | console | 🟡 MEDIUM | Moderate | Add | console.R |
| `print_pipeline_complete()` | console | 🟡 MEDIUM | Moderate | Add | console.R |
| `assert_data_frame()` | validation | ⭐ HIGH | Trivial | Add | assertions.R |
| `assert_row_count()` | validation | 🟡 MEDIUM | Trivial | Add | assertions.R |
| `assert_date_range()` | validation | 🟡 MEDIUM | Trivial | Plan Phase 2+ | assertions.R |
| `assert_time_format()` | validation | 🟡 MEDIUM | Trivial | Plan Phase 2+ | assertions.R |
| `assert_directory_exists()` | validation | ⭐ HIGH | Trivial | Add | assertions.R |
| `assert_scalar_string()` | validation | 🟡 MEDIUM | Trivial | Add | assertions.R |
| `validate_data_frame()` | validation | 🟡 MEDIUM | Trivial | Plan Phase 2+ | assertions.R |

---

## IMPLEMENTATION ROADMAP

### PHASE 1 ENHANCEMENT (This Week)
**Files to Create/Modify:**
1. ✅ R/functions/utilities.R (new) - Add 5 functions:
   - `%||%`
   - `ensure_dir_exists()`
   - `safe_read_csv()`
   - `convert_empty_to_na()`
   - `make_output_path()`

2. ✅ R/functions/console.R (new) - Add 4 functions:
   - `center_text()`
   - `print_stage_header()`
   - `print_workflow_summary()`
   - `print_pipeline_complete()`

3. ✅ R/functions/assertions.R (enhance) - Add 6 functions:
   - `assert_data_frame()`
   - `assert_row_count()`
   - `assert_directory_exists()`
   - `assert_scalar_string()`
   - `validate_data_frame()` (composite)
   - Update existing assertions with better error messages

4. ✅ R/functions/logging.R (enhance) - Add:
   - `show_log()` function
   - Log directory constant

5. ✅ R/functions/config_loader.R (enhance) - Add:
   - `ensure_study_parameters()` wrapper

---

### PHASE 2+ (Future Planning)
**Defer to later:**
- `find_most_recent_file()` - Checkpoint loading
- `make_versioned_path()` - File versioning
- `assert_date_range()`, `assert_time_format()` - Temporal validation
- Quality check functions (check_column_completeness, etc.)

---

## NEXT STEPS

Ready to implement? I recommend:

1. **Create R/functions/utilities.R** with 5 reference functions (adapted to COHA)
2. **Create R/functions/console.R** with 4 reference functions
3. **Enhance R/functions/assertions.R** with 6 additional assertions
4. **Enhance R/functions/logging.R** with show_log() utility
5. **Update R/pipeline/pipeline.R** to use new utilities and console functions

**Total additions:** ~400 lines of well-tested helper code
**Benefit:** Professional output, better error messages, safer I/O, cleaner code

Want me to implement these now?
