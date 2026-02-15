# ============================================================================
# DATA TYPE INTERFACE - Connector #3
# ============================================================================
# Purpose: Data contracts & validation
# 
# Enables modules to declare expected data structures (schemas) and validate
# inputs against those contracts. Prevents boundary bugs from implicit
# assumptions about column names and types.
#
# Part of the LEGO-like modular architecture system.
# ============================================================================

# ============================================================================
# SECTION 1: Standard Data Schemas
# ============================================================================

# COHA Input Data Schema
# Raw dispersal data with required columns
SCHEMA_COHA_INPUT_DATA <- list(
  schema_id = "coha_input_data",
  schema_version = "1.0.0",
  description = "COHA dispersal analysis raw input data",
  
  # Data frame structure requirement
  is_dataframe = TRUE,
  
  # Required columns with types and constraints
  columns = list(
    mass = list(
      type = "numeric",
      required = TRUE,
      description = "Body mass in grams",
      constraints = list(min = 0, max = 10000)
    ),
    year = list(
      type = "integer",
      required = TRUE,
      description = "Year of observation",
      constraints = list(min = 1900, max = 2050)
    ),
    dispersed = list(
      type = "logical",
      required = TRUE,
      description = "Whether individual dispersed"
    ),
    origin = list(
      type = "character",
      required = TRUE,
      description = "Origin location identifier"
    )
  ),
  
  # Dataset constraints
  min_rows = 10,
  max_rows = 1000000,
  
  # Metadata
  tags = c("coha", "dispersal", "input", "raw"),
  compatible_modules = c("plot_operations", "quality_metrics", "analysis_module"),
  
  # Schema compatibility
  previous_versions = c()
)

# COHA Processed Data Schema
# Cleaned/filtered data after quality control
SCHEMA_COHA_PROCESSED_DATA <- list(
  schema_id = "coha_processed_data",
  schema_version = "1.0.0",
  description = "COHA data after quality filtering and outlier removal",
  
  is_dataframe = TRUE,
  
  columns = list(
    mass = list(
      type = "numeric",
      required = TRUE,
      description = "Body mass in grams (after filtering)",
      constraints = list(min = 5, max = 5000)
    ),
    year = list(
      type = "integer",
      required = TRUE,
      description = "Year of observation",
      constraints = list(min = 1900, max = 2050)
    ),
    dispersed = list(
      type = "logical",
      required = TRUE,
      description = "Dispersal outcome"
    ),
    origin = list(
      type = "character",
      required = TRUE,
      description = "Origin location"
    ),
    quality_flag = list(
      type = "logical",
      required = FALSE,
      description = "TRUE if passed quality checks"
    )
  ),
  
  min_rows = 5,
  max_rows = 1000000,
  
  tags = c("coha", "dispersal", "processed", "quality_filtered"),
  compatible_modules = c("plot_operations", "statistical_analysis"),
  
  # This schema evolved from
  previous_versions = c("coha_input_data")
)

# COHA Plot Summary Schema
# Summary statistics for plot generation
SCHEMA_COHA_PLOT_SUMMARY <- list(
  schema_id = "coha_plot_summary",
  schema_version = "1.0.0",
  description = "Summary statistics for COHA dispersal plots",
  
  is_dataframe = TRUE,
  
  columns = list(
    origin = list(
      type = "character",
      required = TRUE,
      description = "Origin location"
    ),
    n_total = list(
      type = "integer",
      required = TRUE,
      description = "Total individuals from origin",
      constraints = list(min = 1)
    ),
    n_dispersed = list(
      type = "integer",
      required = TRUE,
      description = "Individuals that dispersed",
      constraints = list(min = 0)
    ),
    dispersal_rate = list(
      type = "numeric",
      required = TRUE,
      description = "Proportion dispersed (0-1)",
      constraints = list(min = 0, max = 1)
    ),
    mean_mass = list(
      type = "numeric",
      required = TRUE,
      description = "Mean body mass from origin",
      constraints = list(min = 0)
    ),
    sd_mass = list(
      type = "numeric",
      required = TRUE,
      description = "Standard deviation of mass",
      constraints = list(min = 0)
    )
  ),
  
  min_rows = 2,
  max_rows = 1000,
  
  tags = c("coha", "summary", "plot_ready"),
  compatible_modules = c("plot_operations")
)

# ============================================================================
# SECTION 2: Core Validation Functions
# ============================================================================

#' Validate Data Frame Against Schema
#'
#' Checks that a data frame matches a schema specification including:
#' - Has all required columns
#' - Column types match specification
#' - Values respect constraints (min/max)
#' - Row count within bounds
#'
#' @param df Data frame to validate
#' @param schema Schema to validate against (from SCHEMA_* list)
#' @param strict If TRUE, extra columns cause validation failure
#'
#' @return List with:
#'   - valid (logical): Whether data matches schema
#'   - errors (character): Error messages
#'   - warnings (character): Warning messages
#'   - missing_columns (character): Required columns not found
#'   - type_mismatches (list): Column type mismatches
#'   - constraint_violations (list): Constraint violations
validate_data_against_schema <- function(df, schema, strict = FALSE) {
  
  result <- list(
    valid = TRUE,
    errors = character(),
    warnings = character(),
    missing_columns = character(),
    type_mismatches = list(),
    constraint_violations = list(),
    schema_id = schema$schema_id
  )
  
  # Check if input is data frame
  if (!is.data.frame(df)) {
    result$valid <- FALSE
    result$errors <- c(result$errors, "Input is not a data.frame")
    return(result)
  }
  
  # ===== CHECK FOR REQUIRED COLUMNS =====
  for (col_name in names(schema$columns)) {
    col_spec <- schema$columns[[col_name]]
    
    if (isTRUE(col_spec$required) && !(col_name %in% names(df))) {
      result$valid <- FALSE
      result$missing_columns <- c(result$missing_columns, col_name)
      result$errors <- c(
        result$errors,
        sprintf("Required column missing: '%s' (type: %s)", col_name, col_spec$type)
      )
    }
  }
  
  # ===== CHECK COLUMN TYPES =====
  for (col_name in names(schema$columns)) {
    if (!(col_name %in% names(df))) next  # Already reported as missing
    
    col_spec <- schema$columns[[col_name]]
    actual_type <- class(df[[col_name]])[1]
    expected_type <- col_spec$type
    
    # Type checking (with some flexibility for numeric vs integer)
    type_ok <- (actual_type == expected_type)
    
    if (!type_ok && expected_type == "numeric" && actual_type == "integer") {
      type_ok <- TRUE  # integer is acceptable for numeric
    }
    
    if (!type_ok) {
      result$valid <- FALSE
      result$type_mismatches[[col_name]] <- list(
        expected = expected_type,
        actual = actual_type
      )
      result$errors <- c(
        result$errors,
        sprintf("Column '%s': expected type %s, got %s",
                col_name, expected_type, actual_type)
      )
    }
  }
  
  # ===== CHECK CONSTRAINTS =====
  for (col_name in names(schema$columns)) {
    if (!(col_name %in% names(df))) next  # Skip missing columns
    
    col_spec <- schema$columns[[col_name]]
    col_data <- df[[col_name]]
    
    if (!is.null(col_spec$constraints)) {
      constraints <- col_spec$constraints
      
      # Check minimum value
      if (!is.null(constraints$min)) {
        violations <- which(col_data < constraints$min & !is.na(col_data))
        
        if (length(violations) > 0) {
          result$warnings <- c(
            result$warnings,
            sprintf("Column '%s': %d value(s) below minimum %.2f",
                    col_name, length(violations), constraints$min)
          )
          if (length(violations) <= 5) {
            result$constraint_violations[[paste0(col_name, "_min")]] <- violations
          }
        }
      }
      
      # Check maximum value
      if (!is.null(constraints$max)) {
        violations <- which(col_data > constraints$max & !is.na(col_data))
        
        if (length(violations) > 0) {
          result$warnings <- c(
            result$warnings,
            sprintf("Column '%s': %d value(s) above maximum %.2f",
                    col_name, length(violations), constraints$max)
          )
          if (length(violations) <= 5) {
            result$constraint_violations[[paste0(col_name, "_max")]] <- violations
          }
        }
      }
    }
  }
  
  # ===== CHECK ROW COUNT =====
  n_rows <- nrow(df)
  
  if (n_rows < schema$min_rows) {
    result$valid <- FALSE
    result$errors <- c(
      result$errors,
      sprintf("Too few rows: %d (minimum: %d)", n_rows, schema$min_rows)
    )
  }
  
  if (n_rows > schema$max_rows) {
    result$valid <- FALSE
    result$errors <- c(
      result$errors,
      sprintf("Too many rows: %d (maximum: %d)", n_rows, schema$max_rows)
    )
  }
  
  # ===== CHECK FOR EXTRA COLUMNS (strict mode) =====
  if (isTRUE(strict)) {
    expected_cols <- names(schema$columns)
    extra_cols <- setdiff(names(df), expected_cols)
    
    if (length(extra_cols) > 0) {
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        sprintf("Extra columns not in schema (strict mode): %s",
                paste(extra_cols, collapse = ", "))
      )
    }
  }
  
  result
}

#' Generate Human-Readable Schema Documentation
#'
#' Creates formatted documentation describing a schema suitable for
#' displaying to users or including in reports.
#'
#' @param schema Schema object (from SCHEMA_* list)
#'
#' @return Character string with formatted documentation
generate_schema_docs <- function(schema) {
  
  out <- character()
  
  out <- c(out, sprintf("# Data Schema: %s", schema$schema_id))
  out <- c(out, sprintf("Version: %s", schema$schema_version))
  out <- c(out, "")
  out <- c(out, sprintf("**Description:** %s", schema$description))
  out <- c(out, "")
  
  out <- c(out, "## Required Columns")
  out <- c(out, "")
  
  for (col_name in names(schema$columns)) {
    col_spec <- schema$columns[[col_name]]
    
    required_text <- if (isTRUE(col_spec$required)) "**REQUIRED**" else "Optional"
    
    out <- c(out, sprintf("### %s (%s)", col_name, col_spec$type))
    out <- c(out, sprintf("%s | %s", required_text, col_spec$description))
    
    if (!is.null(col_spec$constraints)) {
      constraints <- col_spec$constraints
      constraint_text <- character()
      
      if (!is.null(constraints$min)) {
        constraint_text <- c(constraint_text, sprintf("Min: %.2f", constraints$min))
      }
      if (!is.null(constraints$max)) {
        constraint_text <- c(constraint_text, sprintf("Max: %.2f", constraints$max))
      }
      
      if (length(constraint_text) > 0) {
        out <- c(out, sprintf("*Constraints: %s*", paste(constraint_text, collapse = ", ")))
      }
    }
    
    out <- c(out, "")
  }
  
  out <- c(out, "## Dataset Constraints")
  out <- c(out, sprintf("- Minimum rows: %d", schema$min_rows))
  out <- c(out, sprintf("- Maximum rows: %d", schema$max_rows))
  out <- c(out, "")
  
  out <- c(out, "## Metadata")
  out <- c(out, sprintf("- Tags: %s", paste(schema$tags, collapse = ", ")))
  out <- c(out, sprintf("- Compatible modules: %s", 
                        paste(schema$compatible_modules, collapse = ", ")))
  
  paste(out, collapse = "\n")
}

#' Print Validation Results in Human-Readable Format
#'
#' @param validation List returned by validate_data_against_schema()
#'
#' @return Invisible NULL (prints to console)
print_validation_results <- function(validation) {
  
  status_symbol <- if (validation$valid) "✓" else "✗"
  status_color <- if (validation$valid) "PASS" else "FAIL"
  
  cat(sprintf(
    "%s Schema Validation: %s [%s]\n",
    status_symbol, validation$schema_id, status_color
  ))
  cat(rep("=", nchar(validation$schema_id) + 20), sep = "")
  cat("\n")
  
  if (!validation$valid) {
    cat("\nERRORS:\n")
    for (i in seq_along(validation$errors)) {
      cat(sprintf("  [%d] %s\n", i, validation$errors[[i]]))
    }
  }
  
  if (length(validation$warnings) > 0) {
    cat("\nWARNINGS:\n")
    for (i in seq_along(validation$warnings)) {
      cat(sprintf("  [%d] %s\n", i, validation$warnings[[i]]))
    }
  }
  
  if (length(validation$missing_columns) > 0) {
    cat("\nMISSING COLUMNS:\n")
    cat(sprintf("  %s\n", paste(validation$missing_columns, collapse = ", ")))
  }
  
  if (length(validation$type_mismatches) > 0) {
    cat("\nTYPE MISMATCHES:\n")
    for (col_name in names(validation$type_mismatches)) {
      mismatch <- validation$type_mismatches[[col_name]]
      cat(sprintf("  %s: expected %s, got %s\n",
                  col_name, mismatch$expected, mismatch$actual))
    }
  }
  
  invisible(NULL)
}

# ============================================================================
# SECTION 3: Helper Functions
# ============================================================================

#' Get All Schemas by ID
#'
#' Returns list of all registered schemas in this file
#'
#' @return Named list of schema objects
get_all_schemas <- function() {
  
  list(
    coha_input_data = SCHEMA_COHA_INPUT_DATA,
    coha_processed_data = SCHEMA_COHA_PROCESSED_DATA,
    coha_plot_summary = SCHEMA_COHA_PLOT_SUMMARY
  )
}

#' Get Schema by ID
#'
#' Retrieve a specific schema by its ID
#'
#' @param schema_id String ID of schema (e.g., "coha_input_data")
#'
#' @return Schema object or NULL if not found
get_schema <- function(schema_id) {
  
  schemas <- get_all_schemas()
  schemas[[schema_id]]
}

#' List Available Schemas
#'
#' Display all available schemas and their purposes
#'
#' @return Invisible data frame with schema metadata
list_available_schemas <- function() {
  
  schemas <- get_all_schemas()
  
  schema_list <- data.frame(
    schema_id = names(schemas),
    description = sapply(schemas, \(s) s$description),
    version = sapply(schemas, \(s) s$schema_version),
    min_rows = sapply(schemas, \(s) s$min_rows),
    stringsAsFactors = FALSE
  )
  
  cat("Available Data Schemas:\n")
  print(schema_list, row.names = FALSE)
  cat("\n")
  
  invisible(schema_list)
}

# ============================================================================
# SECTION 4: Module Integration
# ============================================================================

#' Module Function: Get Data Interface for a Module
#'
#' Each module that uses the data interface should define this function
#' to declare what data schemas it requires as input.
#'
#' Example implementation in a module:
#'   module_get_input_schema <- function() SCHEMA_COHA_INPUT_DATA
#'   module_get_output_schema <- function() SCHEMA_COHA_PROCESSED_DATA
#'
#' @param module_name Name of module (for error messages)
#'
#' @return Schema object, or NULL if module doesn't use schemas
module_get_input_schema <- function(module_name = NA_character_) {
  # Intended to be overridden in domain modules
  NULL
}

module_get_output_schema <- function(module_name = NA_character_) {
  # Intended to be overridden in domain modules
  NULL
}

#' Validate Module Input
#'
#' Convenience wrapper for validating module input data
#'
#' @param df Input data frame
#' @param module_name Name of module (for error messages)
#'
#' @return List with validation results
validate_module_input <- function(df, module_name = NA_character_) {
  
  schema <- module_get_input_schema(module_name)
  
  if (is.null(schema)) {
    return(list(
      valid = TRUE,
      message = "No schema defined for this module"
    ))
  }
  
  validate_data_against_schema(df, schema)
}

# ============================================================================
# END: DATA TYPE INTERFACE
# ============================================================================
