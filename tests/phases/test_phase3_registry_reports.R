# Phase 3 Test: Verify Reports Load Only 20 Plots (No Accumulation)
# =======================================================================
# Tests that artifact registry prevents plot accumulation across multiple runs

library(here)
library(yaml)

cat("\n=== Phase 3 Registry Report Test ===\n\n")

# Source required functions
source(here::here("R", "pipeline", "pipeline.R"))
source(here::here("R", "core", "artifacts.R"))

registry_path <- here::here("R", "config", "artifact_registry.yaml")

# Helper: Count ridgeline plots in registry
count_plots_in_registry <- function() {
  if (!file.exists(registry_path)) {
    return(0)
  }
  registry <- yaml::read_yaml(registry_path)
  if (is.null(registry$artifacts)) {
    return(0)
  }
  plot_artifacts <- Filter(
    function(x) x$type == "ridgeline_plots",
    registry$artifacts
  )
  return(length(plot_artifacts))
}

# Test 1: First Run
cat("Test 1: Running pipeline (first time)...\n")
result1 <- run_pipeline(verbose = FALSE, use_registry = TRUE)
plots_after_run1 <- count_plots_in_registry()
cat(sprintf("✓ First run complete: %d plots registered\n", plots_after_run1))

if (plots_after_run1 != 20) {
  stop(sprintf("FAIL: Expected 20 plots, found %d", plots_after_run1))
}

# Test 2: Second Run (should replace, not accumulate)
cat("\nTest 2: Running pipeline again (second time)...\n")
Sys.sleep(2)  # Ensure different timestamp
result2 <- run_pipeline(verbose = FALSE, use_registry = TRUE)
plots_after_run2 <- count_plots_in_registry()
cat(sprintf("✓ Second run complete: %d plots registered\n", plots_after_run2))

if (plots_after_run2 != 20) {
  stop(sprintf("FAIL: Expected 20 plots (not 40!), found %d", plots_after_run2))
}

# Test 3: Verify report would load exactly 20 plots
cat("\nTest 3: Simulating report plot loading...\n")
registry <- yaml::read_yaml(registry_path)
plot_artifacts <- Filter(
  function(x) x$type == "ridgeline_plots",
  registry$artifacts
)

# Count compact vs expanded
compact_plots <- Filter(function(x) grepl("^compact_", x$name), plot_artifacts)
expanded_plots <- Filter(function(x) grepl("^expanded_", x$name), plot_artifacts)

cat(sprintf("✓ Compact plots available: %d\n", length(compact_plots)))
cat(sprintf("✓ Expanded plots available: %d\n", length(expanded_plots)))

if (length(compact_plots) != 10) {
  stop(sprintf("FAIL: Expected 10 compact plots, found %d", length(compact_plots)))
}
if (length(expanded_plots) != 10) {
  stop(sprintf("FAIL: Expected 10 expanded plots, found %d", length(expanded_plots)))
}

# Test 4: Verify all plot files exist
cat("\nTest 4: Verifying plot files exist on disk...\n")
missing_files <- 0
for (artifact_name in names(plot_artifacts)) {
  artifact <- plot_artifacts[[artifact_name]]
  if (!file.exists(artifact$file_path)) {
    cat(sprintf("  ✗ Missing: %s\n", artifact$file_path))
    missing_files <- missing_files + 1
  }
}

if (missing_files > 0) {
  stop(sprintf("FAIL: %d plot files missing", missing_files))
}
cat(sprintf("✓ All 20 plot files exist on disk\n"))

# Test 5: Verify registry has correct metadata
cat("\nTest 5: Verifying plot metadata...\n")
metadata_ok <- TRUE
for (artifact_name in names(plot_artifacts)) {
  artifact <- plot_artifacts[[artifact_name]]
  if (is.null(artifact$metadata$quality_score)) {
    cat(sprintf("  ✗ Missing quality_score: %s\n", artifact_name))
    metadata_ok <- FALSE
  }
  if (is.null(artifact$metadata$generation_time)) {
    cat(sprintf("  ✗ Missing generation_time: %s\n", artifact_name))
    metadata_ok <- FALSE
  }
  if (is.null(artifact$metadata$palette)) {
    cat(sprintf("  ✗ Missing palette: %s\n", artifact_name))
    metadata_ok <- FALSE
  }
}

if (!metadata_ok) {
  stop("FAIL: Some plots missing required metadata")
}
cat("✓ All plots have required metadata (quality_score, generation_time, palette)\n")

# Final Summary
cat("\n=== Phase 3 Test Results ===\n")
cat("✓ Test 1: First run registered 20 plots\n")
cat("✓ Test 2: Second run replaced (not accumulated) - still 20 plots\n")
cat("✓ Test 3: Report loading pattern works (10 compact + 10 expanded)\n")
cat("✓ Test 4: All 20 plot files exist on disk\n")
cat("✓ Test 5: All plots have required metadata\n")
cat("\n✅ PHASE 3 COMPLETE: Registry prevents plot accumulation\n")
cat("\nReports will always show exactly 20 plots from current run.\n\n")
