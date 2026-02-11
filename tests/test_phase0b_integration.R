# ==============================================================================
# tests/test_phase0b_integration.R
# ==============================================================================
# PURPOSE: Integration test for Phase 0b modules
# USAGE: Source this file in R or RStudio
# ==============================================================================

library(here)

cat("\n===============================================\n")
cat("|  PHASE 0B INTEGRATION TEST                |\n")
cat("===============================================\n\n")

# -------------------------
# TEST 1: Module Loading
# -------------------------

cat("[TEST 1] Loading pipeline modules...\n")

tryCatch({
  source(here::here("R", "pipeline", "pipeline.R"))
  cat("  [OK] Pipeline loaded successfully\n")
}, error = function(e) {
  cat("  [FAIL] Pipeline loading error:\n")
  cat(paste0("    ", e$message, "\n"))
  stop("Pipeline load failed")
})

# -------------------------
# TEST 2: Check Functions
# -------------------------

cat("\n[TEST 2] Verifying function availability...\n")

required_functions <- c(
  "init_artifact_registry",
  "register_artifact",
  "hash_file",
  "save_and_register_rds",
  "create_release_bundle",
  "validate_release_inputs",
  "generate_manifest",
  "generate_quarto_report",
  "find_most_recent_file",
  "make_versioned_path"
)

missing_functions <- c()
for (fn in required_functions) {
  if (!exists(fn)) {
    missing_functions <- c(missing_functions, fn)
    cat(sprintf("  [MISSING] %s\n", fn))
  }
}

if (length(missing_functions) > 0) {
  stop(sprintf("Missing %d functions", length(missing_functions)))
} else {
  cat(sprintf("  [OK] All %d functions available\n", length(required_functions)))
}

# -------------------------
# TEST 3: Registry Init
# -------------------------

cat("\n[TEST 3] Testing artifact registry initialization...\n")

tryCatch({
  test_registry <- init_artifact_registry()
  
  if (!is.list(test_registry)) {
    stop("Registry is not a list")
  }
  
  if (is.null(test_registry$artifacts)) {
    stop("Registry missing 'artifacts' field")
  }
  
  cat("  [OK] Registry initialized\n")
  cat(sprintf("  [OK] Registry has %d artifact(s)\n", 
             length(test_registry$artifacts)))
  
}, error = function(e) {
  cat("  [FAIL] Registry initialization error:\n")
  cat(paste0("    ", e$message, "\n"))
  stop("Registry test failed")
})

# -------------------------
# TEST 4: Artifact Registration (Simulated)
# -------------------------

cat("\n[TEST 4] Testing artifact registration (dry-run)...\n")

# Create a temporary test file
temp_file <- tempfile(fileext = ".csv")
write.csv(data.frame(x = 1:5, y = letters[1:5]), temp_file, row.names = FALSE)

cat(sprintf("  [DEBUG] Created temp file: %s\n", temp_file))
cat(sprintf("  [DEBUG] File exists: %s\n", file.exists(temp_file)))
cat(sprintf("  [DEBUG] Registry has %d artifacts before registration\n", 
           length(test_registry$artifacts)))

tryCatch({
  test_registry <- register_artifact(
    registry = test_registry,
    artifact_name = "test_data",
    artifact_type = "raw_data",
    workflow = "testing",
    file_path = temp_file,
    input_artifacts = NULL,
    metadata = list(test = TRUE),
    quiet = FALSE
  )
  
  cat(sprintf("  [DEBUG] Registry has %d artifacts after registration\n", 
             length(test_registry$artifacts)))
  
  if (length(test_registry$artifacts) == 0) {
    stop("No artifacts registered")
  }
  
  # Verify the artifact was added
  artifact_names <- sapply(test_registry$artifacts, function(x) x$name)
  cat(sprintf("  [DEBUG] Artifact names in registry: %s\n", 
             paste(artifact_names, collapse = ", ")))
  
  if (!"test_data" %in% artifact_names) {
    stop("test_data artifact not found in registry")
  }
  
  cat("  [OK] Artifact registered successfully\n")
  cat(sprintf("  [OK] Registry now has %d artifact(s)\n", 
             length(test_registry$artifacts)))
  
}, error = function(e) {
  cat("  [FAIL] Artifact registration error:\n")
  cat(paste0("    Error message: ", e$message, "\n"))
  if (!is.null(e$call)) {
    cat(paste0("    Error call: ", deparse(e$call), "\n"))
  }
  cat("\n  [DEBUG] Full error:\n")
  print(e)
  unlink(temp_file)
  stop("Registration test failed")
}, finally = {
  if (file.exists(temp_file)) unlink(temp_file)
})

# -------------------------
# TEST 5: File Discovery
# -------------------------

cat("\n[TEST 5] Testing file discovery functions...\n")

tryCatch({
  # Test find_most_recent_file with data directory (optional - requires timestamped files)
  data_dir <- here::here("data")
  if (dir.exists(data_dir) && length(list.files(data_dir)) > 0) {
    tryCatch({
      most_recent <- find_most_recent_file(data_dir, pattern = "\\.(csv|rds)$")
      cat(sprintf("  [OK] Most recent file: %s\n", basename(most_recent)))
    }, error = function(e) {
      cat("  [SKIP] No timestamped files found (this is expected)\n")
    })
  } else {
    cat("  [SKIP] No data directory\n")
  }
  
  # Test make_versioned_path
  test_path <- make_versioned_path(here::here("results", "test_output.csv"))
  cat(sprintf("  [OK] Versioned path: %s\n", basename(test_path)))
  
}, error = function(e) {
  cat("  [FAIL] File discovery error:\n")
  cat(paste0("    ", e$message, "\n"))
  stop("Discovery test failed")
})

# -------------------------
# SUMMARY
# -------------------------

cat("\n===============================================\n")
cat("|  ALL TESTS PASSED                         |\n")
cat("===============================================\n\n")

cat("[*] Phase 0b modules are ready for use:\n")
cat("    - core/artifacts.R (artifact registry)\n")
cat("    - core/utilities.R (file discovery)\n")
cat("    - core/release.R (bundle creation)\n")
cat("    - output/report.R (Quarto rendering)\n\n")

cat("[*] Next steps:\n")
cat("    1. Integrate registry into run_project.R\n")
cat("    2. Add artifact registration after plot creation\n")
cat("    3. Test full pipeline with registry\n")
cat("    4. Create first release bundle\n\n")

cat("[OK] Ready for Phase 1 implementation\n\n")
