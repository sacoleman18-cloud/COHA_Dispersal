# ==============================================================================
# R/core/module_schema.R
# ==============================================================================
# PURPOSE
# -------
# Module parameter schema interface and validation.
# Enables modules to declare what parameters they accept, enabling automatic
# validation, documentation, and discovery. This is CONNECTOR #2.
#
# DESIGN PRINCIPLE
# ----------------
# Every module implements get_module_schema() that returns a specification of:
#   - What parameters it accepts (name, type, required, default, constraints)
#   - What data inputs it expects
#   - What data outputs it produces
#   - Dependencies on other modules/packages
#
# This allows:
#   - Validation BEFORE calling module
#   - Auto-generated documentation
#   - Configuration discovery/exploration
#   - Type checking at boundaries
#
# FUNCTIONS PROVIDED
# ------------------
# Schema Definition:
#   None needed - modules define as list (see examples)
#
# Schema Validation:
#   - validate_config(): Check user config matches schema
#   - validate_parameter(): Check single parameter
#   - check_constraints(): Validate numeric/string constraints
#
# Schema Utilities:
#   - get_required_parameters(): Extract required params
#   - get_default_config(): Build default config from schema
#   - get_parameter_spec(): Get spec for one parameter
#
# Schema & Code Generation:
#   - generate_module_docs(): Create documentation from schema
#   - generate_r_function_signature(): Create function stub
#
# CHANGELOG
# ---------
# 2026-02-12: Phase 1.12 - Created module_schema.R
#             - Parameter schema validation (CONNECTOR #2)
#             - Constraint checking (min/max, pattern, etc.)
#             - Documentation generation
# ==============================================================================

library(here)

# ==============================================================================
# SCHEMA STRUCTURE REFERENCE
# ==============================================================================

# Example schema (template for modules to implement):
#
# get_module_schema <- function() {
#   list(
#     # Module metadata
#     module_id = "my_module_id",
#     module_version = "1.0.0",
#     module_type = "domain|plot|utility",
#
#     # Human-readable info
#     name = "Human-Readable Name",
#     description = "What this module does",
#
#     # Parameters specification
#     parameters = list(
#       param_name = list(
#         type = "character|numeric|integer|logical|list|data.frame",
#         required = TRUE|FALSE,
#         description = "What this parameter does",
#         default = NULL|value,
#         constraints = list(
#           # For numeric/integer:
#           min = 0, max = 100,
#           # For character:
#           pattern = "^[a-z]+$",  # Regex
#           allowed_values = c("a", "b", "c")
#         ),
#         examples = list(...)
#       ),
#       # ... more parameters
#     ),
#
#     # Input data specification
#     inputs = list(
#       input_name = list(
#         type = "data.frame|list|numeric|...",
#         required = TRUE|FALSE,
#         description = "...",
#         schema = list(
#           columns = c(...),
#           types = list(...)
#         )
#       )
#     ),
#
#     # Output specification
#     outputs = list(...),
#
#     # Dependencies
#     dependencies = list(
#       core_modules = c("logging", "assertions"),
#       r_packages = c("dplyr", "tidyr")
#     )
#   )
# }

# ==============================================================================
# PARAMETER VALIDATION
# ==============================================================================

#' Validate User Configuration Against Module Schema
#'
#' Checks that user-provided configuration matches the module's parameter
#' schema (types, required fields, value constraints).
#'
#' @param user_config List. User-provided configuration parameters.
#'   Example: list(file_path = "data.csv", min_rows = 50)
#'
#' @param module_schema List. Module schema from get_module_schema().
#'   Should have $parameters field with parameter specifications.
#'
#' @param strict Logical. If TRUE, unknown parameters cause error.
#'   If FALSE, unknown parameters generate warning only.
#'   Default: FALSE (permissive)
#'
#' @return List with validation result:
#'   - $valid: Logical. TRUE if all checks pass
#'   - $errors: Character vector. Validation failures (empty if valid)
#'   - $warnings: Character vector. Non-fatal issues
#'   - $missing_params: Character vector. Required params not provided
#'   - $extra_params: Character vector. Params not in schema
#'   - $config_normalized: List. Config with defaults filled in
#'
#' @details
#' Validates:
#'   1. All required parameters provided
#'   2. Parameter types match schema
#'   3. Values satisfy constraints (min/max, pattern, allowed_values)
#'   4. No unknown parameters (or warning if strict=FALSE)
#'
#' @examples
#' # Module defines schema
#' schema <- list(
#'   parameters = list(
#'     file_path = list(type = "character", required = TRUE),
#'     min_rows = list(
#'       type = "numeric",
#'       required = FALSE,
#'       default = 10,
#'       constraints = list(min = 1, max = 10000)
#'     )
#'   )
#' )
#'
#' # User provides config
#' config <- list(file_path = "data.csv", min_rows = 50)
#'
#' # Validate
#' validation <- validate_config(config, schema)
#' if (validation$valid) {
#'   # Safe to use config
#' } else {
#'   for (err in validation$errors) cat("ERROR:", err, "\n")
#' }
#'
#' @export
validate_config <- function(user_config, module_schema, strict = FALSE) {

  result <- list(
    valid = TRUE,
    errors = character(),
    warnings = character(),
    missing_params = character(),
    extra_params = character(),
    config_normalized = user_config
  )

  # Validate inputs
  if (!is.list(module_schema)) {
    result$valid <- FALSE
    result$errors <- c(result$errors, "module_schema must be a list")
    return(result)
  }

  if (!"parameters" %in% names(module_schema)) {
    # No parameters defined is OK (module takes no params)
    return(result)
  }

  param_specs <- module_schema$parameters
  if (!is.list(param_specs)) {
    result$valid <- FALSE
    result$errors <- c(result$errors, "schema$parameters must be a list")
    return(result)
  }

  # Initialize normalized config with defaults
  result$config_normalized <- as.list(user_config)

  # Check all required parameters are provided
  for (param_name in names(param_specs)) {
    param_spec <- param_specs[[param_name]]

    # Check if required
    is_required <- isTRUE(param_spec$required)

    if (is_required && !(param_name %in% names(user_config))) {
      result$valid <- FALSE
      result$missing_params <- c(result$missing_params, param_name)
      result$errors <- c(
        result$errors,
        sprintf("Required parameter '%s' not provided", param_name)
      )
    } else if (!is_required && !(param_name %in% names(user_config))) {
      # Not required and not provided - use default if available
      if ("default" %in% names(param_spec) && !is.null(param_spec$default)) {
        result$config_normalized[[param_name]] <- param_spec$default
      }
    }
  }

  # Validate parameter types and constraints
  for (param_name in names(user_config)) {

    # Check if parameter is in schema
    if (!(param_name %in% names(param_specs))) {
      result$extra_params <- c(result$extra_params, param_name)
      if (strict) {
        result$valid <- FALSE
        result$errors <- c(
          result$errors,
          sprintf("Unknown parameter: '%s'", param_name)
        )
      } else {
        result$warnings <- c(
          result$warnings,
          sprintf("Unknown parameter: '%s' (will be ignored)", param_name)
        )
      }
      next
    }

    param_spec <- param_specs[[param_name]]
    param_value <- user_config[[param_name]]

    # Type validation
    type_check <- validate_parameter(
      param_value,
      param_spec,
      param_name
    )

    if (!type_check$valid) {
      result$valid <- FALSE
      result$errors <- c(result$errors, type_check$errors)
    } else if (length(type_check$warnings) > 0) {
      result$warnings <- c(result$warnings, type_check$warnings)
    }
  }

  result
}

#' Validate a Single Parameter
#'
#' Check that a parameter value matches its specification (type, constraints).
#'
#' @param param_value Object. Value to validate
#' @param param_spec List. Parameter specification with:
#'   - $type: Expected R type
#'   - $constraints: (optional) min, max, pattern, allowed_values
#'
#' @param param_name Character. Name of parameter (for error messages)
#'
#' @return List with:
#'   - $valid: Logical
#'   - $errors: Character vector
#'   - $warnings: Character vector
#'
#' @keywords internal
#' @export
validate_parameter <- function(param_value, param_spec, param_name = "unknown") {

  result <- list(
    valid = TRUE,
    errors = character(),
    warnings = character()
  )

  # Validate type
  expected_type <- param_spec$type
  actual_type <- class(param_value)[1]

  # Type matching (with some flexibility for common conversions)
  type_matches <- switch(expected_type,
    "numeric" = is.numeric(param_value),
    "integer" = is.integer(param_value) || is.numeric(param_value),
    "character" = is.character(param_value),
    "logical" = is.logical(param_value),
    "data.frame" = is.data.frame(param_value),
    "list" = is.list(param_value),
    "vector" = is.vector(param_value),
    FALSE
  )

  if (!type_matches) {
    result$valid <- FALSE
    result$errors <- c(
      result$errors,
      sprintf(
        "Parameter '%s': expected type '%s', got '%s'",
        param_name, expected_type, actual_type
      )
    )
    return(result)  # Can't validate constraints if type is wrong
  }

  # Validate constraints
  if ("constraints" %in% names(param_spec)) {
    constraint_check <- check_constraints(
      param_value,
      param_spec$constraints,
      param_name,
      expected_type
    )

    if (!constraint_check$valid) {
      result$valid <- FALSE
      result$errors <- c(result$errors, constraint_check$errors)
    }
    if (length(constraint_check$warnings) > 0) {
      result$warnings <- c(result$warnings, constraint_check$warnings)
    }
  }

  result
}

#' Check Parameter Against Constraints
#'
#' Validates numeric bounds, string patterns, allowed values, etc.
#'
#' @param value Object. Value to check
#' @param constraints List with any of:
#'   - $min: Minimum value (numeric)
#'   - $max: Maximum value (numeric)
#'   - $pattern: Regex pattern (character)
#'   - $allowed_values: Vector of allowed values
#'   - $length: Expected vector length
#'   - $non_empty: Must have length > 0 (logical)
#'
#' @param param_name Character. Parameter name (for errors)
#' @param param_type Character. Expected type (for context)
#'
#' @return List with $valid, $errors, $warnings
#'
#' @keywords internal
#' @export
check_constraints <- function(value, constraints, param_name = "unknown", param_type = NULL) {

  result <- list(
    valid = TRUE,
    errors = character(),
    warnings = character()
  )

  if (!is.list(constraints)) {
    return(result)  # No constraints is OK
  }

  # Check numeric bounds (min/max)
  if ("min" %in% names(constraints)) {
    min_val <- constraints$min
    if (is.numeric(value) && min(value) < min_val) {
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        sprintf(
          "Parameter '%s': value(s) below minimum %.0f",
          param_name, min_val
        )
      )
    }
  }

  if ("max" %in% names(constraints)) {
    max_val <- constraints$max
    if (is.numeric(value) && max(value) > max_val) {
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        sprintf(
          "Parameter '%s': value(s) above maximum %.0f",
          param_name, max_val
        )
      )
    }
  }

  # Check string pattern (regex)
  if ("pattern" %in% names(constraints)) {
    pattern <- constraints$pattern
    if (is.character(value)) {
      if (!all(grepl(pattern, value))) {
        result$valid <- FALSE
        result$errors <- c(
          result$errors,
          sprintf(
            "Parameter '%s': value(s) don't match pattern '%s'",
            param_name, pattern
          )
        )
      }
    }
  }

  # Check allowed values (enumeration)
  if ("allowed_values" %in% names(constraints)) {
    allowed <- constraints$allowed_values
    if (!all(value %in% allowed)) {
      invalid <- value[!(value %in% allowed)]
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        sprintf(
          "Parameter '%s': invalid value(s) %s. Allowed: %s",
          param_name,
          paste(unique(invalid), collapse = ", "),
          paste(allowed, collapse = ", ")
        )
      )
    }
  }

  # Check vector length
  if ("length" %in% names(constraints)) {
    expected_len <- constraints$length
    actual_len <- length(value)
    if (actual_len != expected_len) {
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        sprintf(
          "Parameter '%s': expected length %d, got %d",
          param_name, expected_len, actual_len
        )
      )
    }
  }

  # Check non-empty
  if ("non_empty" %in% names(constraints) && isTRUE(constraints$non_empty)) {
    if (length(value) == 0) {
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        sprintf("Parameter '%s': must be non-empty", param_name)
      )
    }
  }

  result
}

# ==============================================================================
# SCHEMA UTILITIES
# ==============================================================================

#' Get Required Parameters from Schema
#'
#' Extract list of parameter names that are required.
#'
#' @param module_schema List. Module schema from get_module_schema()
#'
#' @return Character vector of required parameter names
#'
#' @examples
#' schema <- list(
#'   parameters = list(
#'     required_param = list(type = "character", required = TRUE),
#'     optional_param = list(type = "numeric", required = FALSE)
#'   )
#' )
#' get_required_parameters(schema)  # "required_param"
#'
#' @export
get_required_parameters <- function(module_schema) {

  if (!is.list(module_schema) || !"parameters" %in% names(module_schema)) {
    return(character())
  }

  param_specs <- module_schema$parameters

  required <- sapply(param_specs, function(spec) {
    isTRUE(spec$required)
  })

  names(param_specs)[required]
}

#' Get Default Configuration from Schema
#'
#' Build a configuration list with all default values from schema.
#'
#' @param module_schema List. Module schema from get_module_schema()
#'
#' @return List with all parameters set to their defaults
#'   (or NULL if no default specified)
#'
#' @examples
#' schema <- list(
#'   parameters = list(
#'     file_path = list(type = "character", required = TRUE, default = "data.csv"),
#'     min_rows = list(type = "numeric", required = FALSE, default = 10)
#'   )
#' )
#' get_default_config(schema)  # list(file_path = "data.csv", min_rows = 10)
#'
#' @export
get_default_config <- function(module_schema) {

  if (!is.list(module_schema) || !"parameters" %in% names(module_schema)) {
    return(list())
  }

  param_specs <- module_schema$parameters
  defaults <- list()

  for (param_name in names(param_specs)) {
    param_spec <- param_specs[[param_name]]
    if ("default" %in% names(param_spec)) {
      defaults[[param_name]] <- param_spec$default
    } else {
      defaults[[param_name]] <- NULL
    }
  }

  defaults
}

#' Get Specification for a Single Parameter
#'
#' Extract the full specification for one parameter.
#'
#' @param module_schema List. Module schema
#' @param param_name Character. Name of parameter to look up
#'
#' @return List with parameter specification, or NULL if not found
#'
#' @export
get_parameter_spec <- function(module_schema, param_name) {

  if (!is.list(module_schema) || !"parameters" %in% names(module_schema)) {
    return(NULL)
  }

  module_schema$parameters[[param_name]]
}

# ==============================================================================
# DOCUMENTATION GENERATION
# ==============================================================================

#' Generate Module Documentation from Schema
#'
#' Creates human-readable documentation (Markdown) from module schema.
#'
#' @param module_schema List. Module schema from get_module_schema()
#'
#' @return Character string with Markdown documentation
#'
#' @details
#' Generates:
#'   - Module name and description
#'   - Parameters section with types, defaults, constraints
#'   - Inputs/outputs section (if specified)
#'   - Dependencies section
#'
#' @export
generate_module_docs <- function(module_schema) {

  if (!is.list(module_schema)) {
    return("Invalid schema")
  }

  doc <- c()

  # Header
  if (!"module_id" %in% names(module_schema)) {
    module_id <- "unknown_module"
  } else {
    module_id <- module_schema$module_id
  }

  doc <- c(doc, sprintf("# Module: %s", module_id))

  if ("name" %in% names(module_schema)) {
    doc <- c(doc, "", module_schema$name)
  }

  if ("description" %in% names(module_schema)) {
    doc <- c(doc, "", module_schema$description)
  }

  # Parameters section
  if ("parameters" %in% names(module_schema)) {
    param_specs <- module_schema$parameters

    if (length(param_specs) > 0) {
      doc <- c(doc, "", "## Parameters")

      for (param_name in names(param_specs)) {
        param_spec <- param_specs[[param_name]]
        req_str <- if (isTRUE(param_spec$required)) "**required**" else "optional"
        type_str <- param_spec$type

        doc <- c(
          doc,
          sprintf("### `%s` (%s, %s)", param_name, type_str, req_str)
        )

        if ("description" %in% names(param_spec)) {
          doc <- c(doc, "", param_spec$description)
        }

        if ("default" %in% names(param_spec) && !is.null(param_spec$default)) {
          doc <- c(doc, sprintf("- Default: `%s`", as.character(param_spec$default)))
        }

        if ("constraints" %in% names(param_spec)) {
          constraints <- param_spec$constraints
          if ("min" %in% names(constraints)) {
            doc <- c(doc, sprintf("- Minimum: %.0f", constraints$min))
          }
          if ("max" %in% names(constraints)) {
            doc <- c(doc, sprintf("- Maximum: %.0f", constraints$max))
          }
          if ("allowed_values" %in% names(constraints)) {
            values <- paste(constraints$allowed_values, collapse = ", ")
            doc <- c(doc, sprintf("- Allowed values: %s", values))
          }
        }

        doc <- c(doc, "")
      }
    }
  }

  # Dependencies
  if ("dependencies" %in% names(module_schema)) {
    deps <- module_schema$dependencies
    if (length(deps) > 0) {
      doc <- c(doc, "## Dependencies")
      if ("r_packages" %in% names(deps) && length(deps$r_packages) > 0) {
        pkgs <- paste(deps$r_packages, collapse = ", ")
        doc <- c(doc, sprintf("R packages: %s", pkgs))
      }
      if ("core_modules" %in% names(deps) && length(deps$core_modules) > 0) {
        mods <- paste(deps$core_modules, collapse = ", ")
        doc <- c(doc, sprintf("Core modules: %s", mods))
      }
    }
  }

  paste(doc, collapse = "\n")
}

#' Generate R Function Signature from Schema
#'
#' Creates skeleton R function with proper parameter signature.
#'
#' @param module_schema List. Module schema
#' @param include_body Logical. Include function body comment (default: TRUE)
#'
#' @return Character string with R function definition
#'
#' @export
generate_r_function_signature <- function(module_schema, include_body = TRUE) {

  # Function name from module_id
  fn_name <- if ("module_id" %in% names(module_schema)) {
    gsub("-|_", "", module_schema$module_id)  # Remove dashes/underscores for valid name
  } else {
    "my_module"
  }

  # Build parameter list
  params <- c()
  if ("parameters" %in% names(module_schema)) {
    for (param_name in names(module_schema$parameters)) {
      param_spec <- module_schema$parameters[[param_name]]
      if ("default" %in% names(param_spec)) {
        default_str <- deparse(param_spec$default)
        params <- c(params, sprintf("%s = %s", param_name, default_str))
      } else {
        params <- c(params, param_name)
      }
    }
  }

  # Build function
  params_str <- paste(c("", params, ""), collapse = "\n  ")

  fn <- sprintf("%s <- function(%s) {", fn_name, params_str)

  if (include_body) {
    fn <- c(
      fn,
      "  # TODO: Implement module",
      "  result <- create_module_result(",
      sprintf("    operation = \"%s\",", fn_name),
      sprintf("    module_name = \"%s\"", module_schema$module_id),
      "  )",
      "  result",
      "}"
    )
    fn <- paste(fn, collapse = "\n")
  } else {
    fn <- sprintf("%s\n  # ...\n}", fn)
  }

  fn
}

# ==============================================================================
# EOF
# ==============================================================================
