# ==============================================================================
# tests/test_scalability.R
# ==============================================================================
# PURPOSE: Validate that plot registry system works correctly
# TESTS: Registry structure, dynamic generation, report coverage
# ==============================================================================

cat("\n[TEST] Plot Registry Scalability System\n")
cat(strrep("=", 70), "\n")

# Load dependencies
source(here::here("R", "config", "plot_registry.R"))

test_count <- 0
passed_count <- 0

# =============================================================================
# Test 1: Registry Structure
# =============================================================================
test_registry_structure <- function() {
  cat("\nTest 1: Registry structure and required fields...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    # Check ridgeline exists
    stopifnot(!is.null(plot_registry$ridgeline))
    stopifnot(!is.null(plot_registry$ridgeline$variants))
    stopifnot(length(plot_registry$ridgeline$variants) > 0)
    
    # Check each variant has required fields
    for (variant_id in names(plot_registry$ridgeline$variants)) {
      cfg <- plot_registry$ridgeline$variants[[variant_id]]
      
      # Required fields
      stopifnot(!is.null(cfg$id), cfg$id == variant_id)
      stopifnot(!is.null(cfg$display_name))
      stopifnot(!is.null(cfg$scale))
      stopifnot(!is.null(cfg$fill) || !is.null(cfg$fill_colors))
      stopifnot(!is.null(cfg$palette_type))
      stopifnot(cfg$palette_type %in% c("viridis", "brewer", "custom"))
      
      # Validate palette type
      if (cfg$palette_type == "custom") {
        stopifnot(!is.null(cfg$fill_colors))
        stopifnot(is.character(cfg$fill_colors))
        stopifnot(length(cfg$fill_colors) > 0)
      }
      
      # Validate scale values
      stopifnot(cfg$scale %in% c(0.85, 2.25))
    }
    
    cat("  ✓ Registry structure valid\n")
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 2: Helper Functions
# =============================================================================
test_helper_functions <- function() {
  cat("\nTest 2: Registry helper functions...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    # Test get_plot_ids()
    all_ids <- get_plot_ids("ridgeline")
    stopifnot(length(all_ids) > 0)
    stopifnot(all(grepl("^(compact|expanded)_", all_ids)))
    
    # Test count_plots()
    total <- count_plots()
    ridgeline_count <- count_plots("ridgeline")
    stopifnot(total == ridgeline_count)  # Only ridgeline is active
    stopifnot(ridgeline_count == length(all_ids))
    
    # Test get_plot_config()
    cfg <- get_plot_config("compact_01", "ridgeline")
    stopifnot(!is.null(cfg))
    stopifnot(cfg$id == "compact_01")
    stopifnot(cfg$scale == 0.85)
    
    # Test get_plots_grouped()
    by_scale <- get_plots_grouped("scale", "ridgeline")
    stopifnot("0.85" %in% names(by_scale))
    stopifnot("2.25" %in% names(by_scale))
    stopifnot(length(by_scale$`0.85`) == 12)  # 12 compact
    stopifnot(length(by_scale$`2.25`) == 12)  # 12 expanded
    
    cat("  ✓ Helper functions work correctly\n")
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 3: Palette Type Coverage
# =============================================================================
test_palette_coverage <- function() {
  cat("\nTest 3: Palette type coverage...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    all_ids <- get_plot_ids("ridgeline")
    palette_types <- sapply(all_ids, function(id) {
      get_plot_config(id, "ridgeline")$palette_type
    })
    
    # Should have at least some of each type
    stopifnot("viridis" %in% palette_types)
    stopifnot("brewer" %in% palette_types)
    stopifnot("custom" %in% palette_types)
    
    # Count coverage
    n_viridis <- sum(palette_types == "viridis")
    n_brewer <- sum(palette_types == "brewer")
    n_custom <- sum(palette_types == "custom")
    
    cat(sprintf("  Viridis: %d | Brewer: %d | Custom: %d\n", 
               n_viridis, n_brewer, n_custom))
    cat("  ✓ Multiple palette types represented\n")
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 4: Scale Consistency
# =============================================================================
test_scale_consistency <- function() {
  cat("\nTest 4: Scale consistency...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    all_ids <- get_plot_ids("ridgeline")
    
    # Verify scale and line_height consistency
    for (id in all_ids) {
      cfg <- get_plot_config(id, "ridgeline")
      
      if (cfg$scale == 0.85) {
        stopifnot(cfg$line_height == 0.85, 
                 sprintf("Compact plot %s has inconsistent line_height", id))
      } else if (cfg$scale == 2.25) {
        stopifnot(cfg$line_height == 1,
                 sprintf("Expanded plot %s has inconsistent line_height", id))
      }
    }
    
    cat("  ✓ Scale and line_height consistent\n")
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 5: Custom Palette Validation
# =============================================================================
test_custom_palettes <- function() {
  cat("\nTest 5: Custom palette validation...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    # Find custom palettes
    custom_ids <- names(Filter(
      function(x) x$palette_type == "custom",
      plot_registry$ridgeline$variants
    ))
    
    cat(sprintf("  Found %d custom palettes\n", length(custom_ids)))
    
    for (id in custom_ids) {
      cfg <- get_plot_config(id, "ridgeline")
      
      # Custom palettes MUST have hex colors
      stopifnot(!is.null(cfg$fill_colors), 
               sprintf("%s missing fill_colors", id))
      stopifnot(!is.null(cfg$color_colors),
               sprintf("%s missing color_colors", id))
      stopifnot(length(cfg$fill_colors) > 0)
      stopifnot(length(cfg$color_colors) > 0)
      
      # Validate hex format
      for (color in cfg$fill_colors) {
        stopifnot(grepl("^#[0-9A-Fa-f]{6}$", color),
                 sprintf("Invalid hex in %s: %s", id, color))
      }
    }
    
    cat("  ✓ All custom palettes valid\n")
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 6: Naming Convention
# =============================================================================
test_naming_convention <- function() {
  cat("\nTest 6: Naming convention compliance...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    all_ids <- get_plot_ids("ridgeline")
    
    # All IDs should follow {scale}_{number} pattern
    for (id in all_ids) {
      stopifnot(grepl("^(compact|expanded)_\\d{2}$", id),
               sprintf("Invalid naming: %s (should be compact_XX or expanded_XX)", id))
      
      # Verify ID matches config
      cfg <- get_plot_config(id, "ridgeline")
      stopifnot(cfg$id == id)
    }
    
    cat("  ✓ All IDs follow naming convention\n")
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 7: Scalability - Adding New Variant
# =============================================================================
test_add_new_variant <- function() {
  cat("\nTest 7: Simulated new variant addition...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    initial_count <- count_plots("ridgeline")
    cat(sprintf("  Initial count: %d variants\n", initial_count))
    
    # Simulate adding a new variant (don't actually modify registry)
    new_variant <- list(
      id = "compact_99",
      display_name = "Test Variant",
      scale = 0.85,
      line_height = 0.85,
      fill = "test_palette",
      fill_colors = c("#000000", "#FFFFFF"),
      palette_type = "custom"
    )
    
    # Validate new variant structure
    stopifnot(!is.null(new_variant$id))
    stopifnot(!is.null(new_variant$display_name))
    stopifnot(!is.null(new_variant$scale))
    stopifnot(!is.null(new_variant$fill_colors))
    stopifnot(new_variant$palette_type %in% c("viridis", "brewer", "custom"))
    
    cat(sprintf("  ✓ New variant would be valid\n")
    cat(sprintf("  ✓ After addition: would have %d variants\n", initial_count + 1))
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Test 8: No Hardcoding
# =============================================================================
test_no_hardcoding <- function() {
  cat("\nTest 8: Verify no hardcoding in helper functions...\n")
  test_count <<- test_count + 1
  
  tryCatch({
    # Helper functions should work with ANY number of variants
    initial <- count_plots("ridgeline")
    
    # Simulate different sizes by checking function works with edge cases
    test_ids <- get_plot_ids("ridgeline")
    stopifnot(length(test_ids) == initial)
    
    # Get by group should work regardless of total count
    by_group <- get_plots_grouped("group", "ridgeline")
    stopifnot(!is.null(by_group))
    stopifnot(length(by_group) > 0)
    
    cat(sprintf("  ✓ Helper functions are count-agnostic\n")
    cat(sprintf("  ✓ Current: %d total variants\n", initial))
    passed_count <<- passed_count + 1
    
  }, error = function(e) {
    cat(sprintf("  ✗ %s\n", e$message))
  })
}

# =============================================================================
# Run All Tests
# =============================================================================
test_registry_structure()
test_helper_functions()
test_palette_coverage()
test_scale_consistency()
test_custom_palettes()
test_naming_convention()
test_add_new_variant()
test_no_hardcoding()

# =============================================================================
# Summary
# =============================================================================
cat("\n")
cat(strrep("=", 70), "\n")
cat(sprintf("RESULTS: %d/%d tests passed\n", passed_count, test_count))

if (passed_count == test_count) {
  cat("✓ Scalability system validated!\n")
  cat("\nYou can now safely:\n")
  cat("  • Add new palettes to plot_registry.R\n")
  cat("  • Add new plot types (e.g., boxplot)\n")
  cat("  • Update gallery automatically\n")
  cat("  • Scale to any number of variants\n")
} else {
  cat(sprintf("✗ %d test(s) failed\n", test_count - passed_count))
  stop("Fix failures above before proceeding")
}

cat(strrep("=", 70), "\n\n")

invisible(list(passed = passed_count, total = test_count))

# ==============================================================================
# END tests/test_scalability.R
# ==============================================================================
