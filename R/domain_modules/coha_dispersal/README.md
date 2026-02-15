# COHA Dispersal Domain Module

Domain-specific module for Cooper's Hawk (Accipiter cooperii) natal dispersal analysis.

## Directory Structure

```
R/domain_modules/coha_dispersal/
├── coha_config.R          # Domain configuration (NEW - Phase 3)
├── data_loader.R          # Data loading and validation
├── artifacts_coha.R       # COHA-specific artifact handling
├── release.R              # Release bundling for COHA analyses
├── reports/               # Domain-specific reports (NEW - Phase 3)
│   ├── README.md
│   ├── data_quality_report.qmd
│   ├── full_analysis_report.qmd
│   └── plot_gallery.qmd
└── README.md              # This file
```

## Key Files

### coha_config.R

Domain-specific configuration and metadata. Defines:

- **Domain identity**: COHA name, version, description
- **Data specifications**: Column names, types, and valid ranges
- **Plot configurations**: Enabled plot modules and their parameters
- **File paths**: Data, configuration, output, logs directories
- **Report templates**: Report specifications and locations
- **Analysis parameters**: Density settings, filters, publication specs

**Utility Functions**:
- `get_coha_config(section)` - Get configuration by section
- `get_coha_path(path_type)` - Get absolute paths using here::here()
- `list_coha_plot_modules(enabled_only)` - Available plot modules
- `get_coha_column_spec(column)` - Column specifications

### data_loader.R

Data I/O and validation functions:

- `load_coha_data(filepath)` - Load CSV data from config path
- `validate_coha_schema(df)` - Validate against domain specs
- `assess_coha_quality(df)` - Quality metrics
- `load_and_validate_coha_data()` - Convenience wrapper

All functions use coha_config.R for specifications, making the system
completely configurable without hardcoding.

### artifacts_coha.R

COHA-specific artifact registry and management.

### release.R

Release bundle creation for COHA analyses.

## Usage Examples

### Load and Validate Data

```r
# Load configuration
source("R/domain_modules/coha_dispersal/coha_config.R")

# Load and validate data in one step
data <- load_and_validate_coha_data(verbose = TRUE)

# Or step by step
data <- load_coha_data()
validate_coha_schema(data, verbose = TRUE)
quality <- assess_coha_quality(data)
```

### Access Configuration

```r
# Get entire configuration
config <- get_coha_config()

# Get specific section
data_specs <- get_coha_config("data")
plot_config <- get_coha_config("plot_modules")

# Get paths
plots_dir <- get_coha_path("plots_base")
data_file <- get_coha_path("data_source")

# List available plot modules
enabled_modules <- list_coha_plot_modules(enabled_only = TRUE)

# Get column specifications
mass_spec <- get_coha_column_spec("mass")
all_specs <- get_coha_column_spec()
```

### Validate Data

```r
# Schema validation
validate_coha_schema(data, verbose = TRUE)

# Quality assessment
quality <- assess_coha_quality(data, verbose = TRUE)
print(quality$overall_score)
```

### Access Reports

```r
# Get report directory
reports_dir <- get_coha_reports_dir()

# Get specific report configuration
data_quality_report <- get_coha_report("data_quality")
full_analysis_report <- get_coha_report("full_analysis")
plot_gallery <- get_coha_report("plot_gallery")

# List all configured reports
all_reports <- get_coha_report()
for (rep in all_reports) {
  cat("Report:", rep$name, "\n")
  cat("  ID:", rep$id, "\n")
  cat("  Template:", rep$template, "\n")
  cat("  Enabled:", rep$enabled, "\n")
}
```

## Configuration-Driven Design

All domain logic uses configuration from `coha_config.R`:

- **Data schemas**: Column definitions, types, valid ranges
- **Plot specifications**: Enabled modules, parameters, outputs
- **File management**: Path organization, naming conventions

This means:
- ✅ No hardcoded column names in validation code
- ✅ Easy to adapt to new COHA datasets
- ✅ Configuration changes don't require code changes
- ✅ Validation logic reusable for similar domains

## Integration with Pipeline

The pipeline loads this domain module:

```r
# pipeline.R sources this configuration
source(here::here("R", "domain_modules", "coha_dispersal", "coha_config.R"))
source(here::here("R", "domain_modules", "coha_dispersal", "data_loader.R"))

# Then uses domain-specific functions
df <- load_and_validate_coha_data(verbose = TRUE)
```

## Phase 3 Goals

Phase 3 organizes domain-specific code separate from universal core:

- ✅ Config via coha_config.R (NEW) - 3 data columns: mass, year, dispersed
- ✅ Data loader via data_loader.R (ENHANCED)
- ✅ Plot specifications via coha_config.R
- ✅ Reports via templates in reports/ directory (NEW)
  - `reports/data_quality_report.qmd` - Data quality assessment
  - `reports/full_analysis_report.qmd` - Complete analysis
  - `reports/plot_gallery.qmd` - Visual summary
- ✅ Tests via tests/test_phase3_domain.R
- ✅ Full pipeline integration testing
- ✅ Domain module organization complete

## Future Extensions

This domain module structure enables:

1. **Multi-domain support**: Easy to add new domains (COHA-TX, COHA-East, etc.)
2. **Configuration portability**: Simple YAML exports for configuration sharing
3. **Domain-specific validation**: Custom rules beyond schema checking
4. **Domain-specific reports**: Reports tailored to domain questions
5. **Reusability**: Module can be used in other analysis projects

---

**Created**: Phase 3 (2026-02-12)
**Status**: Active development
