# ==============================================================================
# PHASE 2 PLOT MODULES INTEGRATION TEST SUITE
# ==============================================================================
# Tests for plot module system: discovery, loading, validation, generation
#
# Run with: source("tests/test_phase2_plot_modules.R")
# ==============================================================================

test_count <- 0
passed_count <- 0
failed_count <- 0

run_test <- function(test_name, test_expr) {
  test_count <<- test_count + 1
  
  tryCatch({
    test_expr()
    passed_count <<- passed_count + 1
    cat(sprintf("  [✓] %s\n", test_name))
  }, error = function(e) {
    failed_count <<- failed_count + 1
    cat(sprintf("  [✗] %s: %s\n", test_name, e$message))
  })
}

cat("============================================================\n")
cat("  PHASE 2 PLOT MODULES INTEGRATION TEST SUITE\n")
cat("  Module Discovery, Loading, Validation, and Generation\n")
cat("============================================================\n\n")

# Load required files
source(here::here("R", "core", "utilities.R"))
source(here::here("R", "core", "console.R"))
source(here::here("R", "core", "engine.R"))

# ==============================================================================
# SECTION 1: MODULE DISCOVERY TESTS
# ==============================================================================

cat("TEST SECTION 1: Module Discovery\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 1.1: Discover plot modules
run_test("Discover plot modules", {
  discovered <- discover_modules(type = "plot", verbose = FALSE)
  
  if (!"plot_modules" %in% names(discovered)) {
    stop("Should have plot_modules field")
  }
  if (!"ridgeline" %in% names(discovered$plot_modules)) {
    stop("Should discover ridgeline module")
  }
})

# Test 1.2: Discover domain modules
run_test("Discover domain modules", {
  discovered <- discover_modules(type = "domain", verbose = FALSE)
  
  if (!"domain_modules" %in% names(discovered)) {
    stop("Should have domain_modules field")
  }
})

# Test 1.3: Discover all modules
run_test("Discover all modules", {
  discovered <- discover_modules(type = NULL, verbose = FALSE)
  
  if (!"plot_modules" %in% names(discovered)) {
    stop("Should have plot_modules")
  }
  if (!"domain_modules" %in% names(discovered)) {
    stop("Should have domain_modules")
  }
})

# Test 1.4: Module discovery includes metadata
run_test("Module discovery includes metadata", {
  discovered <- discover_modules(verbose = FALSE)
  ridgeline_module <- discovered$plot_modules$ridgeline
  
  if (is.null(ridgeline_module$path)) {
    stop("Should have module path")
  }
  if (is.null(ridgeline_module$module_file)) {
    stop("Should have module_file")
  }
})

# ==============================================================================
# SECTION 2: MODULE LOADING TESTS
# ==============================================================================

cat("\nTEST SECTION 2: Module Loading\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 2.1: Load plot module
run_test("Load ridgeline plot module", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  
  if (!result$loaded) {
    stop(sprintf("Module load failed: %s", paste(result$errors, collapse = "; ")))
  }
  if (is.null(result$env)) {
    stop("Should have module environment")
  }
})

# Test 2.2: Loaded module has required functions
run_test("Loaded module has get_module_metadata", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  
  if (!exists("get_module_metadata", where = result$env)) {
    stop("Should have get_module_metadata function")
  }
})

# Test 2.3: Can call get_module_metadata
run_test("Call get_module_metadata from loaded module", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  
  metadata <- result$env$get_module_metadata()
  
  if (is.null(metadata)) {
    stop("Should return metadata")
  }
  if (metadata$name != "ridgeline") {
    stop("Metadata name should be 'ridgeline'")
  }
  if (metadata$type != "plot") {
    stop("Metadata type should be 'plot'")
  }
})

# Test 2.4: Can call get_available_plots
run_test("Call get_available_plots from loaded module", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  
  plots <- result$env$get_available_plots()
  
  if (!is.data.frame(plots)) {
    stop("Should return data frame")
  }
  if (nrow(plots) != 9) {
    stop("Should have 9 plots")
  }
  if (!"plot_id" %in% names(plots)) {
    stop("Should have plot_id column")
  }
})

# ==============================================================================
# SECTION 3: MODULE VALIDATION TESTS
# ==============================================================================

cat("\nTEST SECTION 3: Module Validation\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 3.1: Validate plot module interface
run_test("Validate ridgeline module interface", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  validation <- validate_module_interface(result$env, type = "plot", verbose = FALSE)
  
  if (!validation$valid) {
    stop(sprintf("Module validation failed: %s", 
                 paste(validation$errors, collapse = "; ")))
  }
})

# Test 3.2: Detect interface style
run_test("Detect new-style plot module interface", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  validation <- validate_module_interface(result$env, type = "plot", verbose = FALSE)
  
  if (validation$interface_style != "new") {
    stop(sprintf("Should detect new interface style, got: %s", 
                 validation$interface_style))
  }
})

# Test 3.3: Module metadata consistency
run_test("Module metadata is consistent", {
  result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  metadata <- result$env$get_module_metadata()
  validation <- validate_module_interface(result$env, type = "plot", verbose = FALSE)
  
  if (!validation$valid) {
    stop("Valid module should pass validation")
  }
  if (metadata$name == "") {
    stop("Module name should not be empty")
  }
})

# ==============================================================================
# SECTION 4: PLOT GENERATION TESTS
# ==============================================================================

cat("\nTEST SECTION 4: Plot Generation\n")
cat("-" %.0f(45), "\n", sep = "")

# Create test data
test_data <- data.frame(
  generation = rep(c("Gen1", "Gen2", "Gen3"), times = 100),
  mass = rnorm(300, mean = 100, sd = 30),
  dispersed = sample(c(TRUE, FALSE), 300, replace = TRUE)
)

# Test 4.1: Load module for generation tests
run_test("Load module for generation tests", {
  ridge_result <- load_module("ridgeline", type = "plot", verbose = FALSE)
  if (!ridge_result$loaded) {
    stop("Failed to load module for generation tests")
  }
})

# Get loaded module once
ridge_result <- load_module("ridgeline", type = "plot", verbose = FALSE)

# Test 4.2: Generate single plot
run_test("Generate single plot", {
  result <- ridge_result$env$generate_plot(
    data = test_data,
    plot_id = "compact_01",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (result$status == "failed") {
    stop(sprintf("Plot generation failed: %s", result$message))
  }
  if (is.null(result$plot)) {
    stop("Should return plot object")
  }
})

# Test 4.3: Generate plot with all metadata
run_test("Generated plot has complete metadata", {
  result <- ridge_result$env$generate_plot(
    data = test_data,
    plot_id = "regular_02",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  required_fields <- c(
    "status", "message", "plot_id", "plot", "generation_time",
    "quality_score", "data_n", "errors", "warnings"
  )
  
  for (field in required_fields) {
    if (!(field %in% names(result))) {
      stop(sprintf("Missing field: %s", field))
    }
  }
})

# Test 4.4: Generate multiple plots
run_test("Generate multiple plots in batch", {
  result <- ridge_result$env$generate_plots_batch(
    data = test_data,
    plot_ids = c("compact_01", "regular_01", "expanded_01"),
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (length(result) != 3) {
    stop("Should return 3 results")
  }
  if (!all(c("compact_01", "regular_01", "expanded_01") %in% names(result))) {
    stop("Results should be named by plot_id")
  }
})

# Test 4.5: Generate all available plots
run_test("Generate all available plot variants", {
  plots <- ridge_result$env$get_available_plots()
  
  result <- ridge_result$env$generate_plots_batch(
    data = test_data,
    plot_ids = NULL,  # NULL = all
    config = list(verbose = FALSE, save_file = FALSE, continue_on_error = TRUE)
  )
  
  if (length(result) != nrow(plots)) {
    stop(sprintf("Should generate %d plots, got %d", nrow(plots), length(result)))
  }
})

# ==============================================================================
# SECTION 5: ERROR HANDLING TESTS
# ==============================================================================

cat("\nTEST SECTION 5: Error Handling\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 5.1: Handle empty data
run_test("Handle empty data gracefully", {
  result <- ridge_result$env$generate_plot(
    data = data.frame(generation = character()),
    plot_id = "compact_01",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (result$status != "failed") {
    stop("Should return failed status for empty data")
  }
  if (length(result$errors) == 0) {
    stop("Should have error message")
  }
})

# Test 5.2: Handle invalid plot_id
run_test("Handle invalid plot_id", {
  result <- ridge_result$env$generate_plot(
    data = test_data,
    plot_id = "invalid_plot_xyz",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (result$status != "failed") {
    stop("Should return failed status for invalid plot_id")
  }
})

# Test 5.3: Handle bad data type
run_test("Handle non-dataframe input", {
  result <- ridge_result$env$generate_plot(
    data = list(not = "data"),
    plot_id = "compact_01",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (result$status != "failed") {
    stop("Should return failed status for non-dataframe input")
  }
})

# ==============================================================================
# SECTION 6: QUALITY SCORING TESTS
# ==============================================================================

cat("\nTEST SECTION 6: Quality Scoring\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 6.1: Quality score is numeric
run_test("Quality score is numeric", {
  result <- ridge_result$env$generate_plot(
    data = test_data,
    plot_id = "compact_01",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (!is.numeric(result$quality_score)) {
    stop("Quality score should be numeric")
  }
  if (result$quality_score < 0 || result$quality_score > 100) {
    stop("Quality score should be 0-100")
  }
})

# Test 6.2: Failed plot has zero quality score
run_test("Failed plot has zero quality score", {
  result <- ridge_result$env$generate_plot(
    data = data.frame(),
    plot_id = "compact_01",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (result$status == "failed" && result$quality_score != 0) {
    stop("Failed plots should have quality_score=0")
  }
})

# Test 6.3: Successful plot has high quality score
run_test("Successful plot has good quality score", {
  result <- ridge_result$env$generate_plot(
    data = test_data,
    plot_id = "compact_01",
    config = list(verbose = FALSE, save_file = FALSE)
  )
  
  if (result$status == "success" && result$quality_score < 50) {
    stop("Successful plot should have quality_score >= 50")
  }
})

# ==============================================================================
# TEST SUMMARY
# ==============================================================================

cat("\n")
cat("=" %.0f(60), "\n", sep = "")
cat(sprintf("PHASE 2 TEST RESULTS\n"))
cat("=" %.0f(60), "\n", sep = "")
cat(sprintf("Total Tests:  %d\n", test_count))
cat(sprintf("Passed:       %d ✓\n", passed_count))
cat(sprintf("Failed:       %d ✗\n", failed_count))
cat(sprintf("Success Rate: %.1f%%\n", 100 * passed_count / test_count))
cat("=" %.0f(60), "\n", sep = "")

if (failed_count == 0) {
  cat("\n✓ ALL TESTS PASSED - Phase 2 plot module system complete\n\n")
} else {
  cat(sprintf("\n✗ %d test(s) failed - review above\n\n", failed_count))
}

invisible(list(
  total = test_count,
  passed = passed_count,
  failed = failed_count,
  success_rate = passed_count / test_count
))
