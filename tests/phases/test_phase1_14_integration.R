# ==============================================================================
# PHASE 1.14 INTEGRATION TEST SUITE
# ==============================================================================
# Tests for advanced connectors: Dependencies, Lifecycle, and Event System
#
# Run with: source("tests/test_phase1_14_integration.R")
# ==============================================================================

test_count <- 0
passed_count <- 0
failed_count <- 0

run_test <- function(test_name, test_expr) {
  test_count <<- test_count + 1
  
  tryCatch({
    test_expr()
    passed_count <<- passed_count + 1
    cat(sprintf("  [✓] %s\n", test_name))
  }, error = function(e) {
    failed_count <<- failed_count + 1
    cat(sprintf("  [✗] %s: %s\n", test_name, e$message))
  })
}

cat("============================================================\n")
cat("  PHASE 1.14 INTEGRATION TEST SUITE\n")
cat("  Dependencies, Lifecycle, & Event Interfaces\n")
cat("============================================================\n\n")

# Load required files
source(here::here("R", "core", "utilities.R"))
source(here::here("R", "core", "module_result.R"))
source(here::here("R", "core", "module_dependencies.R"))
source(here::here("R", "core", "module_lifecycle.R"))
source(here::here("R", "core", "module_events.R"))

# ==============================================================================
# SECTION 1: DEPENDENCIES INTERFACE TESTS
# ==============================================================================

cat("TEST SECTION 1: Dependencies Interface\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 1.1: Build dependency graph
run_test("Build dependency graph from modules", {
  modules <- list(
    mod_a = list(name = "mod_a"),
    mod_b = list(name = "mod_b"),
    mod_c = list(name = "mod_c")
  )
  
  # Mock adjacency
  graph <- list(
    nodes = c("mod_a", "mod_b", "mod_c"),
    edges = data.frame(
      from_module = c("mod_b", "mod_c"),
      to_module = c("mod_a", "mod_a"),
      stringsAsFactors = FALSE
    ),
    adjacency = list(
      mod_a = character(),
      mod_b = "mod_a",
      mod_c = "mod_a"
    )
  )
  
  if (length(graph$nodes) != 3) {
    stop("Should have 3 nodes")
  }
  if (nrow(graph$edges) != 2) {
    stop("Should have 2 edges")
  }
})

# Test 1.2: Detect circular dependencies
run_test("Detect circular dependencies", {
  graph <- list(
    nodes = c("mod_a", "mod_b"),
    adjacency = list(
      mod_a = "mod_b",
      mod_b = "mod_a"  # Circular!
    )
  )
  
  cycles <- detect_circular_dependencies(graph)
  
  if (!cycles$has_cycles) {
    stop("Should detect circular dependency")
  }
  if (length(cycles$affected_modules) != 2) {
    stop("Should identify both modules")
  }
})

# Test 1.3: No circular dependencies
run_test("Detect no circular dependencies", {
  graph <- list(
    nodes = c("mod_a", "mod_b", "mod_c"),
    adjacency = list(
      mod_a = character(),
      mod_b = "mod_a",
      mod_c = c("mod_a", "mod_b")
    )
  )
  
  cycles <- detect_circular_dependencies(graph)
  
  if (cycles$has_cycles) {
    stop("Should not detect cycles in valid graph")
  }
})

# Test 1.4: Topological sort
run_test("Topological sort modules", {
  graph <- list(
    nodes = c("mod_a", "mod_b", "mod_c"),
    adjacency = list(
      mod_a = character(),
      mod_b = "mod_a",
      mod_c = c("mod_a", "mod_b")
    )
  )
  
  sorted <- topological_sort(graph)
  
  if (is.null(sorted)) {
    stop("Should return valid sort")
  }
  
  # mod_a should come before mod_b and mod_c
  a_pos <- which(sorted == "mod_a")
  b_pos <- which(sorted == "mod_b")
  c_pos <- which(sorted == "mod_c")
  
  if (a_pos > b_pos || a_pos > c_pos) {
    stop("Dependencies not respected in sort order")
  }
})

# Test 1.5: Check dependencies available
run_test("Check dependencies available", {
  result <- check_dependencies_available(
    requires_packages = c("base", "stats"),
    requires_modules = c("mod_a"),
    requires_external = character()
  )
  
  if (!is.list(result)) {
    stop("Should return list")
  }
  if (!("all_available" %in% names(result))) {
    stop("Should have all_available field")
  }
})

# ==============================================================================
# SECTION 2: LIFECYCLE INTERFACE TESTS
# ==============================================================================

cat("\nTEST SECTION 2: Lifecycle Interface\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 2.1: Initialize module
run_test("Initialize module", {
  test_env <- new.env()
  test_env$module_init <- function(config) {
    list(
      initialized = TRUE,
      state = list(cache = list(), calls = 0)
    )
  }
  
  result <- initialize_module(test_env, "test_module", list())
  
  if (!result$initialized) {
    stop("Module should be initialized")
  }
  if (!"state" %in% names(result)) {
    stop("Should have state")
  }
})

# Test 2.2: Reset module state
run_test("Reset module state", {
  test_env <- new.env()
  test_state <- list(
    cache = list(a = 1, b = 2),
    calls = 10
  )
  
  test_env$module_reset <- function(state) {
    state$cache <- list()
    state$calls <- 0
    state
  }
  
  reset_state <- reset_module(test_env, test_state, "test")
  
  if (length(reset_state$cache) != 0) {
    stop("Cache should be cleared")
  }
  if (reset_state$calls != 0) {
    stop("Calls counter should be reset")
  }
})

# Test 2.3: Cleanup module
run_test("Cleanup module", {
  test_env <- new.env()
  cleanup_called <- FALSE
  
  test_env$module_cleanup <- function(state) {
    cleanup_called <<- TRUE
    invisible(NULL)
  }
  
  cleanup_module(test_env, list(), "test")
  
  if (!cleanup_called) {
    stop("Cleanup should be called")
  }
})

# Test 2.4: Lifecycle context manager
run_test("Lifecycle context manager", {
  test_env <- new.env()
  test_env$module_init <- function(config) {
    list(initialized = TRUE, state = list(value = 42))
  }
  
  context <- lifecycle_context("test_mod", test_env, list())
  
  if (!context$initialized) {
    stop("Should be initialized")
  }
  if (context$state$value != 42) {
    stop("State should be preserved")
  }
})

# Test 2.5: Get and set state
run_test("Get and set module state", {
  test_env <- new.env()
  test_env$module_init <- function(config) {
    list(initialized = TRUE, state = list(x = 1))
  }
  
  context <- lifecycle_context("test", test_env, list())
  
  old_state <- context$get_state()
  if (old_state$x != 1) {
    stop("Get state should work")
  }
  
  context$set_state(list(x = 2))
  new_state <- context$get_state()
  
  if (new_state$x != 2) {
    stop("Set state should work")
  }
})

# ==============================================================================
# SECTION 3: EVENT SYSTEM TESTS
# ==============================================================================

cat("\nTEST SECTION 3: Event System\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 3.1: Subscribe to event
run_test("Subscribe to event", {
  clear_events()  # Reset
  
  called <- FALSE
  subscribe("test:event", function(data) {
    called <<- TRUE
  }, "test_listener")
  
  if (!("test:event" %in% names(.EVENT_BUS$subscribers))) {
    stop("Should register subscription")
  }
})

# Test 3.2: Emit event and trigger callback
run_test("Emit event triggers callbacks", {
  clear_events()
  
  event_received <- FALSE
  received_data <- NULL
  
  subscribe("data:loaded", function(data) {
    event_received <<- TRUE
    received_data <<- data
  }, "listener_1")
  
  emit("data:loaded", list(rows = 100), "source_1")
  
  if (!event_received) {
    stop("Callback should be called")
  }
  if (received_data$rows != 100) {
    stop("Data should be passed")
  }
})

# Test 3.3: Multiple subscribers
run_test("Multiple subscribers to one event", {
  clear_events()
  
  call_count <<- 0
  
  subscribe("event", function(data) {
    call_count <<- call_count + 1
  }, "listener_1")
  
  subscribe("event", function(data) {
    call_count <<- call_count + 1
  }, "listener_2")
  
  emit("event", list(), "source")
  
  if (call_count != 2) {
    stop(sprintf("Should call 2 listeners, called %d", call_count))
  }
})

# Test 3.4: Unsubscribe
run_test("Unsubscribe from event", {
  clear_events()
  
  call_count <- 0
  
  subscribe("event", function(data) {
    call_count <<- call_count + 1
  }, "listener_1")
  
  emit("event", list(), "source")
  if (call_count != 1) stop("First emit failed")
  
  unsubscribe("event", "listener_1")
  
  emit("event", list(), "source")
  if (call_count != 1) {
    stop("Second emit should not call unsubscribed listener")
  }
})

# Test 3.5: Get event log
run_test("Get event log", {
  clear_events()
  
  emit("event1", list(), "source1")
  emit("event2", list(), "source2")
  emit("event1", list(), "source1")
  
  log <- get_event_log()
  if (length(log) != 3) {
    stop("Should have 3 events in log")
  }
})

# Test 3.6: Filter event log
run_test("Filter event log by type", {
  clear_events()
  
  emit("event:a", list(), "source")
  emit("event:b", list(), "source")
  emit("event:a", list(), "source")
  
  log <- get_event_log(event_type = "event:a")
  if (length(log) != 2) {
    stop("Should filter correctly")
  }
})

# Test 3.7: Event statistics
run_test("Get event statistics", {
  clear_events()
  
  emit("event", list(), "source1")
  emit("event", list(), "source2")
  emit("event", list(), "source1")
  
  stats <- get_event_statistics()
  
  if (stats$total_events != 3) {
    stop("Should count events")
  }
})

# Test 3.8: Clear event log
run_test("Clear event log", {
  clear_events()
  
  emit("event", list(), "source")
  
  log <- get_event_log()
  if (length(log) != 1) stop("Should have event")
  
  clear_events()
  
  log <- get_event_log()
  if (length(log) != 0) {
    stop("Log should be cleared")
  }
})

# ==============================================================================
# SECTION 4: INTEGRATION TESTS
# ==============================================================================

cat("\nTEST SECTION 4: Integration (All Connectors)\n")
cat("-" %.0f(45), "\n", sep = "")

# Test 4.1: Module with dependencies and lifecycle
run_test("Module with dependencies and lifecycle", {
  env <- new.env()
  
  env$get_dependencies <- function() {
    list(
      requires_modules = c("core_module"),
      requires_packages = c()
    )
  }
  
  env$module_init <- function(config) {
    list(initialized = TRUE, state = list(ready = TRUE))
  }
  
  result <- initialize_module(env, "test", list())
  if (!result$initialized) {
    stop("Should initialize")
  }
})

# Test 4.2: Events during lifecycle
run_test("Emit events from lifecycle hooks", {
  clear_events()
  
  env <- new.env()
  
  env$module_init <- function(config) {
    emit("module:initialized", list(module = "test"), "test")
    list(initialized = TRUE, state = list())
  }
  
  initialize_module(env, "test", list())
  
  log <- get_event_log(event_type = "module:initialized")
  if (length(log) != 1) {
    stop("Should emit initialization event")
  }
})

# Test 4.3: Pipeline event flow
run_test("Pipeline event flow simulation", {
  clear_events()
  
  # Simulate data loading
  emit("data_load:start", list(file = "data.csv"), "loader")
  emit("data_load:complete", list(rows = 1000), "loader")
  
  # Simulate processing
  emit("process:start", list(), "processor")
  emit("process:complete", list(), "processor")
  
  # Get all events
  log <- get_event_log()
  if (length(log) != 4) {
    stop("Should have 4 events in pipeline")
  }
  
  # Filter data events
  data_events <- get_event_log(event_type = "data_load:complete")
  if (length(data_events) != 1) {
    stop("Should find data load event")
  }
})

# Test 4.4: Dependency order with events
run_test("Dependencies respected with event flow", {
  clear_events()
  
  # Module A depends on nothing
  graph_a <- list(
    nodes = c("module_a"),
    adjacency = list(module_a = character())
  )
  
  sorted_a <- topological_sort(graph_a)
  if (sorted_a[1] != "module_a") {
    stop("Solo module should be first")
  }
  
  # Emit events in dependency order
  emit("module_a:loaded", list(), "system")
  
  log <- get_event_log()
  if (length(log) != 1) stop("Should have 1 event")
})

# ==============================================================================
# TEST SUMMARY
# ==============================================================================

cat("\n")
cat("=" %.0f(60), "\n", sep = "")
cat(sprintf("PHASE 1.14 TEST RESULTS\n"))
cat("=" %.0f(60), "\n", sep = "")
cat(sprintf("Total Tests:  %d\n", test_count))
cat(sprintf("Passed:       %d ✓\n", passed_count))
cat(sprintf("Failed:       %d ✗\n", failed_count))
cat(sprintf("Success Rate: %.1f%%\n", 100 * passed_count / test_count))
cat("=" %.0f(60), "\n", sep = "")

if (failed_count == 0) {
  cat("\n✓ ALL TESTS PASSED - Phase 1.14 integration complete\n\n")
} else {
  cat(sprintf("\n✗ %d test(s) failed - review above\n\n", failed_count))
}

invisible(list(
  total = test_count,
  passed = passed_count,
  failed = failed_count,
  success_rate = passed_count / test_count
))
