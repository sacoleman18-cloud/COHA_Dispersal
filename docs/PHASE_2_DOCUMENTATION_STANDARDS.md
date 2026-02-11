# PHASE 2: DOCUMENTATION STANDARDS
**Project:** COHA Dispersal Analysis  
**Phase:** 2 - Documentation  
**Status:** In Progress  
**Date:** February 2026

---

## Overview

Phase 2 transforms Phase 1's functional foundation into publication-ready, professionally documented code. This phase ensures **every function, file, and module is fully documented** with clear purpose, usage, and examples—enabling future maintainers and enabling generation of comprehensive package documentation.

**Phase 2 is about DOCUMENTATION ONLY—no code logic changes to Phase 1 implementations.**

---

## 1. ROXYGEN2 DOCUMENTATION STANDARD

### 1.1 Reference Implementation

All functions must follow Roxygen2 format:

```r
#' Function Title (Imperative, One Line)
#'
#' Longer description explaining what the function does, why it exists,
#' and any important behavior or side effects. Multi-paragraph descriptions
#' are encouraged.
#'
#' @param param_name Description of what this parameter does. If multiple
#'   parameters, continue on the next line with proper indentation.
#' @param another_param Another parameter description with type information
#'   (e.g., character vector, logical flag, data frame with columns x, y).
#'
#' @return Description of what the function returns. Examples:
#'   - "A data frame with columns: id (integer), name (character)"
#'   - "A list with elements: status (logical), message (character)"
#'   - "Invisible NULL, side effect is writing to file"
#'   - "ggplot object (invisibly) with stage header drawn"
#'
#' @details
#' Additional technical details about implementation, assumptions,
#' or behavior not obvious from the description.
#'
#' - **Design Decision:** Why was this approach chosen?
#' - **Safe I/O:** Functions that might fail describe fallback behavior
#' - **Determinism:** Functions describe their output paths/reproducibility
#'
#' @examples
#' # Example 1: Basic usage
#' result <- my_function(data = iris, verbose = TRUE)
#'
#' # Example 2: Using with pipe
#' iris %>%
#'   my_function(verbose = FALSE) %>%
#'   head()
#'
#' # Example 3: Error handling
#' result <- my_function("nonexistent.csv", verbose = FALSE)
#' if (is.null(result)) {
#'   message("File not found, using defaults")
#' }
#'
#' @seealso [related_function()] for related functionality
#'
#' @export
```

### 1.2 Documentation by Function Type

#### Utility Functions (assertions, utilities, console)
- **@return:** Always describe exact return value (NULL vs value, structure, etc.)
- **@param:** Include type hints (character, logical, numeric, data.frame, etc.)
- **@details:** Explain designed failure modes (what happens on invalid input?)
- **@examples:** Show both success and failure cases

#### Configuration Functions (config_loader)
- **@return:** Document structure of returned list/object (all elements)
- **@details:** Include YAML path examples and default behavior
- **@examples:** Show loading config, accessing nested values

#### Pipeline Functions (pipeline.R)
- **@return:** Document complete return structure (list elements, types, when each element exists)
- **@details:** Describe each phase and what happens at each stage
- **@examples:** Show minimal working example (data file → output directory)

#### Logging Functions
- **@details:** Describe file output location, format, append behavior
- **@param verbose:** Always describe what verbose=TRUE produces
- **@return:** Clarify if function returns invisibly, returns object, or returns NULL

### 1.3 Roxygen2 Tags Required in Every Function

| Tag | Required | Notes |
|-----|----------|-------|
| `#'` | YES | Start every roxygen block |
| `@param` | YES* | For every function parameter (*except `verbose` if only for gating) |
| `@return` | YES | Always describe what is returned |
| `@details` | CONDITIONAL | Required if function has important behavior not obvious from description |
| `@examples` | YES | At least one working example |
| `@export` | YES* | For public functions (*omit for internal helpers) |
| `@keywords internal` | YES* | For internal functions (*instead of @export) |
| `@seealso` | OPTIONAL | Link to related functions |

---

## 2. FILE HEADER STANDARD

Every R file must begin with a comprehensive header block followed by a blank line.

### 2.1 Header Format

```r
# ============================================================================
# FILE: R/functions/modulename.R
# PURPOSE: 
#   Brief description of what all functions in this file do,
#   their shared responsibility, and role in the pipeline.
#
# DEPENDS ON:
#   - R ≥ 4.0.0
#   - tidyverse (for %>%, dplyr functions)
#   - ggplot2 (for plot generation)
#   - yaml (for YAML parsing)
#   - readr (for safe file I/O)
#
# INPUTS:
#   Function-specific inputs are documented in @param tags (see below).
#   This section describes typical data formats expected by module functions.
#   Example: "Data frames with columns: id, date, value (numeric)"
#
# OUTPUTS:
#   Function-specific outputs are documented in @return tags (see below).
#   This section describes typical outputs from module functions.
#   Example: "Plots saved to results/plots/ridgeline/variants/PLOT_ID.png"
#
# USAGE:
#   source(here::here("R", "functions", "modulename.R"))
#   result <- function_name(data, param1 = TRUE, param2 = "default")
#
# CHANGELOG:
#   2026-02-10 (v1.0.0): Phase 1 - Initial implementation [Phase 2: Phase 2 docs added]
#   - Added function_name() for [purpose]
#   - Added another_function() for [purpose]
#   - Dependency on [package] added for [reason]
#
# ============================================================================

# Any internal helper functions (not exported) can follow immediately after header
```

### 2.2 Header by File Type

#### R/functions/*.R (Modules)
- Link to config that controls behavior
- List dependencies in order of importance
- Describe typical data shapes (column requirements, types)
- Mention if functions use here::here() for paths

#### R/config/*.R (Configuration)
- Document the configuration object structure
- List all plot type variants
- Explain color/palette choices
- Describe how to add new variants

#### R/pipeline/pipeline.R (Orchestrator)
- Document phase sequence and gates
- Describe configuration loading
- List all sources (which utility modules are needed)
- Explain console output stages

#### inst/config/*.yaml (YAML)
- Document every top-level section
- Use inline comments for complex structures
- Example paths for nested access

---

## 3. INLINE COMMENTS STANDARD

### 3.1 When to Comment

**Comment these:**
- Complex logic (multi-step transformations)
- Non-obvious design decisions
- Why certain error checking exists
- Magic numbers or arbitrary thresholds
- Verbose sections gated by `if (verbose) { ... }`

**Don't comment these:**
- Self-explanatory code (variable assignments, simple dplyr pipes)
- After Roxygen2 examples
- Commented-out debugging code (**remove it instead**)

### 3.2 Comment Format

```r
# Use single # for comments above lines
# Multiple comments explain the block
x <- important_calculation()

# Special case: when verbose output exists, comment it
if (verbose) {
  cat("Debug info: ", x, "\n")  # Only when verbose = TRUE
}
```

---

## 4. DOCUMENTATION COMPLETION CHECKLIST

### 4.1 Per-Function Requirements

For **EVERY exported function** in Phase 1:

- [ ] Roxygen2 block with #' comment lines
- [ ] `@param` for each parameter (with type hints)
- [ ] `@return` describing exact return value/structure
- [ ] `@examples` with at least 1 working example
- [ ] `@export` tag (or `@keywords internal` if internal)
- [ ] Comments in file header listing this function

For **EVERY file**:

- [ ] File header with PURPOSE, DEPENDS ON, INPUTS, OUTPUTS, USAGE, CHANGELOG
- [ ] @export or @keywords internal for every function
- [ ] No orphaned code or commented-out debugging

### 4.2 Module-by-Module Targets

| Module | Function Count | Roxygen2 Status | Headers Status |
|--------|----------------|-----------------|-----------------|
| R/functions/assertions.R | 12 | ⏳ TODO | ⏳ TODO |
| R/functions/logging.R | 8 | ⏳ TODO | ⏳ TODO |
| R/functions/utilities.R | 5 | ⏳ TODO | ⏳ TODO |
| R/functions/console.R | 4 | ⏳ TODO | ⏳ TODO |
| R/functions/config_loader.R | 6 | ⏳ TODO | ⏳ TODO |
| R/pipeline/pipeline.R | 3 | ⏳ TODO | ⏳ TODO |
| R/config/ridgeline_config.R | 1 (object) | ✅ object | ⏳ TODO |
| inst/config/study_parameters.yaml | 1 (object) | N/A | ✅ inline |

**Total functions to document: 39 exported + internal helpers**

---

## 5. DOCUMENTATION DELIVERABLES

### 5.1 README.md (Update Existing)

Update [README.md](README.md) with:

```markdown
## Installation

# Requires R ≥ 4.0.0
# Install dependencies
install.packages(c("tidyverse", "ggplot2", "ggridges", "yaml", "readr", "here"))

# Usage
source(here::here("R", "pipeline", "pipeline.R"))
result <- run_pipeline()

## Project Structure
- R/functions/: Core utility modules (assertions, logging, utilities, console, config_loader)
- R/config/: Plot specifications (ridgeline_config.R)
- R/pipeline/: Main orchestrator (pipeline.R)
- inst/config/: YAML configuration (study_parameters.yaml)
- results/: Output directory for plots and logs
- docs/: Standards and guidelines
```

### 5.2 PIPELINE_GUIDE.md (New File)

Comprehensive guide covering:

```markdown
# PIPELINE_GUIDE.md

## Quick Start
- Load data
- Run pipeline
- Examine results

## Configuration System
- YAML structure
- Overriding defaults
- Adding new plot variants

## Output Structure
- Where do plots go?
- Log file location
- Return structure

## Error Handling
- What functions return on error
- How to check for failures
- Debug mode (verbose=TRUE)

## Extending for New Plot Types
- Add config file
- Add generation function
- No pipeline changes needed
```

### 5.3 FUNCTION_REFERENCE.md (Auto-Generated)

After Roxygen2 documentation complete:

```bash
# In R console:
roxygen2::roxygenise()
```

This creates:
- `man/*.Rd` files (one per function)
- `NAMESPACE` file (export directives)
- Package documentation structure

Then create browsable HTML:

```r
pkgdown::build_site()
```

---

## 6. IMPLEMENTATION SEQUENCE

### Phase 2A: Documentation Setup (Day 1)
1. ✅ Create PHASE_2_DOCUMENTATION_STANDARDS.md (this file)
2. ⏳ Add file headers to all R files
3. ⏳ Add inline comments to complex logic

### Phase 2B: Roxygen2 Documentation (Days 2-3)
4. ⏳ Add Roxygen2 blocks to assertions.R (12 functions)
5. ⏳ Add Roxygen2 blocks to logging.R (8 functions)
6. ⏳ Add Roxygen2 blocks to utilities.R (5 functions)
7. ⏳ Add Roxygen2 blocks to console.R (4 functions)
8. ⏳ Add Roxygen2 blocks to config_loader.R (6 functions)
9. ⏳ Add Roxygen2 blocks to pipeline.R (3 functions)
10. ⏳ Run roxygen2::roxygenise() to generate documentation

### Phase 2C: Guides and References (Days 4-5)
11. ⏳ Update README.md with new structure
12. ⏳ Create PIPELINE_GUIDE.md
13. ⏳ Generate FUNCTION_REFERENCE.md from Roxygen2
14. ⏳ Review all documentation for completeness

### Phase 2D: Validation (Day 6)
15. ⏳ Check ?function_name works in R
16. ⏳ Verify all exported functions visible in namespace
17. ⏳ Run pkgdown::build_site() for HTML docs
18. ⏳ Test all code examples from Roxygen2

---

## 7. QUALITY GATES FOR COMPLETION

Phase 2 is complete when ALL of the following are true:

- [ ] Every exported function has complete Roxygen2 documentation
- [ ] Every file has a proper header block (PURPOSE, DEPENDS ON, INPUTS, OUTPUTS, USAGE, CHANGELOG)
- [ ] Every R file can be sourced without warnings
- [ ] All @examples code runs without error
- [ ] roxygen2::roxygenise() completes without errors
- [ ] ?function_name shows documentation for every exported function
- [ ] pkgdown::build_site() generates complete HTML documentation
- [ ] README.md updated with current structure
- [ ] PIPELINE_GUIDE.md created and complete
- [ ] No TODOs or FIXMEs remain in code
- [ ] No commented-out debugging code remains

---

## 8. STANDARDS RATIONALE

### Why Roxygen2?

1. **Single source of truth:** Roxygen2 docs live in code, stay in sync
2. **Automatic NAMESPACE:** No manual export management
3. **Standard format:** Anyone familiar with R packages recognizes the documentation
4. **Enables pkgdown:** Auto-generates beautiful HTML documentation site
5. **?function_name works:** Users can get help directly in R console

### Why File Headers?

1. **Maintenance clarity:** Future developers know what module does at a glance
2. **Dependency tracking:** No surprises when refactoring
3. **CHANGELOG:** Understand evolution of code without git log
4. **Quick reference:** No need to read entire file for high-level understanding

### Why Inline Comments?

1. **Complex logic clarity:** Multi-step operations explained
2. **Design decisions:** "Why" for non-obvious code
3. **Error handling context:** Why certain checks exist
4. **Verbose gating:** Marks which output is conditional

---

## 9. NEXT PHASES

After Phase 2 (Documentation) is complete:

**Phase 3: Robustness (Error handling, structured returns, defensive programming)**
- Comprehensive error documentation
- Structured return objects with status fields
- Defensive assertions before critical operations

**Phase 4: Polish (Testing, examples, finalization)**
- E2E testing of all 20 plots
- Example gallery of common use cases
- Code cleanup and optimization
- GitHub release preparation

---

## DOCUMENT HISTORY

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-10 | 1.0.0 | Initial Phase 2 Documentation Standards |

---

**Phase 2 Status:** In Progress  
**Target Completion:** End of Phase 2 cycle  
**Responsibility:** Documentation of all Phase 1 code
