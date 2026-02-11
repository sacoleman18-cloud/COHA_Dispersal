library(readr)
library(here)

cat("Reading CSV file...\n")
df <- read_csv(here::here('data', 'data.csv'), show_col_types = FALSE)

cat("✓ CSV read successfully\n")
cat("Columns:", paste(names(df), collapse = ', '), "\n")
cat("Rows:", nrow(df), "\n")
cat("Data types:\n")
print(str(df))
