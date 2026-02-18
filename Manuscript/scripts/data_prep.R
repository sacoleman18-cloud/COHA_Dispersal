## Data preparation: explicit snapshot creation
suppressPackageStartupMessages({
  library(dplyr)
})

res <- load_coha_data(use_frozen = FALSE, save_snapshot = TRUE)
message(sprintf("Wrote snapshot to: %s", res$data_frozen_path))
