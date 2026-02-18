#!/usr/bin/env Rscript
# Run both introductory manuscript plots with an optional snapshot update.

## Determine script directory and set project root (Manuscript/) as working directory
# Prefer RStudio (so reviewers can click "Source"), fall back to Rscript --file, then getwd().
script.dir <- NULL
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  ctx <- tryCatch(rstudioapi::getActiveDocumentContext(), error = function(e) NULL)
  if (!is.null(ctx) && nzchar(ctx$path)) {
    script.dir <- dirname(normalizePath(ctx$path))
  }
}
if (is.null(script.dir)) {
  args <- commandArgs(trailingOnly = FALSE)
  file.arg <- "--file="
  for (i in seq_along(args)) {
    if (startsWith(args[i], file.arg)) {
      script.path <- substring(args[i], nchar(file.arg) + 1)
      script.dir <- dirname(normalizePath(script.path))
      break
    }
  }
}
if (is.null(script.dir)) {
  # Last resort: use current working directory but warn the user.
  script.dir <- getwd()
  message("Note: could not detect runner path. Ensure you run this script from the Manuscript/ directory or open it in RStudio and click Source.")
}
proj.root <- normalizePath(file.path(script.dir, ".."))
manuscript_root <- proj.root

# Use absolute paths to sourced scripts so the runner works regardless of current working directory
setwd(proj.root)

# Optional: update frozen snapshot when UPDATE_SNAPSHOT=1
update_snapshot <- as.logical(as.integer(Sys.getenv("UPDATE_SNAPSHOT", "0")))
if (update_snapshot) {
  message("Updating frozen snapshot via scripts/data_prep.R")
  source(normalizePath(file.path(manuscript_root, "scripts", "data_prep.R")))
}

message("Loading data loader and helpers")
source(normalizePath(file.path(manuscript_root, "scripts", "shared_utils.R")))
source(normalizePath(file.path(manuscript_root, "scripts", "data_loader.R")))

message("Generating ridgeline plot...")
source(normalizePath(file.path(manuscript_root, "scripts", "ridgeline_plot.R")))

message("Generating boxplot...")
source(normalizePath(file.path(manuscript_root, "scripts", "boxplot.R")))

message("All introductory plots complete.")
