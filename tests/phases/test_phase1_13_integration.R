# ==============================================================================
# PHASE 1.13 INTEGRATION TEST SUITE
# ==============================================================================
# Tests for new connectors: Data Type Interface & Error/Logging Interface
#
# Run with: source("tests/test_phase1_13_integration.R")
# ==============================================================================

# Test counter
test_count <- 0
passed_count <- 0
failed_count <- 0

# Helper: Run test
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
cat("  PHASE 1.13 INTEGRATION TEST SUITE\n")
cat("  Data Type Interface & Error/Logging Interface\n")
cat("============================================================\n\n")

# Load required files
source(here::here("R", "core", "utilities.R"))
source(here::here("R", "core", "module_result.R"))
source(here::here("R", "core", "error_interface.R"))
source(here::here("R", "core", "data_interface.R"))

# ==============================================================================
# SECTION 1: DATA TYPE INTERFACE TESTS
# ==============================================================================

cat("TEST SECTION 1: Data Type Interface\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 1.1: Schema validation - valid data
run_test("Valid COHA input data passes validation", {
  test_data <- data.frame(
    mass = c(150.5, 175.2, 162.8),
    year = c(2020L, 2021L, 2020L),
    dispersed = c(TRUE, FALSE, TRUE),
    origin = c("PopA", "PopB", "PopA"),
    stringsAsFactors = FALSE
  )
  
  validation <- validate_data_against_schema(test_data, SCHEMA_COHA_INPUT_DATA)
  
  if (!validation$valid) {
    stop("Valid data should pass validation")
  }
  if (length(validation$errors) > 0) {
    stop(sprintf("Should have no errors, got: %s", validation$errors[1]))
  }
})

# Test 1.2: Schema validation - missing required column
run_test("Missing required column detected", {
  test_data <- data.frame(
    mass = c(150.5, 175.2),
    year = c(2020L, 2021L),
    # Missing: dispersed
    origin = c("PopA", "PopB"),
    stringsAsFactors = FALSE
  )
  
  validation <- validate_data_against_schema(test_data, SCHEMA_COHA_INPUT_DATA)
  
  if (validation$valid) {
    stop("Should detect missing column")
  }
  if (!("dispersed" %in% validation$missing_columns)) {
    stop("Should report 'dispersed' as missing")
  }
})

# Test 1.3: Schema validation - type mismatch
run_test("Type mismatch detected correctly", {
  test_data <- data.frame(
    mass = c("150", "175"),  # Should be numeric, not character
    year = c(2020L, 2021L),
    dispersed = c(TRUE, FALSE),
    origin = c("PopA", "PopB"),
    stringsAsFactors = FALSE
  )
  
  validation <- validate_data_against_schema(test_data, SCHEMA_COHA_INPUT_DATA)
  
  if (validation$valid) {
    stop("Should detect type mismatch")
  }
  if (!("mass" %in% names(validation$type_mismatches))) {
    stop("Should report mass type mismatch")
  }
})

# Test 1.4: Schema validation - constraint violation (warning)
run_test("Constraint violations produce warnings", {
  test_data <- data.frame(
    mass = c(150.5, 175.2, -10.0),  # -10 violates min constraint
    year = c(2020L, 2021L, 2020L),
    dispersed = c(TRUE, FALSE, TRUE),
    origin = c("PopA", "PopB", "PopA"),
    stringsAsFactors = FALSE
  )
  
  validation <- validate_data_against_schema(test_data, SCHEMA_COHA_INPUT_DATA)
  
  if (length(validation$warnings) == 0) {
    stop("Should generate warning for constraint violation")
  }
  if (!any(grepl("below minimum", validation$warnings))) {
    stop("Warning should mention constraint")
  }
})

# Test 1.5: Schema validation - too few rows
run_test("Too few rows detected", {
  test_data <- data.frame(
    mass = c(150.5),
    year = c(2020L),
    dispersed = c(TRUE),
    origin = c("PopA"),
    stringsAsFactors = FALSE
  )
  
  validation <- validate_data_against_schema(test_data, SCHEMA_COHA_INPUT_DATA)
  
  if (validation$valid) {
    stop("Should fail with too few rows")
  }
  if (!any(grepl("Too few rows", validation$errors))) {
    stop("Error should mention row count")
  }
})

# Test 1.6: Generate schema documentation
run_test("Schema documentation generation", {
  docs <- generate_schema_docs(SCHEMA_COHA_INPUT_DATA)
  
  if (!grepl("coha_input_data", docs)) {
    stop("Documentation should contain schema ID")
  }
  if (!grepl("mass", docs)) {
    stop("Documentation should list columns")
  }
})

# Test 1.7: Get schema by ID
run_test("Retrieve schema by ID", {
  schema <- get_schema("coha_input_data")
  
  if (is.null(schema)) {
    stop("Should retrieve schema")
  }
  if (schema$schema_id != "coha_input_data") {
    stop("Schema ID should match")
  }
})

# Test 1.8: List all schemas
run_test("List all available schemas", {
  all_schemas <- get_all_schemas()
  
  if (length(all_schemas) < 3) {
    stop("Should have at least 3 schemas")
  }
  if (!("coha_input_data" %in% names(all_schemas))) {
    stop("Should include coha_input_data schema")
  }
})

# ==============================================================================
# SECTION 2: ERROR/LOGGING INTERFACE TESTS
# ==============================================================================

cat("\nTEST SECTION 2: Error/Logging Interface\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 2.1: Add categorized error to result
run_test("Add categorized error to result", {
  result <- create_module_result(
    operation = "test",
    module_name = "test_module"
  )
  
  result <- add_categorized_error(
    result,
    "File not found",
    category = "FILE_NOT_FOUND"
  )
  
  if (result$status != "failed") {
    stop("Status should be 'failed'")
  }
  if (length(result$errors) != 1) {
    stop("Should have 1 error")
  }
  if (!("error_categories" %in% names(result))) {
    stop("Should have error_categories")
  }
})

# Test 2.2: Error categorization
run_test("Error categorization heuristics", {
  category <- categorize_error("File not found: /path/to/file.csv")
  
  if (category != "FILE_NOT_FOUND") {
    stop(sprintf("Should categorize as FILE_NOT_FOUND, got %s", category))
  }
})

# Test 2.3: Error categories enumeration
run_test("Error categories available", {
  categories <- ERROR_CATEGORIES
  
  if (length(categories) < 10) {
    stop("Should have multiple error categories")
  }
  if (!("FILE_NOT_FOUND" %in% names(categories))) {
    stop("Should include FILE_NOT_FOUND category")
  }
})

# Test 2.4: Safe module call with success
run_test("Safe module call succeeds", {
  test_module <- function(x) {
    x + 1
  }
  
  result <- safe_module_call(
    test_module,
    args = list(x = 5),
    module_name = "test_module",
    operation = "addition",
    log_output = FALSE
  )
  
  if (!inherits(result, "module_result")) {
    stop("Should return module_result")
  }
  if (result$data != 6) {
    stop("Should have correct result data")
  }
})

# Test 2.5: Safe module call with error
run_test("Safe module call catches errors", {
  test_module <- function(x) {
    stop("Intentional error")
  }
  
  result <- safe_module_call(
    test_module,
    args = list(x = 5),
    module_name = "test_module",
    operation = "error_test",
    log_output = FALSE
  )
  
  if (result$status != "failed") {
    stop("Status should be 'failed'")
  }
  if (length(result$errors) == 0) {
    stop("Should capture error")
  }
})

# Test 2.6: Has errors check
run_test("has_errors() function works", {
  result <- create_module_result(
    operation = "test",
    module_name = "test"
  )
  
  if (has_errors(result)) {
    stop("Empty result should not have errors")
  }
  
  result <- add_categorized_error(result, "Test error")
  
  if (!has_errors(result)) {
    stop("Result with error should have errors")
  }
})

# Test 2.7: Has warnings check
run_test("has_warnings() function works", {
  result <- create_module_result(
    operation = "test",
    module_name = "test"
  )
  
  if (has_warnings(result)) {
    stop("Empty result should not have warnings")
  }
  
  result$warnings <- c("Test warning")
  
  if (!has_warnings(result)) {
    stop("Result with warning should have warnings")
  }
})

# Test 2.8: Error report generation
run_test("Generate error report from results", {
  result1 <- create_module_result("op1", "mod1")
  result1 <- add_categorized_error(result1, "Error 1")
  
  result2 <- create_module_result("op2", "mod2")
  result2 <- add_categorized_error(result2, "Error 2")
  
  report <- generate_error_report(list(result1, result2))
  
  if (report$total_errors != 2) {
    stop("Should report 2 errors")
  }
  if (length(report$modules_with_errors) != 2) {
    stop("Should list both modules")
  }
})

# Test 2.9: Get error category
run_test("Retrieve error category", {
  result <- create_module_result("op", "mod")
  result <- add_categorized_error(result, "Test", category = "FILE_NOT_FOUND")
  
  category <- get_error_category(result, 1)
  
  if (category != "FILE_NOT_FOUND") {
    stop("Should retrieve correct category")
  }
})

# Test 2.10: List error categories
run_test("List all error categories", {
  categories <- list_error_categories()
  
  if (!is.data.frame(categories)) {
    stop("Should return data frame")
  }
  if (nrow(categories) < 10) {
    stop("Should list multiple categories")
  }
})

# ==============================================================================
# SECTION 3: INTEGRATION TESTS
# ==============================================================================

cat("\nTEST SECTION 3: Integration (Data + Error Interfaces)\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 3.1: Validate data and report errors safely
run_test("Validate data with error handling", {
  bad_data <- data.frame(
    mass = c("invalid"),
    year = c(2020L),
    dispersed = c(TRUE),
    origin = c("PopA")
  )
  
  validation <- validate_data_against_schema(bad_data, SCHEMA_COHA_INPUT_DATA)
  
  if (validation$valid) {
    stop("Should detect invalid data")
  }
  if (length(validation$errors) == 0) {
    stop("Should have error messages")
  }
})

# Test 3.2: Safe module call that includes data validation
run_test("Safe module call with validation", {
  
  validation_module <- function(df) {
    validation <- validate_data_against_schema(df, SCHEMA_COHA_INPUT_DATA)
    
    if (!validation$valid) {
      stop(validation$errors[1])
    }
    
    list(rows = nrow(df), cols = ncol(df))
  }
  
  good_data <- data.frame(
    mass = c(150, 175),
    year = c(2020L, 2021L),
    dispersed = c(TRUE, FALSE),
    origin = c("PopA", "PopB")
  )
  
  result <- safe_module_call(
    validation_module,
    args = list(df = good_data),
    module_name = "validator",
    operation = "validate_data",
    log_output = FALSE
  )
  
  if (result$status != "success") {
    stop(sprintf("Should succeed, got status: %s", result$status))
  }
})

# Test 3.3: Format error for display
run_test("Format error for user display", {
  formatted <- format_error_for_display(
    "Data validation failed",
    category = "INVALID_DATA",
    details = list(
      columns = "mass, year",
      rows = "5"
    )
  )
  
  if (!grepl("INVALID_DATA", formatted)) {
    stop("Should include category")
  }
  if (!grepl("columns", formatted)) {
    stop("Should include details")
  }
})

# ==============================================================================
# TEST SUMMARY
# ==============================================================================

cat("\n")
cat("=" %.0f(60), "\n", sep = "")
cat(sprintf("PHASE 1.13 TEST RESULTS\n"))
cat("=" %.0f(60), "\n", sep = "")
cat(sprintf("Total Tests:  %d\n", test_count))
cat(sprintf("Passed:       %d ✓\n", passed_count))
cat(sprintf("Failed:       %d ✗\n", failed_count))
cat(sprintf("Success Rate: %.1f%%\n", 100 * passed_count / test_count))
cat("=" %.0f(60), "\n", sep = "")

if (failed_count == 0) {
  cat("\n✓ ALL TESTS PASSED - Phase 1.13 integration complete\n\n")
} else {
  cat(sprintf("\n✗ %d test(s) failed - review above\n\n", failed_count))
  stop(sprintf("%d test(s) failed", failed_count))
}

# Return test results
invisible(list(
  total = test_count,
  passed = passed_count,
  failed = failed_count,
  success_rate = passed_count / test_count
))
