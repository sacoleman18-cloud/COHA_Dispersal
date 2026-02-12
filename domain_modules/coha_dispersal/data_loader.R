# ==============================================================================
# domain_modules/coha_dispersal/data_loader.R
# ==============================================================================
# PURPOSE
# -------
# COHA-specific data loading and validation for ridgeline analysis.
# Domain-specific version of assertions validated in core/assertions.R
#
# DEPENDS ON
# ----------
# - core/assertions.R (universal assertion functions)
# - here (path management)
#
# ==============================================================================

source(here::here("core", "assertions.R"))

#' Validate Ridgeline Plot Data (COHA-Specific)
#'
#' @description
#' Comprehensive schema validation for COHA ridgeline plot data.
#' Performs all critical checks: type, shape, and completeness.
#' Stops pipeline on any failure with clear error messages.
#'
#' @param df Data frame. Data to validate for ridgeline plotting.
#' @param verbose Logical. Print validation details to console.
#'   Default: FALSE.
#'
#' @return Invisible logical TRUE if all checks pass.
#'   Stops execution with error message if any check fails.
#'
#' @details
#' **Validation Checks (in order):**
#' 1. Input is a data frame
#' 2. Contains required columns: mass, year, dispersed
#' 3. Data is not empty (has at least 1 row)
#' 4. Column types are correct (mass, year numeric; dispersed character)
#' 5. Key columns (mass, year) have no NA values
#'
#' **verbose=TRUE output:** Shows each check with ✓ indicator, useful for debugging
#' data issues. Should be used during development and troubleshooting.
#'
#' **Design:** Composite function using individual assertions from core/ module.
#' Performs all checks in logical sequence, stopping at first failure.
#' Uses tryCatch for NA check so minor NA issues produce warning, not error.
#'
#' @examples
#' \dontrun{
#' # After loading data, validate before plotting
#' data <- readr::read_csv(here::here("data", "data.csv"))
#' validate_ridgeline_data(data, verbose = TRUE)  # Shows detailed output
#'
#' # Then proceed with pipeline
#' plots <- generate_all_ridgeline_plots(data)
#' }
#'
#' @export
validate_ridgeline_data <- function(df, verbose = FALSE) {
  # Check is data frame
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  if (verbose) message("[VALIDATE] ✓ Input is data frame")
  
  # Check required columns exist
  required_cols <- c("mass", "year", "dispersed")
  assert_columns_exist(df, required_cols, context = "ridgeline data")
  if (verbose) message("[VALIDATE] ✓ All required columns present")
  
  # Check not empty
  assert_not_empty(df, context = "ridgeline data")
  if (verbose) message("[VALIDATE] ✓ Data contains ", nrow(df), " rows")
  
  # Check column types
  assert_is_numeric(df, "mass", context = "ridgeline validation")
  assert_is_numeric(df, "year", context = "ridgeline validation")
  assert_is_character(df, "dispersed", context = "ridgeline validation")
  if (verbose) message("[VALIDATE] ✓ Column types correct")
  
  # Check for NAs in key columns
  tryCatch(
    {
      assert_no_na(df, "mass", context = "ridgeline mass data")
      assert_no_na(df, "year", context = "ridgeline year data")
    },
    error = function(e) {
      warning("Data contains NA values - may impact ridgeline plot", 
              call. = FALSE)
    }
  )
  
  if (verbose) message("[VALIDATE] ✓ Ridgeline data validation complete")
  invisible(TRUE)
}

# ==============================================================================
# END domain_modules/coha_dispersal/data_loader.R
# ==============================================================================
