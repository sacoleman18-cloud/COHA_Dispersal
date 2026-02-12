#!/usr/bin/env Rscript
library(here)
setwd(here::here())

# Load core utilities (updated paths)
source("core/utilities.R")
source("core/console.R")
source("core/assertions.R")
source("core/logging.R")

# Load domain-specific functions
source("core/robustness.R")
source("core/data_quality.R")
source("R/functions/data_operations.R")

cat("\nTesting load_and_validate_data...\n\n")

result <- load_and_validate_data(
  file_path = "data/data.csv",
  required_columns = c("mass", "year", "dispersed", "origin"),
  min_rows = 10,
  verbose = TRUE
)

cat("\n\n=== RESULT ===\n")
cat("Status:", result$status, "\n")
cat("Quality Score:", result$quality_score, "\n")
cat("Rows:", result$rows, "\n")
cat("Columns:", result$columns, "\n")
cat("Message:", result$message, "\n")

if (length(result$errors) > 0) {
  cat("Errors:\n")
  for (err in result$errors) cat("  -", err, "\n")
}

if (length(result$warnings) > 0) {
  cat("Warnings:\n")
  for (warn in result$warnings) cat("  -", warn, "\n")
}

cat("\nData head:\n")
print(head(result$data))
