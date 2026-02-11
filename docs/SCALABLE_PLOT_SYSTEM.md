# Scalable Plot System Architecture - GUIDE

**Date:** February 11, 2026  
**Version:** 2.0 (Scalable Architecture)  
**Status:** IMPLEMENTED

---

## Overview

The COHA project now uses a **centralized plot registry system** that eliminates hardcoded assumptions about plot counts, names, or types. Adding new palettes, scales, or plot types requires changes in **ONE place** only: `R/config/plot_registry.R`.

---

## Key Files

```
R/
├── config/
│   ├── plot_registry.R ⭐ MASTER CONFIG (edit here for new plots)
│   ├── ridgeline_config.R (DEPRECATED - kept for compatibility only)
│
├── pipeline/
│   └── pipeline.R (reads from plot_registry)
│
└── functions/
    ├── plot_operations.R (generates plots from configurations)
    └── core/
        └── artifacts.R (artifact registry - track generated plots)

reports/
├── plot_gallery_v2.qmd ⭐ FULLY DYNAMIC (generates from registry)
├── full_analysis_report.qmd
└── data_quality_report.qmd
```

---

## How It Works

### 1. Define Plot in Registry

Edit `R/config/plot_registry.R`:

```r
plot_registry <- list(
  ridgeline = list(
    variants = list(
      # Add new variant here
      compact_13 = list(
        id = "compact_13",
        display_name = "Variant 25: Compact + My New Palette",
        scale = 0.85,
        fill = "my_new_palette",
        fill_colors = c("#XXXXXX", "#XXXXXX", ...),  # custom hex
        palette_type = "custom"
      )
    )
  )
)
```

### 2. Update Palette Support (if needed)

If using a new palette TYPE (not just new colors):

Edit `R/functions/plot_operations.R`:

- Handle in the palette application section (already handles: viridis, brewer, custom)

### 3. Pipeline Automatically Includes It

`R/pipeline/pipeline.R` reads from registry:

```r
# NO HARDCODING - reads what's in registry
ridgeline_variants <- plot_registry$ridgeline$variants
plot_configs_active <- ridgeline_variants
```

Generation count is **dynamic** - as many as you define.

### 4. Gallery Automatically Updates

`reports/plot_gallery_v2.qmd` is **fully data-driven**:

- Iterates through `all_plot_ids <- names(plot_registry$ridgeline$variants)`
- Generates tabs dynamically - no editing needed
- Comparison section builds side-by-side views automatically

---

## What Changed (vs Old System)

### Before (Problem)
```r
# Hard-coded everywhere:
ridgeline_plot_configs <- list(...)  # 20 items
names(plot_registry$artifacts) == 20  # tests checked this
reports/plot_gallery.qmd  # manually added 24 tabs
```
❌ Adding 1 palette = edit 4+ files, update tests

### After (Solution)
```r
# Single source of truth:
plot_registry$ridgeline$variants <- list(...)  # N items
# Everything else reads from this ⬆️
```
✅ Adding 1 palette = edit 1 file, no other changes needed

---

## Use Cases

### Use Case 1: Add New Color Palette

**Goal:** Add "Hawk Sunset" palette  
**Steps:** Edit ONLY `R/config/plot_registry.R`

```r
compact_13 = list(
  id = "compact_13",
  display_name = "Variant 25: Compact + Hawk Sunset",
  scale = 0.85,
  fill = "hawk_sunset",
  fill_colors = c("#FFD700", "#FFA500", "#FF6347", ...),
  color = "hawk_sunset",
  color_colors = c("#FFD700", "#FFA500", "#FF6347", ...),
  palette_type = "custom",
  group = "compact"
),
expanded_13 = list(
  # ... same for expanded
)
```

Then run:
```r
source("R/run_project.R")
```

**Result:**
- ✅ 2 new plots generated (26 total now)
- ✅ Gallery automatically shows new tabs
- ✅ Tests automatically pass (no hardcoding)

### Use Case 2: Add Support for New Plot Type

**Goal:** Add boxplot variant  
**Steps:**

1. Add to registry:
```r
plot_registry$boxplot = list(
  type = "boxplot",
  active = TRUE,
  variants = list(
    boxplot_01 = list(
      id = "boxplot_01",
      grouping_var = "period",
      response_var = "mass",
      comparison_var = "dispersed"
    )
  )
)
```

2. Create generator function: `generate_boxplot_safe()` in `R/functions/`

3. Update pipeline:
```r
# In pipeline.R:
if ("boxplot" %in% enabled_types) {
  boxplot_variants <- plot_registry$boxplot$variants
  # ...generate using generate_boxplot_safe()
}
```

4. New reports get tags dynamically when you filter by type.

### Use Case 3: Remove a Variant

**Goal:** Remove underperforming palette  
**Steps:** Delete from `R/config/plot_registry.R`, that's it!

---

## Helper Functions

Access registry through `R/config/plot_registry.R`:

```r
# Get all plot IDs of a type
get_plot_ids("ridgeline")
# Returns: c("compact_01", "compact_02", ..., "expanded_12")

# Count active plots
count_plots()  # All types
count_plots("ridgeline")  # Just ridgeline

# Get plot config by ID
cfg <- get_plot_config("compact_01", "ridgeline")
cfg$fill  # "plasma"
cfg$scale  # 0.85

# Get plots grouped by field
by_scale <- get_plots_grouped("scale", "ridgeline")
by_scale$`0.85`  # All compact plot IDs
by_scale$`2.25`  # All expanded plot IDs
```

---

## Best Practices

### ✅ DO

- **Edit only `R/config/plot_registry.R`** for new plots
- **Use consistent naming**: `{scale}_{number}` (e.g., `expanded_12`)
- **Group plots logically**: use `group` field (compact/expanded)
- **Test in gallery**: run pipeline and check `plot_gallery_v2.html`

### ❌ DON'T

- Hard-code numbers like "expecting 24 plots"
- Edit `ridgeline_config.R` (kept for reference only)
- Add `ifdef` statements for plot counts in code
- Manually edit reports when palette changes

---

## Deprecation Path

### Old Files (kept for compatibility, not used)
- `R/config/ridgeline_config.R` - deprecated
- `reports/plot_gallery.qmd` - replaced by plot_gallery_v2.qmd

### Files to Delete Later
Once all reports use `plot_gallery_v2.qmd`, delete:
- `ridgeline_config.R`
- Old `plot_gallery.qmd`

---

## Testing

Tests automatically validate registry consistency:

```r
# In tests/test_scalability.R (new):

# Test 1: All variants in registry have required fields
test_registry_structure()

# Test 2: Generate plots from registry (not hardcoded count)
test_dynamic_generation()

# Test 3: Gallery loads all generated plots
test_gallery_coverage()

# Test 4: Add new variant - ensure it's included
test_registry_expansion()
```

---

## Future Roadmap

Once this system is proven:

1. ✅ Add boxplot type (`plot_registry$boxplot`)
2. ✅ Add heatmap type (`plot_registry$heatmap`)
3. ✅ Create plot type framework in pipeline
4. ✅ Build report generator for any plot type

All without editing core pipeline logic.

---

## Migration Checklist

- [x] Create `plot_registry.R` with all 24 variants
- [x] Update `pipeline.R` to read from registry
- [x] Create `plot_gallery_v2.qmd` (dynamic)
- [x] Test dynamic generation
- [ ] Update documentation (this file ✓)
- [ ] Run full pipeline test
- [ ] Verify reports generate correctly
- [ ] Update README with new workflow

---

## Questions?

The system is designed for extensibility. If you want to:

- **Add a palette?** → Edit registry only
- **Add a plot type?** → Add registry section + generator function
- **Change report layout?** → Edit `plot_gallery_v2.qmd`

All changes are **localized and explicit** - no hidden dependencies.
