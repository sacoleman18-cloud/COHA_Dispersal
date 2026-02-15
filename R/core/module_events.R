# ============================================================================
# EVENT SYSTEM - Connector #7
# ============================================================================
# Purpose: Pub/sub inter-module communication
#
# Enables modules to broadcast events and react to events from other modules
# without direct coupling. Modules emit events at key pipeline points
# (data loaded, plot generated, etc) and other modules can subscribe to react.
#
# Part of the LEGO-like modular architecture system.
# ============================================================================

# ============================================================================
# SECTION 1: Global Event Bus Setup
# ============================================================================

# Global event bus environment (persists across calls)
.EVENT_BUS <- new.env()
.EVENT_BUS$subscribers <- list()  # event_type -> list(callback_1, callback_2, ...)
.EVENT_BUS$events_log <- list()   # All events that have been emitted
.EVENT_BUS$event_count <- 0       # Total events emitted

# ============================================================================
# SECTION 2: Event Subscription
# ============================================================================

#' Subscribe to an Event Type
#'
#' Register a callback function to be called when a specific event is emitted.
#'
#' @param event_type Type of event to subscribe to (e.g., "data_load:complete")
#' @param callback Function to call when event occurs. Receives event_data as param.
#' @param listener_name Optional name for this listener (for unsubscribe)
#'
#' @return Invisible NULL
#'
#' @examples
#' subscribe("data_load:complete", function(event_data) {
#'   cat(sprintf("Data loaded: %d rows\n", nrow(event_data$data))
#' }, listener_name = "my_listener")
subscribe <- function(
  event_type,
  callback,
  listener_name = "anonymous"
) {
  
  if (!is.function(callback)) {
    stop("callback must be a function")
  }
  
  # Create event type list if doesn't exist
  if (!(event_type %in% names(.EVENT_BUS$subscribers))) {
    .EVENT_BUS$subscribers[[event_type]] <- list()
  }
  
  # Add callback
  .EVENT_BUS$subscribers[[event_type]][[listener_name]] <- callback
  
  cat(sprintf(
    "[EventBus] %s subscribed to \"%s\"\n",
    listener_name, event_type
  ))
  
  invisible(NULL)
}

#' Unsubscribe from an Event Type
#'
#' Remove a listener from an event
#'
#' @param event_type Type of event
#' @param listener_name Name of listener to remove
#'
#' @return Invisible NULL
unsubscribe <- function(
  event_type,
  listener_name
) {
  
  if (event_type %in% names(.EVENT_BUS$subscribers)) {
    .EVENT_BUS$subscribers[[event_type]][[listener_name]] <- NULL
    
    cat(sprintf(
      "[EventBus] %s unsubscribed from \"%s\"\n",
      listener_name, event_type
    ))
  }
  
  invisible(NULL)
}

#' List Active Subscriptions
#'
#' Display all event subscriptions
#'
#' @return Invisible data frame of subscriptions
list_subscriptions <- function() {
  
  subs_df <- data.frame(
    event_type = character(),
    listener_name = character(),
    listener_count = integer(),
    stringsAsFactors = FALSE
  )
  
  for (event_type in names(.EVENT_BUS$subscribers)) {
    listeners <- .EVENT_BUS$subscribers[[event_type]]
    
    for (listener_name in names(listeners)) {
      if (!is.null(listeners[[listener_name]])) {
        subs_df <- rbind(subs_df, data.frame(
          event_type = event_type,
          listener_name = listener_name,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  
  cat("Active Event Subscriptions:\n")
  print(subs_df, row.names = FALSE)
  cat("\n")
  
  invisible(subs_df)
}

# ============================================================================
# SECTION 3: Event Emission
# ============================================================================

#' Emit an Event to All Subscribers
#'
#' Broadcast an event - calls all registered callbacks for that event type
#'
#' @param event_type Type of event being emitted
#' @param event_data Data to pass to callbacks
#' @param source_module Module emitting the event
#'
#' @return Invisible NULL
#'
#' @examples
#' emit("data_load:complete", 
#'      list(data = my_data, rows = nrow(my_data)),
#'      source_module = "data_loader")
emit <- function(
  event_type,
  event_data = list(),
  source_module = "unknown"
) {
  
  .EVENT_BUS$event_count <- .EVENT_BUS$event_count + 1
  
  # Record in log
  event_record <- list(
    id = .EVENT_BUS$event_count,
    type = event_type,
    source = source_module,
    timestamp = Sys.time(),
    data = event_data
  )
  .EVENT_BUS$events_log <- c(.EVENT_BUS$events_log, list(event_record))
  
  # Get subscribers for this event type
  if (!(event_type %in% names(.EVENT_BUS$subscribers))) {
    # No subscribers
    return(invisible(NULL))
  }
  
  subscribers <- .EVENT_BUS$subscribers[[event_type]]
  n_called <- 0
  
  # Call each subscriber
  for (listener_name in names(subscribers)) {
    callback <- subscribers[[listener_name]]
    
    if (is.null(callback)) next
    
    tryCatch({
      callback(event_data)
      n_called <- n_called + 1
      
    }, error = function(e) {
      warning(sprintf(
        "[EventBus] Error in %s handling %s: %s",
        listener_name, event_type, e$message
      ))
    })
  }
  
  cat(sprintf(
    "[EventBus] Emitted \"%s\" from %s, %d listener(s) notified\n",
    event_type, source_module, n_called
  ))
  
  invisible(NULL)
}

#' Emit Async Event
#'
#' Emit event but don't wait for callbacks (fire and forget)
#'
#' @param event_type Type of event
#' @param event_data Data for event
#' @param source_module Source module
#'
#' @return Invisible NULL (event logged asynchronously)
emit_async <- function(
  event_type,
  event_data = list(),
  source_module = "unknown"
) {
  
  # In real implementation, would use background job
  # For now, just call emit immediately
  emit(event_type, event_data, source_module)
}

# ============================================================================
# SECTION 4: Event Log Management
# ============================================================================

#' Get Event Log
#'
#' Retrieve events from the log, optionally filtered
#'
#' @param event_type Optional: filter by event type
#' @param source_module Optional: filter by source module
#' @param since Optional: only events after this time
#' @param limit Optional: max number of events to return
#'
#' @return List of event records matching criteria
get_event_log <- function(
  event_type = NULL,
  source_module = NULL,
  since = NULL,
  limit = NULL
) {
  
  log <- .EVENT_BUS$events_log
  
  # Filter by event type
  if (!is.null(event_type)) {
    log <- Filter(function(e) e$type == event_type, log)
  }
  
  # Filter by source module
  if (!is.null(source_module)) {
    log <- Filter(function(e) e$source == source_module, log)
  }
  
  # Filter by timestamp
  if (!is.null(since)) {
    log <- Filter(function(e) e$timestamp >= since, log)
  }
  
  # Limit results
  if (!is.null(limit) && length(log) > limit) {
    log <- utils::tail(log, limit)
  }
  
  log
}

#' Clear Event Log
#'
#' Reset event log and subscription list
#'
#' @return Invisible NULL
clear_events <- function() {
  .EVENT_BUS$events_log <<- list()
  .EVENT_BUS$event_count <<- 0
  
  cat("[EventBus] Event log cleared\n")
  invisible(NULL)
}

#' Get Event Statistics
#'
#' Get statistics about events
#'
#' @return List with:
#'   - total_events: Total emitted
#'   - events_by_type: Table of counts by type
#'   - events_by_source: Table of counts by source
get_event_statistics <- function() {
  
  log <- .EVENT_BUS$events_log
  
  if (length(log) == 0) {
    return(list(
      total_events = 0,
      events_by_type = integer(),
      events_by_source = integer()
    ))
  }
  
  event_types <- sapply(log, \(e) e$type)
  event_sources <- sapply(log, \(e) e$source)
  
  list(
    total_events = length(log),
    events_by_type = table(event_types),
    events_by_source = table(event_sources),
    first_event = log[[1]]$timestamp,
    last_event = log[[length(log)]]$timestamp
  )
}

# ============================================================================
# SECTION 5: Event Querying & Analysis
# ============================================================================

#' Print Event Log
#'
#' Display event log in human-readable format
#'
#' @param n Number of events to show (NULL for all)
#' @param event_type Optional filter by event type
#'
#' @return Invisible NULL (prints to console)
print_event_log <- function(
  n = NULL,
  event_type = NULL
) {
  
  log <- .EVENT_BUS$events_log
  
  if (length(log) == 0) {
    cat("(Event log is empty)\n")
    return(invisible(NULL))
  }
  
  # Filter
  if (!is.null(event_type)) {
    log <- Filter(function(e) e$type == event_type, log)
  }
  
  # Limit
  if (!is.null(n) && length(log) > n) {
    log <- utils::tail(log, n)
  }
  
  cat("\n")
  cat(rep("=", 80), sep = "")
  cat("\nEVENT LOG\n")
  cat(rep("=", 80), sep = "")
  cat("\n")
  
  for (i in seq_along(log)) {
    event <- log[[i]]
    
    cat(sprintf(
      "[%d] %s - %s -> %s\n",
      event$id,
      format(event$timestamp, "%H:%M:%S.%OS2"),
      event$source,
      event$type
    ))
  }
  
  cat(rep("=", 80), sep = "")
  cat("\n\n")
  
  invisible(NULL)
}

#' Print Event Statistics
#'
#' Display statistics about events
#'
#' @return Invisible NULL (prints to console)
print_event_statistics <- function() {
  
  stats <- get_event_statistics()
  
  cat("\n")
  cat(rep("=", 60), sep = "")
  cat("\nEVENT STATISTICS\n")
  cat(rep("=", 60), sep = "")
  cat("\n")
  
  cat(sprintf("Total Events: %d\n", stats$total_events))
  
  if (stats$total_events > 0) {
    cat(sprintf(
      "Time Span: %s to %s\n",
      format(stats$first_event, "%H:%M:%S"),
      format(stats$last_event, "%H:%M:%S")
    ))
    
    cat("\nEvents by Type:\n")
    for (type in names(stats$events_by_type)) {
      cat(sprintf("  %s: %d\n", type, stats$events_by_type[[type]]))
    }
    
    cat("\nEvents by Source:\n")
    for (source in names(stats$events_by_source)) {
      cat(sprintf("  %s: %d\n", source, stats$events_by_source[[source]]))
    }
  }
  
  cat(rep("=", 60), sep = "")
  cat("\n\n")
  
  invisible(NULL)
}

# ============================================================================
# SECTION 6: Common Event Types
# ============================================================================

#' Standard Event Types for COHA Pipeline
#'
#' Documented event types that can be emitted/subscribed to
#'
#' Data Loading Events:
#'   - "data_load:start" - Before loading data
#'   - "data_load:complete" - After data loaded
#'   - "data_quality:check" - Quality check result
#'
#' Processing Events:
#'   - "process:start" - Before processing
#'   - "process:complete" - Processing done
#'
#' Plot Events:
#'   - "plot:generate_start" - Before plot generation
#'   - "plot:generated" - Plot created successfully
#'   - "plot:failed" - Plot generation failed
#'
#' Report Events:
#'   - "report:start" - Before rendering report
#'   - "report:complete" - Report rendered
#'
#' Pipeline Events:
#'   - "pipeline:start" - Pipeline starting
#'   - "pipeline:complete" - Pipeline finished
#'   - "pipeline:error" - Pipeline encountered error
#'
#' @return Invisible NULL
event_types_documentation <- function() {
  cat("See function documentation for standard event types\n")
}

# ============================================================================
# SECTION 7: Pipeline Integration Helpers
# ============================================================================

#' Broadcast Standard Pipeline Events
#'
#' Helper for emitting standard pipeline lifecycle events
#'
#' @param phase Pipeline phase ("start", "complete", "error")
#' @param config Configuration (for start)
#' @param results Results (for complete/error)
#' @param error Error message (for error)
#'
#' @return Invisible NULL
broadcast_pipeline_event <- function(
  phase = "start",
  config = list(),
  results = list(),
  error = NULL
) {
  
  if (phase == "start") {
    emit("pipeline:start",
         list(name = "coha_dispersal", config = config),
         source_module = "pipeline")
    
  } else if (phase == "complete") {
    emit("pipeline:complete",
         list(status = "success", summary = results),
         source_module = "pipeline")
    
  } else if (phase == "error") {
    emit("pipeline:error",
         list(error = error),
         source_module = "pipeline")
  }
  
  invisible(NULL)
}

# ============================================================================
# SECTION 8: Event-Driven Module Example
# ============================================================================

#' Event-Driven Module Template
#'
#' Example showing how to build a module that reacts to events
#'
#' @examples
#' # In your module, subscribe to events on load:
#'
#' subscribe(
#'   "data_load:complete",
#'   function(event_data) {
#'     cat("[quality_checker] Data received, checking quality...\n")
#'     
#'     data <- event_data$data
#'     quality_score <- assess_quality(data)
#'     
#'     emit(
#'       "data_quality:check",
#'       list(score = quality_score, status = "ok"),
#'       source_module = "quality_checker"
#'     )
#'   },
#'   listener_name = "quality_checker"
#' )
#'
#' # When data is emitted:
#' emit("data_load:complete",
#'      list(data = df, rows = nrow(df)),
#'      source_module = "data_loader")
#' # ← Automatically triggers quality_checker's function!
event_driven_module_template <- function() {
  cat("See @examples for event-driven module pattern\n")
}

# ============================================================================
# END: EVENT SYSTEM
# ============================================================================
