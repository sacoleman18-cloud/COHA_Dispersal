#!/usr/bin/env Rscript
library(here)
setwd(here::here())

source("R/functions/utilities.R")
source("R/functions/console.R")
source("R/functions/assertions.R")
source("R/functions/logging.R")
source("R/functions/robustness.R")
source("R/functions/data_quality.R")
source("R/functions/phase3_data_operations.R")

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
