# ==============================================================================
# Quick diagnostic test for artifact registry
# ==============================================================================

library(here)

cat("\n=== QUICK REGISTRY TEST ===\n\n")

# Test 1: Load required packages
cat("[1] Loading required packages...\n")
required_pkgs <- c("yaml", "digest")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package '%s' not installed. Run: install.packages('%s')", pkg, pkg))
  }
  library(pkg, character.only = TRUE)
  cat(sprintf("  [OK] %s loaded\n", pkg))
}

# Test 2: Source artifacts.R directly
cat("\n[2] Sourcing artifacts.R...\n")
source(here::here("core", "utilities.R"))
source(here::here("R", "functions", "core", "artifacts.R"))
cat("  [OK] artifacts.R sourced\n")

# Test 3: Check function exists
cat("\n[3] Checking function availability...\n")
if (!exists("init_artifact_registry")) {
  stop("init_artifact_registry not found!")
}
if (!exists("register_artifact")) {
  stop("register_artifact not found!")
}
cat("  [OK] Functions available\n")

# Test 4: Initialize registry
cat("\n[4] Initializing registry...\n")
registry <- init_artifact_registry()
cat("  [OK] Registry initialized\n")
cat(sprintf("  - Type: %s\n", class(registry)))
cat(sprintf("  - Has artifacts field: %s\n", !is.null(registry$artifacts)))
cat(sprintf("  - Number of artifacts: %d\n", length(registry$artifacts)))

# Test 5: Create test file and register
cat("\n[5] Testing registration...\n")
temp_file <- tempfile(fileext = ".csv")
write.csv(data.frame(a = 1:3), temp_file, row.names = FALSE)
cat(sprintf("  - Created temp file: %s\n", basename(temp_file)))
cat(sprintf("  - File exists: %s\n", file.exists(temp_file)))
cat(sprintf("  - File size: %d bytes\n", file.info(temp_file)$size))

cat("\n  Attempting registration...\n")
tryCatch({
  registry <- register_artifact(
    registry = registry,
    artifact_name = "test_artifact",
    artifact_type = "raw_data",
    workflow = "testing",
    file_path = temp_file,
    input_artifacts = NULL,
    metadata = list(test = TRUE),
    quiet = FALSE
  )
  
  cat("\n  [OK] Registration succeeded!\n")
  cat(sprintf("  - Registry now has %d artifact(s)\n", length(registry$artifacts)))
  
  # Check the artifact
  if (length(registry$artifacts) > 0) {
    test_artifact <- registry$artifacts[[1]]
    cat(sprintf("  - Artifact name: %s\n", test_artifact$name))
    cat(sprintf("  - Artifact type: %s\n", test_artifact$type))
    cat(sprintf("  - File hash: %s\n", substr(test_artifact$file_hash_sha256, 1, 16)))
  }
  
}, error = function(e) {
  cat("\n  [FAIL] Registration error:\n")
  cat(sprintf("    Message: %s\n", e$message))
  cat(sprintf("    Call: %s\n", deparse(e$call)))
  cat("\n  Full error object:\n")
  print(e)
}, finally = {
  unlink(temp_file)
})

cat("\n=== TEST COMPLETE ===\n\n")
