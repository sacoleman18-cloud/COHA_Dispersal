# Modular Artifact Registry Pattern

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       TEST FILES                         │
│  (test_phase3_registry_reports.R, etc.)                 │
└▲────────────────────────────────────────────────────────┘
 │
 │ source()
 │
┌┴──────────────────────────────────────┐
│  COHA CONNECTOR MODULE                 │
│  artifacts_coha.R                      │
│  ────────────────────────────────────  │
│  • COHA_ARTIFACT_TYPES constant        │
│  • register_coha_artifact()            │
│  • discover_coha_rds()                 │
│  • validate_coha_artifacts()           │
│  (Imports core/artifacts.R)            │
└▲────────────────────────────────────┬──┘
 │ Calls with COHA_ARTIFACT_TYPES      │
 │                                     │
┌┴─────────────────────────────────────▼──┐
│   UNIVERSAL CORE MODULE                  │
│   core/artifacts.R                       │
│   ────────────────────────────────────   │
│   • register_artifact()                  │
│   • init_artifact_registry()             │
│   • hash_file(), hash_dataframe()       │
│   • validate_artifact_registry()         │
│   • (accepts allowed_types parameter)   │
│   (NO domain-specific logic)             │
└────────────────────────────────────────┘
```

## Design Pattern: **Connector Pattern**

Instead of hardcoding domain logic in core functions, we use wrapper functions
that "connect" domain-specific configuration to universal functions.

### Before (Tightly Coupled)
```r
# core/artifacts.R
ARTIFACT_TYPES <- c("ridgeline_plots", "summary_stats", ...)  # COHA-specific!

register_artifact <- function(...) {
  if (!artifact_type %in% ARTIFACT_TYPES) { ... }  # Hardcoded validation
}
```

### After (Modular)
```r
# core/artifacts.R - UNIVERSAL
DEFAULT_ARTIFACT_TYPES <- c("raw_data", "checkpoint", "processed_data", ...)

register_artifact <- function(..., allowed_types = DEFAULT_ARTIFACT_TYPES) {
  if (!artifact_type %in% allowed_types) { ... }  # Parameterized!
}

# domain_modules/coha_dispersal/artifacts_coha.R - CONNECTOR
COHA_ARTIFACT_TYPES <- c("ridgeline_plots", "summary_stats", "plot_objects", ...)

register_coha_artifact <- function(...) {
  register_artifact(..., allowed_types = COHA_ARTIFACT_TYPES)  # Wrapper!
}
```

## Usage Examples

### Using COHA Connector
```r
source(here::here("domain_modules", "coha_dispersal", "artifacts_coha.R"))

registry <- init_artifact_registry()
registry <- register_coha_artifact(
  registry,
  artifact_name = "dispersal_plots",
  artifact_type = "ridgeline_plots",  # COHA-specific type!
  workflow = "plot_generation",
  file_path = "results/plots.png"
)
```

### Using Direct Core (Generic)
```r
source(here::here("core", "artifacts.R"))

registry <- init_artifact_registry()
registry <- register_artifact(
  registry,
  artifact_name = "processed_data",
  artifact_type = "processed_data",  # Generic type
  workflow = "data_processing",
  file_path = "results/data.rds",
  allowed_types = c("raw_data", "processed_data", "results")  # Custom types
)
```

## Creating a New Domain Module

To add support for a new domain (e.g., XYZ):

1. Create `domain_modules/xyz/artifacts_xyz.R`
2. Define `XYZ_ARTIFACT_TYPES`
3. Create wrapper functions:
   - `register_xyz_artifact()`
   - `discover_xyz_rds()`
   - `validate_xyz_artifacts()`
4. Each calls the corresponding core function with XYZ types

**No modifications to core/artifacts.R needed!**

## Benefits

✅ **Separation of Concerns**
- Core: Universal registry logic (reusable)
- Connector: Domain configuration (specific)

✅ **Extensibility**
- Add new domains without modifying core
- Each domain has isolated configuration

✅ **Testability**
- Core functions tested generically
- Domain functions tested with their types

✅ **Maintainability**
- Changes to registry logic in one place
- Domain teams can modify their connector independently
