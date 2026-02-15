#!/usr/bin/env Rscript
# ==============================================================================
# test_28_plots_integration.R
# ==============================================================================
# Test that the refactored ridgeline module can generate all 28 plots
# ==============================================================================

library(here)

# Load test data
message("[TEST] Loading data...")
data <- read.csv(here::here("data", "data.csv"))
message(sprintf("[TEST] Data loaded: %d rows", nrow(data)))

# Source the refactored ridgeline module directly
message("[TEST] Source ridgeline module...")
source(here::here("R", "plot_modules", "ridgeline", "module.R"))

# Get module metadata
message("[TEST] Getting module metadata...")
metadata <- get_module_metadata()
cat("Module: ", metadata$name, "\n")
cat("Version: ", metadata$version, "\n")
cat("Plots available: ", metadata$plots_available, "\n")

# Get available plots
message("[TEST] Getting available plots...")
available <- get_available_plots()
cat(sprintf("Found: %d plots\n", nrow(available)))
print(head(available, 5))

# Test parsing each plot ID
message("[TEST] Testing plot ID parsing...")
parse_results <- list()
for (plot_id in available$plot_id) {
  config <- .parse_plot_id(plot_id)
  parse_results[[plot_id]] <- list(
    found = !is.null(config),
    scale = if (!is.null(config)) config$scale else NA,
    palette = if (!is.null(config)) config$palette else NA
  )
}

# Show results
success_count <- sum(sapply(parse_results, function(x) x$found))
cat(sprintf("Plot ID parsing: %d successful, %d failed\n", 
            success_count, length(parse_results) - success_count))

if (success_count < length(parse_results)) {
  cat("Failed plots:\n")
  for (plot_id in names(parse_results)) {
    if (!parse_results[[plot_id]]$found) {
      cat("  -", plot_id, "\n")
    }
  }
}

# Test generating a few plots
message("[TEST] Testing plot generation...")
test_plots <- c("compact_01", "compact_07", "compact_14", 
                "expanded_01", "expanded_07", "expanded_14")

generate_results <- list()
for (plot_id in test_plots) {
  cat("\n--- Generating:", plot_id, "---\n")
  result <- generate_plot(
    data = data,
    plot_id = plot_id,
    config = list(
      output_dir = here::here("results", "plots"),
      save_file = TRUE,
      verbose = TRUE
    )
  )
  
  generate_results[[plot_id]] <- list(
    status = result$status,
    message = result$message,
    errors = result$errors,
    plot_generated = !is.null(result$plot)
  )
  
  cat(sprintf("Result: status=%s, plot=%s\n", 
              result$status, 
              if (!is.null(result$plot)) "YES" else "NO"))
}

# Summary
message("\n[TEST] SUMMARY")
cat("================================================\n")
parse_success <- sum(sapply(parse_results, function(x) x$found))
cat(sprintf("Plot ID parsing: %d/%d successful\n", 
            parse_success, length(parse_results)))

gen_success <- sum(sapply(generate_results, function(x) x$status %in% c("success", "partial")))
cat(sprintf("Test plots generated: %d/%d successful\n", 
            gen_success, length(generate_results)))

cat("\nDetailed results:\n")
for (plot_id in names(generate_results)) {
  r <- generate_results[[plot_id]]
  cat(sprintf("  %s: %s\n", plot_id, r$status))
  if (length(r$errors) > 0) {
    cat(sprintf("    Errors: %s\n", paste(r$errors, collapse="; ")))
  }
}

cat("================================================\n")
message("[TEST] COMPLETE")

# Final success indicator
if (parse_success == length(parse_results) && gen_success == length(generate_results)) {
  message("[SUCCESS] All tests passed!")
  quit(status = 0)
} else {
  message("[FAILURE] Some tests failed")
  quit(status = 1)
}
