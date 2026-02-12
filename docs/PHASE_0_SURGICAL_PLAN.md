# Phase 0: Surgical Preparation Plan
**Project:** COHA Dispersal Modular Pipeline Transformation  
**Date:** February 12, 2026  
**Phase:** 0 - Preparation (Pre-Implementation)  
**Approach:** Slow, deliberate, surgical

---

## Executive Summary

You already have **excellent universal functions** well-organized in `R/functions/core/`. The challenge is surgically separating:
- ✅ **Pure universal code** (ready to move to `core/`)
- ⚠️ **Mixed code** (universal patterns with COHA-specific logic intertwined)
- ⚠️ **Plot-specific code** (should go to `plot_modules/ridgeline/`)

This plan breaks Phase 0 into **7 surgical sub-phases** to methodically analyze, map, and document before touching any code.

---

## Current Codebase Audit Results

### Universal Functions (Ready for `core/`)

**Location:** `R/functions/core/`

| File | Lines | Functions | Status | Notes |
|------|-------|-----------|--------|-------|
| `artifacts.R` | 769 | 13 | ✅ Universal | Artifact registry, hashing, validation. Ready to move as-is. |
| `assertions.R` | ? | ? | ✅ Universal | Validation functions. Need to audit. |
| `config.R` | ? | ? | ✅ Universal | Config loading. Need to audit. |
| `console.R` | ? | ? | ✅ Universal | Console output. Need to audit. |
| `logging.R` | 406 | 7 | ✅ Universal | File/console logging. Ready to move as-is. |
| `utilities.R` | 590 | ~10 | ✅ Universal | File I/O, paths, operators. Ready to move as-is. |

**TOTAL READY:** ~2,000+ lines of proven universal code

---

### Robustness Infrastructure (Needs Analysis)

**Location:** `R/functions/` (top level)

| File | Lines | Functions | Status | Assessment |
|------|-------|-----------|--------|------------|
| `robustness.R` | 425 | 8 | ✅ Universal | Result objects, timers, error formatting. Universal pattern, no COHA logic. |
| `data_quality.R` | ? | 3 | ⚠️ Mixed | Quality metric computation. Pattern is universal, but may have COHA-specific thresholds/columns. |

**ACTION NEEDED:** Audit for COHA-specific hardcoded values

---

### Data Operations (Mixed - Needs Separation)

**Location:** `R/functions/data_operations.R`

| Function | Lines | Status | Issue |
|----------|-------|--------|-------|
| `load_and_validate_data()` | ~100 | ⚠️ Mixed | **Hardcoded columns:** `c("mass", "year", "dispersed", "origin")` |
| `assess_data_quality()` | ~50 | ⚠️ Mixed | May reference COHA-specific schema |

**UNIVERSAL PATTERN:**
```r
load_and_validate_data(file_path, required_columns, min_rows, verbose)
```

**COHA-SPECIFIC USAGE:**
```r
# In pipeline.R
load_and_validate_data(
  file_path = data_path_full,
  required_columns = c("mass", "year", "dispersed"),  # ← COHA
  min_rows = 10,
  verbose = FALSE
)
```

**SOLUTION:** Function is already universal! Just the *call site* specifies COHA columns. No refactoring needed.

---

### Plot Operations (Plot-Specific - Move to Module)

**Location:** `R/functions/plot_operations.R` (697 lines)

| Function | Status | Destination |
|----------|--------|-------------|
| `generate_plot_safe()` | 🔵 Ridgeline | → `plot_modules/ridgeline/ridgeline_generator.R` |
| `generate_all_plots_safe()` | 🔵 Ridgeline | → `plot_modules/ridgeline/ridgeline_generator.R` |
| _(internal helpers)_ | 🔵 Ridgeline | → `plot_modules/ridgeline/` |

**ACTION NEEDED:** These are ridgeline-specific. Will move to module in Phase 2.

---

### Pipeline Orchestration (Mixed - Core of Refactor)

**Location:** `R/pipeline/pipeline.R` (627 lines)

**Current Structure:**
```r
run_pipeline() {
  1. Load config
  2. Initialize artifact registry
  3. Load and validate data (COHA-specific columns)
  4. Generate plots (ridgeline-specific)
  5. Generate reports (COHA-specific)
  6. Return aggregated results
}
```

**What's Universal:**
- Artifact registry initialization
- Structured result aggregation
- Error handling patterns
- Timing/logging orchestration

**What's COHA-Specific:**
- Hardcoded data columns ("mass", "year", "dispersed")
- Ridgeline plot generation
- Report templates

**What's Plot-Specific:**
- `generate_all_plots_safe()` calls
- Plot registry loading

**SOLUTION:** Extract orchestration pattern → `core/engine.R`, keep data/plot specifics in domain/modules

---

## Dependency Map

### Layer 0: Zero-Dependency Utilities
```
utilities.R (operators, file I/O)
└── NO DEPENDENCIES
```

### Layer 1: Foundation with External Deps Only
```
logging.R
├── here (package)
└── utilities.R (ensure_dir_exists)

console.R
└── base R only
```

### Layer 2: Config & Validation
```
config.R
├── yaml (package)
├── here (package)
└── utilities.R

assertions.R
└── base R only
```

### Layer 3: Complex Infrastructure
```
artifacts.R
├── yaml (package)
├── digest (package)
├── here (package)
└── utilities.R (ensure_dir_exists)

robustness.R
├── logging.R
└── assertions.R
```

### Layer 4: Domain Operations
```
data_quality.R
├── robustness.R
├── logging.R
└── base stats

data_operations.R
├── data_quality.R
├── robustness.R
├── logging.R
├── assertions.R
└── utilities.R (safe_read_csv)

plot_operations.R
├── robustness.R
├── logging.R
├── assertions.R
├── utilities.R
├── ggplot2
└── ggridges
```

### Layer 5: Orchestration
```
pipeline.R
├── ALL OF THE ABOVE
├── config.R
├── artifacts.R
└── plot_registry.R
```

**INSIGHT:** Clean dependency hierarchy! No circular dependencies. Can extract in reverse order (Layer 5 → 0).

---

## File Counts & Size Analysis

```powershell
# Functions directory structure
R/functions/
├── core/              # ✅ ~2000+ lines universal
│   ├── artifacts.R    (769 lines)
│   ├── assertions.R   (? lines)
│   ├── config.R       (? lines)
│   ├── console.R      (? lines)
│   ├── logging.R      (406 lines)
│   └── utilities.R    (590 lines)
├── output/
│   └── report.R       # ⚠️ Need to audit
├── robustness.R       # ✅ Universal (425 lines)
├── data_quality.R     # ⚠️ Mixed (need audit)
├── data_operations.R  # ✅ Universal pattern (379 lines)
└── plot_operations.R  # 🔵 Ridgeline-specific (697 lines)
```

**Estimated Breakdown:**
- ✅ **Pure Universal:** ~3,000 lines (ready to move)
- ⚠️ **Needs Audit:** ~500 lines (check for COHA hardcodes)
- 🔵 **Plot-Specific:** ~700 lines (move to module)

---

## Phase 0 Sub-Phases (Surgical Breakdown)

### Sub-Phase 0.1: Complete File Audits (Week 1, Days 1-2)
**Goal:** Read every file, document every function, identify any hidden dependencies

**Tasks:**
- [ ] 0.1.1: Read `assertions.R` completely
  - Document all functions
  - Check for COHA-specific validation logic
  - Verify zero dependencies except base R
- [ ] 0.1.2: Read `config.R` completely
  - Document all functions
  - Check for hardcoded COHA paths/values
  - Map what it loads from `study_parameters.yaml`
- [ ] 0.1.3: Read `console.R` completely
  - Document all functions
  - Verify pure utility (no business logic)
- [ ] 0.1.4: Read `data_quality.R` completely
  - Identify COHA-specific thresholds
  - Identify universal metric patterns
  - Document what's parameterizable
- [ ] 0.1.5: Read `coha_release.R` (if exists in core/)
  - Determine if this is COHA-specific or universal
  - If COHA-specific, plan move to domain module
- [ ] 0.1.6: Read `report.R` (output/)
  - Determine if report rendering is universal
  - Check for COHA-specific template logic

**Deliverable:** `FUNCTION_INVENTORY.md` with:
- Every function in codebase
- Parameters, dependencies, purpose
- Classification: Universal / Mixed / Domain-specific
- Line counts

---

### Sub-Phase 0.2: Deep Dependency Analysis (Week 1, Days 3-4)
**Goal:** Understand every import, every `source()`, every function call

**Tasks:**
- [ ] 0.2.1: Map all `source()` calls
  - Which files source which?
  - Order of sourcing (dependencies)
  - Create dependency graph
- [ ] 0.2.2: Map all function calls within functions
  - Which functions call which?
  - Identify circular references (if any)
  - Build call tree
- [ ] 0.2.3: Map all external package dependencies
  - Which functions require which packages?
  - Version requirements?
  - Optional vs required?
- [ ] 0.2.4: Map all file I/O paths
  - What directories are read from?
  - What directories are written to?
  - Hardcoded vs configurable paths?
- [ ] 0.2.5: Map all config dependencies
  - What reads from `study_parameters.yaml`?
  - What fields are used where?
  - What's universal vs COHA-specific?

**Deliverable:** `DEPENDENCY_GRAPH.md` with:
- Visual dependency tree
- Package dependency matrix
- File I/O path inventory
- Config field usage map

---

### Sub-Phase 0.3: Identify Entanglement Points (Week 1, Day 5)
**Goal:** Find exact lines where universal code calls COHA-specific code

**Tasks:**
- [ ] 0.3.1: Grep for hardcoded column names
  ```r
  # Find: "mass", "year", "dispersed", "origin", "period"
  ```
- [ ] 0.3.2: Grep for hardcoded paths
  ```r
  # Find: "data/data.csv", "results/plots", "ridgeline"
  ```
- [ ] 0.3.3: Grep for COHA-specific business logic
  ```r
  # Find: dispersal-related calculations, period binning, etc.
  ```
- [ ] 0.3.4: Grep for plot-specific ggplot code
  ```r
  # Find: geom_density_ridges, stat_density_ridges
  ```
- [ ] 0.3.5: Document each entanglement point
  - File, line number, function
  - What's hardcoded
  - How to parameterize

**Deliverable:** `ENTANGLEMENT_POINTS.md` with:
- Exact file:line references
- Before/after refactor plan for each
- Risk assessment (high/medium/low)

---

### Sub-Phase 0.4: Design Extraction Strategy (Week 2, Days 1-2)
**Goal:** Plan exactly how to surgically extract each component

**Tasks:**
- [ ] 0.4.1: Design `core/` structure
  ```
  core/
  ├── engine.R          # What goes here?
  ├── data_io.R         # Extract from where?
  ├── artifact_registry.R  # Copy from artifacts.R?
  ├── report_builder.R  # Extract from report.R?
  ├── plugin_manager.R  # New file, what functions?
  ├── error_handler.R   # Extract from robustness.R?
  └── ...
  ```
- [ ] 0.4.2: Design `plot_modules/ridgeline/` structure
  ```
  plot_modules/ridgeline/
  ├── ridgeline_generator.R  # Extract generate_plot_safe() from plot_operations.R
  ├── config_schema.yaml     # New, what parameters?
  ├── defaults.yaml          # New, extract from plot_registry.R?
  └── ...
  ```
- [ ] 0.4.3: Design `domain_modules/coha_dispersal/` structure
  ```
  domain_modules/coha_dispersal/
  ├── domain_config.yaml     # New, what configuration?
  ├── data/data.csv          # Move from data/
  ├── data_loader.R          # New, extract COHA preprocessing
  ├── plot_specs/
  │   └── plot_registry.R    # Move from R/config/
  └── ...
  ```
- [ ] 0.4.4: Design migration sequence
  - What order to extract files?
  - How to maintain backward compatibility during transition?
  - Git strategy (branch? incremental commits?)
- [ ] 0.4.5: Design testing strategy
  - What tests before extraction?
  - What tests after each extraction?
  - How to verify nothing broke?

**Deliverable:** `EXTRACTION_STRATEGY.md` with:
- New directory structures
- File-by-file extraction plan
- Testing checkpoints
- Rollback procedures

---

### Sub-Phase 0.5: Identify Backward Compatibility Needs (Week 2, Day 3)
**Goal:** Ensure existing code keeps working during transition

**Tasks:**
- [ ] 0.5.1: Identify external scripts that call pipeline
  - `run_analysis.R`
  - Any other R scripts?
  - Quarto reports?
- [ ] 0.5.2: Identify external scripts that source functions directly
  - Does anything source `plot_operations.R` directly?
  - Does anything source `data_operations.R` directly?
- [ ] 0.5.3: Design shim layer
  ```r
  # Old interface
  run_pipeline(data_path, verbose)
  
  # New interface
  engine <- initialize_pipeline()
  domain <- engine$load_domain("coha_dispersal")
  result <- engine$run_analysis(domain)
  
  # Shim layer (maintains old interface)
  run_pipeline <- function(data_path, verbose) {
    engine <- initialize_pipeline()
    # ... convert old params to new style
  }
  ```
- [ ] 0.5.4: Identify breaking changes
  - What can't be shimmed?
  - What requires user code changes?
  - Document migration path
- [ ] 0.5.5: Plan deprecation warnings
  ```r
  # Old function
  load_data <- function(...) {
    .Deprecated("core::load_data", "Use new core module")
    # ... shim implementation
  }
  ```

**Deliverable:** `BACKWARD_COMPATIBILITY.md` with:
- Shim layer design
- Breaking changes list
- Migration guide for users
- Deprecation timeline

---

### Sub-Phase 0.6: Risk Assessment & Mitigation (Week 2, Day 4)
**Goal:** Identify what could go wrong, plan contingencies

**Risks:**

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Missed dependencies** | Medium | High | Thorough grep search, test after each extraction |
| **Breaking reports** | Medium | High | Test report rendering after each change |
| **Performance regression** | Low | Medium | Benchmark before/after |
| **Lost functionality** | Low | High | Comprehensive test suite before starting |
| **Git history complexity** | High | Low | Clear commit messages, keep file renames separate |
| **Incomplete extraction** | Medium | Medium | Work in small chunks, test continuously |
| **Scope creep** | High | Medium | Strict adherence to phase boundaries |

**Tasks:**
- [ ] 0.6.1: Create comprehensive test suite for current system
  - Test all 28 plots generate
  - Test all 3 reports render
  - Test artifact registry
  - Test data quality validation
  - Capture outputs as baseline
- [ ] 0.6.2: Create rollback procedure
  - Git branch strategy
  - Backup important files
  - Document rollback steps
- [ ] 0.6.3: Define success criteria
  - What must work after each phase?
  - What's acceptable to break temporarily?
  - What's unacceptable to break?
- [ ] 0.6.4: Create validation checklist
  - Run before starting Phase 1
  - Run after each extraction
  - Run before merging
- [ ] 0.6.5: Plan communication
  - If others use this code, how to notify?
  - Documentation updates needed?

**Deliverable:** `RISK_MITIGATION.md` with:
- Risk register
- Test suite
- Rollback procedures
- Success criteria matrix
- Validation checklists

---

### Sub-Phase 0.7: Final Preparation & Stakeholder Review (Week 2, Day 5)
**Goal:** Consolidate all Phase 0 work, get approval to proceed

**Tasks:**
- [ ] 0.7.1: Consolidate all Phase 0 documents
  - `FUNCTION_INVENTORY.md`
  - `DEPENDENCY_GRAPH.md`
  - `ENTANGLEMENT_POINTS.md`
  - `EXTRACTION_STRATEGY.md`
  - `BACKWARD_COMPATIBILITY.md`
  - `RISK_MITIGATION.md`
- [ ] 0.7.2: Create Phase 0 summary presentation
  - What we found
  - What's ready to move
  - What needs work
  - Recommended approach
  - Time estimates for Phase 1
- [ ] 0.7.3: Review with stakeholders (yourself!)
  - Does this approach make sense?
  - Any concerns with the plan?
  - Ready to commit to Phase 1?
- [ ] 0.7.4: Finalize Phase 1 plan
  - Exact order of operations
  - Time estimates
  - Checkpoints
- [ ] 0.7.5: Create Phase 1 detailed checklist
  - Convert Phase 1 from architecture doc into surgical steps
  - Like we did for Phase 0

**Deliverable:** 
- `PHASE_0_COMPLETE.md` - Summary of findings
- `PHASE_1_DETAILED_PLAN.md` - Surgical breakdown like this doc
- `GO_NO_GO_DECISION.md` - Decision to proceed or iterate

---

## Quick Wins Identified

### Already Universal (No Refactor Needed)
1. ✅ **`artifacts.R`** - Already perfect, just move to `core/artifact_registry.R`
2. ✅ **`logging.R`** - Already perfect, just move to `core/logging.R`
3. ✅ **`utilities.R`** - Already perfect, just move to `core/utilities.R`
4. ✅ **`robustness.R`** - Already universal, move to `core/error_handler.R`

**Estimated effort:** 1 hour per file (just moving + updating paths)

### Nearly Universal (Minimal Refactor)
1. ⚠️ **`data_operations.R`** - Functions are universal, just parameterize column names (already done!)
2. ⚠️ **`data_quality.R`** - Likely universal, need to verify thresholds aren't hardcoded

**Estimated effort:** 2-4 hours per file (audit + minor changes)

### Requires Extraction (Medium Complexity)
1. 🔵 **`plot_operations.R`** → `plot_modules/ridgeline/ridgeline_generator.R`
   - Extract ridgeline-specific logic
   - Create module interface wrapper
   - Test isolation

**Estimated effort:** 8-16 hours (careful extraction + testing)

### Requires Design (High Complexity)
1. 🔵 **`pipeline.R`** → `core/engine.R` + domain config
   - Extract orchestration pattern
   - Design plugin loading
   - Design domain configuration system

**Estimated effort:** 16-32 hours (new design + careful refactor)

---

## Recommended Phase 0 Execution Order

### Week 1: Deep Analysis
```
Mon: Sub-Phase 0.1 (File audits: assertions, config, console)
Tue: Sub-Phase 0.1 (File audits: data_quality, report, coha_release)
Wed: Sub-Phase 0.2 (Dependency analysis: source calls, function calls)
Thu: Sub-Phase 0.2 (Dependency analysis: packages, paths, configs)
Fri: Sub-Phase 0.3 (Identify entanglement points)
```

### Week 2: Strategic Planning
```
Mon: Sub-Phase 0.4 (Design extraction strategy: core/)
Tue: Sub-Phase 0.4 (Design extraction strategy: modules/)
Wed: Sub-Phase 0.5 (Backward compatibility design)
Thu: Sub-Phase 0.6 (Risk mitigation, test suite creation)
Fri: Sub-Phase 0.7 (Consolidation, review, Phase 1 planning)
```

**Total Time:** 10 working days (2 weeks)

---

## Tools for Surgical Analysis

### Research Commands

```powershell
# Count lines in all R files
Get-ChildItem -Recurse -Filter "*.R" | ForEach-Object {
    $lines = (Get-Content $_.FullName).Count
    [PSCustomObject]@{
        File = $_.FullName
        Lines = $lines
    }
} | Sort-Object -Property Lines -Descending

# Find all function definitions
Get-ChildItem -Recurse -Filter "*.R" | Select-String "^[a-zA-Z_]+ <- function"

# Find all source() calls
Get-ChildItem -Recurse -Filter "*.R" | Select-String 'source\('

# Find COHA-specific hardcoded values
Get-ChildItem -Recurse -Filter "*.R" | Select-String '"mass"|"year"|"dispersed"|"origin"'

# Find all library/require calls
Get-ChildItem -Recurse -Filter "*.R" | Select-String 'library\(|require\('

# Map file dependencies
Get-Content "R/pipeline/pipeline.R" | Select-String 'source\(' | ForEach-Object {
    $_ -replace '.*source\((.*)\).*', '$1'
}
```

### Analysis Scripts

```r
# Create function inventory
list_all_functions <- function(dir = "R") {
  files <- list.files(dir, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  
  inventory <- lapply(files, function(f) {
    lines <- readLines(f)
    func_lines <- grep("^[a-zA-Z_]+ <- function", lines)
    
    funcs <- lapply(func_lines, function(i) {
      func_name <- sub(" <-.*", "", lines[i])
      # Extract params
      params_line <- lines[i]
      params <- sub(".*function\\((.*)\\).*", "\\1", params_line)
      
      list(
        file = f,
        name = func_name,
        line = i,
        params = params
      )
    })
    funcs
  })
  
  do.call(rbind, unlist(inventory, recursive = FALSE))
}

# Run and save
inventory <- list_all_functions()
write.csv(inventory, "docs/FUNCTION_INVENTORY.csv")
```

---

## Next Steps After Phase 0

Once Phase 0 complete, you'll have:

1. **Complete understanding** of every line of code
2. **Clear dependency map** showing what depends on what
3. **Surgical extraction plan** with exact file:line operations
4. **Risk mitigation** with rollback procedures
5. **Confidence** to start Phase 1

Then we proceed to **Phase 1: Core Engine Extraction** with a detailed surgical plan (like this one) breaking it into tiny, verifiable steps.

---

## Success Metrics for Phase 0

Phase 0 is complete when:

- [ ] Every function documented with purpose, params, dependencies
- [ ] Dependency graph shows no surprises or circular deps
- [ ] Entanglement points identified with exact file:line locations
- [ ] Extraction strategy designed for every file
- [ ] Test suite created and baseline captured
- [ ] Rollback procedure documented and tested
- [ ] Risk mitigation plans for all medium/high risks
- [ ] You feel confident starting Phase 1
- [ ] Estimated 2 weeks effort, no code changes yet

---

## Appendix: File Location Reference

### Current Structure
```
R/
├── functions/
│   ├── core/
│   │   ├── artifacts.R       ✅ → core/artifact_registry.R
│   │   ├── assertions.R      ✅ → core/assertions.R
│   │   ├── config.R          ✅ → core/config.R
│   │   ├── console.R         ✅ → core/console.R
│   │   ├── logging.R         ✅ → core/logging.R
│   │   ├── utilities.R       ✅ → core/utilities.R
│   │   └── coha_release.R    ⚠️ → domain_modules/coha_dispersal/?
│   ├── output/
│   │   └── report.R          ⚠️ → core/report_builder.R
│   ├── robustness.R          ✅ → core/error_handler.R
│   ├── data_quality.R        ⚠️ → core/data_quality.R (need audit)
│   ├── data_operations.R     ✅ → core/data_io.R
│   └── plot_operations.R     🔵 → plot_modules/ridgeline/
├── config/
│   └── plot_registry.R       🔵 → domain_modules/coha_dispersal/plot_specs/
└── pipeline/
    └── pipeline.R            🔵 → core/engine.R + domain module
```

### Target Structure (After Phase 3)
```
core/
├── engine.R              # Extract from pipeline.R
├── data_io.R             # From data_operations.R
├── artifact_registry.R   # From core/artifacts.R
├── report_builder.R      # From output/report.R
├── plugin_manager.R      # New
├── error_handler.R       # From robustness.R
├── logging.R             # From core/logging.R
├── utilities.R           # From core/utilities.R
├── assertions.R          # From core/assertions.R
├── config.R              # From core/config.R
├── console.R             # From core/console.R
└── data_quality.R        # From data_quality.R (if universal)

plot_modules/
└── ridgeline/
    ├── ridgeline_generator.R  # From plot_operations.R
    ├── config_schema.yaml     # New
    ├── defaults.yaml          # Extract from plot_registry.R
    └── INTERFACE.md           # New

domain_modules/
└── coha_dispersal/
    ├── domain_config.yaml
    ├── data/
    │   └── data.csv
    ├── data_loader.R          # New (COHA preprocessing)
    ├── plot_specs/
    │   └── plot_registry.R    # From R/config/
    └── reports/
        └── *.qmd              # From reports/
```

---

**Status:** Phase 0 Surgical Plan Complete - Ready for Execution  
**Next Action:** Choose sub-phase to start (recommend 0.1.1)

