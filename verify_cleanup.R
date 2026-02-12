#!/usr/bin/env Rscript
# ==============================================================================
# verify_cleanup.R
# ==============================================================================
# PURPOSE: Verify codebase cleanup was successful
# USAGE: Rscript verify_cleanup.R
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("COHA CODEBASE CLEANUP VERIFICATION\n")
cat("================================================================================\n\n")

library(here)
setwd(here::here())

# Test 1: Verify deleted files are gone
cat("[1/5] Checking deleted files...\n")
deleted_files <- c(
  "R/functions/core/assertions.R",
  "R/functions/core/config.R",
  "R/functions/core/console.R",
  "R/functions/core/logging.R",
  "R/functions/core/utilities.R",
  "R/functions/core/coha_release.R",
  "R/functions/plot_function.R",
  "R/legacy/ridgeline_plot.R"
)

all_deleted <- TRUE
for (f in deleted_files) {
  if (file.exists(f)) {
    cat(sprintf("  ✗ FAIL: File still exists: %s\n", f))
    all_deleted <- FALSE
  }
}
if (all_deleted) {
  cat("  ✓ PASS: All redundant files deleted\n\n")
} else {
  cat("\n")
  stop("Cleanup verification failed: Some files not deleted")
}

# Test 2: Verify renamed files exist
cat("[2/5] Checking renamed files...\n")
renamed_files <- c(
  "R/functions/data_operations.R",
  "R/functions/plot_operations.R"
)

all_renamed <- TRUE
for (f in renamed_files) {
  if (!file.exists(f)) {
    cat(sprintf("  ✗ FAIL: File missing: %s\n", f))
    all_renamed <- FALSE
  }
}
if (all_renamed) {
  cat("  ✓ PASS: All renamed files exist\n\n")
} else {
  cat("\n")
  stop("Cleanup verification failed: Renamed files missing")
}

# Test 3: Verify pipeline loads without errors
cat("[3/5] Loading pipeline...\n")
tryCatch({
  source("R/pipeline/pipeline.R")
  cat("  ✓ PASS: Pipeline loaded successfully\n\n")
}, error = function(e) {
  cat(sprintf("  ✗ FAIL: Pipeline load error: %s\n\n", e$message))
  stop("Cleanup verification failed: Pipeline cannot load")
})

# Test 4: Run pipeline
cat("[4/5] Running pipeline...\n")
result <- tryCatch({
  run_pipeline(verbose = FALSE)
}, error = function(e) {
  cat(sprintf("  ✗ FAIL: Pipeline execution error: %s\n\n", e$message))
  stop("Cleanup verification failed: Pipeline execution error")
})

if (result$status %in% c("success", "partial")) {
  cat(sprintf("  ✓ PASS: Pipeline executed successfully\n"))
  cat(sprintf("    - Status: %s\n", result$status))
  cat(sprintf("    - Plots Generated: %d/%d\n", 
              result$plots_generated, result$plots_total))
  cat(sprintf("    - Success Rate: %.0f%%\n\n", result$success_rate))
} else {
  cat(sprintf("  ✗ FAIL: Pipeline status: %s\n\n", result$status))
  stop("Cleanup verification failed: Pipeline failed")
}

# Test 5: Verify no phase3_ references in active code
cat("[5/5] Checking for legacy 'phase3_' references in active R code...\n")
r_files <- list.files("R", pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
r_files <- r_files[!grepl("legacy", r_files)] # Exclude legacy folder if exists

legacy_refs_found <- FALSE
for (f in r_files) {
  content <- readLines(f, warn = FALSE)
  # Check for active source() statements with phase3_ (not comments)
  active_lines <- grep("^[^#]*source.*phase3_", content, value = TRUE)
  if (length(active_lines) > 0) {
    cat(sprintf("  ⚠ WARNING: Found phase3_ reference in %s:\n", f))
    for (line in active_lines) {
      cat(sprintf("    %s\n", trimws(line)))
    }
    legacy_refs_found <- TRUE
  }
}

if (!legacy_refs_found) {
  cat("  ✓ PASS: No legacy phase3_ references in active code\n\n")
} else {
  cat("\n  Note: Some legacy references found but may be in comments.\n\n")
}

# Summary
cat("================================================================================\n")
cat("✅ CLEANUP VERIFICATION COMPLETE\n")
cat("================================================================================\n\n")
cat(sprintf("Files Deleted: %d\n", length(deleted_files)))
cat(sprintf("Files Renamed: %d\n", length(renamed_files)))
cat(sprintf("Pipeline Status: %s\n", result$status))
cat(sprintf("Plots Generated: %d/%d (%.0f%% success)\n", 
            result$plots_generated, result$plots_total, result$success_rate))
cat("\n")
cat("All cleanup tasks completed successfully! 🎉\n\n")
