#!/usr/bin/env Rscript
library(here)

cat("Before sourcing pipeline.R\n")
cat("load_coha_data exists:", exists("load_coha_data"), "\n")

source(here::here("R", "pipeline", "pipeline.R"))

cat("\nAfter sourcing pipeline.R\n")
cat("load_coha_data exists:", exists("load_coha_data"), "\n")
cat("run_pipeline exists:", exists("run_pipeline"), "\n")

if (exists("load_coha_data")) {
  cat("  ✓ load_coha_data is available\n")
} else {
  cat("  ✗ load_coha_data is NOT available\n")
}

cat("\nFunctions in global environment:\n")
funs <- ls(pattern = "^load|^run|^validate")
cat(sprintf("Found %d matching functions:\n", length(funs)))
for (f in funs) {
  cat("  -", f, "\n")
}
