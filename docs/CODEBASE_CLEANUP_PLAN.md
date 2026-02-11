# COHA Dispersal - Codebase Cleanup Plan

**Date:** 2026-02-11  
**Status:** ✅ COMPLETED  
**Goal:** Production-ready R codebase with zero redundancy, no debug artifacts, clean structure

---

## AUDIT FINDINGS

### 1. **REDUNDANT FILES** ❌ High Priority

| File | Status | Issue | Action |
|------|--------|-------|--------|
| `R/functions/core/release.R` | ✗ REDUNDANT | KPro generic release system (518 lines), replaced by `coha_release.R` | **DELETE** |
| `R/functions/core/coha_release.R` | ✓ ACTIVE | COHA-specific release (285 lines), actively used by run_project.R | **KEEP** |
| `R/functions/plot_function.R` | ✗ REDUNDANT | Defines `create_ridgeline_plot()` - NEVER CALLED | **DELETE** |
| `R/pipeline/pipeline.R::generate_single_plot()` | ✗ REDUNDANT | Function definition at line ~630 - NEVER CALLED | **DELETE FUNCTION** |
| `R/legacy/ridgeline_plot.R` | ✗ REDUNDANT | Pre-project standalone script (136 lines) - NEVER SOURCED | **DELETE** |

**Impact:** ~900 lines of dead code currently in codebase

**Call Chain Analysis:**
- ✅ **ACTIVE:** run_project.R → run_pipeline() → generate_all_plots_safe() [phase3_plot_operations.R] ✓ Used
- ❌ **DEAD:** generate_single_plot() → create_ridgeline_plot() [plot_function.R] ✗ Never called
- ❌ **DEAD:** create_release_bundle() in release.R ✗ Pipeline sources but never calls

---

### 2. **SOURCING CONFLICTS** ⚠ Medium Priority

#### In `R/pipeline/pipeline.R`:
```r
Line 43: source(here::here("R", "functions", "core", "release.R"))  # ← REDUNDANT (never used)
Line 47: source(here::here("R", "functions", "plot_function.R"))     # ← REDUNDANT (never used)
```

**Issue:** Pipeline sources 2 files that define functions never called in production

**Details:**
- `release.R` defines `create_release_bundle()` with complex KPro signature - **NEVER CALLED**
- `plot_function.R` defines `create_ridgeline_plot()` - **NEVER CALLED**  
- `run_pipeline()` uses `generate_all_plots_safe()` from phase3_plot_operations.R instead
- Only `run_project.R` creates bundles (using `coha_release.R`, NOT release.R)

**Fix:**
- Remove line 43 entirely  
- Remove line 47 entirely  
- No functionality will be lost

---

### 3. **UNUSED FUNCTIONS** ✓ Verified

Functions defined but never called:

| Module | Function | Lines | Called By | Action |
|--------|----------|-------|-----------|--------|
| `release.R` | `create_release_bundle()` | ~100 | NONE | Delete with file |
| `release.R` | `validate_release_inputs()` | ~80 | NONE | Delete with file |
| `release.R` | `generate_manifest()` | ~120 | NONE | Delete with file |
| `plot_function.R` | `create_ridgeline_plot()` | 145 | NONE | Delete with file |
| `pipeline.R` | `generate_single_plot()` | ~80 | NONE | **DELETE FUNCTION** |
| `legacy/ridgeline_plot.R` | (standalone script) | 136 | NONE | Delete with file |

**Total Dead Code:** ~780 lines spanning 518 (release.R) + 145 (plot_function.R) + 80 (generate_single_plot) + 136 (legacy) = **~880 lines**

**Rationale:** These are holdovers from prior phases. Current production uses:
- `coha_release.R::create_release_bundle()` (simplified COHA version)  
- `phase3_plot_operations.R::generate_all_plots_safe()` (batch generation)  
- `phase3_plot_operations.R::generate_plot_safe()` (single plot with inline logic)

---

### 4. **DEBUG/TEST CODE** ✓ Clean

**Finding:** No debug artifacts found
- No `print()` / `cat()` for debugging
- All `message()` calls are intentional logging (with `[LOG]`, `[INFO]` prefixes)
- No commented-out test blocks
- No leftover TODO markers

**Action:** None required

---

### 5. **FILE ORGANIZATION** ⚠ Needs Cleanup

#### Current Structure:
```
R/
├── functions/
│   ├── core/           # ✓ Clean module organization
│   ├── output/         # Contains report.R
│   ├── plot_function.R      # ← MOVE TO LEGACY
│   ├── phase3_*.R           # ← RENAME (remove "phase3_" prefix)
│   ├── data_quality.R       # ✓ OK
│   └── robustness.R         # ✓ OK
├── legacy/                  # ← DELETE ENTIRE FOLDER
└── ...
```

#### Proposed Structure:
```
R/
├── functions/
│   ├── core/           # artifacts, assertions, config, console, logging, utilities
│   ├── operations/     # NEW: data_operations.R, plot_operations.R (no "phase3_")
│   ├── output/         # report.R
│   ├── data_quality.R
│   └── robustness.R
├── pipeline/
└── config/
```

**Rationale:** "phase3_" prefix implies temporary development phase, not production code

---

### 6. **MODULE DEPENDENCIES** ⚠ Needs Verification

Need to audit:
1. Do all `source()` statements point to active files?
2. Are any functions defined in multiple places?
3. Are all required modules loaded before use?

**Files to Check:**
- `R/run_project.R` (lines 1-50)
- `R/pipeline/pipeline.R` (lines 1-50)
- All test files in `tests/`

---

## CLEANUP PRIORITY MATRIX

| Priority | Task | Impact | Effort | Lines Removed |
|----------|------|--------|--------|---------------|
| 🔴 **HIGH** | Delete release.R + remove source | Removes 518 lines dead code | 2 min | 518 |
| 🔴 **HIGH** | Delete plot_function.R + remove source | Removes 145 lines dead code | 2 min | 145 |
| 🔴 **HIGH** | Delete R/legacy/ folder | Removes 136 lines dead code | 1 min | 136 |
| 🔴 **HIGH** | Delete generate_single_plot() in pipeline.R | Removes ~80 lines dead function | 3 min | 80 |
| 🟡 **MEDIUM** | Rename phase3_*.R → *_operations.R | Professional naming | 10 min | 0 (rename) |
| 🟢 **LOW** | Create operations/ subfolder | Better organization | 5 min | 0 (reorg) |

**Total Impact:** Remove 880 lines (13.5% codebase reduction)

---

## EXECUTION PLAN

### Phase 1: Remove Dead Code (10-15 minutes)
1. ✅ Delete `R/functions/core/release.R` (518 lines)
2. ✅ Delete `R/functions/plot_function.R` (145 lines)
3. ✅ Delete entire `R/legacy/` directory (136 lines)
4. ✅ Remove lines 43, 47 from `R/pipeline/pipeline.R` (source statements)
5. ✅ Delete `generate_single_plot()` function from `pipeline.R` (~80 lines, starts around line 630)

**Total Deletion:** ~880 lines of code without functionality loss

### Phase 2: Rename Production Files (10-15 minutes)
1. ✅ Rename `phase3_data_operations.R` → `data_operations.R`
2. ✅ Rename `phase3_plot_operations.R` → `plot_operations.R`
3. ✅ Update all `source()` statements across codebase
4. ✅ Update all references in documentation

### Phase 3: Final Verification (5 minutes)
1. ✅ Run `grep -r "phase3_" R/` → should return 0 matches
2. ✅ Run `grep -r "release.R" R/` → should only find `coha_release.R`
3. ✅ Run `grep -r "plot_function.R" R/` → should return 0 matches
4. ✅ Test pipeline: `source("R/pipeline/pipeline.R"); run_pipeline()`

### Phase 4: Optional Reorganization (5 minutes)
1. ⚪ Create `R/functions/operations/` directory
2. ⚪ Move `data_operations.R` and `plot_operations.R` there
3. ⚪ Update imports

---

## BEFORE/AFTER COMPARISON

### File Count
- **Before:** 18 R files (5 files contain dead code)
- **After:** 15 R files (0 dead code)
- **Removed:** release.R, plot_function.R, legacy/ridgeline_plot.R

### Lines of Code
- **Before:** ~6,500 lines (880 dead + 80 dead function)
- **After:** ~5,540 lines (0 dead)
- **Savings:** 14.8% reduction

### Source Statements in pipeline.R
- **Before:** Sources 10 files (2 never used: release.R, plot_function.R)
- **After:** Sources 8 files (all actively used)

### Function Architecture
- **Before:** 3 competing plot generation systems (legacy, plot_function, phase3)
- **After:** 1 production system (phase3_plot_operations)

---

## RISKS & MITIGATION

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing scripts | Medium | Test pipeline after each change |
| Missing dependencies | High | Grep all sourced files before deletion |
| Documentation outdated | Low | Update README.md with new file names |

---

## ARCHITECTURE VISUALIZATION

### BEFORE Cleanup (Current State)
```
run_project.R
    │
    ├─► run_pipeline() [pipeline.R]
    │       │
    │       ├─► generate_all_plots_safe() ✓ USED
    │       │       └─► generate_plot_safe() ✓ USED [phase3_plot_operations.R]
    │       │               └─► (inline ridgeline plotting ✓)
    │       │
    │       └─► generate_single_plot() ✗ NEVER CALLED [pipeline.R]
    │               └─► create_ridgeline_plot() ✗ NEVER CALLED [plot_function.R]
    │
    └─► create_release_bundle() ✓ USED [coha_release.R]

ALSO LOADED:
    ├─► release.R ✗ SOURCED BUT NEVER USED (518 lines)
    ├─► plot_function.R ✗ SOURCED BUT NEVER USED (145 lines)
    └─► legacy/ridgeline_plot.R ✗ STANDALONE SCRIPT NEVER SOURCED (136 lines)
```

### AFTER Cleanup (Proposed State)
```
run_project.R
    │
    ├─► run_pipeline() [pipeline.R]
    │       │
    │       └─► generate_all_plots_safe() ✓
    │               └─► generate_plot_safe() ✓ [plot_operations.R]
    │                       └─► (inline ridgeline plotting)
    │
    └─► create_release_bundle() ✓ [coha_release.R]

ALL FILES HAVE PURPOSE - ZERO DEAD CODE
```

---

## APPROVAL CHECKLIST

Before executing, confirm:

- [ ] User approves deletion of `release.R` (KPro generic version)
- [ ] User approves archiving `plot_function.R` to legacy
- [ ] User approves deleting entire `R/legacy/` folder
- [ ] User approves renaming `phase3_*.R` files
- [ ] User approves optional reorganization into `operations/` subfolder

---

## POST-CLEANUP VERIFICATION

Run these commands to verify cleanup:

```r
# 1. Check for redundant files
list.files("R", recursive = TRUE, pattern = "\\.R$")

# 2. Load pipeline (should work)
source("R/pipeline/pipeline.R")

# 3. Run full workflow (should succeed)
result <- run_pipeline(verbose = FALSE)
stopifnot(result$status == "success")
stopifnot(result$plots_generated == 20)

# 4. Check for "phase3_" references
system("grep -r 'phase3_' R/ || echo 'Clean!'")

# 5. Verify no broken sources
system("grep -r 'source.*release\\.R' R/ || echo 'Clean!'")
```

---

**Ready to execute?** Please review and approve specific actions.
