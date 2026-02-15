source("core/data_quality.R")

# Test 1: COHA defaults
coha_df <- data.frame(
  mass = c(100, 200, NA),
  year = c(2000, 2028, 1990),
  dispersed = c("Y", "N", "Y"),
  stringsAsFactors = FALSE
)

metrics_default <- compute_quality_metrics(coha_df, verbose = FALSE)

stopifnot(is.list(metrics_default))
stopifnot(round(metrics_default$schema_match, 1) == 100.0)
stopifnot(metrics_default$outliers_detected == 1)

# Test 2: Custom columns with explicit types and ranges
custom_df <- data.frame(
  height = c(150, 160, 999),
  weight = c(50, 60, 70),
  stringsAsFactors = FALSE
)

metrics_custom <- compute_quality_metrics(
  custom_df,
  required_columns = c("height", "weight"),
  column_types = list(height = "numeric", weight = "numeric"),
  outlier_ranges = list(height = c(100, 250), weight = c(10, 500)),
  verbose = FALSE
)

stopifnot(round(metrics_custom$schema_match, 1) == 100.0)
stopifnot(metrics_custom$outliers_detected == 1)

message(".test_data_quality.R: all tests passed")
