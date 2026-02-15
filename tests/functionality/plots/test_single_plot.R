#!/usr/bin/env Rscript
library(here)

# Load just the ridgeline module directly
source(here::here("R", "plot_modules", "ridgeline", "module.R"))

# Load data
source(here::here("R", "domain_modules", "coha_dispersal", "data_loader.R"))
df <- load_coha_data(verbose = FALSE)

cat("Data loaded:", nrow(df), "rows\n\n")

# Test get_available_plots
cat("Available plots:\n")
available <- get_available_plots()
print(available[1:3, ])

# Try generating one plot
cat("\n\nTrying to generate plot: compact_01\n")
tryCatch({
  result <- generate_plot(df, "compact_01", config = list(
    output_dir = here::here("test_plots"),
    dpi = 150,
    verbose = TRUE
  ))
  cat("\n\nResult:\n")
  str(result, max.level = 2)
}, error = function(e) {
  cat("\n!!! ERROR:\n")
  print(e)
  cat("\nFull traceback:\n")
  traceback()
})
