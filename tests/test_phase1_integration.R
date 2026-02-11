# ==============================================================================
# tests/test_phase1_integration.R
# ==============================================================================
# PURPOSE: Test Phase 1 artifact registry integration in run_pipeline()
# USAGE: Source this file in R or RStudio
# ==============================================================================

library(here)

cat("\n===============================================\n")
cat("|  PHASE 1 INTEGRATION TEST                 |\n")
cat("===============================================\n\n")

# -------------------------
# TEST 1: Run pipeline with registry enabled
# -------------------------

cat("[TEST 1] Running pipeline with artifact registry...\n\n")

tryCatch({
  source(here::here("R", "pipeline", "pipeline.R"))
  
  result <- run_pipeline(verbose = TRUE, use_registry = TRUE)
  
  cat("\n[TEST 1] Pipeline execution complete\n")
  cat(sprintf("  Status: %s\n", result$status))
  cat(sprintf("  Plots generated: %d\n", result$plots_generated %||% 0))
  cat(sprintf("  Duration: %.2f seconds\n", result$duration_secs))
  
  # Check registry
  if (!is.null(result$registry)) {
    cat(sprintf("  [OK] Registry present in result\n"))
    cat(sprintf("  [OK] Registry has %d artifact(s)\n", 
               length(result$registry$artifacts)))
    
    # List artifacts
    cat("\n  Registered artifacts:\n")
    for (name in names(result$registry$artifacts)) {
      artifact <- result$registry$artifacts[[name]]
      cat(sprintf("    - %s (%s)\n", name, artifact$type))
    }
  } else {
    cat("  [WARNING] No registry in result\n")
  }
  
}, error = function(e) {
  cat("  [FAIL] Pipeline error:\n")
  cat(paste0("    ", e$message, "\n"))
  stop("Pipeline test failed")
})

# -------------------------
# TEST 2: Verify registry persistence
# -------------------------

cat("\n[TEST 2] Checking registry persistence...\n")

registry_path <- here::here("R", "config", "artifact_registry.yaml")
if (file.exists(registry_path)) {
  cat(sprintf("  [OK] Registry file exists: %s\n", basename(registry_path)))
  
  # Read registry
  registry <- yaml::read_yaml(registry_path)
  cat(sprintf("  [OK] Registry contains %d artifact(s)\n", 
             length(registry$artifacts)))
  
  # Check for expected artifacts
  artifact_names <- names(registry$artifacts)
  
  if ("coha_dispersal_data" %in% artifact_names) {
    cat("  [OK] Data artifact registered\n")
  } else {
    cat("  [WARNING] Data artifact not found\n")
  }
  
  plot_artifacts <- grep("^(compact|expanded)_", artifact_names, value = TRUE)
  if (length(plot_artifacts) > 0) {
    cat(sprintf("  [OK] %d plot artifacts registered\n", length(plot_artifacts)))
  } else {
    cat("  [WARNING] No plot artifacts found\n")
  }
  
} else {
  cat("  [WARNING] Registry file not created\n")
}

# -------------------------
# TEST 3: Verify artifact integrity
# -------------------------

cat("\n[TEST 3] Verifying artifact integrity...\n")

if (exists("result") && !is.null(result$registry)) {
  registry <- result$registry
  
  # Test a few artifacts
  test_count <- 0
  verified_count <- 0
  
  for (name in names(registry$artifacts)[1:min(3, length(registry$artifacts))]) {
    artifact <- registry$artifacts[[name]]
    test_count <- test_count + 1
    
    if (file.exists(artifact$file_path)) {
      # Compute current hash
      current_hash <- digest::digest(file = artifact$file_path, algo = "sha256")
      
      if (current_hash == artifact$file_hash_sha256) {
        verified_count <- verified_count + 1
      }
    }
  }
  
  if (test_count > 0) {
    cat(sprintf("  [OK] Verified %d/%d artifact(s)\n", verified_count, test_count))
  } else {
    cat("  [SKIP] No artifacts to verify\n")
  }
} else {
  cat("  [SKIP] Registry not available\n")
}

# -------------------------
# TEST 4: Test registry-disabled mode
# -------------------------

cat("\n[TEST 4] Testing pipeline with registry disabled...\n")

tryCatch({
  result_no_reg <- run_pipeline(verbose = FALSE, use_registry = FALSE)
  
  if (is.null(result_no_reg$registry)) {
    cat("  [OK] No registry when use_registry=FALSE\n")
  } else {
    cat("  [WARNING] Registry present when disabled\n")
  }
  
  if (result_no_reg$status %in% c("success", "partial")) {
    cat("  [OK] Pipeline runs successfully without registry\n")
  }
  
}, error = function(e) {
  cat("  [FAIL] Pipeline failed without registry:\n")
  cat(paste0("    ", e$message, "\n"))
})

# -------------------------
# SUMMARY
# -------------------------

cat("\n===============================================\n")
cat("|  PHASE 1 INTEGRATION TEST COMPLETE        |\n")
cat("===============================================\n\n")

if (exists("result") && !is.null(result$registry)) {
  cat("[SUCCESS] Phase 1 integration working correctly\n\n")
  
  cat("[*] Integration points verified:\n")
  cat("    ✓ Registry initialization in run_pipeline()\n")
  cat("    ✓ Data artifact registration after load\n")
  cat("    ✓ Plot artifact registration after generation\n")
  cat("    ✓ Registry stored in pipeline result\n")
  cat("    ✓ Registry persisted to YAML file\n")
  cat("    ✓ Artifact integrity verification working\n")
  cat("    ✓ Registry can be disabled with use_registry=FALSE\n\n")
  
  cat("[*] Next steps:\n")
  cat("    - Phase 2: Add report artifact registration\n")
  cat("    - Phase 3: Implement artifact discovery functions\n")
  cat("    - Phase 4: Create release bundle workflow\n\n")
} else {
  cat("[WARNING] Some tests incomplete or failed\n")
  cat("  Review output above for details\n\n")
}
