## Data loader for Manuscript plots
load_coha_data <- function(
  data_dir = "data",
  use_frozen = as.logical(as.integer(Sys.getenv("USE_FROZEN", "1"))),
  save_snapshot = FALSE
) {
  data_path <- file.path(data_dir, "data.csv")
  data_frozen_path <- file.path(data_dir, "data_frozen.rds")

  if (use_frozen && file.exists(data_frozen_path)) {
    coha_df <- readRDS(data_frozen_path)
    data_source <- data_frozen_path
  } else {
    if (!file.exists(data_path)) stop(sprintf("Missing CSV data at %s", data_path))
    coha_df <- read.csv(data_path, stringsAsFactors = FALSE)
    data_source <- data_path
    if (save_snapshot) {
      saveRDS(coha_df, data_frozen_path)
    }
  }

  # Basic validation and period assignment
  # Require the canonical `dispersed` column in the Manuscript bundle.
  required_cols <- c("mass", "year", "dispersed")
  missing_cols <- setdiff(required_cols, names(coha_df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
  }

  # Normalize the canonical `dispersed` column (trim + character)
  coha_df$dispersed <- as.character(coha_df$dispersed)
  coha_df$dispersed <- trimws(coha_df$dispersed)

  coha_df <- assign_periods(coha_df, year_col = "year")

  list(data = coha_df, data_path = data_path, data_frozen_path = data_frozen_path, data_source = data_source)
}
