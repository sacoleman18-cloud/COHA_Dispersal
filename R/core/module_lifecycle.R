# ============================================================================
# LIFECYCLE INTERFACE - Connector #6
# ============================================================================
# Purpose: Lifecycle management - initialization, reset, cleanup
#
# Enables modules to manage state across multiple runs. Modules can:
# - Initialize once (allocate resources, open connections)
# - Reset state between runs (clear caches, reset counters)
# - Cleanup when done (close connections, free resources)
#
# Part of the LEGO-like modular architecture system.
# ============================================================================

# ============================================================================
# SECTION 1: Lifecycle Hook Declarations
# ============================================================================

#' Module Initialization Hook
#'
#' Called once when module first loads. Intended to be implemented in modules.
#'
#' @param config Configuration list for this module
#'
#' @return List with:
#'   - initialized: logical
#'   - state: list with module state
#'
#' @examples
#' module_init <- function(config) {
#'   list(
#'     initialized = TRUE,
#'     state = list(
#'       db_connection = NULL,
#'       cache = list(),
#'       initialized_at = Sys.time()
#'     )
#'   )
#' }
module_init <- function(config = list()) {
  list(
    initialized = TRUE,
    state = list()
  )
}

#' Module Reset Hook
#'
#' Called between runs to reset module state (clear caches, reset counters).
#' Intended to be implemented in modules.
#'
#' @param state Module state from initialization
#'
#' @return Updated state list after reset
module_reset <- function(state = list()) {
  # Override in actual modules
  state
}

#' Module Cleanup Hook
#'
#' Called when module is done (cleanup connections, free resources).
#' Intended to be implemented in modules.
#'
#' @param state Module state
#'
#' @return NULL (invisible)
module_cleanup <- function(state = list()) {
  # Override in actual modules
  invisible(NULL)
}

# ============================================================================
# SECTION 2: Lifecycle Management
# ============================================================================

#' Initialize a Module
#'
#' Calls the module's initialization hook and stores state.
#'
#' @param module_env Module environment (containing module_init function)
#' @param module_name Name of module (for logging)
#' @param config Configuration for this module
#'
#' @return List:
#'   - module_name: Name of module
#'   - initialized: Logical success indicator
#'   - state: Module state from init
#'   - init_time: When initialized
initialize_module <- function(
  module_env,
  module_name = NA_character_,
  config = list()
) {
  
  init_time <- Sys.time()
  
  result <- list(
    module_name = module_name %||% "unknown",
    initialized = FALSE,
    state = list(),
    init_time = init_time,
    error = NULL
  )
  
  # Check if module has init hook
  if (!exists("module_init", where = module_env, mode = "function")) {
    return(result)  # No init needed
  }
  
  # Call init hook
  tryCatch({
    init_result <- module_env$module_init(config)
    
    result$initialized <- init_result$initialized %||% FALSE
    result$state <- init_result$state %||% list()
    
  }, error = function(e) {
    result$initialized <<- FALSE
    result$error <<- e$message
  })
  
  cat(sprintf(
    "[LIFECYCLE] %s: Initialized (state size: %d bytes)\n",
    result$module_name,
    object.size(result$state)
  ))
  
  result
}

#' Reset a Module
#'
#' Calls the module's reset hook to clear state between runs.
#'
#' @param module_env Module environment
#' @param module_state Current module state
#' @param module_name Name of module (for logging)
#'
#' @return Updated module state
reset_module <- function(
  module_env,
  module_state = list(),
  module_name = NA_character_
) {
  
  if (!exists("module_reset", where = module_env, mode = "function")) {
    return(module_state)  # No reset needed
  }
  
  tryCatch({
    updated_state <- module_env$module_reset(module_state)
    
    cat(sprintf(
      "[LIFECYCLE] %s: Reset (cleared %d items)\n",
      module_name %||% "unknown",
      length(module_state) - length(updated_state)
    ))
    
    return(updated_state)
    
  }, error = function(e) {
    warning(sprintf("Error resetting %s: %s", module_name, e$message))
    return(module_state)
  })
}

#' Cleanup a Module
#'
#' Calls the module's cleanup hook to free resources.
#'
#' @param module_env Module environment
#' @param module_state Current module state
#' @param module_name Name of module (for logging)
#'
#' @return Invisible NULL
cleanup_module <- function(
  module_env,
  module_state = list(),
  module_name = NA_character_
) {
  
  if (!exists("module_cleanup", where = module_env, mode = "function")) {
    return(invisible(NULL))  # No cleanup needed
  }
  
  tryCatch({
    module_env$module_cleanup(module_state)
    
    cat(sprintf(
      "[LIFECYCLE] %s: Cleanup complete\n",
      module_name %||% "unknown"
    ))
    
  }, error = function(e) {
    warning(sprintf("Error cleaning up %s: %s", module_name, e$message))
  })
  
  invisible(NULL)
}

# ============================================================================
# SECTION 3: Batch Lifecycle Management
# ============================================================================

#' Initialize Multiple Modules
#'
#' Initialize group of modules with their configs
#'
#' @param module_names Character vector of module names
#' @param module_envs Named list of module environments
#' @param config List of configs (by module name)
#'
#' @return Invisible list of initialization results
initialize_modules <- function(
  module_names = character(),
  module_envs = list(),
  config = list()
) {
  
  results <- list()
  
  for (mod_name in module_names) {
    mod_env <- module_envs[[mod_name]]
    mod_config <- config[[mod_name]] %||% list()
    
    result <- initialize_module(mod_env, mod_name, mod_config)
    results[[mod_name]] <- result
  }
  
  cat(sprintf(
    "[LIFECYCLE] Initialized %d module(s)\n",
    sum(sapply(results, \(r) r$initialized))
  ))
  
  invisible(results)
}

#' Reset Multiple Modules
#'
#' Reset group of modules between runs
#'
#' @param modules Named list of module states
#' @param module_envs Named list of module environments
#'
#' @return Invisible updated module states
reset_modules <- function(
  modules = list(),
  module_envs = list()
) {
  
  for (mod_name in names(modules)) {
    mod_env <- module_envs[[mod_name]]
    mod_state <- modules[[mod_name]]$state
    
    modules[[mod_name]]$state <<- reset_module(
      mod_env,
      mod_state,
      mod_name
    )
  }
  
  invisible(modules)
}

#' Cleanup Multiple Modules
#'
#' Cleanup group of modules after work complete
#'
#' @param modules Named list of module states
#' @param module_envs Named list of module environments
#'
#' @return Invisible NULL
cleanup_modules <- function(
  modules = list(),
  module_envs = list()
) {
  
  for (mod_name in names(modules)) {
    mod_env <- module_envs[[mod_name]]
    mod_state <- modules[[mod_name]]$state
    
    cleanup_module(mod_env, mod_state, mod_name)
  }
  
  invisible(NULL)
}

# ============================================================================
# SECTION 4: Lifecycle Context Manager
# ============================================================================

#' Create Lifecycle Context
#'
#' Manage module lifecycle as context (init on entry, cleanup on exit)
#'
#' @param module_name Name of module
#' @param module_env Module environment
#' @param config Module config
#'
#' @return List representing lifecycle context:
#'   - module_name: Name
#'   - module_env: Environment
#'   - state: Current state
#'   - initialized: Logical
lifecycle_context <- function(
  module_name,
  module_env,
  config = list()
) {
  
  # Initialize on context creation
  init_result <- initialize_module(module_env, module_name, config)
  
  list(
    module_name = module_name,
    module_env = module_env,
    state = init_result$state,
    initialized = init_result$initialized,
    created_at = Sys.time(),
    
    # Methods
    reset = function() {
      state <<- reset_module(module_env, state, module_name)
      invisible(state)
    },
    
    cleanup = function() {
      cleanup_module(module_env, state, module_name)
      invisible(NULL)
    },
    
    get_state = function() {
      state
    },
    
    set_state = function(new_state) {
      state <<- new_state
      invisible(state)
    }
  )
}

# ============================================================================
# SECTION 5: State Inspection & Reporting
# ============================================================================

#' Inspect Module State
#'
#' Get detailed information about module state
#'
#' @param state Module state list
#' @param module_name Name of module (for logging)
#'
#' @return Invisible list with state inspection
inspect_module_state <- function(
  state = list(),
  module_name = NA_character_
) {
  
  cat(sprintf(
    "\n[STATE] Module: %s\n",
    module_name %||% "unknown"
  ))
  cat(rep("=", 50), sep = "")
  cat("\n")
  
  if (length(state) == 0) {
    cat("(empty state)\n")
  } else {
    for (name in names(state)) {
      item <- state[[name]]
      
      if (is.null(item)) {
        cat(sprintf("  %s: NULL\n", name))
      } else if (is.list(item)) {
        cat(sprintf("  %s: list(%d items)\n", name, length(item)))
      } else if (is.data.frame(item)) {
        cat(sprintf("  %s: data.frame(%d x %d)\n", name, nrow(item), ncol(item)))
      } else if (is.vector(item)) {
        cat(sprintf("  %s: %s[%d]\n", name, class(item)[1], length(item)))
      } else {
        cat(sprintf("  %s: %s\n", name, class(item)[1]))
      }
    }
  }
  
  cat(sprintf(
    "  Size: %s\n",
    format(object.size(state), units = "auto")
  ))
  cat(rep("=", 50), sep = "")
  cat("\n\n")
  
  invisible(list(
    module_name = module_name,
    state_size = object.size(state),
    n_items = length(state),
    item_types = sapply(state, class)
  ))
}

#' Print Lifecycle Status
#'
#' Display lifecycle status of module(s)
#'
#' @param modules Named list of module lifecycle data
#'
#' @return Invisible NULL (prints to console)
print_lifecycle_status <- function(modules = list()) {
  
  cat("\n")
  cat(rep("=", 60), sep = "")
  cat("\nLIFECYCLE STATUS REPORT\n")
  cat(rep("=", 60), sep = "")
  cat("\n")
  
  if (length(modules) == 0) {
    cat("(no modules loaded)\n")
  } else {
    for (mod_name in names(modules)) {
      mod <- modules[[mod_name]]
      
      status_symbol <- if (mod$initialized) "✓" else "✗"
      init_time_str <- if (!is.null(mod$init_time)) {
        format(mod$init_time, "%H:%M:%S")
      } else {
        "N/A"
      }
      
      state_size <- if (!is.null(mod$state)) {
        format(object.size(mod$state), units = "auto")
      } else {
        "0 B"
      }
      
      cat(sprintf(
        "%s %s: state=%s, init=%s\n",
        status_symbol,
        mod_name,
        state_size,
        init_time_str
      ))
    }
  }
  
  cat(rep("=", 60), sep = "")
  cat("\n\n")
  
  invisible(NULL)
}

# ============================================================================
# SECTION 6: Lifecycle Hooks Template
# ============================================================================

#' Example: Lifecycle Hooks Template
#'
#' Template showing how to implement lifecycle hooks in a module.
#' Copy and adapt for real modules.
#'
#' Module developers should implement these three functions:
#'
#' @examples
#' # In your module file (e.g., R/core/my_module.R):
#'
#' # Hook 1: Initialization (called once, sets up state)
#' my_module_init <- function(config) {
#'   cat("[my_module] Initializing...\n")
#'   
#'   list(
#'     initialized = TRUE,
#'     state = list(
#'       cache = list(),                    # Cache for results
#'       connection = NULL,                 # DB connection
#'       counters = list(calls = 0),       # Usage counters
#'       config = config                    # Save config
#'     )
#'   )
#' }
#'
#' # Hook 2: Reset (clear state between runs)
#' my_module_reset <- function(state) {
#'   cat("[my_module] Resetting state...\n")
#'   
#'   state$cache <<- list()
#'   state$counters$calls <<- 0
#'   
#'   state
#' }
#'
#' # Hook 3: Cleanup (free resources when done)
#' my_module_cleanup <- function(state) {
#'   cat("[my_module] Cleaning up...\n")
#'   
#'   if (!is.null(state$connection)) {
#'     # close(state$connection)
#'   }
#'   
#'   invisible(NULL)
#' }
#'
#' # In your module's main functions, use state like:
#' do_work <- function(data) {
#'   # Access state - in real module, maintain pointer to state
#'   my_state$counters$calls <- my_state$counters$calls + 1
#'   
#'   # Check cache
#'   cache_key <- digest::digest(data)
#'   if (cache_key %in% names(my_state$cache)) {
#'     return(my_state$cache[[cache_key]])
#'   }
#'   
#'   # Do work...
#'   result <- expensive_computation(data)
#'   
#'   # Cache result
#'   my_state$cache[[cache_key]] <- result
#'   
#'   result
#' }
lifecycle_hooks_template <- function() {
  cat("Use the @examples section of this function as template\n")
}

# ============================================================================
# END: LIFECYCLE INTERFACE
# ============================================================================
