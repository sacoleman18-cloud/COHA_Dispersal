# ==============================================================================
# tests/test_phase3_domain.R
# ==============================================================================
# PURPOSE
# -------
# Test Phase 3: COHA Domain module organization
# Tests domain config, data loading, validation, and quality assessment
#
# DEPENDS ON
# ----------
# - here (path management)
# - testthat (testing framework) - use stop() for simple assertions
#
# ==============================================================================

library(here)

# Source domain module
source(here::here("R", "domain_modules", "coha_dispersal", "coha_config.R"))
source(here::here("R", "domain_modules", "coha_dispersal", "data_loader.R"))

# ==============================================================================
# TEST 1: Configuration Loading
# ==============================================================================

test_coha_config_loads <- function() {
  cat("\n[TEST 1] COHA Configuration Loading\n")
  cat("  ✓ Config object exists: ")
  
  if (!exists("coha_domain_config")) {
    stop("coha_domain_config not found", call. = FALSE)
  }
  cat("OK\n")
  
  # Check main sections
  expected_sections <- c("domain", "data", "plot_modules", "paths", "reports", "analysis", "publication")
  cat("  ✓ Config sections: ")
  
  for (section in expected_sections) {
    if (!section %in% names(coha_domain_config)) {
      stop(sprintf("Missing section: %s", section), call. = FALSE)
    }
  }
  cat(sprintf("%d sections\n", length(expected_sections)))
  
  # Check domain metadata
  cat("  ✓ Domain metadata: ")
  if (is.null(coha_domain_config$domain$name)) {
    stop("Domain name not set", call. = FALSE)
  }
  cat(sprintf("%s (v%s)\n", coha_domain_config$domain$name, coha_domain_config$domain$version))
  
  invisible(TRUE)
}

# ==============================================================================
# TEST 2: Configuration Utility Functions
# ==============================================================================

test_config_functions <- function() {
  cat("\n[TEST 2] Configuration Utility Functions\n")
  
  # Test get_coha_config()
  cat("  ✓ get_coha_config('domain'): ")
  domain <- get_coha_config("domain")
  if (is.null(domain$name)) stop("Failed to get domain config", call. = FALSE)
  cat(sprintf("%s\n", domain$name))
  
  # Test get_coha_path()
  cat("  ✓ get_coha_path('data_source'): ")
  data_path <- get_coha_path("data_source")
  if (!is.character(data_path) || nchar(data_path) == 0) {
    stop("Invalid data path", call. = FALSE)
  }
  cat(sprintf("%s\n", basename(data_path)))
  
  # Test list_coha_plot_modules()
  cat("  ✓ list_coha_plot_modules(): ")
  modules <- list_coha_plot_modules()
  if (length(modules) == 0) stop("No plot modules found", call. = FALSE)
  cat(sprintf("%d modules\n", length(modules)))
  
  # Test get_coha_column_spec()
  cat("  ✓ get_coha_column_spec('mass'): ")
  spec <- get_coha_column_spec("mass")
  if (is.null(spec$type)) stop("Failed to get column spec", call. = FALSE)
  cat(sprintf("type=%s, units=%s\n", spec$type, spec$units))
  
  invisible(TRUE)
}

# ==============================================================================
# TEST 3: Data Loading
# ==============================================================================

test_data_loading <- function() {
  cat("\n[TEST 3] Data Loading\n")
  
  # Load data
  cat("  ✓ load_coha_data(): ")
  tryCatch({
    data <- load_coha_data(verbose = FALSE)
    if (!is.data.frame(data)) {
      stop("Didn't return a data frame", call. = FALSE)
    }
    cat(sprintf("%d rows, %d cols\n", nrow(data), ncol(data)))
  }, error = function(e) {
    cat(sprintf("FAILED - %s\n", e$message))
    stop(e)
  })
  
  invisible(data)
}

# ==============================================================================
# TEST 4: Schema Validation
# ==============================================================================

test_schema_validation <- function() {
  cat("\n[TEST 4] Schema Validation\n")
  
  # Load data first
  data <- load_coha_data(verbose = FALSE)
  
  # Test validation
  cat("  ✓ validate_coha_schema(): ")
  tryCatch({
    validate_coha_schema(data, verbose = FALSE)
    cat("OK (all checks passed)\n")
  }, error = function(e) {
    cat(sprintf("FAILED - %s\n", e$message))
    stop(e)
  })
  
  # Test with bad data (missing column)
  cat("  ✓ Validation rejects bad data: ")
  bad_data <- data[, !names(data) %in% "mass"]  # Remove mass column
  tryCatch({
    validate_coha_schema(bad_data, verbose = FALSE)
    stop("Should have rejected data without required columns", call. = FALSE)
  }, error = function(e) {
    if (grepl("Missing required columns", e$message)) {
      cat("OK (correctly rejected)\n")
    } else {
      stop(e)
    }
  })
  
  invisible(TRUE)
}

# ==============================================================================
# TEST 5: Quality Assessment
# ==============================================================================

test_quality_assessment <- function() {
  cat("\n[TEST 5] Quality Assessment\n")
  
  data <- load_coha_data(verbose = FALSE)
  
  cat("  ✓ assess_coha_quality(): ")
  quality <- assess_coha_quality(data, verbose = FALSE)
  
  if (!is.list(quality)) {
    stop("assess_coha_quality() should return a list", call. = FALSE)
  }
  
  if (is.null(quality$overall_score)) {
    stop("Quality must include overall_score", call. = FALSE)
  }
  
  if (quality$overall_score < 0 || quality$overall_score > 100) {
    stop(sprintf("Quality score out of range: %.0f", quality$overall_score), call. = FALSE)
  }
  
  cat(sprintf("Score: %.0f/100\n", quality$overall_score))
  
  invisible(quality)
}

# ==============================================================================
# TEST 6: Convenience Wrapper
# ==============================================================================

test_convenience_wrapper <- function() {
  cat("\n[TEST 6] Convenience Wrapper Function\n")
  
  cat("  ✓ load_and_validate_coha_data(): ")
  tryCatch({
    data <- load_and_validate_coha_data(verbose = FALSE)
    if (!is.data.frame(data)) {
      stop("Should return data frame", call. = FALSE)
    }
    cat(sprintf("OK (%d rows)\n", nrow(data)))
  },error = function(e) {
    cat(sprintf("FAILED - %s\n", e$message))
    stop(e)
  })
  
  invisible(data)
}

# ==============================================================================
# MAIN TEST RUNNER
# ==============================================================================

cat("\n")
cat("=" %>% strrep(80) %>% paste0(), "\n")
cat("PHASE 3: COHA DOMAIN MODULE TESTS\n")
cat("=" %>% strrep(80) %>% paste0(), "\n")

all_pass <- TRUE

# Run all tests
tryCatch({
  test_coha_config_loads()
  test_config_functions()
  data <- test_data_loading()
  test_schema_validation()
  quality <- test_quality_assessment()
  test_convenience_wrapper()
  
  cat("\n")
  cat("=" %>% strrep(80) %>% paste0(), "\n")
  cat("✓ ALL TESTS PASSED\n")
  cat("=" %>% strrep(80) %>% paste0(), "\n")
  
}, error = function(e) {
  cat("\n")
  cat("=" %>% strrep(80) %>% paste0(), "\n")
  cat(sprintf("✗ TEST FAILED: %s\n", e$message))
  cat("=" %>% strrep(80) %>% paste0(), "\n")
  all_pass <<- FALSE
})

# Return status
invisible(all_pass)
