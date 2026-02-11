# ==============================================================================
# R/functions/plot_operations.R
# ==============================================================================
# PURPOSE
# -------
# Phase 3 plot operations with structured returns and error recovery.
# All functions return result objects with status, message, quality metrics.
# Unlike Phase 1, plot generation failures don't stop pipeline.
#
# DEPENDS ON
# ----------
# - R/functions/assertions.R (validation)
# - R/functions/logging.R (audit trail)
# - R/functions/robustness.R (result objects)
# - R/functions/utilities.R (directory management)
# - ggplot2, ggridges, dplyr
#
# INPUTS
# ------
# Data frames, plot configurations, output directories
#
# OUTPUTS
# -------
# Structured result objects with status, plots, quality metrics
# PNG files to disk

# Load required packages
if (!require(ggplot2, quietly = TRUE)) {
  stop("ggplot2 package required")
}
if (!require(ggridges, quietly = TRUE)) {
  stop("ggridges package required")
}
if (!require(dplyr, quietly = TRUE)) {
  stop("dplyr package required")
}

# USAGE
# -----
# source("R/functions/plot_operations.R")
# result <- generate_plot_safe(df, config, "compact_01", output_dir)
# summary <- generate_all_plots_safe(df, configs, output_dir, verbose = TRUE)
#
# CHANGELOG
# ---------
# 2026-02-10 (v1.0.0): Phase 3 - Initial plot operations
#   - generate_plot_safe() - Single plot with error recovery
#   - generate_all_plots_safe() - Batch generation with continue-on-error
#
# ==============================================================================

#' Safely Generate Single Plot with Error Recovery
#'
#' @description
#' Generates ridgeline plot with comprehensive error handling.
#' Returns structured result instead of failing on error.
#' If plot generation fails, continues pipeline with error logged.
#'
#' @param df Data frame. Data to plot.
#' @param plot_config List. Plot specification with fields:
#'   - plot_id: Unique identifier (e.g., "compact_01")
#'   - scale: Ridgeline scale factor
#'   - fill: Palette/color specification
#'   - title: Plot title
#' @param output_dir Character. Directory to save PNG.
#' @param verbose Logical. Print progress. Default: FALSE.
#' @param dpi Integer. PNG resolution. Default: 300.
#' @param width Numeric. PNG width in inches. Default: 10.
#' @param height Numeric. PNG height in inches. Default: 6.
#'
#' @return List. Structured result with fields:
#'   - status: "success", "partial", or "failed"
#'   - message: Human-readable status
#'   - plot_id: Plot identifier
#'   - plot: ggplot object (if status != "failed")
#'   - output_path: Where PNG saved (if success)
#'   - file_size_mb: Size of PNG file (if saved)
#'   - generation_time: Seconds to generate plot
#'   - quality_score: 0-100 quality rating
#'   - errors: List of errors encountered
#'   - warnings: List of non-blocking issues
#'   - timestamp: When operation completed
#'   - duration_secs: Total operation time
#'
#' @details
#' **Error Recovery:**
#' - If data missing: logs error, returns status="failed"
#' - If plot generation fails: logs error, returns status="failed"
#' - If file save fails: logs error, returns plot object anyway
#' - Never stops execution; returns status for caller to decide
#'
#' **Pre-Checks:**
#' 1. Data is data frame and not empty
#' 2. Output directory exists (creates if missing)
#' 3. Plot config has required fields
#'
#' **Quality Score Factors:**
#' - Data completeness (30%)
#' - Plot generation success (40%)
#' - File save success (20%)
#' - Generation time reasonable (10%)
#'
#' @examples
#' \dontrun{
#' config <- list(
#'   plot_id = "compact_01",
#'   scale = 0.85,
#'   fill = "plasma",
#'   title = "Mass Distribution (Compact, Plasma)"
#' )
#'
#' result <- generate_plot_safe(
#'   df = hawk_data,
#'   plot_config = config,
#'   output_dir = here::here("results", "plots", "ridgeline", "variants"),
#'   verbose = TRUE
#' )
#'
#' if (result$status == "success") {
#'   message(sprintf("Plot saved: %s (%.2f MB)",
#'                  result$output_path, result$file_size_mb))
#' } else {
#'   warning(sprintf("Plot failed: %s", result$message))
#' }
#' }
#'
#' @export
generate_plot_safe <- function(df,
                                plot_config,
                                output_dir,
                                verbose = FALSE,
                                dpi = 300,
                                width = 10,
                                height = 6) {
  # Normalize config fields for compatibility with ridgeline_config.R
  if (is.null(plot_config$plot_id) && !is.null(plot_config$id)) {
    plot_config$plot_id <- plot_config$id
  }
  if (is.null(plot_config$scale) && !is.null(plot_config$scale_value)) {
    plot_config$scale <- plot_config$scale_value
  }
  if (is.null(plot_config$fill) && !is.null(plot_config$fill_palette)) {
    plot_config$fill <- plot_config$fill_palette
  }
  if (is.null(plot_config$title) && !is.null(plot_config$name)) {
    plot_config$title <- plot_config$name
  }

  # Initialize result
  result <- create_result("generate_plot_safe", verbose)
  result$plot_id <- plot_config$plot_id %||% "unknown"
  start_time <- start_timer()

  if (verbose) {
    log_entry(sprintf("Generating plot: %s", result$plot_id), verbose = TRUE)
  }

  # 1. DEFENSIVE CHECKS
  tryCatch(
    {
      assert_data_frame(df, "input data")
      assert_not_empty(df, "input data")
      assert_directory_exists(output_dir, create = TRUE)
      assert_scalar_string(plot_config$plot_id, "plot_id")
    },
    error = function(e) {
      result <<- add_error(
        result,
        format_error_message(
          sprintf("plot_%s", result$plot_id),
          e$message,
          "Check input data and output directory"
        ),
        verbose
      )
    }
  )

  if (result$status == "failed") {
    result$duration_secs <- stop_timer(start_time)
    return(invisible(result))
  }

  # 2. BUILD OUTPUT PATH
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  output_file <- sprintf("%s_%s.png", result$plot_id, timestamp)
  output_path <- file.path(output_dir, output_file)

  if (verbose) {
    message(sprintf("[PLOT] Output: %s", output_file))
  }

  # 3. GENERATE PLOT
  plot_generation_time <- NA_real_
  plot_obj <- NULL

  tryCatch(
    {
      plot_start <- start_timer()

      period_levels <- c(
        "1980-1985", "1986-1991", "1992-1997", "1998-2003",
        "2004-2009", "2010-2015", "2016-2021", "2022-2027"
      )
      line_height <- plot_config$line_height %||% 1.0

      df_plot <- df %>%
        dplyr::mutate(
          disp_lower = tolower(dispersed),
          period = dplyr::case_when(
            year >= 1980 & year <= 1985 ~ "1980-1985",
            year >= 1986 & year <= 1991 ~ "1986-1991",
            year >= 1992 & year <= 1997 ~ "1992-1997",
            year >= 1998 & year <= 2003 ~ "1998-2003",
            year >= 2004 & year <= 2009 ~ "2004-2009",
            year >= 2010 & year <= 2015 ~ "2010-2015",
            year >= 2016 & year <= 2021 ~ "2016-2021",
            year >= 2022 & year <= 2027 ~ "2022-2027",
            TRUE ~ NA_character_
          )
        )

      data_unknown <- df_plot %>%
        dplyr::filter(disp_lower == "unknown", !is.na(period))

      period_means <- df_plot %>%
        dplyr::filter(disp_lower == "wisconsin", !is.na(period)) %>%
        dplyr::group_by(period) %>%
        dplyr::summarise(mean_mass = mean(mass, na.rm = TRUE), .groups = "drop")

      unknown_means <- data_unknown %>%
        dplyr::group_by(period) %>%
        dplyr::summarise(mean_mass = mean(mass, na.rm = TRUE), .groups = "drop")

      data_unknown <- data_unknown %>%
        dplyr::mutate(period = factor(period, levels = period_levels, ordered = TRUE))
      period_means <- period_means %>%
        dplyr::mutate(period = factor(period, levels = period_levels, ordered = TRUE))
      unknown_means <- unknown_means %>%
        dplyr::mutate(period = factor(period, levels = period_levels, ordered = TRUE))

      plot_obj <- ggplot2::ggplot(
        data_unknown,
        ggplot2::aes(x = mass, y = period, fill = period)
      ) +
        ggridges::geom_density_ridges(
          scale = plot_config$scale %||% 1.0,
          alpha = 0.7,
          show.legend = FALSE
        ) +
        ggplot2::geom_segment(
          data = period_means,
          ggplot2::aes(
            x = mean_mass,
            xend = mean_mass,
            y = as.numeric(period),
            yend = as.numeric(period) + line_height
          ),
          color = "black",
          linetype = "dashed",
          linewidth = 0.4,
          alpha = 0.7
        ) +
        ggplot2::geom_segment(
          data = unknown_means,
          ggplot2::aes(
            x = mean_mass,
            xend = mean_mass,
            y = as.numeric(period),
            yend = as.numeric(period) + line_height,
            color = period
          ),
          linetype = "solid",
          linewidth = 0.8,
          alpha = 1
        ) +
        ggplot2::geom_point(
          data = period_means,
          ggplot2::aes(x = mean_mass, y = period, fill = period),
          shape = 21,
          size = 3,
          stroke = 0.6,
          color = "black",
          inherit.aes = FALSE
        ) +
        ggplot2::geom_point(
          data = unknown_means,
          ggplot2::aes(x = mean_mass, y = period, fill = period),
          shape = 24,
          size = 3,
          stroke = 0.6,
          color = "black",
          inherit.aes = FALSE
        ) +
        # Apply palette based on type
        (if (plot_config$palette_type == "custom") {
          # Custom hex palette - interpolate if needed to match number of periods
          hex_colors <- plot_config$fill_colors
          n_needed <- length(period_levels)
          if (length(hex_colors) < n_needed) {
            # Interpolate to get enough colors
            hex_colors <- grDevices::colorRampPalette(hex_colors)(n_needed)
          }
          ggplot2::scale_fill_manual(values = hex_colors)
        } else if (plot_config$palette_type == "brewer") {
          ggplot2::scale_fill_brewer(palette = plot_config$fill %||% "Set2")
        } else {
          ggplot2::scale_fill_viridis_d(option = plot_config$fill %||% "plasma")
        }) +
        (if (plot_config$palette_type == "custom") {
          # Custom hex palette for color (line)
          hex_colors <- plot_config$color_colors
          n_needed <- length(period_levels)
          if (length(hex_colors) < n_needed) {
            hex_colors <- grDevices::colorRampPalette(hex_colors)(n_needed)
          }
          ggplot2::scale_color_manual(values = hex_colors)
        } else if (plot_config$palette_type == "brewer") {
          ggplot2::scale_color_brewer(palette = plot_config$color %||% "Set2")
        } else {
          ggplot2::scale_color_viridis_d(option = plot_config$color %||% "plasma")
        }) +
        ggplot2::labs(
          title = plot_config$title %||% result$plot_id,
          x = "Mass (g)",
          y = "Period"
        ) +
        ggplot2::theme_minimal(base_size = 12) +
        ggplot2::theme(
          plot.title = ggplot2::element_text(size = 14, face = "bold"),
          axis.title = ggplot2::element_text(size = 12),
          panel.grid.major.y = ggplot2::element_blank(),
          panel.grid.minor = ggplot2::element_blank(),
          axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 8)),
          axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 8)),
          legend.position = "none"
        )

      plot_generation_time <- stop_timer(plot_start)

      if (verbose) {
        message(sprintf("[PLOT] Generated in %.2f seconds", plot_generation_time))
      }
    },
    error = function(e) {
      result <<- add_error(
        result,
        format_error_message(
          sprintf("plot_%s", result$plot_id),
          sprintf("Plot generation failed: %s", e$message),
          "Check plot config fields: scale, fill, title"
        ),
        verbose
      )
    }
  )

  if (result$status == "failed") {
    result$duration_secs <- stop_timer(start_time)
    return(invisible(result))
  }

  result$plot <- plot_obj

  # 4. SAVE PLOT TO DISK
  file_size_mb <- NA_real_

  tryCatch(
    {
      if (verbose) message("[PLOT] Saving to disk...")

      ggplot2::ggsave(
        filename = output_path,
        plot = plot_obj,
        width = width,
        height = height,
        dpi = dpi,
        device = "png"
      )

      # Get file size
      file_info <- file.info(output_path)
      file_size_mb <- file_info$size / (1024 * 1024)

      if (verbose) {
        message(sprintf("[PLOT] ✓ Saved (%s, %.2f MB)",
                       output_file, file_size_mb))
      }

      result <- set_result_status(
        result,
        "success",
        sprintf("Plot generated and saved: %s", result$plot_id),
        verbose
      )
    },
    error = function(e) {
      result <<- add_warning(
        result,
        format_error_message(
          sprintf("plot_%s", result$plot_id),
          sprintf("Failed to save PNG: %s", e$message),
          sprintf("Check write permissions in %s", output_dir)
        ),
        verbose
      )
      # Change status to partial (plot generated but not saved)
      result$status <<- "partial"
    }
  )

  # 5. COMPUTE QUALITY SCORE
  quality_components <- list(
    generation = if (!is.na(plot_generation_time)) 100 else 0,
    file_saved = if (!is.na(file_size_mb)) 100 else 50,
    status = if (result$status == "success") 100 else if (result$status == "partial") 75 else 0
  )

  result <- add_quality_metrics(result, quality_components)

  # 6. FINALIZE
  result$output_path <- output_path
  result$file_size_mb <- file_size_mb
  result$generation_time <- plot_generation_time
  result$duration_secs <- stop_timer(start_time)
  result$timestamp <- Sys.time()
  
  # Store plot config metadata for registry
  result$metadata <- list(
    scale_value = plot_config$scale,
    palette = plot_config$fill,
    palette_type = plot_config$palette_type
  )

  if (verbose) {
    log_success(
      sprintf("Generated plot %s", result$plot_id),
      sprintf("quality: %.0f/100, time: %.2f sec",
             result$quality_score, result$duration_secs),
      verbose = TRUE
    )
  }

  invisible(result)
}

#' Safely Generate All Configured Plots
#'
#' @description
#' Generate all plots from configuration list with error recovery.
#' If one plot fails, continues with remaining plots.
#' Returns summary of all results.
#'
#' @param df Data frame. Data for all plots.
#' @param plot_configs List. List of plot configurations.
#' @param output_dir Character. Base output directory.
#' @param verbose Logical. Print progress. Default: FALSE.
#' @param dpi Integer. PNG resolution. Default: 300.
#' @param stop_on_first_error Logical. Stop if any plot fails?
#'   Default: FALSE (continue on error).
#'
#' @return List. Summary result with fields:
#'   - status: "success", "partial", or "failed"
#'   - message: Summary message
#'   - plots_generated: Number of successful plots
#'   - plots_failed: Number of failed plots
#'   - plots_total: Total attempted
#'   - generation_times: Vector of per-plot times
#'   - output_dir: Directory where plots saved
#'   - success_rate: Percent generated successfully
#'   - quality_score: Average quality across all
#'   - results: List of individual plot results
#'   - errors: All errors encountered
#'   - warnings: All warnings
#'   - duration_secs: Total time for all plots
#'   - timestamp: When batch completed
#'
#' @details
#' **Continue-on-Error Pattern:**
#' - Individual plot failure logged but doesn't stop batch
#' - All plots attempted even if some fail
#' - Summary shows count of successes and failures
#'
#' **Status Determination:**
#' - All success: status = "success"
#' - Some success: status = "partial"
#' - All fail: status = "failed"
#' - OR stop_on_first_error=TRUE and any fails: status = "failed"
#'
#' **Quality Score:**
#' Average of individual plot quality scores.
#' Higher is better (0-100).
#'
#' @examples
#' \dontrun{
#' # Generate all 20 ridgeline variants
#' summary <- generate_all_plots_safe(
#'   df = hawk_data,
#'   plot_configs = ridgeline_plot_configs,
#'   output_dir = here::here("results", "plots", "ridgeline", "variants"),
#'   verbose = TRUE
#' )
#'
#' # Check results
#' message(sprintf(
#'   "Generated %d/%d plots (success rate: %.0f%%)",
#'   summary$plots_generated,
#'   summary$plots_total,
#'   summary$success_rate
#' ))
#'
#' # Handle summary status
#' if (summary$status == "success") {
#'   message("All plots generated successfully")
#' } else if (summary$status == "partial") {
#'   warning(sprintf("Generated %d plots, %d failed",
#'                  summary$plots_generated, summary$plots_failed))
#' } else {
#'   stop("All plots failed")
#' }
#' }
#'
#' @export
generate_all_plots_safe <- function(df,
                                     plot_configs,
                                     output_dir,
                                     verbose = FALSE,
                                     dpi = 300,
                                     stop_on_first_error = FALSE) {

  # Initialize summary
  summary <- create_result("generate_all_plots_safe", verbose)
  start_time <- start_timer()

  if (verbose) {
    message(sprintf("[BATCH] Starting batch generation of %d plots",
                   length(plot_configs)))
  }

  # Pre-checks
  tryCatch(
    {
      assert_data_frame(df, "data")
      assert_not_empty(df, "data")
      assert_directory_exists(output_dir, create = TRUE)
    },
    error = function(e) {
      summary <<- add_error(summary, e$message, verbose)
    }
  )

  if (summary$status == "failed") {
    summary$duration_secs <- stop_timer(start_time)
    return(invisible(summary))
  }

  # Track results
  individual_results <- list()
  generation_times <- numeric()
  quality_scores <- numeric()
  plots_generated <- 0
  plots_failed <- 0

  # Generate each plot
  for (i in seq_along(plot_configs)) {
    config <- plot_configs[[i]]
    plot_id <- config$plot_id %||% sprintf("plot_%d", i)

    if (verbose) {
      message(sprintf("[BATCH] %d/%d: Generating %s",
                     i, length(plot_configs), plot_id))
    }

    # Generate plot
    result <- tryCatch(
      {
        generate_plot_safe(
          df = df,
          plot_config = config,
          output_dir = output_dir,
          verbose = FALSE,
          dpi = dpi
        )
      },
      error = function(e) {
        # Wrap external error
        res <- create_result(sprintf("plot_%s", plot_id))
        res <- add_error(res, sprintf("Unexpected error: %s", e$message))
        res
      }
    )

    # Store result
    individual_results[[length(individual_results) + 1]] <- result

    # Track metrics
    if (result$status != "failed") {
      plots_generated <- plots_generated + 1
      if (!is.na(result$duration_secs)) {
        generation_times <- c(generation_times, result$duration_secs)
      }
    } else {
      plots_failed <- plots_failed + 1
    }

    if (!is.na(result$quality_score)) {
      quality_scores <- c(quality_scores, result$quality_score)
    }

    # Check stop-on-error flag
    if (stop_on_first_error && result$status == "failed") {
      if (verbose) {
        message(sprintf("[BATCH] Stopping after first failure: %s", plot_id))
      }
      break
    }
  }

  # 6. DETERMINE SUMMARY STATUS
  if (plots_failed == 0) {
    summary <- set_result_status(
      summary,
      "success",
      sprintf("All %d plots generated successfully", plots_generated),
      verbose
    )
  } else if (plots_generated > 0) {
    summary <- set_result_status(
      summary,
      "partial",
      sprintf("Generated %d/%d plots (%d failed)",
             plots_generated,
             plots_generated + plots_failed,
             plots_failed),
      verbose
    )
  } else {
    summary <- add_error(
      summary,
      format_error_message(
        "generate_all_plots",
        sprintf("All %d plots failed", plots_failed),
        "Check data and plot configurations"
      ),
      verbose
    )
  }

  # 7. ASSEMBLE SUMMARY METRICS
  summary$plots_generated <- plots_generated
  summary$plots_failed <- plots_failed
  summary$plots_total <- plots_generated + plots_failed
  summary$output_dir <- output_dir
  summary$success_rate <- (plots_generated / summary$plots_total) * 100
  summary$generation_times <- generation_times
  summary$results <- individual_results

  # Average quality score
  if (length(quality_scores) > 0) {
    summary$quality_score <- mean(quality_scores)
  } else {
    summary$quality_score <- 0
  }

  # Collect all errors and warnings
  for (result in individual_results) {
    if (length(result$errors) > 0) {
      summary$errors <- c(summary$errors, result$errors)
    }
    if (length(result$warnings) > 0) {
      summary$warnings <- c(summary$warnings, result$warnings)
    }
  }

  # 8. FINALIZE
  summary$duration_secs <- stop_timer(start_time)
  summary$timestamp <- Sys.time()

  if (verbose) {
    message(sprintf(
      "[BATCH] Complete: %d/%d plots (%.0f%% success, quality: %.0f/100, time: %.1fs)",
      plots_generated,
      summary$plots_total,
      summary$success_rate,
      summary$quality_score,
      summary$duration_secs
    ))
  }

  invisible(summary)
}

# ==============================================================================
# END R/functions/plot_operations.R
# ==============================================================================

