# ==============================================================================
# ARTIFACT REGISTRY APPLICATION GUIDE: COHA DISPERSAL PROJECT
# ==============================================================================
# VERSION: 1.0
# DATE: 2026-02-11
# PURPOSE: Comprehensive analysis of applying ST_artifact_release_standards
#          and ST_quarto_reporting_standards to COHA Dispersal pipeline
# ==============================================================================

## EXECUTIVE SUMMARY

Your existing COHA pipeline produces **20 ridgeline plot variants** and **3 Quarto reports** per run. Currently, there is **no artifact tracking**—plots are saved to disk and reports reference them via `list.files()` or direct indexing into `plot_results`. 

Applying the **artifact registry system** from your KPro pipeline would provide:

1. **Cryptographic verification** - SHA256 hashing of all plots and RDS outputs
2. **Reproducibility tracking** - Full provenance chain (input → plot → report)
3. **Deterministic report generation** - Time-stamped artifact registry prevents accumulation
4. **Release bundles** - Portable, self-contained outputs for distribution
5. **Audit trail** - Complete YAML manifest documenting every output

**Key advantage for COHA:** Solves the "60+ plots in report" problem by registering artifacts atomically with generation, making reports reference the registry (not filesystem).

---

## PART 1: CURRENT STATE ANALYSIS

### 1.1 Current Workflow

```
R/run_project.R
├─ run_pipeline()                    [generates 20 plots → PNG files]
├─ extractplot_results               [in-memory list from pipeline]
└─ render_reports()                  [reports read from results/plots/]
    ├─ full_analysis_report.qmd      [now uses plot_results[1:20]]
    ├─ plot_gallery.qmd              [uses plot_results[1:20]]
    └─ data_quality_report.qmd       [data-focused]
```

**Current issues:**

| Issue | Impact | Root Cause |
|-------|--------|-----------|
| No artifact registry | Multiple runs create orphaned plots | No timestamping or cleanup |
| Filesystem-based tracking | 60+ plots in reports | `list.files()` finds all matching patterns |
| No provenance | Can't verify which plots went into which report | No linking between outputs |
| No hashing | Can't detect if plots changed between runs | Determinism unverified |
| No release bundles | Cannot distribute entire analysis to collaborators | No packaging mechanism |
| No manifest | No single source of truth for reproducibility | No metadata documentation |

### 1.2 Current Plot Generation

```r
# In phase3_plot_operations.R: generate_plot_safe()
# Output pattern: {output_dir}/{plot_id}_{YYYYMMDD}_{HHMMSS}.png
# Example: results/plots/ridgeline/variants/compact_01_20260211_012345.png

# Returned in result object:
# result$output_path = full path to PNG
# result$plot_id = "compact_01"
```

**Problem:** Timestamp in filename doesn't prevent duplicates; no registry tracks which outputs belong to which run.

### 1.3 Current Report Generation

**full_analysis_report.qmd (FIXED):**
```r
# Now uses plot_results from current pipeline run
compact_paths <- sapply(plot_results[1:10], function(x) x$output_path)
```

**Problem (now resolved):** Was using `list.files()` which accumulated old plots.

---

## PART 2: ARTIFACT REGISTRY SYSTEM ARCHITECTURE

### 2.1 Proposed Registry Structure for COHA

```yaml
# File: inst/config/artifact_registry.yaml
registry_version: '1.0'
created_utc: '2026-02-11T12:00:00Z'
pipeline_version: '1.0'
study: 'COHA_Dispersal'

artifacts:
  
  # Data artifacts
  raw_data_20260211_010000:
    name: raw_data_20260211_010000
    type: raw_input
    file_path: data/data.csv
    file_hash_sha256: 'a7f3c28d9e1b4f...'
    file_size_bytes: 847000
    created_utc: '2026-02-11T01:00:00Z'
    metadata:
      n_rows: 847
      n_cols: 3
      columns: [mass, year, dispersed]
  
  # Plot artifacts (20 total)
  plot_compact_01_20260211_120500:
    name: plot_compact_01_20260211_120500
    type: plot_object
    file_path: results/plots/ridgeline/variants/compact_01_20260211_120500.png
    file_hash_sha256: 'b2e8f51c3a9d7e...'
    file_size_bytes: 245000
    created_utc: '2026-02-11T12:05:00Z'
    pipeline_version: '1.0'
    input_artifacts: [raw_data_20260211_010000]
    metadata:
      plot_id: compact_01
      palette: plasma
      scale: 0.85
      generation_time_sec: 3.42
      quality_score: 92
      status: success
      config_used:
        scale_value: 0.85
        line_height: 0.85
        fill_palette: plasma
        color_palette: plasma
  
  # ... 19 more plot artifacts ...
  
  # RDS artifacts (cached results)
  plot_objects_rds_20260211_120600:
    name: plot_objects_rds_20260211_120600
    type: plot_collection
    file_path: results/rds/plot_objects_20260211_120600.rds
    file_hash_sha256: 'c4d7e2f9a1b8c3...'
    file_size_bytes: 8500000
    created_utc: '2026-02-11T12:06:00Z'
    input_artifacts: [
      plot_compact_01_20260211_120500,
      # ... all 20 plots ...
    ]
    metadata:
      n_plots: 20
      total_generation_time_sec: 68.5
      avg_quality_score: 90
  
  # Report artifacts
  report_full_analysis_20260211_120700:
    name: report_full_analysis_20260211_120700
    type: report
    file_path: results/reports/full_analysis_report.html
    file_hash_sha256: 'd5e9f3c1b2a7d8...'
    file_size_bytes: 52000000
    created_utc: '2026-02-11T12:07:00Z'
    input_artifacts: [
      plot_objects_rds_20260211_120600,
      raw_data_20260211_010000
    ]
    metadata:
      embedded_plots: 20
      report_type: full_analysis
      self_contained: true
  
  report_plot_gallery_20260211_120800:
    name: report_plot_gallery_20260211_120800
    type: report
    file_path: results/reports/plot_gallery.html
    file_hash_sha256: 'e6f0a4d2c3b8e9...'
    file_size_bytes: 45000000
    created_utc: '2026-02-11T12:08:00Z'
    input_artifacts: [
      plot_objects_rds_20260211_120600
    ]
    metadata:
      embedded_plots: 20
      report_type: gallery
      self_contained: true
  
  # Release bundle
  release_coha_20260211_120900:
    name: release_coha_20260211_120900
    type: release_bundle
    file_path: results/releases/coha_release_20260211_120900.zip
    file_hash_sha256: 'f7a1b5e3d4c9f0...'
    file_size_bytes: 120000000
    created_utc: '2026-02-11T12:09:00Z'
    input_artifacts: [
      plot_objects_rds_20260211_120600,
      report_full_analysis_20260211_120700,
      report_plot_gallery_20260211_120800,
      raw_data_20260211_010000
    ]
    metadata:
      bundle_version: 1
      includes_reports: true
      includes_raw_data: true

last_modified_utc: '2026-02-11T12:09:00Z'
```

### 2.2 Artifact Types for COHA

| Type | Description | Example |
|------|-------------|---------|
| `raw_input` | Source CSV data file | `data/data.csv` |
| `plot_object` | Individual PNG plot | `results/plots/ridgeline/variants/compact_01_*.png` |
| `plot_collection` | RDS containing all plots | `results/rds/plot_objects_*.rds` |
| `report` | Rendered Quarto HTML | `results/reports/*_report.html` |
| `release_bundle` | Portable zip for distribution | `results/releases/coha_release_*.zip` |
| `config` | Pipeline configuration | `ridgeline_config.R` |

### 2.3 Key Differences from KPro Pipeline

**KPro (Bat Acoustic):**
- Multiple data sources (multiple detectors, multiple files)
- 3-5 checkpoint artifacts between stages
- Heavy transformation (duplicate removal, filtering, aggregation)
- Multiple summary tables
- Species-optional sections in reports

**COHA (Dispersal):**
- Single data source (data/data.csv)
- Lightweight transformation (already quite clean)
- Heavy visualization (20 plot variants instead of 5-10)
- No intermediate checkpoints needed
- **Focus is artifact OUTPUTS not intermediate checkpoints**

**Implication:** COHA registry needs **plot-centric artifact types**, not transformation checkpoints. Your registry structure should emphasize plot objects, RDS caches, and reports.

---

## PART 3: IMPLEMENTATION FOR COHA

### 3.1 New Functions Required

#### 3.1.1 `init_artifact_registry()` - Initialize or Load Registry

```r
init_artifact_registry <- function(registry_path = here("inst", "config", "artifact_registry.yaml")) {
  
  if (file.exists(registry_path)) {
    registry <- yaml::read_yaml(registry_path)
  } else {
    registry <- list(
      registry_version = "1.0",
      created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      pipeline_version = "1.0",
      study = "COHA_Dispersal",
      artifacts = list(),
      last_modified_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    )
  }
  
  registry
}
```

#### 3.1.2 `compute_sha256()` - Hash Files

```r
compute_sha256 <- function(file_path) {
  digest::digest(file = file_path, algo = "sha256")
}
```

#### 3.1.3 `register_artifact()` - Add Artifact to Registry

```r
register_artifact <- function(
  registry,
  artifact_name,
  artifact_type,
  file_path,
  input_artifacts = NULL,
  metadata = NULL,
  verbose = FALSE
) {
  
  if (!file.exists(file_path)) {
    stop(sprintf("File not found: %s", file_path))
  }
  
  file_info <- file.info(file_path)
  file_hash <- compute_sha256(file_path)
  
  artifact <- list(
    name = artifact_name,
    type = artifact_type,
    file_path = file_path,
    file_hash_sha256 = file_hash,
    file_size_bytes = as.integer(file_info$size),
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    pipeline_version = "1.0",
    input_artifacts = input_artifacts %||% NULL,
    metadata = metadata %||% list()
  )
  
  registry$artifacts[[artifact_name]] <- artifact
  registry$last_modified_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  
  if (verbose) {
    cat(sprintf("[ARTIFACT] Registered %s: %s\n", artifact_type, artifact_name))
  }
  
  registry
}
```

#### 3.1.4 `save_and_register_rds()` - Atomic Save + Register

```r
save_and_register_rds <- function(
  object,
  file_path,
  artifact_type,
  registry,
  input_artifacts = NULL,
  metadata = NULL,
  verbose = FALSE
) {
  
  # Create directory if needed
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  
  # Save RDS
  saveRDS(object, file = file_path)
  
  if (verbose) {
    cat(sprintf("[RDS] Saved to %s\n", file_path))
  }
  
  # Register immediately after successful save
  artifact_name <- gsub("\\.(rds|RDS)$", "", basename(file_path))
  artifact_name <- paste0(artifact_name, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  
  registry <- register_artifact(
    registry = registry,
    artifact_name = artifact_name,
    artifact_type = artifact_type,
    file_path = file_path,
    input_artifacts = input_artifacts,
    metadata = metadata,
    verbose = verbose
  )
  
  registry
}
```

#### 3.1.5 `save_registry()` - Persist Registry to YAML

```r
save_registry <- function(registry, registry_path = here("inst", "config", "artifact_registry.yaml")) {
  
  dir.create(dirname(registry_path), recursive = TRUE, showWarnings = FALSE)
  yaml::write_yaml(registry, file = registry_path)
  
}
```

### 3.2 Integration Points

#### 3.2.1 In `R/pipeline/pipeline.R` (run_pipeline)

```r
run_pipeline <- function(verbose = TRUE) {
  
  # Initialize registry at start of pipeline
  registry <- init_artifact_registry()
  
  # Register raw input
  registry <- register_artifact(
    registry = registry,
    artifact_name = paste0("raw_data_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    artifact_type = "raw_input",
    file_path = here("data", "data.csv"),
    metadata = list(
      n_rows = nrow(df),
      n_cols = ncol(df),
      columns = colnames(df)
    ),
    verbose = verbose
  )
  
  # ... data load, quality checks, plotting ...
  
  # After generate_all_plots_safe() returns:
  # Register each plot
  plot_artifact_names <- character(length(plot_results))
  for (i in seq_along(plot_results)) {
    plt_result <- plot_results[[i]]
    if (plt_result$status == "success") {
      artifact_name <- paste0(
        "plot_", plt_result$plot_id, "_",
        format(Sys.time(), "%Y%m%d_%H%M%S")
      )
      registry <- register_artifact(
        registry = registry,
        artifact_name = artifact_name,
        artifact_type = "plot_object",
        file_path = plt_result$output_path,
        input_artifacts = "raw_data_*",  # Reference to data artifact
        metadata = list(
          plot_id = plt_result$plot_id,
          palette = extract_palette(plt_result),
          scale = extract_scale(plt_result),
          generation_time_sec = plt_result$generation_time,
          quality_score = plt_result$quality_score,
          status = plt_result$status
        ),
        verbose = verbose
      )
      plot_artifact_names[i] <- artifact_name
    }
  }
  
  # Save plot objects RDS and register
  plots_rds_path <- here("results", "rds", 
                         sprintf("plot_objects_%s.rds", format(Sys.Date(), "%Y%m%d")))
  registry <- save_and_register_rds(
    object = plot_results,
    file_path = plots_rds_path,
    artifact_type = "plot_collection",
    registry = registry,
    input_artifacts = plot_artifact_names,
    metadata = list(
      n_plots = length(plot_results),
      total_generation_time_sec = sum(sapply(plot_results, function(x) x$generation_time %||% 0)),
      avg_quality_score = mean(sapply(plot_results, function(x) x$quality_score %||% 0))
    ),
    verbose = verbose
  )
  
  # Save registry at end
  save_registry(registry)
  
  # Return with registry included
  return(list(
    # ... existing returns ...
    registry = registry,
    plot_artifact_names = plot_artifact_names
  ))
}
```

#### 3.2.2 In `reports/` Query Registry Instead of Filesystem

**full_analysis_report.qmd:**
```r
# Instead of: plot_results[1:10]
# Use: load from artifact registry

# In Quarto setup chunk:
registry <- yaml::read_yaml(here("inst", "config", "artifact_registry.yaml"))

# Get most recent plot collection artifact
plot_artifacts <- Filter(function(x) x$type == "plot_collection", registry$artifacts)
latest_plots_rds <- names(plot_artifacts)[length(plot_artifacts)]  # Last one

# Load plots from RDS registered in artifact
plot_objects_path <- registry$artifacts[[latest_plots_rds]]$file_path
plot_results <- readRDS(plot_objects_path)
```

**Advantage:** Report reads from artifact registry, not filesystem scan.

### 3.3 Modified Workflow

```
R/run_project.R
├─ run_pipeline()
│  ├─ register raw_data artifact
│  ├─ generate 20 plots
│  ├─ register each plot_object artifact
│  ├─ save + register plot_collection RDS
│  └─ save artifact_registry.yaml
│
└─ render_reports()
   ├─ full_analysis_report.qmd
   │  ├─ read artifact_registry.yaml
   │  ├─ find latest plot_collection artifact
   │  ├─ load RDS from path in registry
   │  └─ render with those plots
   │
   ├─ plot_gallery.qmd (same pattern)
   │
   └─ data_quality_report.qmd (same pattern)
```

---

## PART 4: IMPROVEMENTS & ENHANCEMENTS

### 4.1 What Works Well (Keep As-Is)

| System | Rationale | Action |
|--------|-----------|--------|
| Single .qmd files | Simple, transparent templating | ✓ Keep current |
| Parameterized rendering | Flexible, config-driven | ✓ Keep current |
| `embed-resources: true` | Self-contained HTML (good for distribution) | ✓ Keep current |
| ggplot/ggridges templates | Proven palette + scale combo | ✓ Keep current |

### 4.2 What to Add (Priority Order)

#### 4.2.1 [HIGH PRIORITY] Artifact Registry + RDS Caching

**Problem:** Multiple runs create orphaned plots; reports don't reference a single source of truth.

**Solution:** Implement 3.1-3.3 above.

**Effort:** Medium (4-6 hours)
- Create `R/functions/core/artifacts.R` with functions
- Modify `pipeline.R` to register artifacts
- Update `R/run_project.R` to save registry
- Test determinism (same input → same registry)

**Benefit:** 
- Solves the "60+ plots" accumulation problem
- Reports reference latest artifact, not filesystem
- Full provenance chain visible in YAML
- Can delete old PNG files manually (known artifact paths)

#### 4.2.2 [HIGH PRIORITY] Atomic Report Rendering with Registry Validation

**Problem:** Report could render with mixed artifact versions if registry isn't checked.

**Solution:** Before rendering each report, validate artifact registry:

```r
validate_and_render_report <- function(report_name, registry_path) {
  
  # Load registry
  registry <- yaml::read_yaml(registry_path)
  
  # Check latest plot_collection artifact exists and is valid
  plot_artifacts <- Filter(function(x) x$type == "plot_collection", registry$artifacts)
  if (length(plot_artifacts) == 0) {
    stop("No plot_collection artifacts in registry!")
  }
  
  latest_plots <- plot_artifacts[[length(plot_artifacts)]]
  plots_rds_path <- latest_plots$file_path
  
  if (!file.exists(plots_rds_path)) {
    stop(sprintf("Artifact RDS not found: %s", plots_rds_path))
  }
  
  # Verify hash
  computed_hash <- digest::digest(file = plots_rds_path, algo = "sha256")
  if (computed_hash != latest_plots$file_hash_sha256) {
    stop(sprintf("Hash mismatch for %s!", plots_rds_path))
  }
  
  # Now safe to render
  quarto::quarto_render(...)
}
```

**Effort:** Low (1-2 hours)

**Benefit:** Cryptographic verification before report generation; prevents silently using stale plots.

#### 4.2.3 [MEDIUM PRIORITY] Release Bundle Creation

**Problem:** Sharing entire analysis with collaborators requires manual zip creation.

**Solution:** Implement `create_release_bundle()`:

```r
create_release_bundle <- function(
  study_name = "COHA_Dispersal",
  include_raw_data = TRUE,
  include_reports = TRUE,
  include_config = TRUE
) {
  
  # Create staging directory
  staging_dir <- file.path(tempdir(), 
                          sprintf("coha_release_%s", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(staging_dir, recursive = TRUE)
  
  # Copy components
  if (include_raw_data) {
    dir.create(file.path(staging_dir, "data"))
    file.copy(here("data", "data.csv"), 
              file.path(staging_dir, "data", "data.csv"))
  }
  
  if (include_reports) {
    dir.create(file.path(staging_dir, "reports"))
    file.copy(list.files(here("results", "reports"), full.names = TRUE),
              file.path(staging_dir, "reports"),
              recursive = TRUE)
  }
  
  if (include_config) {
    dir.create(file.path(staging_dir, "config"))
    file.copy(here("inst", "config", "artifact_registry.yaml"),
              file.path(staging_dir, "config", "artifact_registry.yaml"))
  }
  
  # Create manifest
  manifest <- list(
    release_name = basename(staging_dir),
    created_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    pipeline_version = "1.0",
    study = study_name,
    includes = list(
      raw_data = include_raw_data,
      reports = include_reports,
      config = include_config
    )
  )
  yaml::write_yaml(manifest, file.path(staging_dir, "manifest.yaml"))
  
  # Zip it
  zip_path <- file.path(here("results", "releases"),
                       sprintf("coha_release_%s.zip", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(dirname(zip_path), recursive = TRUE, showWarnings = FALSE)
  
  zip::zip(zip_path, files = staging_dir, recurse = TRUE)
  
  zip_path
}

# In R/run_project.R:
# bundle_path <- create_release_bundle(include_raw_data = TRUE, include_reports = TRUE)
```

**Effort:** Low-Medium (2-3 hours)

**Benefit:** One-command release creation; collaborators get complete analysis with manifest.

#### 4.2.4 [MEDIUM PRIORITY] Manifest Documentation

**Problem:** No single document explains what artifacts exist and their relationships.

**Solution:** Enhance artifact registry YAML with `manifest_metadata` section (from KPro):

```yaml
manifest_metadata:
  manifest_version: "1.0"
  manifest_schema: "coha_artifact_manifest_v1"
  generated_by: "R/run_project.R"
  generated_at_utc: "2026-02-11T12:09:00Z"
  
  sections:
    artifacts:
      description: "All pipeline outputs with cryptographic hashes"
      count: 23  # 20 plots + 1 RDS + 2 reports
    
    provenance:
      description: "Input-to-output dependency chain"
      linear: ["raw_data → plots → rds → reports"]
    
    data_integrity:
      algorithm: "SHA256"
      verification: "All artifacts checksummed for reproducibility"
      verification_command: "digest::digest(file = path, algo = 'sha256')"
  
  documentation:
    standards: "reference_standards/ST_artifact_release_standards.md"
    project_home: "https://github.com/yourname/COHA_Dispersal"
    report_location: "results/reports/"
    data_input: "data/data.csv"
```

**Effort:** Low (1 hour)

**Benefit:** Self-documenting artifacts; clarity on what's in the artifact registry and why.

#### 4.2.5 [LOW PRIORITY] Artifact Cleanup & Archival

**Problem:** Old PNG files accumulate, taking up disk space.

**Solution:** Add cleanup script:

```r
cleanup_old_artifacts <- function(keep_count = 3, registry_path = here("inst", "config", "artifact_registry.yaml")) {
  
  registry <- yaml::read_yaml(registry_path)
  
  # Find all plot_object artifacts sorted by creation time
  plot_artifacts <- Filter(function(x) x$type == "plot_object", registry$artifacts)
  plot_names <- names(plot_artifacts)
  
  # Sort by created_utc descending (newest first)
  plot_names_sorted <- plot_names[order(
    sapply(plot_artifacts[plot_names], function(x) x$created_utc),
    decreasing = TRUE
  )]
  
  # Delete old ones (keep only last 3 sets)
  to_delete <- plot_names_sorted[-(1:(keep_count * 20))]
  
  for (artifact_name in to_delete) {
    file_path <- registry$artifacts[[artifact_name]]$file_path
    if (file.exists(file_path)) {
      unlink(file_path)
      cat(sprintf("[CLEANUP] Deleted %s\n", basename(file_path)))
    }
    registry$artifacts[[artifact_name]] <- NULL
  }
  
  save_registry(registry)
}
```

**Effort:** Low (1 hour)

**Benefit:** Prevents disk bloat; easy to run quarterly.

### 4.3 Roadmap

| Phase | Items | Effort | Priority |
|-------|-------|--------|----------|
| 1 | Registry functions (4.2.1) | 4-6h | HIGH |
| 2 | Validate + render (4.2.2) | 1-2h | HIGH |
| 3 | Release bundle (4.2.3) | 2-3h | MEDIUM |
| 4 | Manifest metadata (4.2.4) | 1h | MEDIUM |
| 5 | Cleanup script (4.2.5) | 1h | LOW |
| **TOTAL** | | **9-13h** | |

---

## PART 5: SPECIFIC COHA ENHANCEMENTS

### 5.1 Plot-Centric Organization

Unlike KPro (which tracks data transformations), COHA's pipeline is **plot-centric**. Enhance the artifact system to emphasize this:

```r
# Artifact type for plot variants
list(
  type = "plot_variant_set",
  metadata = list(
    scale_variants = 2,  # compact + expanded
    palette_variants = 10,  # plasma, viridis, magma, inferno, cividis, rocket, mako, turbo, set2, dark2
    total_combinations = 20
  )
)

# Can query by palette
get_artifacts_by_palette <- function(registry, palette) {
  artifacts <- registry$artifacts
  Filter(function(x) {
    x$type == "plot_object" && 
    !is.null(x$metadata$palette) && 
    x$metadata$palette == palette
  }, artifacts)
}

# Get all compact variants
compact <- get_artifacts_by_type(registry, "plot_object") %>%
  Filter(function(x) grepl("compact", x$metadata$plot_id), .)
```

### 5.2 Quality Score Tracking

Your pipeline already computes `quality_score` per plot. **Archive this in artifacts:**

```yaml
artifact:
  metadata:
    quality_score: 92
    quality_grade: "A"  # derived from score
    quality_components:
      data_completeness: 95
      visual_clarity: 90
      technical_correctness: 92
```

**Benefit:** Reports can auto-flag low-quality plots; see trends over time.

### 5.3 Configuration Versioning

Store the exact config used for each artifact:

```yaml
artifact:
  config_hash_sha256: "c4d7e2f..."  # hash of ridgeline_config.R
  config_used:
    palette: "plasma"
    scale_value: 0.85
    line_height: 0.85
    fill_palette: "plasma"
    color_palette: "plasma"
```

**Benefit:** Can reproduce exact plot by looking up config in artifact.

### 5.4 Palette Comparison Report

Use artifact registry to auto-generate palette comparison:

```r
# In Quarto: dynamically build comparison section from registry
registry <- yaml::read_yaml(...)

palettes <- unique(sapply(
  Filter(function(x) x$type == "plot_object", registry$artifacts),
  function(x) x$metadata$palette
))

for (palette in sort(palettes)) {
  artifacts <- Filter(function(x) x$metadata$palette == palette, ...)
  # Render gallery of all variants of this palette
}
```

**Benefit:** If you add new palettes, report auto-updates with new comparisons.

---

## PART 6: MIGRATION STRATEGY

### 6.1 Phase 1: No Breaking Changes (Week 1)

1. Create `R/functions/core/artifacts.R` with registry functions
2. Modify `run_pipeline()` to register plots silently (no changes to output)
3. Save `artifact_registry.yaml` at end of pipeline
4. **Do NOT change reports yet** — they still work as-is

### 6.2 Phase 2: Report Validation (Week 2)

1. Modify `R/run_project.R` to validate registry before rendering reports
2. Add checks: "Does latest RDS exist?" "Is hash correct?"
3. Reports still read from file system, but validation happens
4. Keep backward compatibility (reports work if registry missing)

### 6.3 Phase 3: Report Integration (Week 3)

1. Update `full_analysis_report.qmd` to load from artifact registry
2. Update `plot_gallery.qmd` to load from artifact registry  
3. Keep `data_quality_report.qmd` as-is (doesn't embed plots)
4. Test: Run multiple times, verify only 20 plots in report

### 6.4 Phase 4: Bundle + Cleanup (Week 4)

1. Implement `create_release_bundle()`
2. Implement cleanup script
3. Add optional command to `R/run_project.R`
4. Document in README

---

## PART 7: COMPARISON WITH KPro PIPELINE

### What COHA Gained From KPro Standards

| Feature | KPro Use | COHA Adaptation |
|---------|----------|-----------------|
| Artifact registry | Track 3 checkpoints + 5+ outputs | Track 20 plots + 1 RDS + 3 reports |
| SHA256 hashing | Verify data integrity across chunks | Verify plots haven't changed between runs |
| Provenance chain | Show how data transforms | Show how input → plots → reports |
| RDS caching | Save processed dataframes | Save plot objects for reuse |
| Release bundles | Package for downstream projects | Package for collaborators |
| Manifest YAML | Document everything about release | Document plot specs + configs |

### What COHA Simplifies (vs KPro)

| Aspect | KPro | COHA |
|--------|------|------|
| Input sources | Multiple files/detectors | Single CSV |
| Transformation stages | 3-4 checkpoints | 1 data load |
| Output types | Data + summaries + plots + reports | Mostly plots + reports |
| Registry size | 20-30 artifacts | 23-25 artifacts (stable) |
| Release frequency | Ad-hoc (after each chunk) | After full pipeline (once per run) |

### What COHA Still Needs (Not in KPro)

| Need | Why | Approach |
|------|-----|----------|
| Palette tracking | 10 color schemes across 20 plots | Add `palette` field to artifact metadata |
| Scale comparison | Need to see 2x scale effect | Tag artifacts with scale version |
| Quality metrics per plot | Not just overall score | Store per-plot quality scores in artifact |

---

## PART 8: IMPLEMENTATION CHECKLIST

### Before Starting

- [ ] Review this document with team
- [ ] Allocate 9-13 hours over 4 weeks
- [ ] Clone reference standards into bookmarks

### Phase 1: Core Registry (Week 1)

- [ ] Create `R/functions/core/artifacts.R`
- [ ] Implement `init_artifact_registry()`
- [ ] Implement `register_artifact()`
- [ ] Implement `save_registry()`
- [ ] Implement `compute_sha256()`
- [ ] Modify `run_pipeline()` to register plots
- [ ] Test: Pipeline runs, registry.yaml created
- [ ] Commit: "Add artifact registry functions"

### Phase 2: RDS Caching (Week 1-2)

- [ ] Implement `save_and_register_rds()`
- [ ] Modify `run_pipeline()` to save + register plot_objects RDS
- [ ] Test: RDS exists, is registered with correct hash
- [ ] Commit: "Add RDS caching and registration"

### Phase 3: Report Validation (Week 2)

- [ ] Implement `validate_artifact_registry()`
- [ ] Modify `R/run_project.R` render_reports() to validate before rendering
- [ ] Add error handling (graceful fallback if registry missing)
- [ ] Test: Reports only render if registry valid
- [ ] Commit: "Add report validation from registry"

### Phase 4: Report Integration (Week 3)

- [ ] Update `full_analysis_report.qmd` to load from registry
- [ ] Update `plot_gallery.qmd` to load from registry
- [ ] Test: Run 3x, verify only 20 plots in each report (not 60+)
- [ ] Verify hashes match between runs
- [ ] Commit: "Reports read from artifact registry"

### Phase 5: Release Bundle (Week 4)

- [ ] Implement `create_release_bundle()`
- [ ] Implement cleanup script
- [ ] Add optional bundle creation to `R/run_project.R`
- [ ] Test: Bundle contains all expected files
- [ ] Commit: "Add release bundle creation"

### Final

- [ ] Update README with artifact registry info
- [ ] Document how to query registry programmatically
- [ ] Create example: "Get all plasma palette plots"
- [ ] Archive old PNG files (cleanup script)

---

## CONCLUSION

Your KPro artifact registry system is **highly applicable to COHA**, with minimal adaptation needed. The key insight is that COHA's complexity isn't in data transformation (KPro's strength) but in **visualization variants** (20 plots). 

By adapting the registry to be **plot-centric** rather than **checkpoint-centric**, you gain:
1. **Reproducibility** - Full hash verification of all outputs
2. **Determinism** - Reports reference registry, not filesystem
3. **Discoverability** - Query plots by palette, scale, quality score
4. **Distribution** - Release bundles for collaborators
5. **Auditability** - Complete provenance chain in YAML

**Recommended implementation order:**
1. Registry core (critical, prevents report issues)
2. RDS caching (enables report determinism)
3. Report validation (cryptographic safety check)
4. Release bundles (nice-to-have for collaboration)
5. Cleanup (maintenance, low priority)

**Estimated total effort:** 9-13 hours over 4 weeks, with no breaking changes to current workflow.
