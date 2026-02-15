# ============================================================================
# DEPENDENCIES INTERFACE - Connector #5
# ============================================================================
# Purpose: Dependency declaration and resolution
#
# Enables modules to declare what they depend on (other modules, packages,
# external tools) and automatically resolves loading order. Prevents silent
# failures from missing dependencies and circular dependency detection.
#
# Part of the LEGO-like modular architecture system.
# ============================================================================

# ============================================================================
# SECTION 1: Dependency Declaration
# ============================================================================

#' Get Module Dependencies
#'
#' Default implementation (intended to be overridden in modules).
#' Each module should define this to declare its dependencies.
#'
#' @return List with:
#'   - module_name: Name of this module
#'   - version: Module version
#'   - requires_modules: Character vector of module IDs this module needs
#'   - requires_packages: Character vector of R package names
#'   - requires_external: Character vector of external tools (quarto, git, etc)
#'   - depended_by: Character vector of modules that depend on this one
#'
#' @examples
#' get_module_dependencies <- function() {
#'   list(
#'     module_name = "data_loader",
#'     version = "1.0.0",
#'     requires_modules = c("logging", "assertions"),
#'     requires_packages = c("readr", "dplyr"),
#'     requires_external = c(),
#'     depended_by = c("analyzer", "plotter")
#'   )
#' }
module_get_dependencies <- function() {
  list(
    module_name = "unknown",
    version = "1.0.0",
    requires_modules = character(),
    requires_packages = character(),
    requires_external = character(),
    depended_by = character()
  )
}

# ============================================================================
# SECTION 2: Dependency Graph Management
# ============================================================================

#' Build Dependency Graph from Modules
#'
#' Analyzes all provided modules and constructs a directed acyclic graph
#' (DAG) of their dependencies.
#'
#' @param modules List of module environments or module info lists
#' @param module_names Character vector of module IDs to analyze
#'
#' @return List representing dependency graph:
#'   - nodes: character vector of all module names
#'   - edges: data frame with columns from_module, to_module
#'   - adjacency: named list, each element is modules it depends on
build_dependency_graph <- function(modules, module_names = NULL) {
  
  if (is.null(module_names)) {
    module_names <- names(modules)
  }
  
  adjacency <- list()
  edges <- data.frame(
    from_module = character(),
    to_module = character(),
    stringsAsFactors = FALSE
  )
  
  # Build adjacency list
  for (mod_name in module_names) {
    
    # Get module dependencies
    deps <- tryCatch({
      if (is.environment(modules[[mod_name]])) {
        modules[[mod_name]]$get_dependencies()
      } else if (is.list(modules[[mod_name]])) {
        modules[[mod_name]]$dependencies
      } else {
        character()
      }
    }, error = function(e) character())
    
    # Get required modules
    required_mods <- if (is.list(deps)) {
      deps$requires_modules %||% character()
    } else {
      character()
    }
    
    adjacency[[mod_name]] <- required_mods
    
    # Add edges
    for (dep in required_mods) {
      edges <- rbind(edges, data.frame(
        from_module = mod_name,
        to_module = dep,
        stringsAsFactors = FALSE
      ))
    }
  }
  
  list(
    nodes = module_names,
    edges = edges,
    adjacency = adjacency
  )
}

#' Detect Circular Dependencies
#'
#' Checks if dependency graph contains any cycles (circular dependencies).
#' Returns information about cycles if found.
#'
#' @param graph Dependency graph from build_dependency_graph()
#'
#' @return List:
#'   - has_cycles: Logical
#'   - cycles: List of circular paths found (empty if no cycles)
#'   - affected_modules: Modules involved in cycles
detect_circular_dependencies <- function(graph) {
  
  cycles <- list()
  visited <- set_new()
  rec_stack <- set_new()
  
  # Helper: DFS to detect cycles
  dfs_visit <- function(node, path = character()) {
    
    visited <<- set_add(visited, node)
    rec_stack <<- set_add(rec_stack, node)
    path <- c(path, node)
    
    # Get dependencies of this node
    dependencies <- graph$adjacency[[node]] %||% character()
    
    for (dep in dependencies) {
      if (!(dep %in% visited)) {
        # Not visited - recurse
        dfs_visit(dep, path)
      } else if (dep %in% rec_stack) {
        # Back edge - found cycle!
        cycle_start <- which(path == dep)
        cycle <- path[cycle_start:length(path)]
        cycles[[length(cycles) + 1]] <<- c(cycle, dep)
      }
    }
    
    rec_stack <<- set_remove(rec_stack, node)
  }
  
  # Check all nodes
  for (node in graph$nodes) {
    if (!(node %in% visited)) {
      dfs_visit(node)
    }
  }
  
  list(
    has_cycles = length(cycles) > 0,
    cycles = cycles,
    affected_modules = unique(unlist(cycles))
  )
}

# ============================================================================
# SECTION 3: Topological Sorting
# ============================================================================

#' Topologically Sort Modules
#'
#' Sorts modules in order respecting dependencies using Kahn's algorithm.
#' Modules with no dependencies come first, then modules depending only on
#' earlier modules, etc.
#'
#' @param graph Dependency graph from build_dependency_graph()
#'
#' @return Character vector of sorted module names (in load order)
#'   OR NULL if circular dependency detected
topological_sort <- function(graph) {
  
  # Check for circular dependencies first
  cycles <- detect_circular_dependencies(graph)
  if (cycles$has_cycles) {
    warning(sprintf(
      "Circular dependency detected: %s",
      paste(cycles$affected_modules, collapse = " -> ")
    ))
    return(NULL)
  }
  
  # Kahn's algorithm
  # Count in-degree (dependencies) for each module
  in_degree <- rep(0, length(graph$nodes))
  names(in_degree) <- graph$nodes
  
  for (node in graph$nodes) {
    dependencies <- graph$adjacency[[node]] %||% character()
    in_degree[node] <- length(dependencies)
  }
  
  # Queue of nodes with no dependencies
  queue <- names(in_degree[in_degree == 0])
  sorted <- character()
  
  while (length(queue) > 0) {
    # Take first node from queue
    node <- queue[1]
    queue <- queue[-1]
    sorted <- c(sorted, node)
    
    # Find modules that depend on this one
    # (reverse of adjacency - find who depends on 'node')
    dependents <- character()
    for (mod in graph$nodes) {
      if (node %in% (graph$adjacency[[mod]] %||% character())) {
        dependents <- c(dependents, mod)
      }
    }
    
    # Reduce in-degree for dependents
    for (dep in dependents) {
      in_degree[dep] <- in_degree[dep] - 1
      
      if (in_degree[dep] == 0) {
        queue <- c(queue, dep)
      }
    }
  }
  
  if (length(sorted) != length(graph$nodes)) {
    warning("Could not sort all modules (circular dependency or other issue)")
    return(NULL)
  }
  
  sorted
}

# ============================================================================
# SECTION 4: Dependency Checking
# ============================================================================

#' Check Module Dependencies Available
#'
#' Verifies that all declared dependencies are available/installed.
#'
#' @param requires_packages Character vector of package names
#' @param requires_modules Character vector of module IDs
#' @param requires_external Character vector of external tool names
#'
#' @return List:
#'   - all_available: Logical - all dependencies found
#'   - packages: status of each package
#'   - modules: status of each module
#'   - external: status of each tool
check_dependencies_available <- function(
  requires_packages = character(),
  requires_modules = character(),
  requires_external = character()
) {
  
  result <- list(
    all_available = TRUE,
    packages = list(),
    modules = list(),
    external = list()
  )
  
  # Check R packages
  for (pkg in requires_packages) {
    installed <- requireNamespace(pkg, quietly = TRUE)
    result$packages[[pkg]] <- list(
      name = pkg,
      available = installed,
      status = if (installed) "✓" else "✗ Not installed"
    )
    if (!installed) result$all_available <- FALSE
  }
  
  # Check modules (would need module registry)
  for (mod in requires_modules) {
    # Placeholder - in real implementation, check module registry
    result$modules[[mod]] <- list(
      name = mod,
      available = TRUE,  # Assume available for now
      status = "✓ Assumed available"
    )
  }
  
  # Check external tools
  for (tool in requires_external) {
    available <- check_external_tool_available(tool)
    result$external[[tool]] <- list(
      name = tool,
      available = available,
      status = if (available) "✓ Found" else "✗ Not found"
    )
    if (!available) result$all_available <- FALSE
  }
  
  result
}

#' Check if External Tool is Available
#'
#' @param tool Tool name (quarto, git, etc)
#'
#' @return Logical - TRUE if tool found in PATH
check_external_tool_available <- function(tool) {
  
  # Try to find tool in PATH
  result <- tryCatch({
    if (.Platform$OS.type == "windows") {
      system(sprintf("where %s", tool), show.output.on.console = FALSE)
    } else {
      system(sprintf("which %s", tool), show.output.on.console = FALSE)
    }
  }, error = function(e) 127)
  
  result == 0
}

# ============================================================================
# SECTION 5: Auto-Loading with Dependencies
# ============================================================================

#' Load Modules in Dependency Order
#'
#' Automatically sources modules in correct order based on dependencies.
#'
#' @param module_names Character vector of module IDs to load
#' @param module_dir Directory containing module files
#'
#' @return List of module info (invisible)
load_modules_auto <- function(
  module_names,
  module_dir = here::here("R", "core")
) {
  
  # Build graph
  modules <- list()
  for (mod_name in module_names) {
    modules[[mod_name]] <- list(name = mod_name)
  }
  
  graph <- build_dependency_graph(modules, module_names)
  
  # Check for cycles
  cycles <- detect_circular_dependencies(graph)
  if (cycles$has_cycles) {
    stop(sprintf(
      "Cannot load modules - circular dependency: %s",
      paste(cycles$affected_modules, collapse = " -> ")
    ))
  }
  
  # Topological sort
  sorted_order <- topological_sort(graph)
  
  if (is.null(sorted_order)) {
    stop("Cannot determine module load order")
  }
  
  # Load in order
  loaded <- list()
  for (mod_name in sorted_order) {
    file_path <- file.path(module_dir, paste0(mod_name, ".R"))
    
    if (!file.exists(file_path)) {
      warning(sprintf("Module file not found: %s", file_path))
      next
    }
    
    tryCatch({
      source(file_path, local = FALSE)
      loaded[[mod_name]] <- list(
        name = mod_name,
        loaded = TRUE,
        path = file_path
      )
      cat(sprintf("Loaded: %s\n", mod_name))
    }, error = function(e) {
      warning(sprintf("Error loading %s: %s", mod_name, e$message))
      loaded[[mod_name]] <<- list(
        name = mod_name,
        loaded = FALSE,
        error = e$message
      )
    })
  }
  
  invisible(list(
    load_order = sorted_order,
    loaded = loaded,
    graph = graph
  ))
}

# ============================================================================
# SECTION 6: Dependency Visualization & Reporting
# ============================================================================

#' Print Dependency Information
#'
#' Display dependency information in human-readable format
#'
#' @param graph Dependency graph from build_dependency_graph()
#'
#' @return Invisible NULL (prints to console)
print_dependency_graph <- function(graph) {
  
  cat(rep("=", 60), sep = "")
  cat("\nDEPENDENCY GRAPH\n")
  cat(rep("=", 60), sep = "")
  cat("\n")
  
  for (node in graph$nodes) {
    dependencies <- graph$adjacency[[node]]
    
    if (length(dependencies) == 0) {
      cat(sprintf("%s (no dependencies)\n", node))
    } else {
      cat(sprintf("%s requires: %s\n", node, paste(dependencies, collapse = ", ")))
    }
  }
  
  # Check for cycles
  cycles <- detect_circular_dependencies(graph)
  if (cycles$has_cycles) {
    cat("\n⚠ CIRCULAR DEPENDENCIES DETECTED:\n")
    for (i in seq_along(cycles$cycles)) {
      cat(sprintf("  Cycle %d: %s\n", i, paste(cycles$cycles[[i]], collapse = " -> ")))
    }
  } else {
    cat("\n✓ No circular dependencies\n")
  }
  
  # Try to sort
  sorted <- topological_sort(graph)
  if (!is.null(sorted)) {
    cat("\nLoad Order:\n")
    for (i in seq_along(sorted)) {
      cat(sprintf("  %d. %s\n", i, sorted[i]))
    }
  }
  
  cat(rep("=", 60), sep = "")
  cat("\n\n")
  
  invisible(NULL)
}

#' Generate Dependency Report
#'
#' Create comprehensive report of module dependencies
#'
#' @param graph Dependency graph
#'
#' @return Data frame with dependency information
generate_dependency_report <- function(graph) {
  
  report <- data.frame(
    module = character(),
    dependencies = character(),
    dependents = character(),
    can_load = logical(),
    stringsAsFactors = FALSE
  )
  
  for (node in graph$nodes) {
    dependencies <- paste(graph$adjacency[[node]], collapse = ", ")
    
    # Find dependents
    dependents <- character()
    for (other in graph$nodes) {
      if (node %in% (graph$adjacency[[other]] %||% character())) {
        dependents <- c(dependents, other)
      }
    }
    dependents_str <- paste(dependents, collapse = ", ")
    
    # Can load if dependencies are available
    can_load <- all(graph$adjacency[[node]] %in% graph$nodes)
    
    report <- rbind(report, data.frame(
      module = node,
      dependencies = dependencies,
      dependents = dependents_str,
      can_load = can_load,
      stringsAsFactors = FALSE
    ))
  }
  
  report
}

# ============================================================================
# SECTION 7: Helper Functions
# ============================================================================

# Simple set operations for cycle detection
set_new <- function() character()
set_add <- function(s, x) unique(c(s, x))
set_remove <- function(s, x) setdiff(s, x)
set_contains <- function(s, x) x %in% s

# ============================================================================
# END: DEPENDENCIES INTERFACE
# ============================================================================
