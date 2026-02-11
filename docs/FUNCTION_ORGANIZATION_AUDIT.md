# COHA Function Organization Audit & Cleanup Plan

**Date:** 2026-02-11  
**Purpose:** Analyze existing R/functions/ structure and reorganize for clarity  
**Status:** Analysis complete, cleanup plan ready

---

## EXECUTIVE SUMMARY

**Current State:** 11 files in R/functions/ with some organizational issues:
- ✓ Good separation: logging.R, console.R, assertions.R
- ⚠️ Config duplication: config.R (plot configs) vs config_loader.R (YAML loader)
- ⚠️ Utilities incomplete: Has basics but missing artifact registry functions
- ⚠️ Domain-specific scattered: Phase 3 files, plot files, quality/robustness

**Recommendation:** Create **core/** subdirectory with clean module separation matching Reference_code structure, consolidate config files, keep domain-specific at top level.

---

## PART 1: CURRENT INVENTORY

### File-by-File Analysis

#### ✅ **R/functions/logging.R** (406 lines)
**Functions:**
- `initialize_pipeline_log()` - Create log file
- `get_log_file()` - Get current log path
- `log_message()` - Write timestamped log entries
- `show_log()` - Display recent log entries
- `clear_log()` - Clean log history

**Status:** ✓ KEEP AS-IS  
**Matches Reference:** Yes (core/logging.R pattern)  
**Action:** Move to core/logging.R

---

#### ✅ **R/functions/console.R** (356 lines)
**Functions:**
- `center_text()` - Text centering helper
- `print_stage_header()` - Stage box formatting
- `print_workflow_summary()` - Workflow result display
- `print_pipeline_complete()` - Pipeline completion message

**Status:** ✓ KEEP AS-IS  
**Matches Reference:** Yes (core/console.R pattern)  
**Action:** Move to core/console.R

---

#### ✅ **R/functions/assertions.R** (575 lines)
**Functions:**
- `assert_file_exists()` - File validation
- `assert_columns_exist()` - Schema checking
- `assert_not_empty()` - Data frame emptiness
- `assert_no_na()` - NA value checking
- `assert_is_numeric()` - Type validation
- `assert_is_character()` - Type validation
- `validate_ridgeline_data()` - COHA-specific validation
- `assert_data_frame()` - Data frame type check
- `assert_row_count()` - Row count validation
- `assert_directory_exists()` - Directory validation
- `assert_scalar_string()` - String validation
- `validate_data_frame()` - Composite validation

**Status:** ✓ KEEP AS-IS  
**Matches Reference:** Not in Reference (COHA-specific)  
**Action:** Move to core/assertions.R (good defensive programming)

---

#### ⚠️ **R/functions/utilities.R** (383 lines)
**Functions:**
- `%||%` - Null coalescing operator
- `ensure_dir_exists()` - Directory creation
- `safe_read_csv()` - Non-stopping CSV read
- `convert_empty_to_na()` - Empty string conversion
- `make_output_path()` - Timestamped path generation

**Status:** ⚠️ INCOMPLETE  
**Missing from Reference:**
- `find_most_recent_file()` - Critical for checkpoint discovery
- `make_versioned_path()` - Version incrementation
- `fill_readme_template()` - Template processing
- `save_checkpoint_and_register()` - Atomic save + register

**Action:** 
1. Move to core/utilities.R
2. ADD missing functions from Reference_code/core/utilities.R

---

#### ⚠️ **R/functions/config.R** (194 lines)
**Contents:**
- Plot configurations list (20 ridgeline variants)
- Pure data structure (no functions)

**Status:** ⚠️ MISNAMED - Should be R/config/ridgeline_config.R  
**Issue:** This is configuration DATA, not utility FUNCTIONS  
**Action:** MOVE to R/config/ridgeline_config.R (already exists there!)

---

#### ⚠️ **R/functions/config_loader.R** (345 lines)
**Functions:**
- `load_study_config()` - Load YAML configuration
- `get_config_value()` - Extract nested config value
- `get_enabled_plot_types()` - Check plot type flags
- `validate_config_paths()` - Ensure output directories
- `print_config_summary()` - Display config summary

**Status:** ✓ GOOD FUNCTIONS  
**Issue:** Name collision with config.R  
**Action:** 
1. RENAME to core/config.R (it's the config manager)
2. DELETE old R/functions/config.R (duplicate of R/config/ridgeline_config.R)

---

#### ✅ **R/functions/robustness.R** (425 lines)
**Functions:**
- `create_result()` - Initialize result object
- `set_result_status()` - Update result status
- `add_error()` - Add error to result
- `add_warning()` - Add warning to result
- `add_quality_metrics()` - Add quality scores
- `start_timer()` - Begin timing
- `stop_timer()` - End timing
- `format_error_message()` - Error formatting
- `is_result_success()` - Check success status

**Status:** ✓ DOMAIN-SPECIFIC (Phase 3 pattern)  
**Matches Reference:** No (COHA-specific robustness pattern)  
**Action:** KEEP at R/functions/robustness.R (not core, phase-specific)

---

#### ✅ **R/functions/data_quality.R** (415 lines)
**Functions:**
- `compute_quality_metrics()` - Calculate quality indicators
- `calculate_quality_score()` - Aggregate to 0-100 score
- `generate_quality_report()` - Human-readable summary

**Status:** ✓ DOMAIN-SPECIFIC (COHA quality assessment)  
**Matches Reference:** No (COHA-specific)  
**Action:** KEEP at R/functions/data_quality.R (not core, phase-specific)

---

#### ✅ **R/functions/phase3_data_operations.R**
**Status:** DOMAIN-SPECIFIC (Phase 3 data processing)  
**Action:** KEEP at top level (not core)

---

#### ✅ **R/functions/phase3_plot_operations.R**
**Status:** DOMAIN-SPECIFIC (Phase 3 plot generation)  
**Action:** KEEP at top level (not core)

---

#### ✅ **R/functions/plot_function.R**
**Functions:**
- `create_ridgeline_plot()` - Generate single ridgeline plot

**Status:** DOMAIN-SPECIFIC (Ridgeline plotting)  
**Action:** KEEP at top level (not core)

---

## PART 2: MISSING FUNCTIONS (From Reference_code)

### Critical Missing: Artifact Registry (artifacts.R)

**Functions needed:**
- `init_artifact_registry()` ⭐⭐⭐ CRITICAL
- `register_artifact()` ⭐⭐⭐ CRITICAL
- `get_artifact()` ⭐⭐ USEFUL
- `list_artifacts()` ⭐⭐ USEFUL
- `get_latest_artifact()` ⭐⭐ USEFUL
- `hash_file()` ⭐⭐⭐ CRITICAL
- `hash_dataframe()` ⭐⭐⭐ CRITICAL
- `verify_artifact()` ⭐⭐ USEFUL
- `save_and_register_rds()` ⭐⭐⭐ CRITICAL
- `discover_pipeline_rds()` ⭐⭐ USEFUL
- `validate_rds_structure()` ⭐⭐ USEFUL

**Source:** Reference_code/core/artifacts.R (919 lines)  
**Action:** CREATE R/functions/core/artifacts.R (adapted for COHA)

---

### Missing: Release Bundle Creation (release.R)

**Functions needed:**
- `create_release_bundle()` ⭐⭐⭐ HIGH PRIORITY
- `validate_release_inputs()` ⭐⭐ USEFUL
- `generate_manifest()` ⭐⭐ USEFUL

**Source:** Reference_code/core/release.R (556 lines)  
**Action:** CREATE R/functions/core/release.R (adapted for COHA)

---

### Missing: Quarto Report Generation (report.R)

**Functions needed:**
- `generate_quarto_report()` ⭐⭐⭐ CRITICAL

**Source:** Reference_code/output/report.R (214 lines)  
**Action:** CREATE R/functions/output/report.R (adapted for COHA)

---

### Missing: Extended Utilities

**Functions to add to utilities.R:**
- `find_most_recent_file()` ⭐⭐⭐ CRITICAL
- `make_versioned_path()` ⭐⭐ USEFUL
- `fill_readme_template()` ⭐ OPTIONAL

**Source:** Reference_code/core/utilities.R (selected functions)  
**Action:** ADD to existing R/functions/core/utilities.R

---

## PART 3: REORGANIZATION PLAN

### Proposed Directory Structure

```
R/functions/
├── core/                           # NEW - Universal utilities
│   ├── artifacts.R                 # NEW - From Reference_code (Phase 0b)
│   ├── assertions.R                # MOVE from R/functions/assertions.R
│   ├── config.R                    # RENAME from config_loader.R
│   ├── console.R                   # MOVE from R/functions/console.R
│   ├── logging.R                   # MOVE from R/functions/logging.R
│   ├── release.R                   # NEW - From Reference_code (Phase 0b)
│   └── utilities.R                 # MOVE + EXTEND from R/functions/utilities.R
│
├── output/                         # NEW - Report generation
│   └── report.R                    # NEW - From Reference_code (Phase 0b)
│
├── data_quality.R                  # KEEP - Domain-specific (COHA quality)
├── phase3_data_operations.R        # KEEP - Domain-specific
├── phase3_plot_operations.R        # KEEP - Domain-specific
├── plot_function.R                 # KEEP - Domain-specific
└── robustness.R                    # KEEP - Domain-specific (Phase 3)
```

### What Gets Deleted

```
DELETE: R/functions/config.R        # Duplicate of R/config/ridgeline_config.R
```

---

## PART 4: STEP-BY-STEP CLEANUP ACTIONS

### Step 1: Create Directory Structure
```r
# Create new directories
dir.create("R/functions/core", recursive = TRUE, showWarnings = FALSE)
dir.create("R/functions/output", recursive = TRUE, showWarnings = FALSE)
```

### Step 2: Move Existing Files to core/
```r
# Move utilities
file.rename(
  "R/functions/logging.R",
  "R/functions/core/logging.R"
)

file.rename(
  "R/functions/console.R",
  "R/functions/core/console.R"
)

file.rename(
  "R/functions/assertions.R",
  "R/functions/core/assertions.R"
)

file.rename(
  "R/functions/utilities.R",
  "R/functions/core/utilities.R"
)
```

### Step 3: Rename config_loader.R → core/config.R
```r
file.rename(
  "R/functions/config_loader.R",
  "R/functions/core/config.R"
)
```

### Step 4: Delete Duplicate config.R
```r
# This is a duplicate of R/config/ridgeline_config.R
file.remove("R/functions/config.R")
```

### Step 5: Create New Files from Reference_code (Phase 0b)
```r
# Will be done in Phase 0b implementation:
# - R/functions/core/artifacts.R (from Reference_code/core/artifacts.R)
# - R/functions/core/release.R (from Reference_code/core/release.R)
# - R/functions/output/report.R (from Reference_code/output/report.R)
```

### Step 6: Extend core/utilities.R
Add missing functions from Reference_code:
- `find_most_recent_file()`
- `make_versioned_path()`
- `fill_readme_template()`

### Step 7: Update Sourcing in run_project.R
```r
# OLD:
source("R/functions/utilities.R")
source("R/functions/logging.R")
source("R/functions/console.R")
source("R/functions/config_loader.R")

# NEW:
source("R/functions/core/utilities.R")
source("R/functions/core/logging.R")
source("R/functions/core/console.R")
source("R/functions/core/config.R")
source("R/functions/core/artifacts.R")  # Phase 0b
```

---

## PART 5: FUNCTION DEPENDENCY GRAPH

### Core Module Dependencies

```
core/utilities.R (FOUNDATION - no internal deps)
├── Imports: readr, base R
└── Functions: %||%, ensure_dir_exists, safe_read_csv, 
               make_output_path, find_most_recent_file

core/logging.R
├── Depends on: core/utilities.R (ensure_dir_exists)
├── Imports: here, base R
└── Functions: initialize_pipeline_log, log_message, show_log

core/console.R (INDEPENDENT)
├── Imports: base R only
└── Functions: print_stage_header, print_workflow_summary

core/assertions.R
├── Depends on: core/logging.R (for logging validation)
├── Imports: base R
└── Functions: assert_*, validate_*

core/config.R
├── Depends on: core/assertions.R, core/logging.R
├── Imports: yaml, here
└── Functions: load_study_config, get_config_value

core/artifacts.R (Phase 0b)
├── Depends on: core/utilities.R (ensure_dir_exists)
├── Imports: yaml, digest, here
└── Functions: init_artifact_registry, register_artifact, 
               hash_file, save_and_register_rds

core/release.R (Phase 0b)
├── Depends on: core/artifacts.R, core/utilities.R
├── Imports: yaml, zip, digest, here
└── Functions: create_release_bundle, validate_release_inputs

output/report.R (Phase 0b)
├── Depends on: core/artifacts.R (for RDS validation)
├── Imports: quarto, yaml, here
└── Functions: generate_quarto_report
```

### Sourcing Order (for load_all.R or run_project.R)

```r
# Order matters! Source from least to most dependent:

# 1. Foundation (no internal deps)
source("R/functions/core/utilities.R")

# 2. Console (independent, used for headers)
source("R/functions/core/console.R")

# 3. Logging (uses utilities)
source("R/functions/core/logging.R")

# 4. Assertions (uses logging)
source("R/functions/core/assertions.R")

# 5. Config (uses assertions + logging)
source("R/functions/core/config.R")

# 6. Artifacts (uses utilities)
source("R/functions/core/artifacts.R")

# 7. Release (uses artifacts + utilities)
source("R/functions/core/release.R")

# 8. Report generation (uses artifacts)
source("R/functions/output/report.R")

# 9. Domain-specific (any order)
source("R/functions/robustness.R")
source("R/functions/data_quality.R")
source("R/functions/phase3_data_operations.R")
source("R/functions/phase3_plot_operations.R")
source("R/functions/plot_function.R")
```

---

## PART 6: WHAT STAYS AT TOP LEVEL

These files are **domain-specific** to COHA dispersal analysis and should NOT move to core/:

### ✅ R/functions/robustness.R
- Phase 3 specific result handling
- Not reusable across projects
- Keep at top level

### ✅ R/functions/data_quality.R
- COHA-specific quality metrics
- Not reusable across projects
- Keep at top level

### ✅ R/functions/phase3_data_operations.R
- Phase 3 data processing
- COHA dispersal logic
- Keep at top level

### ✅ R/functions/phase3_plot_operations.R
- Phase 3 plot generation
- Ridgeline-specific
- Keep at top level

### ✅ R/functions/plot_function.R
- Ridgeline plot creation
- COHA-specific styling
- Keep at top level

---

## PART 7: CONFIG FILE CLEANUP

### Current Confusion: TWO Config Files

**R/functions/config.R:**
- Contains plot_configs list (20 ridgeline variants)
- Pure data, no functions
- **This is a duplicate!**

**R/config/ridgeline_config.R:**
- Contains same plot_configs list
- Properly located in R/config/
- **This is the correct location!**

**R/functions/config_loader.R:**
- Contains config loading functions
- Loads from inst/config/study_parameters.yaml
- Should be at R/functions/core/config.R

### Resolution

```r
# DELETE duplicate
file.remove("R/functions/config.R")

# RENAME config loader
file.rename(
  "R/functions/config_loader.R",
  "R/functions/core/config.R"
)

# KEEP (no change)
# R/config/ridgeline_config.R - already correct location
```

---

## PART 8: IMPLEMENTATION CHECKLIST

### Phase 0b.0: Pre-cleanup Validation
- [ ] Verify all files tracked in git
- [ ] Create backup branch: `git checkout -b function-cleanup-backup`
- [ ] Run existing tests to establish baseline
- [ ] Document current sourcing patterns

### Phase 0b.1: Directory Creation
- [ ] Create R/functions/core/
- [ ] Create R/functions/output/
- [ ] Verify directories created successfully

### Phase 0b.2: Move Existing Core Files
- [ ] Move logging.R → core/logging.R
- [ ] Move console.R → core/console.R
- [ ] Move assertions.R → core/assertions.R
- [ ] Move utilities.R → core/utilities.R
- [ ] Rename config_loader.R → core/config.R

### Phase 0b.3: Delete Duplicates
- [ ] Confirm R/config/ridgeline_config.R exists
- [ ] Delete R/functions/config.R
- [ ] Verify no references to old path

### Phase 0b.4: Extend utilities.R
- [ ] Add find_most_recent_file() from Reference_code
- [ ] Add make_versioned_path() from Reference_code
- [ ] Add fill_readme_template() from Reference_code
- [ ] Test all new functions

### Phase 0b.5: Create New Modules (From Reference_code)
- [ ] Create core/artifacts.R (from Reference_code/core/artifacts.R)
- [ ] Create core/release.R (from Reference_code/core/release.R)
- [ ] Create output/report.R (from Reference_code/output/report.R)
- [ ] Adapt ARTIFACT_TYPES for COHA
- [ ] Adapt validation for COHA schema

### Phase 0b.6: Update Sourcing
- [ ] Update R/run_project.R source() calls
- [ ] Create/update load_all.R with correct order
- [ ] Update any test files with new paths

### Phase 0b.7: Testing
- [ ] Source all files in correct order
- [ ] Run pipeline end-to-end
- [ ] Verify reports still generate
- [ ] Check logs for errors

### Phase 0b.8: Documentation
- [ ] Update README with new structure
- [ ] Document sourcing order
- [ ] Update PHASE_0_CODE_ANALYSIS_AND_ADAPTATION.md
- [ ] Mark Phase 0b complete

---

## PART 9: BEFORE & AFTER COMPARISON

### BEFORE (Current State)
```
R/functions/
├── assertions.R          # Good but not in core/
├── config.R              # DUPLICATE (should delete)
├── config_loader.R       # Should be core/config.R
├── console.R             # Good but not in core/
├── data_quality.R        # Domain-specific (correct)
├── logging.R             # Good but not in core/
├── phase3_data_operations.R  # Domain-specific (correct)
├── phase3_plot_operations.R  # Domain-specific (correct)
├── plot_function.R       # Domain-specific (correct)
├── robustness.R          # Domain-specific (correct)
└── utilities.R           # Incomplete, not in core/

MISSING:
- Artifact registry
- Release bundle creation
- Report generation
- Extended utilities
```

### AFTER (Proposed State)
```
R/functions/
├── core/                 # ← NEW
│   ├── artifacts.R       # ← NEW (Phase 0b)
│   ├── assertions.R      # ← Moved
│   ├── config.R          # ← Renamed from config_loader.R
│   ├── console.R         # ← Moved
│   ├── logging.R         # ← Moved
│   ├── release.R         # ← NEW (Phase 0b)
│   └── utilities.R       # ← Moved + Extended
│
├── output/               # ← NEW
│   └── report.R          # ← NEW (Phase 0b)
│
├── data_quality.R        # ← No change (domain-specific)
├── phase3_data_operations.R   # ← No change
├── phase3_plot_operations.R   # ← No change
├── plot_function.R       # ← No change
└── robustness.R          # ← No change

DELETED:
- config.R (was duplicate)

COMPLETE:
✓ Artifact registry
✓ Release bundle creation
✓ Report generation
✓ Extended utilities
✓ Clean separation: core vs domain-specific
```

---

## CONCLUSION

**Action Required:** Execute Steps 1-7 to reorganize R/functions/ with clean core/ separation

**Estimated Time:** 2-4 hours for reorganization + 8-12 hours for Phase 0b new modules

**Risk Level:** Low (moving files, clear dependencies)

**Benefits:**
- ✓ Clear separation: core vs domain-specific
- ✓ Matches Reference_code structure
- ✓ Removes config.R duplication
- ✓ Prepares for Phase 0b (artifact registry)
- ✓ Easier to source in correct order
- ✓ More maintainable long-term

**Next Step:** Execute reorganization (Steps 1-4), then proceed to Phase 0b implementation

---

**Document Version:** 1.0  
**Status:** Ready for implementation  
**Author:** GitHub Copilot  
**Date:** 2026-02-11
