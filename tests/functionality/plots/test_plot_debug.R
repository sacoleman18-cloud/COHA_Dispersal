#!/usr/bin/env Rscript
library(here)

source(here::here("R", "pipeline", "pipeline.R"))

cat("\n\n=== Testing plot generation directly ===\n\n")

# Load and validate data
df <- load_coha_data(verbose = TRUE)
cat("\n\nData loaded:", nrow(df), "rows\n")

# Now try to load and run the ridgeline module 
cat("\n\nLoading ridgeline module...\n")
ridge_result <- load_module("ridgeline", module_type = "plot", verbose = TRUE)

if (ridge_result$status == "success") {
  cat("\n\nGetting available plots...\n")
  tryCatch({
    available <- ridge_result$env$get_available_plots()
    cat("Available plots:\n")
    str(available)
    
    cat("\n\nCalling generate_plots_batch...\n")
    result <- ridge_result$env$generate_plots_batch(
      data = df,
      plot_ids = available$plot_id[1:2],  # Just try first 2
      config = list(
        output_dir = here::here("test_plots"),
        dpi = 150,
        verbose = TRUE
      )
    )
    cat("\n\nResult:\n")
    str(result, max.level = 2)
  }, error = function(e) {
    cat("\n!!! ERROR:\n")
    print(e)
    cat("\nTraceback:\n")
    traceback()
  })
} else {
  cat("Failed to load module:", ridge_result$message, "\n")
}
