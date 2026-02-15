#!/usr/bin/env Rscript
library(here)

source(here::here("R", "pipeline", "pipeline.R"))

cat("\n\nRunning pipeline with verbose=TRUE\n\n")
result <- run_pipeline(verbose = TRUE)

cat("\n\nPipeline result:\n")
str(result, max.level = 1)
