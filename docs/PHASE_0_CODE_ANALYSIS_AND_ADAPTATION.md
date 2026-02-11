# PHASE 0: KPro Reference Code Analysis & Adaptation Plan

**Status:** Design Document (Phase 0a complete, Phase 0b planning)  
**Date:** 2025-02-09  
**Scope:** Analyze Reference_code/ implementations and plan COHA adaptations  
**Goal:** Reuse proven functions from KPro bat acoustic project instead of rewriting

---

## EXECUTIVE SUMMARY

The Reference_code/ folder contains **battle-tested implementations** of 4 core modules from the KPro (bat acoustic) project. Instead of building artifact registry functions from scratch, we will **adapt existing KPro functions** for COHA using the same architecture and patterns.

**Key Insight:** KPro and COHA share identical needs for:
- Artifact registry (tracking outputs with hashes)
- Release bundles (portable zip archives)
- Report generation (Quarto rendering)
- File utilities (discovery, hashing, I/O)

The functions differ only in **metadata schema** (bat species → dispersal metrics), not in underlying logic.

---

## PART 1: REFERENCE CODE FILE INVENTORY

### 1.1 `Reference_code/core/artifacts.R` (919 lines)

**Purpose:** Artifact registry & file provenance tracking  
**Core Responsibility:** Tracks all pipeline outputs with SHA256 hashes and metadata

#### Key Functions:

| Function | Signature | Imports | Purpose | Relevance to COHA |
|----------|-----------|---------|---------|-------------------|
| `init_artifact_registry()` | `() → List` | yaml, here, base R | Create/load registry | ⭐⭐⭐ CRITICAL - Use as-is |
| `register_artifact()` | `(registry, artifact_name, type, workflow, file_path, input_artifacts, metadata, data_hash) → List` | digest, base R | Add artifact entry | ⭐⭐⭐ CRITICAL - Adapt metadata |
| `get_artifact()` | `(registry, artifact_name) → List\|NULL` | base R | Retrieve metadata | ⭐⭐ USEFUL - No changes needed |
| `list_artifacts()` | `(registry, type, workflow) → df` | purrr, base R | List all artifacts | ⭐⭐ USEFUL - No changes needed |
| `get_latest_artifact()` | `(registry, type) → List\|NULL` | purrr, base R | Get most recent | ⭐⭐ USEFUL - No changes needed |
| `hash_file()` | `(file_path) → char[64]` | digest | SHA256 file hash | ⭐⭐⭐ CRITICAL - Use as-is |
| `hash_dataframe()` | `(df, sort_by) → char[64]` | digest | Content-based hash | ⭐⭐⭐ CRITICAL - Use as-is |
| `verify_artifact()` | `(registry, artifact_name) → logical` | digest | Verify integrity | ⭐⭐ USEFUL - No changes needed |
| `save_and_register_rds()` | `(object, file_path, artifact_type, workflow, registry, metadata, verbose) → List` | base R, digest | Atomic RDS save + register | ⭐⭐⭐ CRITICAL - Use as-is |
| `discover_pipeline_rds()` | `(rds_dir) → List` | base R | Find summary/plot RDS | ⭐⭐ ADAPT - Change RDS naming |
| `validate_rds_structure()` | `(all_summaries, all_plots) → List` | base R | Validate RDS contents | ⭐⭐ ADAPT - COHA schema |

**Adaptation Needs:**
- `ARTIFACT_TYPES` list: Add COHA-specific types (e.g., "ridgeline_plots", "dispersal_summary")
- `REGISTRY_PATH`: Change from `inst/config/` to COHA's path structure (e.g., `R/config/`)
- `discover_pipeline_rds()`: Expects `summary_data_*.rds`, `plot_objects_*.rds` naming → Change to COHA naming
- `validate_rds_structure()`: Expects bat-specific elements (detector_summary, species) → Use COHA summaries

**Code Quality:** ⭐⭐⭐⭐⭐
- Excellent separation of concerns
- Clear contract documentation
- Comprehensive error handling
- No hardcoded paths (uses `here::here()`)

---

### 1.2 `Reference_code/core/release.R` (556 lines)

**Purpose:** Create portable release bundles (zip archives)  
**Core Responsibility:** Package pipeline outputs into self-contained deliverables

#### Key Functions:

| Function | Signature | Imports | Purpose | Relevance to COHA |
|----------|-----------|---------|---------|-------------------|
| `create_release_bundle()` | `(study_id, calls_per_night_final, kpro_master, all_summaries, all_plots, report_path, study_params, output_dir, registry) → char` | yaml, zip, here, base R | Create zip bundle | ⭐⭐⭐ CRITICAL - Adapt data structure |
| `validate_release_inputs()` | `(calls_per_night_final, kpro_master) → List` | base R | Check inputs | ⭐⭐ ADAPT - COHA columns |
| `generate_manifest()` | `(release_name, study_id, study_params, staging_dir, cpn_path, master_path, n_figures) → List` | base R, digest | Create provenance YAML | ⭐⭐ ADAPT - COHA metadata |

**Release Bundle Structure (KPro):**
```
kpro_release_<study_id>_<timestamp>/
├── manifest.yaml              # Full provenance
├── data/
│   ├── calls_per_night_raw.csv
│   ├── kpro_master.csv
│   └── summary/
│       ├── detector_summary.csv
│       ├── study_summary.csv
│       └── species_summary.csv
├── figures/
│   ├── quality/
│   ├── detector/
│   ├── species/
│   └── temporal/
├── report/
│   └── kpro_report.html
└── analysis_bundle.rds
```

**Adaptation for COHA:**
- Remove bat-specific data (detector_summary, species_summary)
- Add dispersal-specific summaries (natal_summary, plot_summary)
- Keep structure (portable, self-documenting)
- Adapt column validation in `validate_release_inputs()`

**Code Quality:** ⭐⭐⭐⭐
- Clear directory structure generation
- Atomic operations (no partial failures)
- Cross-platform zip handling (Windows path fix included!)
- Good separation of manifest generation

---

### 1.3 `Reference_code/core/utilities.R` (1,369 lines)

**Purpose:** Foundational utilities with ZERO domain dependencies  
**Core Responsibility:** Safe I/O, path generation, file discovery (bedrock of pipeline)

#### Key Functions (Selected):

| Function | Signature | Imports | Purpose | Relevance to COHA |
|----------|-----------|---------|---------|-------------------|
| `%\|\|%` | `(x, y)` | base R | Null coalescing | ⭐⭐⭐ CRITICAL - Use as-is |
| `ensure_dir_exists()` | `(dir_path) → logical` | base R | Create dir if missing | ⭐⭐⭐ CRITICAL - Use as-is |
| `safe_read_csv()` | `(file_path, error_log_path, verbose) → df\|NULL` | readr, base R | Non-stopping CSV read | ⭐⭐⭐ CRITICAL - Use as-is |
| `convert_empty_to_na()` | `(df, columns) → df` | dplyr | Replace "" with NA | ⭐⭐ USEFUL - Use as-is |
| `find_most_recent_file()` | `(directory, pattern, error_if_none, hint) → char` | base R, lubridate | Find newest timestamped file | ⭐⭐⭐ CRITICAL - Use as-is |
| `make_output_path()` | `(workflow_num, base_name, extension, output_dir) → char` | here, base R | Generate timestamped path | ⭐⭐⭐ CRITICAL - Use as-is |
| `make_versioned_path()` | `(workflow_num, base_name, extension, output_dir) → char` | base R | Auto-increment version | ⭐⭐ USEFUL - Use as-is |
| `fill_readme_template()` | `(template_path, output_path, parameters, log_path) → logical` | base R | Populate README | ⭐⭐ OPTIONAL - Use if releasing |
| `log_stage_start()` | `(stage_num, title, verbose, log_path, workflow_prefix) → NULL` | base R (+ log_message, print_stage_header from other modules) | Log stage transition | ⭐⭐ OPTIONAL - Use in orchestrator |
| `save_checkpoint_and_register()` | `(data, file_path, checkpoint_name, output_dir, artifact_name, artifact_type, workflow, metadata, data_hash, verbose, registry) → List` | readr, base R, digest | Atomic CSV save + register | ⭐⭐⭐ CRITICAL - Use with adaptation |

**Note:** Utilities has been *split across multiple files* in KPro for modularity:
- **utilities.R** (this file): Core I/O, paths, file discovery
- **logging.R**: log_message(), initialize_pipeline_log() (not needed yet)
- **console.R**: print_stage_header(), print_workflow_summary() (not provided)
- **orchestration_helpers.R**: Higher-level workflow patterns (not provided)

**Adaptation Needs:**
- `save_checkpoint_and_register()` includes DateTime formatting logic → Adapt for COHA dates
- Path generation assumes "workflow_num" prefix (e.g., "02_") → COHA uses different naming (phase1_analysis)
- `find_most_recent_file()` uses YYYYMMDD_HHMMSS timestamp extraction → Compatible with current COHA naming

**Code Quality:** ⭐⭐⭐⭐⭐
- Foundational functions with zero domain dependencies
- Excellent documentation (PURPOSE, CONTRACT, DOES NOT sections)
- Safe defaults (safe_read_csv returns NULL, never errors)
- Deterministic behavior (uses filename timestamps, not mtime)

---

### 1.4 `Reference_code/output/report.R` (214 lines)

**Purpose:** Render Quarto report templates with pre-computed data  
**Core Responsibility:** Generate HTML reports from summary/plot objects

#### Key Functions:

| Function | Signature | Imports | Purpose | Relevance to COHA |
|----------|-----------|---------|---------|-------------------|
| `generate_quarto_report()` | `(all_summaries, all_plots, study_params_path, template_path, output_dir, quiet) → char` | quarto, yaml, here, base R | Render .qmd to HTML | ⭐⭐⭐ CRITICAL - Use as-is |

**Key Design Feature:**
```r
# CRITICAL: Sets execute_dir = here::here() for proper context
quarto::quarto_render(
  input = template_path,
  execute_dir = here::here(),  # Ensures load_all.R can be sourced
  execute_params = list(
    summary_rds = summary_rds_path,
    plots_rds = plots_rds_path,
    study_params_path = study_params_path
  )
)
```

This solves the problem COHA recently encountered: ensuring Quarto renders from project root so custom functions can be sourced.

**Adaptation Needs:**
- Parameter names: `all_summaries` → COHA summary structure
- Parameter names: `all_plots` → COHA plot structure
- Template path: Point to COHA's quarto files
- Output naming: Change from `bat_activity_report_` to `coha_dispersal_report_`

**Code Quality:** ⭐⭐⭐⭐
- Clean parameter handling
- RDS path resolution (accepts both objects and file paths)
- Proper error messages
- Integration with artifact registry ready

---

## PART 2: FUNCTIONAL GAP ANALYSIS

### Which KPro Functions Address COHA Needs?

**COHA Current State (from ARTIFACT_REGISTRY_APPLICATION.md):**
- ✓ Running pipeline (R/run_project.R with callr)
- ✓ Generating 20 plots
- ✓ 3 working Quarto reports
- ✗ Tracking outputs (list.files() scanning)
- ✗ Registry of what was produced
- ✗ Hashes for reproducibility
- ✗ Release bundles

**KPro Functions That Address Gaps:**

| COHA Need | KPro Solution | Status |
|-----------|---------------|--------|
| Track plot outputs | `register_artifact()` | Ready |
| Verify report integrity | `hash_file()` | Ready |
| Bundle outputs for sharing | `create_release_bundle()` | Needs adaptation |
| Find latest RDS | `discover_pipeline_rds()` | Needs adaptation |
| Safe CSV I/O | `safe_read_csv()` | Ready |
| Generate timestamped paths | `make_output_path()` | Ready |
| Format report params | `generate_quarto_report()` with execute_dir | Ready |

### Coverage Assessment:

| Phase | Function | Source | Ready | Adaptation |
|-------|----------|--------|-------|-----------|
| Phase 1: Core Registry | `init_artifact_registry()` | artifacts.R | ✓ 95% | Registry path only |
| Phase 1: Core Registry | `register_artifact()` | artifacts.R | ✓ 90% | Metadata schema |
| Phase 2: RDS Caching | `save_and_register_rds()` | artifacts.R | ✓ 95% | Naming conventions |
| Phase 2: RDS Discovery | `discover_pipeline_rds()` | artifacts.R | ⚠ 60% | COHA RDS names |
| Phase 2: RDS Validation | `validate_rds_structure()` | artifacts.R | ⚠ 60% | COHA schema |
| Phase 3: Report Integration | `generate_quarto_report()` | report.R | ✓ 95% | Output filename |
| Phase 4: Bundle + Cleanup | `create_release_bundle()` | release.R | ⚠ 70% | COHA data structure |
| Phase 5: Bundle Release | `validate_release_inputs()` | release.R | ⚠ 70% | COHA columns |
| Phase 5: Bundle Release | `generate_manifest()` | release.R | ⚠ 80% | COHA metadata |

---

## PART 3: DETAILED ADAPTATION REQUIREMENTS

### 3.1 Artifact Types (artifacts.R)

**KPro ARTIFACT_TYPES:**
```r
ARTIFACT_TYPES <- c(
  "raw_input",      # Detector files, raw audio metadata
  "checkpoint",     # Intermediate processing stages
  "masterfile",     # Standardized master detection file
  "cpn_template",   # Calls Per Night template
  "cpn_final",      # Final CPN with validation
  "summary_stats",  # Summary statistics (detector, species, temporal)
  "plot_objects",   # ggplot2 objects from analysis
  "report",         # HTML reports
  "release_bundle", # Portable zip archive
  "validation_report" # Validation HTML
)
```

**COHA ARTIFACT_TYPES (Proposed):**
```r
ARTIFACT_TYPES <- c(
  "raw_data",           # Raw CSV from data/ folder
  "checkpoint",         # Phase-by-phase checkpoints
  "processed_data",     # standardized_coha.csv
  "ridgeline_plots",    # 20 plot variants (new category)
  "summary_stats",      # Dispersal metrics, summaries
  "plot_objects",       # ggplot2 ridgeline objects
  "report",             # HTML reports
  "release_bundle",     # Portable package
  "validation_report"   # Data quality report
)
```

**COHA-Specific Metadata:**
- `ridgeline_config`: "compact_0.85" | "expanded_2.25"
- `palette_name`: "plasma" | "viridis" | "magma" | ... (10 options)
- `dispersal_metrics`: e.g., `list(mean_distance = 42.5, max_distance = 120)`

---

### 3.2 Registry Path

**KPro:**
```r
REGISTRY_PATH <- here::here("inst", "config", "artifact_registry.yaml")
```

**COHA:** Keep same, create directory if needed:
```r
REGISTRY_PATH <- here::here("R", "config", "artifact_registry.yaml")
# Directory: R/config/ already exists
```

---

### 3.3 RDS Discovery & Validation

**KPro Function:**
```r
discover_pipeline_rds <- function(rds_dir) {
  # Finds: summary_data_*.rds, plot_objects_*.rds
  # Returns: list(valid=TRUE, summary_path=..., plots_path=...)
}
```

**COHA Adaptation:**
- KPro names: `summary_data_YYYYMMDD.rds`, `plot_objects_YYYYMMDD.rds`
- COHA names: Currently using `plot_results_*.rds` (or similar)
- **Action:** Rename COHA outputs to match KPro convention OR modify function

**Recommended:** Use KPro naming convention in COHA (clearer semantics)

---

### 3.4 Release Bundle Structure

**KPro Structure:**
```
kpro_release_SchmeeckleBatStudy_20260209_153000/
├── manifest.yaml
├── data/
│   ├── calls_per_night_raw.csv    # For GAMM project
│   ├── kpro_master.csv            # All detections
│   └── summary/
│       ├── detector_summary.csv
│       ├── study_summary.csv
│       └── species_summary.csv
├── figures/quality/, /detector/, /species/, /temporal/
├── report/kpro_report.html
└── analysis_bundle.rds
```

**COHA Adaptation:**
```
coha_dispersal_release_[STUDY_ID]_20250209_153000/
├── manifest.yaml
├── data/
│   ├── standardized_coha.csv      # Main data file
│   └── summary/
│       ├── dispersal_summary.csv
│       ├── study_summary.csv
│       └── na_origins_summary.csv  # Natal origin locations
├── figures/
│   ├── ridgeline_compact/         # Scale 0.85 variants
│   ├── ridgeline_expanded/        # Scale 2.25 variants
│   └── palette_comparison/        # Multi-palette comparison plots
├── report/coha_dispersal_report.html
└── analysis_bundle.rds
```

---

### 3.5 Validation Requirements

**KPro `validate_release_inputs()`:**
```r
# Checks calls_per_night_final:
#   - Columns: Detector, Night, CallsPerNight, RecordingHours
#   - Night is Date class
#   - No NA in Detector
# Checks kpro_master:
#   - Columns: Detector, DateTime_local, auto_id
```

**COHA Adaptation:**
```r
# Checks standardized_coha:
#   - Columns: dispersal_distance, natal_origin, release_location, species, etc.
#   - Numeric checks (distance > 0)
#   - Location data present
# Validates plot outputs:
#   - 20 ridgeline plots exist
#   - PNG files readable
```

---

## PART 4: IMPLEMENTATION PRIORITY

### Critical Priority (Must Adapt First)

| Function | File | Reason |
|----------|------|--------|
| `init_artifact_registry()` | artifacts.R | Foundation - needed before anything else |
| `register_artifact()` | artifacts.R | Core registry operation |
| `hash_file()` | artifacts.R | File integrity verification |
| `hash_dataframe()` | artifacts.R | Reproducibility tracking |
| `save_and_register_rds()` | artifacts.R | Consolidates RDS save + register |
| `generate_quarto_report()` | report.R | Report generation (ready to use!) |

**Effort:** Low (mostly copy-paste + path changes)  
**Risk:** Very low (proven code)  
**Timeline:** 2-4 hours

### High Priority (Adapt in Phase 0b)

| Function | File | Reason |
|----------|------|--------|
| `discover_pipeline_rds()` | artifacts.R | RDS discovery (rename detection) |
| `validate_rds_structure()` | artifacts.R | Validate COHA schema |
| `find_most_recent_file()` | utilities.R | Already compatible! |
| `make_output_path()` | utilities.R | Already compatible! |
| `ensure_dir_exists()` | utilities.R | Already compatible! |

**Effort:** Low-Medium (schema changes)  
**Risk:** Low (clear transformations)  
**Timeline:** 4-6 hours

### Medium Priority (Phase 1 implementation)

| Function | File | Reason |
|----------|------|--------|
| `create_release_bundle()` | release.R | Bundle creation (major feature) |
| `validate_release_inputs()` | release.R | Input validation |
| `generate_manifest()` | release.R | Provenance YAML |

**Effort:** Medium (structure design)  
**Risk:** Medium (bundle design choices)  
**Timeline:** 6-8 hours

---

## PART 5: PHASE 0a & 0b ROADMAP

### Phase 0a: Code Analysis ✅ COMPLETE

**What:** Analyze Reference_code files and create this document  
**Deliverable:** This file (PHASE_0_CODE_ANALYSIS_AND_ADAPTATION.md)  
**Status:** ✅ Done

---

### Phase 0b: Core Function Adaptation

**Goal:** Create adapted versions of critical functions for COHA  
**Output:** New files in R/functions/core/ (adapted from Reference_code)

#### 0b.1 Create R/functions/core/artifacts_coha.R

**Source:** Reference_code/core/artifacts.R  
**Changes:**
- ✏️ ARTIFACT_TYPES: Add/modify for COHA (ridgeline_plots, dispersal_summary)
- ✏️ REGISTRY_PATH: `R/config/artifact_registry.yaml`
- ✏️ remove `discover_pipeline_rds()` (needs 0b.2 work first)
- ⏭️ TODO: Adapt `validate_rds_structure()` for COHA schema
- Copy as-is: All other functions

**Estimated Lines:** ~700 lines (90% from reference)

#### 0b.2 Create R/functions/core/utilities_coha.R

**Source:** Reference_code/core/utilities.R (selected functions)  
**Include:**
- All operators + directory management (lines 1-50)
- `safe_read_csv()` (as-is)
- `convert_empty_to_na()` (as-is)
- `find_most_recent_file()` (as-is)
- `make_output_path()` (as-is)
- `make_versioned_path()` (as-is)
- `ensure_dir_exists()` (as-is)
- `fill_readme_template()` (optional)

**Estimated Lines:** ~400 lines (60% from reference, omit bat-specific)

#### 0b.3 Create R/functions/output/report_coha.R

**Source:** Reference_code/output/report.R  
**Changes:**
- Change output filename: `bat_activity_report_` → `coha_dispersal_report_`
- Rest: Copy as-is (already generic)

**Estimated Lines:** ~200 lines (95% from reference)

#### 0b.4 Create R/functions/core/release_coha.R

**Source:** Reference_code/core/release.R  
**Changes:**
- ✏️ Use COHA data structure (standardized_coha, summary files)
- ✏️ Directory structure: Remove species/, add ridgeline_compact/, ridgeline_expanded/
- ✏️ `validate_release_inputs()`: COHA columns instead of bat columns
- ✏️ `generate_manifest()`: COHA metadata instead of bat metadata
- ⏭️ TODO: Handle plot saving (ridgeline vs ggplot2 facets)

**Estimated Lines:** ~450 lines (80% from reference)

#### 0b.5 Create Integration Tests

**Scope:** Unit tests for adapted functions  
**Files:**
- tests/testthat/test_artifacts_coha.R
- tests/testthat/test_utilities_coha.R
- tests/testthat/test_report_coha.R

**Estimated Lines:** ~400 lines

#### 0b.6 Create Usage Documentation

**File:** docs/PHASE_0b_IMPLEMENTATION_NOTES.md  
**Content:**
- Copy locations (from Reference_code → R/functions/)
- Exact changes made (documented with comments)
- Testing verification
- Integration with R/run_project.R

---

## PART 6: IMPLEMENTATION CHECKLIST

### Pre-Implementation
- [ ] Backup current R/functions/ state
- [ ] Create git branch for Phase 0b work
- [ ] Verify Reference_code files are accessible

### 0b.1: artifacts_coha.R
- [ ] Copy Reference_code/core/artifacts.R → R/functions/core/artifacts_coha.R
- [ ] Update ARTIFACT_TYPES with COHA types
- [ ] Update REGISTRY_PATH to R/config/artifact_registry.yaml
- [ ] Add comments marking COHA-specific changes
- [ ] Test: `init_artifact_registry()` creates correct path ✓
- [ ] Test: `register_artifact()` accepts COHA types ✓
- [ ] Test: `hash_file()` works on COHA CSVs ✓

### 0b.2: utilities_coha.R
- [ ] Copy selected functions from Reference_code/core/utilities.R
- [ ] Verify all imports are available (readr, lubridate, here, dplyr)
- [ ] Test: `ensure_dir_exists()` ✓
- [ ] Test: `safe_read_csv()` on data/data.csv ✓
- [ ] Test: `find_most_recent_file()` finds checkpoints ✓
- [ ] Test: `make_output_path()` generates correct format ✓

### 0b.3: report_coha.R
- [ ] Copy Reference_code/output/report.R → R/functions/output/report_coha.R
- [ ] Change output filename prefix
- [ ] Test: Works with existing plot_gallery.qmd ✓
- [ ] Test: execute_dir = here::here() works ✓

### 0b.4: release_coha.R
- [ ] Copy Reference_code/core/release.R → R/functions/core/release_coha.R
- [ ] Adapt data validation for COHA columns
- [ ] Adapt directory structure
- [ ] Adapt manifest generation
- [ ] Plan plot saving strategy (TBD)
- [ ] Test: Creates valid zip file ✓

### 0b.5: Integration Tests
- [ ] Create tests/testthat/test_*.R files
- [ ] Run: `devtools::test()` ✓
- [ ] Coverage > 80% on critical paths ✓

### 0b.6: Documentation
- [ ] Document all changes with comments in code
- [ ] Create PHASE_0b_IMPLEMENTATION_NOTES.md
- [ ] Link to this document from README
- [ ] Mark reference lines in comments

### Post-Implementation
- [ ] Update R/run_project.R to use new functions
- [ ] Run full pipeline with registry enabled
- [ ] Verify reports still generate correctly
- [ ] Create initial artifact_registry.yaml
- [ ] Test registry persistence across runs

---

## PART 7: INTEGRATION WITH EXISTING COHA CODE

### How Phase 0 Functions Integrate with Current COHA

**Current State (R/run_project.R):**
```r
source("R/functions/phase3_plot_operations.R")
source("R/config/ridgeline_config.R")

# Runs pipeline → generates 20 plots, 3 reports
# But: No tracking of what was produced
```

**After Phase 0b (With Registry):**
```r
# NEW: Core functions
source("R/functions/core/artifacts_coha.R")
source("R/functions/core/utilities_coha.R")
source("R/functions/output/report_coha.R")

# EXISTING (unchanged)
source("R/functions/phase3_plot_operations.R")
source("R/config/ridgeline_config.R")

# ENHANCED: Orchestration
registry <- init_artifact_registry()

# Generate plots (existing)
plot_results <- generate_20_plot_variants()

# NEW: Register plots as artifacts
for (i in 1:20) {
  registry <- save_and_register_rds(
    object = plot_results[[i]],
    file_path = sprintf("results/rds/plot_%d.rds", i),
    artifact_type = "ridgeline_plots",
    workflow = "plot_generation",
    registry = registry,
    metadata = list(variant = i, palette = plot_results[[i]]$palette)
  )
}

# Generate reports (already works)
render_reports(...)

# NEW: Create release bundle
bundle_path <- create_release_bundle(
  study_id = "COHA_2025",
  processed_data = standardized_data,
  all_plots = plot_results,
  all_summaries = summary_stats,
  report_path = "results/reports/full_analysis_report.html",
  registry = registry
)
```

### Minimal Changes to Existing Code
- ✅ phase3_plot_operations.R: No changes needed
- ✅ ridgeline_config.R: No changes needed
- ✅ full_analysis_report.qmd: No changes needed
- ✅ plot_gallery.qmd: No changes needed
- ✅ data_quality_report.qmd: No changes needed
- ⚠️ run_project.R: Add registry initialization + save_and_register calls

---

## PART 8: KNOWN ISSUES & CONSIDERATIONS

### 1. DateTime Formatting in save_checkpoint_and_register()

**Issue:** KPro's utilities.R includes DateTime formatting logic (lines ~850)
```r
if ("DateTime_local" %in% names(data_to_save)) {
  # Convert POSIXct to "MM/DD/YYYY HH:MM:SS" for CSV
  data_to_save$DateTime_local <- format_datetime_for_csv(...)
}
```

**For COHA:** This isn't needed (COHA doesn't have DateTime_local)  
**Action:** Include but don't use (cleaner than removing)

### 2. Plot Object Storage in release_coha.R

**Issue:** KPro uses ggplot2 objects directly:
```r
for (plot_name in names(all_plots[[category]])) {
  ggplot2::ggsave(plot_path, all_plots[[category]][[plot_name]], ...)
}
```

**For COHA:** We have 20 specific ridgeline plots  
**Action:** Adapt to loop through `plot_results[1:20]` or similar

### 3. RDS Naming Conventions

**Current COHA:** Likely using different naming (check results/rds/)  
**KPro Convention:** `summary_data_YYYYMMDD.rds`, `plot_objects_YYYYMMDD.rds`  
**Decision Needed:** Rename outputs or customize discover_pipeline_rds()?

**Recommendation:** Use KPro naming (clearer semantics)

### 4. Metadata Schema Evolution

**Phase 0b:** Use minimal metadata (filename, type, workflow, hash)  
**Phase 1+:** Add rich metadata as needed (palette, scale, config_version)  
**Versioning:** Registry version field allows schema evolution

---

## PART 9: REFERENCE MAPPING

### Which lines to copy from Reference_code:

```
artifacts.R:
  Line 1-140:      Headers, constants, setup → Copy to artifacts_coha.R
  Line 141-250:    init_artifact_registry() → Copy as-is
  Line 251-375:    register_artifact() → Copy with comment markers
  Line 376-450:    get_artifact(), list_artifacts() → Copy as-is
  Line 451-500:    get_latest_artifact() → Copy as-is
  Line 501-628:    hash_file(), hash_dataframe() → Copy as-is
  Line 629-700:    verify_artifact() → Copy as-is
  Line 701-800:    save_and_register_rds() → Copy as-is
  Line 801-919:    discover_pipeline_rds(), validate_rds_structure() → ADAPT

utilities.R (selected):
  Line 1-50:       Operators, directory management → Copy as-is
  Line 51-200:     safe_read_csv() → Copy as-is
  Line 201-300:    convert_empty_to_na(), find_most_recent_file() → Copy as-is
  Line 301-450:    make_output_path(), make_versioned_path() → Copy as-is
  Line 451-650:    fill_readme_template() → Copy as-is (optional)
  Line 651+:       log_stage_start(), save_checkpoint_and_register() → PARTIAL
                   (Include, but mark DateTime logic as COHA-specific)

release.R:
  Line 1-100:      Headers, constants → Copy to release_coha.R
  Line 101-300:    create_release_bundle() → Copy with adaptations
  Line 301-400:    validate_release_inputs() → ADAPT for COHA columns
  Line 401-556:    generate_manifest() → ADAPT for COHA metadata

report.R:
  Line 1-214:      All → Copy to report_coha.R with filename change
```

---

## CONCLUSION

**Phase 0a Status:** ✅ Complete  
**Phase 0b Timeline:** 16-20 hours (distributed over 2-3 days)  
**Critical Success Factor:** Low-touch adaptations (mostly copy-paste + schema changes)  
**Risk Assessment:** Very low (reusing battle-tested code)  
**Next Step:** Begin Phase 0b.1 (artifacts_coha.R adaptation)

---

## APPENDIX: Function Dependency Graph

```
artifacts_coha.R
├── Imports: yaml, digest, here, base R
├── register_artifact() → uses hash_file()
├── save_and_register_rds() → uses register_artifact()
├── verify_artifact() → uses hash_file()
└── discover_pipeline_rds() → uses base R (list.files)

utilities_coha.R
├── Imports: readr, lubridate, here, dplyr, base R
├── ensure_dir_exists() → uses base R
├── safe_read_csv() → uses readr
├── find_most_recent_file() → uses lubridate (ymd_hms)
├── make_output_path() → pure string ops
├── make_versioned_path() → uses base R (list.files)
└── save_checkpoint_and_register() → uses register_artifact() [from artifacts_coha.R]

report_coha.R
├── Imports: quarto, yaml, here, base R
├── generate_quarto_report() → calls quarto::quarto_render()
└── Must source artifacts_coha.R for RDS validation

release_coha.R
├── Imports: yaml, zip, here, base R, digest
├── Depends on: artifacts_coha.R, utilities_coha.R
├── create_release_bundle() → uses register_artifact(), hash_file()
├── validate_release_inputs() → base R validation
└── generate_manifest() → uses hash_file()
```

**Sourcing Order:**
```r
source("R/functions/core/utilities_coha.R")      # Foundation
source("R/functions/core/artifacts_coha.R")      # Registry (uses utilities)
source("R/functions/core/release_coha.R")        # Release (uses artifacts + utilities)
source("R/functions/output/report_coha.R")       # Reports (uses artifacts)
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-02-09  
**Author:** GitHub Copilot  
**Review Status:** Ready for Phase 0b Implementation
