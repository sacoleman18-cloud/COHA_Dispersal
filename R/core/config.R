# ==============================================================================
# R/functions/config_loader.R
# ==============================================================================
# PURPOSE
# -------
# Load and validate project configuration from YAML.
# Provides single consistent interface for accessing all project settings.
#
# DEPENDS ON
# ----------
# - yaml package for YAML parsing
# - here::here() for path management
# - R/functions/assertions.R for validation
# - R/functions/logging.R for logging
#
# INPUTS
# ------
# - inst/config/study_parameters.yaml
#
# OUTPUTS
# -------
# Configuration list with all settings
#
# USAGE
# -----
# source("R/functions/config_loader.R")
# config <- load_study_config(verbose = TRUE)
# config$data$source_file  # Returns "data/data.csv"
#
# ==============================================================================

#' Load Study Configuration from YAML
#'
#' @description
#' Loads project configuration from inst/config/study_parameters.yaml
#' and validates that all required sections exist. Call once at pipeline start.
#'
#' @param verbose Logical. Print configuration loading progress and status.
#'   Shows file path, parsing status, section validation.
#'   Default: FALSE.
#'
#' @return List. Nested configuration with all project settings.
#'   Top-level keys: project, data, paths, plot_types, defaults, logging, etc.
#'   Access via: config$section$key or get_config_value(config, c("section", "key")).
#'
#' @details
#' **YAML File:** Loads from inst/config/study_parameters.yaml
#' (automatically resolved via here::here() for portability).
#'
#' **Validation:** Checks that required top-level sections exist:
#' - project, data, paths, plot_types, defaults
#' Stops with error if any section missing.
#'
#' **Warnings:** Warns if no plot types are enabled (will produce no output).
#'
#' **Determinism:** Uses here::here() so path is consistent across
#' machines running from project root.
#'
#' **Return Structure:**
#' ```r
#' config$project$name       # Project name string
#' config$project$version    # Version string
#' config$data$source_file   # Path to data CSV
#' config$data$required_columns  # Character vector of column names
#' config$plot_types$ridgeline$enabled  # TRUE/FALSE
#' config$defaults$verbose   # Default verbose setting
#' config$paths$plots_base   # Base directory for plots
#' ```
#'
#' @examples
#' \dontrun{
#' # Load configuration at pipeline start
#' config <- load_study_config(verbose = TRUE)
#'
#' # Access nested values
#' source_file <- config$data$source_file
#' plot_types <- get_enabled_plot_types(config)
#'
#' # Validate paths exist (creates if needed)
#' validate_config_paths(config, verbose = TRUE)
#' }
#'
#' @seealso [get_config_value()], [get_enabled_plot_types()],
#'   [validate_config_paths()], [print_config_summary()]
#'
#' @export
load_study_config <- function(verbose = FALSE) {
  # Check that yaml package is available
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "Package 'yaml' required for config loading.\n",
      "Install with: install.packages('yaml')",
      call. = FALSE
    )
  }
  
  # Check that here package is available
  if (!requireNamespace("here", quietly = TRUE)) {
    stop(
      "Package 'here' required.\n",
      "Install with: install.packages('here')",
      call. = FALSE
    )
  }
  
  # Build path to config file
  config_path <- here::here("inst", "config", "study_parameters.yaml")
  
  if (verbose) {
    message(sprintf("[CONFIG] Loading from %s", config_path))
  }
  
  # Check file exists
  if (!file.exists(config_path)) {
    stop(
      sprintf("Configuration file not found: %s\n",
              "Create inst/config/study_parameters.yaml"),
      call. = FALSE
    )
  }
  
  # Load YAML
  tryCatch(
    {
      config <- yaml::read_yaml(config_path)
      if (verbose) {
        message("[CONFIG] ✓ YAML parsed successfully")
      }
    },
    error = function(e) {
      stop(
        sprintf("Failed to parse YAML config: %s", e$message),
        call. = FALSE
      )
    }
  )
  
  # Validate required top-level sections
  required_sections <- c("project", "data", "paths", "plot_types", "defaults")
  missing_sections <- setdiff(required_sections, names(config))
  
  if (length(missing_sections) > 0) {
    stop(
      sprintf("Config missing required sections: %s",
              paste(missing_sections, collapse = ", ")),
      call. = FALSE
    )
  }
  
  if (verbose) {
    message("[CONFIG] ✓ All required sections present")
  }
  
  # Validate that at least one plot type is enabled
  has_enabled <- FALSE
  for (plot_type in names(config$plot_types)) {
    if (!is.null(config$plot_types[[plot_type]]$enabled) &&
        config$plot_types[[plot_type]]$enabled) {
      has_enabled <- TRUE
      break
    }
  }
  
  if (!has_enabled) {
    warning("No plot types enabled in configuration", call. = FALSE)
  }
  
  if (verbose) {
    message("[CONFIG] ✓ Configuration validation complete")
    message(sprintf("[CONFIG] Project: %s v%s",
                    config$project$name,
                    config$project$version))
  }
  
  invisible(config)
}

#' Get Configuration Value
#'
#' @description
#' Safely retrieve nested configuration values with default fallback.
#'
#' @param config List. Configuration object from load_study_config().
#' @param path Character vector. Path to config value, e.g., c("data", "source_file").
#' @param default Object. Default value if path not found.
#'
#' @return Configuration value at path, or default if not found.
#'
#' @examples
#' config <- load_study_config()
#' get_config_value(config, c("data", "source_file"))
#' get_config_value(config, c("missing", "key"), default = "fallback")
#'
#' @export
get_config_value <- function(config, path, default = NULL) {
  value <- config
  for (key in path) {
    if (is.list(value) && key %in% names(value)) {
      value <- value[[key]]
    } else {
      return(default)
    }
  }
  value
}

#' Get Enabled Plot Types
#'
#' @description
#' Returns list of plot types that are enabled in configuration.
#'
#' @param config List. Configuration from load_study_config().
#'
#' @return Character vector. Names of enabled plot types.
#'
#' @examples
#' config <- load_study_config()
#' enabled_plots <- get_enabled_plot_types(config)
#' # c("ridgeline") if only ridgeline enabled
#'
#' @export
get_enabled_plot_types <- function(config) {
  enabled <- c()
  
  for (plot_type in names(config$plot_types)) {
    if (!is.null(config$plot_types[[plot_type]]$enabled) &&
        config$plot_types[[plot_type]]$enabled) {
      enabled <- c(enabled, plot_type)
    }
  }
  
  enabled
}

#' Validate Configuration Paths
#'
#' @description
#' Check that all directories referenced in config exist or can be created.
#'
#' @param config List. Configuration from load_study_config().
#' @param create Logical. Create missing directories. Default: TRUE.
#' @param verbose Logical. Print validation messages. Default: FALSE.
#'
#' @return invisible(TRUE) if valid, or after creating directories.
#'
#' @examples
#' config <- load_study_config()
#' validate_config_paths(config, verbose = TRUE)
#'
#' @export
validate_config_paths <- function(config, create = TRUE, verbose = FALSE) {
  if (!requireNamespace("here", quietly = TRUE)) {
    stop("Package 'here' required", call. = FALSE)
  }
  
  required_dirs <- c(
    config$paths$plots_base,
    config$paths$reports_base,
    config$paths$logs_dir,
    config$paths$data_processed
  )
  
  for (dir_path in required_dirs) {
    full_path <- here::here(dir_path)
    
    if (!dir.exists(full_path)) {
      if (create) {
        tryCatch(
          {
            dir.create(full_path, showWarnings = FALSE, recursive = TRUE)
            if (verbose) {
              message(sprintf("[CONFIG] Created directory: %s", full_path))
            }
          },
          error = function(e) {
            stop(sprintf("Could not create directory: %s", full_path),
                 call. = FALSE)
          }
        )
      } else {
        stop(sprintf("Directory does not exist: %s", full_path),
             call. = FALSE)
      }
    }
  }
  
  if (verbose) {
    message("[CONFIG] ✓ All configured paths available")
  }
  
  invisible(TRUE)
}

#' Print Configuration Summary
#'
#' @description
#' Display human-readable summary of current configuration.
#'
#' @param config List. Configuration from load_study_config().
#'
#' @return invisible(NULL)
#'
#' @examples
#' config <- load_study_config()
#' print_config_summary(config)
#'
#' @export
print_config_summary <- function(config) {
  cat("\n")
  cat("=" %+% rep("-", 60), "\n", sep = "")
  cat("PROJECT CONFIGURATION SUMMARY\n")
  cat("=" %+% rep("-", 60), "\n", sep = "")
  
  cat("\nProject:\n")
  cat("  Name:    ", config$project$name, "\n", sep = "")
  cat("  Version: ", config$project$version, "\n", sep = "")
  
  cat("\nData:\n")
  cat("  Source:  ", config$data$source_file, "\n", sep = "")
  cat("  Columns: ", paste(config$data$required_columns, collapse = ", "), "\n", sep = "")
  
  cat("\nEnabled Plot Types:\n")
  enabled <- get_enabled_plot_types(config)
  if (length(enabled) > 0) {
    for (plot_type in enabled) {
      cat("  - ", plot_type, "\n", sep = "")
    }
  } else {
    cat("  (None enabled)\n")
  }
  
  cat("\nOutput Paths:\n")
  cat("  Plots:   ", config$paths$plots_base, "\n", sep = "")
  cat("  Reports: ", config$paths$reports_base, "\n", sep = "")
  cat("  Logs:    ", config$paths$logs_dir, "\n", sep = "")
  
  cat("\n" %+% rep("-", 60), "\n\n", sep = "")
  
  invisible(NULL)
}

# ==============================================================================
# END R/functions/config_loader.R
# ==============================================================================
