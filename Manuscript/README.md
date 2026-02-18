# COHA Dispersal Manuscript - Supplementary Code

This directory contains reproducible analysis scripts for generating figures in the Cooper's Hawk (COHA) natal dispersal and mass analysis manuscript.

## Directory Structure

```
Manuscript/
├── README.md                # This file
├── data/
│   ├── data.csv             # Raw input data
│   └── data_frozen.rds      # Frozen data snapshot (auto-generated)
├── scripts/
│   ├── ridgeline_plot.R     # Ridgeline density plot by period
│   ├── boxplot.R            # Boxplot comparing dispersal groups
│   ├── shared_utils.R       # small helpers: palettes, themes, stats, repro report
│   ├── data_loader.R        # canonical data loader (uses `dispersed` column)
│   └── data_prep.R          # explicit snapshot creator (writes data_frozen.rds)
└── figures/
    ├── ridgeline.png        # Ridgeline plot output (PNG, 300 dpi)
    ├── ridgeline.pdf        # Ridgeline plot output (PDF, vector)
    ├── boxplot.png          # Boxplot output (PNG, 300 dpi)
    ├── boxplot.pdf          # Boxplot output (PDF, vector)
    ├── repro_report.txt     # Reproducibility report for ridgeline
    └── repro_report_boxplot.txt  # Reproducibility report for boxplot
```

## Required R Packages

All scripts require R version 4.0 or higher. Install required packages:

```r
install.packages(c("ggplot2", "ggridges", "dplyr", "ggtext", "digest"))
```

### Package Versions Used in Development
- `ggplot2`: for plotting
- `ggridges`: for ridgeline density plots
- `dplyr`: for data manipulation
- `ggtext`: for markdown-formatted axis labels (ridgeline plot only)
- `digest`: for SHA256 file hashing

Tip: for exact reproducibility consider using `renv::snapshot()` to create a `renv.lock` and instruct reviewers to run `renv::restore()`.

## Input Data

**File:** `data/data.csv`

**Required columns:**
- `mass`: Body mass in grams (numeric)
- `year`: Year of observation (integer, 1980-2027)
- `dispersed`: Dispersal classification (e.g. `"Wisconsin"`, `"Unknown"`)

The Manuscript scripts expect the canonical `dispersed` column. Scripts internally create a local lowercased indicator (e.g. `tolower(dispersed)`) when filtering for `"wisconsin"` vs `"unknown"`.

**Data structure:**
- 6-year period bins (1980-1985, 1986-1991, ..., 2022-2027)
- Two dispersal groups typically used in figures: Wisconsin (dispersed) and Unknown (non-dispersed)

## Running the Scripts

All scripts should be run from the `Manuscript/` directory as the working directory.

### Toggle frozen vs live data
The loader honors the environment variable `USE_FROZEN` (default `1`). To force reading the CSV instead of the frozen snapshot:

```powershell
# Use live CSV
$env:USE_FROZEN = "0"
Rscript scripts/ridgeline_plot.R
Rscript scripts/boxplot.R
```

To use the frozen snapshot (default behavior):
```powershell
$env:USE_FROZEN = "1"
Rscript scripts/ridgeline_plot.R
```

### Create or update the frozen snapshot
The plotting scripts no longer write snapshots. To (re)create `data/data_frozen.rds` from `data.csv` run:

```powershell
Rscript scripts/data_prep.R
```

### Alternative: R Console

```r
# Set working directory to Manuscript/
setwd("path/to/Manuscript")

# Run scripts
source("scripts/ridgeline_plot.R")
source("scripts/boxplot.R")
```

## Figure Descriptions

### Ridgeline Plot (`scripts/ridgeline_plot.R`)

**Output:** `figures/ridgeline.png`, `figures/ridgeline.pdf`

Displays mass distributions across 6-year periods using ridgeline (joy) plots with the HawkO_natural color palette. Includes mean markers for both dispersal groups:
- **Dashed line + circle**: Wisconsin (dispersed) mean
- **Solid line + triangle**: Unknown (non-dispersed) mean

**Visual features:**
- Scale: 2.25 (moderate overlap between distributions)
- Y-axis labels show period and sample sizes (dispersal: n, non-dispersal: n)
- Color palette: HawkO_natural gradient (#1F2A3A → #EF8C27)

**Runtime:** ~5-10 seconds

---

### Boxplot (`scripts/boxplot.R`)

**Output:** `figures/boxplot.png`, `figures/boxplot.pdf`

Standard boxplots comparing mass distributions between dispersal groups across periods.

**Visual features:**
- **Dispersed (Wisconsin)**: #56677F (blue-gray)
- **Non-dispersed (Unknown)**: #C98C63 (tan)
- Box shows 1st quartile, median, and 3rd quartile
- Whiskers extend to 1.5 × IQR
- Diamond markers indicate group means
- Mean lines connect across periods

**Runtime:** ~3-5 seconds

## Reproducibility Features

Both scripts implement gold-standard reproducibility practices:

### 1. **Fixed Random Seed**
```r
set.seed(12345)
```

### 2. **Frozen Data Snapshots**
- `data_prep.R` explicitly creates `data/data_frozen.rds` from `data.csv` when you want to lock inputs.
- Plotting scripts read the frozen snapshot by default but can be forced to use the live CSV with `USE_FROZEN=0`.
- This ensures reproducibility when desired, while preserving the ability to iterate on CSV inputs.

### 3. **Dual Output Formats**
- **PNG**: High-resolution (300 dpi) for manuscripts
- **PDF**: Vector format for editing and publication

### 4. **Reproducibility Reports**
Each script generates a text report (`repro_report*.txt`) containing:
- Execution timestamp
- R version and OS information
- Loaded package versions
- SHA256 hashes for input files (CSV and RDS)
- SHA256 hashes for output files (PNG and PDF)
- Random seed used

**Example:**
```
=== Reproducibility Report ===

Script: ridgeline_plot.R
Execution time: 2026-02-16 10:30:45

R version: R version 4.x.x
OS: Windows 10.x

Loaded packages:
[package version details]

Input files:
- data/data.csv (sha256): abc123...
- data/data_frozen.rds (sha256): def456...

Output files:
- figures/ridgeline.png (sha256): ghi789...
- figures/ridgeline.pdf (sha256): jkl012...

Random seed: 12345
```

## Troubleshooting

### Missing `dispersed` column error
**Problem:** The Manuscript scripts require the canonical `dispersed` column in `data.csv`.

**Solution:** Ensure `data.csv` contains the `dispersed` column (string values like `"Wisconsin"`/`"Unknown"`). The scripts will internally normalize this column (trim and lowercase) before plotting.

### Package installation issues
**Problem:** Cannot install `ggtext` or `ggridges`.

**Solution:**
```r
# Try installing dependencies first
install.packages("systemfonts")
install.packages("textshaping")
install.packages("ggtext")
```

### Path issues on different OS
**Problem:** Scripts fail with path errors.

**Note:** Scripts use `file.path()` for cross-platform compatibility. Always run from `Manuscript/` directory as working directory.

## Citation

If you use this code in your work, please cite:

[Author names]. ([Year]). [Manuscript title]. [Journal], [Volume]([Issue]), [Pages].

## Contact

For questions about this analysis, please contact [contact information].

## License

[Specify license if applicable, e.g., MIT, CC-BY-4.0, etc.]

---

**Last updated:** February 18, 2026
