# ==============================================================================
# tests/test_phase3_robustness.R
# ==============================================================================
# PURPOSE: Unit tests for Phase 3A robustness infrastructure
# DEPENDS: R/functions/robustness.R, R/functions/logging.R
# ==============================================================================

cat("\n[TEST] Phase 3A: Robustness Infrastructure\n")
cat("=" * 60, "\n")

# Source required modules
source(here::here("R", "functions", "robustness.R"))
source(here::here("R", "functions", "logging.R"))
source(here::here("core", "assertions.R"))

test_count <- 0
passed_count <- 0

# =============================================================================
# Test 1: Result Object Creation
# =============================================================================
test_create_result <- function() {
  cat("\n  Test 1: Result object creation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- create_result("test_operation", verbose = FALSE)
      
      # Verify structure
      stopifnot(
        is.list(result),
        !is.null(result$status),
        result$status == "unknown",
        !is.null(result$timestamp),
        is.list(result$errors),
        length(result$errors) == 0,
        is.list(result$warnings),
        length(result$warnings) == 0,
        result$operation == "test_operation",
        is.numeric(result$duration_secs),
        result$duration_secs == 0
      )
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 2: Status Transitions
# =============================================================================
test_status_transitions <- function() {
  cat("\n  Test 2: Status transitions... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Transition: unknown → success
      result <- create_result("test", verbose = FALSE)
      result <- set_result_status(result, "success", "Test passed", FALSE)
      stopifnot(result$status == "success", 
                result$message == "Test passed")
      
      # Transition: success → partial (via warning)
      result <- create_result("test", verbose = FALSE)
      result <- set_result_status(result, "success", "OK", FALSE)
      result <- add_warning(result, "Some issues", FALSE)
      stopifnot(result$status == "partial")
      
      # Transition: unknown → failed (via error)
      result <- create_result("test", verbose = FALSE)
      result <- add_error(result, "Test error", FALSE)
      stopifnot(result$status == "failed")
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 3: Quality Score Computation
# =============================================================================
test_quality_score_computation <- function() {
  cat("\n  Test 3: Quality score with weights... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      result <- create_result("test", verbose = FALSE)
      
      # Add quality metrics: 0.3*85 + 0.5*90 + 0.2*75 = 25.5 + 45 + 15 = 85.5
      result <- add_quality_metrics(result,
        list(c1 = 85, c2 = 90, c3 = 75),
        list(w1 = 0.3, w2 = 0.5, w3 = 0.2)
      )
      
      stopifnot(
        !is.na(result$quality_score),
        abs(result$quality_score - 85.5) < 0.1
      )
      
      # Boundary: all 100
      result <- create_result("test", verbose = FALSE)
      result <- add_quality_metrics(result,
        list(c1 = 100, c2 = 100),
        list(w1 = 0.5, w2 = 0.5)
      )
      stopifnot(result$quality_score == 100)
      
      # Boundary: all 0
      result <- create_result("test", verbose = FALSE)
      result <- add_quality_metrics(result,
        list(c1 = 0, c2 = 0),
        list(w1 = 0.5, w2 = 0.5)
      )
      stopifnot(result$quality_score == 0)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 4: Error and Warning Lists
# =============================================================================
test_error_warning_lists <- function() {
  cat("\n  Test 4: Error and warning accumulation... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Multiple errors
      result <- create_result("test", verbose = FALSE)
      result <- add_error(result, "Error 1", FALSE)
      result <- add_error(result, "Error 2", FALSE)
      stopifnot(
        length(result$errors) == 2,
        result$status == "failed",
        "Error 1" %in% result$errors,
        "Error 2" %in% result$errors
      )
      
      # Multiple warnings
      result <- create_result("test", verbose = FALSE)
      result <- add_warning(result, "Warning 1", FALSE)
      result <- add_warning(result, "Warning 2", FALSE)
      stopifnot(
        length(result$warnings) == 2,
        result$status == "partial",
        "Warning 1" %in% result$warnings,
        "Warning 2" %in% result$warnings
      )
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 5: Timing Functions
# =============================================================================
test_timing_functions <- function() {
  cat("\n  Test 5: Timer accuracy (100ms tolerance)... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      start <- start_timer()
      Sys.sleep(0.15)  # 150ms delay
      elapsed <- stop_timer(start)
      
      stopifnot(
        !is.na(elapsed),
        is.numeric(elapsed),
        elapsed >= 0.1,
        elapsed < 1.0
      )
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 6: Error Message Formatting
# =============================================================================
test_error_message_formatting <- function() {
  cat("\n  Test 6: Error message formatting... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      msg <- format_error_message(
        "operation_test",
        "Something went wrong",
        "Check parameters"
      )
      
      stopifnot(
        is.character(msg),
        nchar(msg) > 0,
        grepl("operation_test", msg),
        grepl("Something went wrong", msg),
        grepl("Check parameters", msg)
      )
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Test 7: Result Success Predicate
# =============================================================================
test_is_result_success <- function() {
  cat("\n  Test 7: is_result_success predicate... ")
  test_count <<- test_count + 1
  
  tryCatch(
    {
      # Success case
      result <- create_result("test", verbose = FALSE)
      result <- set_result_status(result, "success", "OK", FALSE)
      stopifnot(is_result_success(result) == TRUE)
      
      # Partial case (still ok to proceed)
      result <- set_result_status(result, "partial", "Warning", FALSE)
      stopifnot(is_result_success(result) == TRUE)
      
      # Failed case (cannot proceed)
      result <- set_result_status(result, "failed", "Error", FALSE)
      stopifnot(is_result_success(result) == FALSE)
      
      cat("✓\n")
      passed_count <<- passed_count + 1
    },
    error = function(e) {
      cat(sprintf("✗ %s\n", e$message))
    }
  )
}

# =============================================================================
# Run All Tests
# =============================================================================
test_create_result()
test_status_transitions()
test_quality_score_computation()
test_error_warning_lists()
test_timing_functions()
test_error_message_formatting()
test_is_result_success()

cat(sprintf("\n  Summary: %d/%d passed\n", passed_count, test_count))
cat("=" * 60, "\n\n")

# Return counts for aggregation
invisible(list(passed = passed_count, total = test_count))
