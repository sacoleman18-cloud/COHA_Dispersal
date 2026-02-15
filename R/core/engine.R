# ==============================================================================
# R/core/engine.R
# ==============================================================================
# PURPOSE
# -------
# Universal pipeline orchestrator and plugin manager.
# Manages module discovery, loading, validation, and analysis execution.
# Core of the modular architecture - remains domain-agnostic.
#
# DESIGN PATTERN
# ---------------
# This engine follows the PLUGIN ARCHITECTURE pattern:
# 1. Core engine (this file) - knows HOW to execute analyses
# 2. Domain modules (domain_modules/) - know WHAT to analyze
# 3. Plot modules (future - plot_modules/) - know HOW to plot
#
# FUNCTIONS PROVIDED
# ------------------
# Plugin Management:
#   - discover_modules(): Find all available modules
#   - load_module(): Dynamically load a module
#   - validate_module_interface(): Check module contract
#   - register_module(): Register module with engine
#
# Pipeline Management:
#   - initialize_pipeline(): Set up execution environment
#   - run_analysis(): Main entry point for analyses
#
# CHANGELOG
# ---------
# 2026-02-12: Phase 1.11 - Created core/engine.R
#             - Plugin discovery and loading
#             - Module validation
#             - Analysis orchestration
# ==============================================================================

library(here)
library(yaml)

# Source dependencies
source(here::here("R", "core", "assertions.R"))
source(here::here("R", "core", "logging.R"))
source(here::here("R", "core", "robustness.R"))
source(here::here("R", "core", "artifacts.R"))

# ==============================================================================
# ENGINE STATE
# ==============================================================================

# Global registry for loaded modules
.MODULE_REGISTRY <- new.env()
.MODULE_REGISTRY$modules <- list()
.MODULE_REGISTRY$plot_modules <- list()
.MODULE_REGISTRY$domain_modules <- list()

# ==============================================================================
# PLUGIN MANAGER: MODULE DISCOVERY
# ==============================================================================

#' Discover Available Modules
#'
#' Scans module directories (plot_modules/, domain_modules/) and returns
#' metadata for all discovered modules.
#'
#' @param base_dir Character. Root directory to scan (default: project root)
#' @param type Character. Type to discover: "plot", "domain", or NULL for all
#' @param verbose Logical. Print discovery progress (default: FALSE)
#'
#' @return List of discovered modules with metadata
#'   - $plot_modules: List of plot type modules
#'   - $domain_modules: List of domain modules
#'
#' @section DISCOVERY STRATEGY:
#' Scans directories looking for:
#' - module.R or main generator file in each module directory
#' - get_module_metadata() function (module.R style) OR
#' - get_module_info() function (older style)
#' - README.md or INTERFACE.md documentation
#'
#' @export
discover_modules <- function(base_dir = here::here(), type = NULL, verbose = FALSE) {
  
  modules_found <- list(
    plot_modules = list(),
    domain_modules = list()
  )
  
  # Scan plot_modules/ directory (if not filtered out)
  if (is.null(type) || type == "plot") {
    plot_dir <- file.path(base_dir, "R", "plot_modules")
    if (dir.exists(plot_dir)) {
      if (verbose) cat("[Discovery] Scanning plot_modules/...\n")
      
      plot_subdirs <- list.dirs(plot_dir, recursive = FALSE, full.names = TRUE)
      for (module_path in plot_subdirs) {
        module_name <- basename(module_path)
        
        # Check for module.R (new style)
        module_file <- file.path(module_path, "module.R")
        has_module_file <- file.exists(module_file)
        
        # Check for README.md for documentation
        readme_file <- file.path(module_path, "README.md")
        has_readme <- file.exists(readme_file)
        
        # Check for old-style INTERFACE.md
        info_file <- file.path(module_path, "INTERFACE.md")
        has_interface_file <- file.exists(info_file)
        
        # Accept module if has module.R or INTERFACE.md
        if (has_module_file || has_interface_file) {
          modules_found$plot_modules[[module_name]] <- list(
            name = module_name,
            type = "plot",
            path = module_path,
            module_file = if (has_module_file) module_file else NULL,
            interface_file = if (has_interface_file) info_file else NULL,
            readme_file = if (has_readme) readme_file else NULL
          )
          if (verbose) cat(sprintf("  ✓ Found plot module: %s\n", module_name))
        }
      }
    }
  }
  
  # Scan domain_modules/ directory (if not filtered out)
  if (is.null(type) || type == "domain") {
    domain_base <- file.path(base_dir, "R", "domain_modules")
    if (dir.exists(domain_base)) {
      if (verbose) cat("[Discovery] Scanning domain_modules/...\n")
      
      domain_subdirs <- list.dirs(domain_base, recursive = FALSE, full.names = TRUE)
      for (module_path in domain_subdirs) {
        module_name <- basename(module_path)
        config_file <- file.path(module_path, "domain_config.yaml")
        readme_file <- file.path(module_path, "README.md")
        
        if (file.exists(config_file) || file.exists(readme_file)) {
          modules_found$domain_modules[[module_name]] <- list(
            name = module_name,
            type = "domain",
            path = module_path,
            config_file = config_file,
            readme_file = readme_file
          )
          if (verbose) cat(sprintf("  ✓ Found domain module: %s\n", module_name))
        }
      }
    }
  }
  
  if (verbose) {
    cat(sprintf("\n[Discovery] Found %d plot modules and %d domain modules\n",
                length(modules_found$plot_modules),
                length(modules_found$domain_modules)))
  }
  
  modules_found
}


#' Load a Module Dynamically
#'
#' Loads an R module by sourcing its main file and extracting module info.
#'
#' @param module_name Character. Name of the module to load
#' @param module_type Character. Type: "plot" or "domain"
#' @param base_dir Character. Root directory
#' @param verbose Logical. Print loading progress
#'
#' @return List with:
#'   - $loaded: Logical. Success status
#'   - $name: Module name
#'   - $info: Module metadata from get_module_info()
#'   - $env: Environment where module was loaded
#'   - $errors: Character vector of any errors
#'
#' @export
load_module <- function(module_name,
                       module_type = c("plot", "domain"),
                       base_dir = here::here(),
                       verbose = FALSE) {
  
  module_type <- match.arg(module_type)
  
  result <- create_result(
    operation = sprintf("load_module(%s, type=%s)", module_name, module_type)
  )
  
  # Determine module path
  if (module_type == "plot") {
    module_path <- file.path(base_dir, "R", "plot_modules", module_name)
  } else {
    # Domain modules might have subdirectories
    module_base <- file.path(base_dir, "R", "domain_modules")
    module_path <- file.path(module_base, module_name)
  }
  
  if (!dir.exists(module_path)) {
    return(add_error(result, sprintf("Module directory not found: %s", module_path)))
  }
  
  # Find module main file
  # For plot modules, prefer module.R (new interface style)
  # For domain modules, look for data_loader.R or config file
  main_files <- if (module_type == "plot") {
    c(
      "module.R",                            # New plot module interface
      sprintf("%s_generator.R", module_name),  # Older plot modules
      sprintf("%s.R", module_name),            # Generic
      "main.R"                                 # Fallback
    )
  } else {
    # Domain modules
    c(
      sprintf("%s.R", module_name),
      "data_loader.R",
      "main.R",
      "module.R"
    )
  }
  
  main_file <- NULL
  for (f in main_files) {
    candidate <- file.path(module_path, f)
    if (file.exists(candidate)) {
      main_file <- candidate
      break
    }
  }
  
  if (is.null(main_file)) {
    return(add_error(result, 
                    sprintf("No main R file found in %s", module_path)))
  }
  
  # Load module in new environment
  tryCatch({
    module_env <- new.env(parent = .GlobalEnv)
    
    # Set module path for relative imports
    module_env$MODULE_PATH <- module_path
    
    # Source the main file
    source(main_file, local = module_env)
    
    if (verbose) {
      cat(sprintf("[Engine] Loaded module: %s from %s\n", 
                  module_name, basename(main_file)))
    }
    
    # Try to get module info
    module_info <- NULL
    if (exists("get_module_info", where = module_env)) {
      module_info <- module_env$get_module_info()
    }
    
    # Return success
    result$loaded <- TRUE
    result$name <- module_name
    result$type <- module_type
    result$path <- module_path
    result$main_file <- main_file
    result$info <- module_info
    result$env <- module_env
    
  }, error = function(e) {
    add_error(result, sprintf("Failed to load module: %s", e$message))
  })
  
  result
}


#' Validate Module Interface
#'
#' Checks that a loaded module implements the required interface for its type.
#' Supports two interface styles:
#' - NEW STYLE (Phase 2+ plot modules): get_module_metadata, generate_plot, get_available_plots
#' - OLD STYLE (earlier modules): get_module_info, generate_variants, validate_config
#'
#' @param module_env Environment. Loaded module environment
#' @param module_type Character. Type: "plot" or "domain"
#' @param verbose Logical. Print validation details
#'
#' @return List with:
#'   - $valid: Logical. TRUE if implements required interface
#'   - $interface_style: Character. "new" or "old" 
#'   - $missing_functions: Character vector of missing functions
#'   - $errors: Character vector of validation errors
#'
#' @export
validate_module_interface <- function(module_env,
                                     module_type = c("plot", "domain"),
                                     verbose = FALSE) {
  
  module_type <- match.arg(module_type)
  
  result <- list(
    valid = TRUE,
    interface_style = NA_character_,
    missing_functions = character(),
    errors = character()
  )
  
  if (module_type == "plot") {
    # NEW PLOT MODULE INTERFACE (Phase 2+)
    # Stricter requirements
    new_style_functions <- c(
      "get_module_metadata",      # Module identification
      "get_available_plots",      # List available plots
      "generate_plot"             # Generate single plot
    )
    
    # OLD PLOT MODULE INTERFACE (Pre-Phase 2)
    old_style_functions <- c(
      "generate_variants",      # Generate plots
      "get_module_info",        # Metadata
      "validate_config",        # Configuration validation
      "get_default_config"      # Default configuration
    )
    
    # Check for new style first
    new_style_missing <- character()
    for (func in new_style_functions) {
      if (!exists(func, where = module_env, inherits = FALSE)) {
        new_style_missing <- c(new_style_missing, func)
      }
    }
    
    # Check for old style
    old_style_missing <- character()
    for (func in old_style_functions) {
      if (!exists(func, where = module_env, inherits = FALSE)) {
        old_style_missing <- c(old_style_missing, func)
      }
    }
    
    # Determine which style is implemented
    if (length(new_style_missing) == 0) {
      # NEW STYLE - all required functions present
      result$interface_style <- "new"
      result$valid <- TRUE
    } else if (length(old_style_missing) == 0) {
      # OLD STYLE - all required functions present
      result$interface_style <- "old"
      result$valid <- TRUE
    } else {
      # NEITHER STYLE - missing critical functions
      result$valid <- FALSE
      result$interface_style <- "unknown"
      result$missing_functions <- union(new_style_missing, old_style_missing)
      result$errors <- c(
        "Module does not implement known plot module interface",
        "Missing new-style functions:", 
        paste("  -", new_style_missing),
        "Missing old-style functions:",
        paste("  -", old_style_missing)
      )
    }
    
  } else {
    # DOMAIN MODULES - minimal requirements
    required_functions <- c(
      "module_init" # At minimum, provide metadata
    )
    
    for (func in required_functions) {
      if (!exists(func, where = module_env, inherits = FALSE)) {
        result$valid <- FALSE
        result$missing_functions <- c(result$missing_functions, func)
        result$errors <- c(result$errors,
                          sprintf("Missing required function: %s()", func))
      }
    }
    
    result$interface_style <- ifelse(result$valid, "domain", "invalid")
  }
  
  if (verbose) {
    if (result$valid) {
      cat(sprintf("[Validation] Module is valid (%s interface style)\n",
                  result$interface_style))
    } else {
      cat(sprintf("[Validation] Module is INVALID. Issues:\n"))
      for (err in result$errors) {
        cat(sprintf("  %s\n", err))
      }
    }
  }
  
  result
}


#' Register a Module with the Engine
#'
#' Adds a loaded and validated module to the engine's registry.
#'
#' @param module_name Character. Name of the module
#' @param module_env Environment. Loaded module environment
#' @param module_type Character. Type: "plot" or "domain"
#' @param verbose Logical. Print registration details
#'
#' @return Logical. TRUE if registered successfully
#'
#' @export
register_module <- function(module_name,
                           module_env,
                           module_type = c("plot", "domain"),
                           verbose = FALSE) {
  
  module_type <- match.arg(module_type)
  
  # Validate first
  validation <- validate_module_interface(module_env, module_type, FALSE)
  if (!validation$valid) {
    if (verbose) {
      cat(sprintf("[Registry] Cannot register %s - validation failed:\n", 
                  module_name))
      for (err in validation$errors) {
        cat(sprintf("  - %s\n", err))
      }
    }
    return(FALSE)
  }
  
  # Register in appropriate list
  if (module_type == "plot") {
    .MODULE_REGISTRY$plot_modules[[module_name]] <- module_env
  } else {
    .MODULE_REGISTRY$domain_modules[[module_name]] <- module_env
  }
  
  if (verbose) {
    cat(sprintf("[Registry] Registered %s module: %s\n", module_type, module_name))
  }
  
  TRUE
}

# ==============================================================================
# PIPELINE MANAGEMENT
# ==============================================================================

#' Initialize Pipeline
#'
#' Prepares the execution environment for an analysis.
#' - Creates output directories
#' - Initializes artifact registry
#' - Loads system configuration
#'
#' @param output_dir Character. Base output directory
#' @param verbose Logical. Print initialization details
#'
#' @return List with:
#'   - $initialized: Logical. Success status
#'   - $artifacts: Artifact registry object
#'   - $output_dirs: Named list of output directories
#'   - $errors: Character vector of errors if any
#'
#' @export
initialize_pipeline <- function(output_dir = here::here("results"),
                               verbose = FALSE) {
  
  result <- create_result(operation = "initialize_pipeline")
  result$initialized <- FALSE
  
  # Create output directory structure
  subdirs <- list(
    plots = file.path(output_dir, "plots"),
    reports = file.path(output_dir, "reports"),
    data = file.path(output_dir, "data"),
    logs = file.path(output_dir, "logs")
  )
  
  tryCatch({
    for (name in names(subdirs)) {
      dir.create(subdirs[[name]], recursive = TRUE, showWarnings = FALSE)
      if (verbose) cat(sprintf("[Init] Created directory: %s\n", subdirs[[name]]))
    }
    
    # Initialize artifact registry
    registry <- init_artifact_registry()
    if (verbose) cat("[Init] Artifact registry initialized\n")
    
    # Set result
    result$initialized <- TRUE
    result$output_dirs <- subdirs
    result$artifacts <- registry
    
  }, error = function(e) {
    add_error(result, sprintf("Initialization failed: %s", e$message))
  })
  
  result
}


#' Run Analysis (Main Entry Point)
#'
#' Execute a complete analysis:
#' 1. Initialize pipeline
#' 2. Load and validate domain module
#' 3. Load and configure plot modules
#' 4. Generate plots
#' 5. Render reports
#'
#' @param domain_name Character. Name of domain module to run (e.g., "coha_dispersal")
#' @param verbose Logical. Print execution details
#'
#' @return List with:
#'   - $success: Logical. Overall success status
#'   - $domain: Character. Domain module name
#'   - $artifacts: Artifact registry with all outputs
#'   - $duration: Execution time in seconds
#'   - $errors: Character vector of any errors
#'   - $warnings: Character vector of any warnings
#'
#' @section USAGE:
#' ```r
#' result <- run_analysis("coha_dispersal", verbose = TRUE)
#' 
#' if (result$success) {
#'   cat("Analysis complete!\n")
#'   cat("Generated", length(result$artifacts$artifacts), "artifacts\n")
#' } else {
#'   cat("Analysis failed:\n")
#'   for (err in result$errors) cat("  -", err, "\n")
#' }
#' ```
#'
#' @export
run_analysis <- function(domain_name, verbose = FALSE) {
  
  start_time <- Sys.time()
  
  result <- create_result(operation = sprintf("run_analysis(%s)", domain_name))
  result$success <- FALSE
  result$domain <- domain_name
  
  tryCatch({
    # Step 1: Initialize pipeline
    if (verbose) cat("\n[1/5] Initializing pipeline...\n")
    init_result <- initialize_pipeline(verbose = verbose)
    if (!init_result$initialized) {
      for (err in init_result$errors) {
        add_error(result, err)
      }
      return(result)
    }
    
    registry <- init_result$artifacts
    output_dirs <- init_result$output_dirs
    
    # Step 2: Load domain module
    if (verbose) cat("\n[2/5] Loading domain module: ", domain_name, "...\n")
    domain_result <- load_module(domain_name, 
                                module_type = "domain",
                                verbose = verbose)
    if (!domain_result$loaded) {
      for (err in domain_result$errors) {
        add_error(result, err)
      }
      return(result)
    }
    
    domain_env <- domain_result$env
    
    # Step 3: Register domain module
    if (!register_module(domain_name, domain_env, "domain", verbose)) {
      add_error(result, "Failed to register domain module")
      return(result)
    }
    
    # At this point, we have a working domain module loaded
    result$success <- TRUE
    result$artifacts <- registry
    result$environment <- domain_env
    result$output_dirs <- output_dirs
    
    # Future steps would be:
    # Step 4: Load plot modules (from domain config)
    # Step 5: Generate plots
    # Step 6: Render reports
    
    if (verbose) {
      cat("\n[Analysis] Pipeline initialized successfully\n")
      cat("[Analysis] Domain module: ", domain_name, "\n")
      cat("[Analysis] Output directory: ", output_dirs$plots, "\n")
    }
    
  }, error = function(e) {
    add_error(result, sprintf("Execution error: %s", e$message))
  })
  
  # Record execution time
  elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  result$duration <- elapsed
  
  result
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

#' Get Module Registry Status
#'
#' Get a summary of all registered modules
#'
#' @return List with:
#'   - $plot_modules: Character vector of registered plot modules
#'   - $domain_modules: Character vector of registered domain modules
#'
#' @export
get_registry_status <- function() {
  list(
    plot_modules = names(.MODULE_REGISTRY$plot_modules),
    domain_modules = names(.MODULE_REGISTRY$domain_modules),
    total_modules = length(.MODULE_REGISTRY$plot_modules) + 
                   length(.MODULE_REGISTRY$domain_modules)
  )
}

# ==============================================================================
# PHASE 2.1: PLUGIN-BASED PLOT ORCHESTRATION
# ==============================================================================

#' Orchestrate Multi-Module Plot Generation
#'
#' Discovers, loads, and executes all available plot modules to generate
#' complete set of plots. This is the heart of plug-and-play plot system:
#' - Auto-discovers all plot modules in R/plot_modules/
#' - Dynamically loads each module
#' - Calls module's generate_plots_batch() to create plots
#' - Aggregates results across all modules
#'
#' @param data Data frame. Input data for all plot modules
#' @param base_dir Character. Project root directory for module discovery
#' @param output_base Character. Base directory for plot output
#' @param verbose Logical. Print progress messages
#' @param dpi Numeric. DPI for PNG output (default: 300)
#' @param continue_on_error Logical. Continue if a module fails (default: TRUE)
#'
#' @return List with aggregated results:
#'   - $status: "success", "partial", or "failed"
#'   - $modules_found: Integer count of discovered modules
#'   - $modules_loaded: Integer count of successfully loaded modules
#'   - $modules_failed: Integer count of modules that failed
#'   - $plots_generated: Total plots created across all modules
#'   - $plots_failed: Total plots that failed
#'   - $results: List of results by module name
#'   - $duration_secs: Total execution time
#'   - $errors: Character vector of errors encountered
#'
#' @section ARCHITECTURE:
#'   Phase 2.1 enables TRUE plug-and-play:
#'   - Add new plot module to R/plot_modules/[new_type]/ with module.R
#'   - Pipeline auto-discovers it
#'   - No downstream code changes needed
#'
#' @export
orchestrate_plot_generation <- function(data,
                                        base_dir = here::here(),
                                        output_base = here::here("data", "plots"),
                                        verbose = FALSE,
                                        dpi = 300,
                                        continue_on_error = TRUE) {
  
  start_time <- Sys.time()
  
  result <- list(
    status = "success",
    modules_found = 0,
    modules_loaded = 0,
    modules_failed = 0,
    plots_generated = 0,
    plots_failed = 0,
    results = list(),
    duration_secs = 0,
    errors = character(0),
    timestamp = start_time
  )
  
  tryCatch({
    # STEP 1: Discover all plot modules
    if (verbose) cat("[Phase 2.1] Discovering plot modules...\n")
    
    discovery_result <- discover_modules(
      base_dir = base_dir,
      type = "plot",
      verbose = verbose
    )
    
    if (is.null(discovery_result$plot_modules) || 
        length(discovery_result$plot_modules) == 0) {
      result$status <- "failed"
      result$errors <- c(result$errors, "No plot modules found in R/plot_modules/")
      return(result)
    }
    
    result$modules_found <- length(discovery_result$plot_modules)
    
    if (verbose) {
      cat(sprintf("[Phase 2.1] Found %d plot module(s)\n", 
                  result$modules_found))
    }
    
    # STEP 2: Load and execute each module
    for (module_name in names(discovery_result$plot_modules)) {
      
      if (verbose) {
        cat(sprintf("\n[Phase 2.1] Processing module: %s\n", module_name))
      }
      
      # Load module
      load_result <- load_module(
        module_name = module_name,
        module_type = "plot",
        base_dir = base_dir,
        verbose = verbose
      )
      
      if (!load_result$loaded) {
        result$modules_failed <- result$modules_failed + 1
        msg <- sprintf("Failed to load module '%s': %s",
                      module_name,
                      paste(load_result$errors, collapse = "; "))
        result$errors <- c(result$errors, msg)
        
        if (verbose) cat(sprintf("  ✗ %s\n", msg))
        
        if (!continue_on_error) {
          result$status <- "failed"
          return(result)
        }
        next
      }
      
      result$modules_loaded <- result$modules_loaded + 1
      
      if (verbose) {
        cat(sprintf("  ✓ Module loaded: %s\n", module_name))
      }
      
      # Validate module interface
      validation <- validate_module_interface(
        module_env = load_result$env,
        module_type = "plot",
        verbose = FALSE
      )
      
      if (!validation$valid) {
        result$modules_failed <- result$modules_failed + 1
        msg <- sprintf("Module '%s' missing required functions: %s",
                      module_name,
                      paste(validation$missing_functions, collapse = ", "))
        result$errors <- c(result$errors, msg)
        
        if (verbose) cat(sprintf("  ✗ Interface validation failed: %s\n", msg))
        
        if (!continue_on_error) {
          result$status <- "failed"
          return(result)
        }
        next
      }
      
      if (verbose) cat("  ✓ Interface validated\n")
      
      # Get available plots from module
      tryCatch({
        available_plots <- load_result$env$get_available_plots()
        n_plots <- nrow(available_plots)
        
        if (verbose) {
          cat(sprintf("  ✓ Module provides %d plot variant(s)\n", n_plots))
        }
        
        # Create output directory for this plot type
        module_output_dir <- file.path(output_base, module_name)
        dir.create(module_output_dir, recursive = TRUE, showWarnings = FALSE)
        
        # Generate plots via module's batch interface
        if (verbose) cat(sprintf("  → Generating %d plot(s)...\n", n_plots))
        
        gen_result <- load_result$env$generate_plots_batch(
          data = data,
          plot_ids = available_plots$plot_id,
          config = list(
            output_dir = module_output_dir,
            dpi = dpi,
            verbose = FALSE
          )
        )
        
        # STEP 3: Aggregate results
        result$results[[module_name]] <- gen_result
        
        if (is.list(gen_result) && length(gen_result) > 0) {
          # Count successful plots
          successful <- sum(sapply(gen_result, function(r) {
            is.list(r) && !is.null(r$status) && r$status == "success"
          }))
          failed <- length(gen_result) - successful
          
          result$plots_generated <- result$plots_generated + successful
          result$plots_failed <- result$plots_failed + failed
          
          if (verbose) {
            cat(sprintf("  ✓ Generated: %d successful, %d failed\n",
                       successful, failed))
          }
        }
        
      }, error = function(e) {
        msg <- sprintf("Error executing module '%s': %s",
                      module_name, e$message)
        result$errors <<- c(result$errors, msg)
        
        if (verbose) cat(sprintf("  ✗ Execution error: %s\n", msg))
        
        result$modules_failed <<- result$modules_failed + 1
        if (!continue_on_error) {
          result$status <<- "failed"
        }
      })
      
    } # End module loop
    
    # STEP 4: Finalize status
    if (result$modules_failed == result$modules_found) {
      result$status <- "failed"
    } else if (result$modules_failed > 0 || result$plots_failed > 0) {
      result$status <- "partial"
    } else if (result$plots_generated == 0) {
      result$status <- "failed"
      result$errors <- c(result$errors, "No plots generated from any module")
    } else {
      result$status <- "success"
    }
    
    if (verbose) {
      cat(sprintf("\n[Phase 2.1] Summary:\n"))
      cat(sprintf("  Modules: %d discovered, %d loaded, %d failed\n",
                 result$modules_found, result$modules_loaded, result$modules_failed))
      cat(sprintf("  Plots: %d generated, %d failed\n",
                 result$plots_generated, result$plots_failed))
      cat(sprintf("  Status: %s\n", result$status))
    }
    
  }, error = function(e) {
    result$status <<- "failed"
    result$errors <<- c(result$errors, sprintf("Fatal error: %s", e$message))
    if (verbose) cat(sprintf("✗ FATAL: %s\n", e$message))
  })
  
  result$duration_secs <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  result
}

# ==============================================================================
# EOF
# ==============================================================================
