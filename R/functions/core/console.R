# ==============================================================================
# R/functions/console.R
# ==============================================================================
# PURPOSE
# -------
# Console formatting utilities for visual output.
# Provides consistent stage headers, workflow summaries, and pipeline 
# completion displays. Separated from utilities.R for modularity.
#
# DEPENDS ON
# ----------
# - base R only (message, sprintf, strrep, nchar)
#
# INPUTS
# ------
# Stage names, titles, results summaries
#
# OUTPUTS
# -------
# - Console output via message() (not files)
#
# USAGE
# -----
# source("R/functions/console.R")
# print_stage_header("1.1", "Load & Validate Data")
# print_workflow_summary("Ridgeline Generation", "20 plots generated")
# print_pipeline_complete("Analysis Complete")
#
# ==============================================================================

# ==============================================================================
# TEXT HELPERS
# ==============================================================================

#' Center Text Within Fixed Width
#'
#' @description
#' Centers text by adding padding on both sides to reach target width.
#' Internal helper used by all console formatting functions.
#'
#' @param text Character. Text string to center.
#' @param width Integer. Total width including padding.
#'
#' @return Character. Centered text string with padding on both sides.
#'
#' @details
#' **Padding Distribution:** Uses floor/ceiling to handle odd widths:
#' - 3-character text in width 7: " 3ch " (1 left, 1 right)
#' - With rounding, odd pixels go to right side
#'
#' **No Output:** Returns string only; use with sprintf().
#'
#' **See Also:** Used internally by print_stage_header(), print_workflow_summary()
#' and print_pipeline_complete(). Not typically called directly.
#'
#' @keywords internal
center_text <- function(text, width) {
  pad_total <- width - nchar(text)
  pad_left <- floor(pad_total / 2)
  pad_right <- ceiling(pad_total / 2)
  
  sprintf("%s%s%s",
          strrep(" ", pad_left),
          text,
          strrep(" ", pad_right))
}

# ==============================================================================
# STAGE FORMATTING
# ==============================================================================

#' Print Stage Header Box
#'
#' @description
#' Prints a consistently formatted single-border ASCII box for workflow stages.
#' Call to mark major pipeline processing steps and inform user of progress.
#'
#' @param stage_num Character. Stage number or identifier
#'   (e.g., "1", "1.1", "Phase 2").
#' @param title Character. Descriptive stage title
#'   (e.g., "Load & Validate Data").
#' @param width Integer. Interior width of box (excluding borders).
#'   Default: 65 characters.
#'
#' @return Invisible NULL (side effect: prints to console).
#'
#' @details
#' **Output Format:**
#' ```
#' +-----[width dashes]-----+
#' | [centered: STAGE X: Title] |
#' +-----[width dashes]-----+
#' ```
#' (plus newlines for readability)
#'
#' **Typical Use:** Call at start of each major pipeline phase:
#' ```r
#' print_stage_header("1", "Load & Validate Data")
#' # [Load and validate]
#'
#' print_stage_header("2", "Generate Plots")
#' # [Generate plots]
#'
#' print_stage_header("3", "Create Report")
#' # [Create report]
#' ```
#'
#' **Width Consideration:** Default 65 fits within standard 80-char terminal.
#' Increase for longer titles; decrease for compact output.
#'
#' **Visual Distinction:** Single border lines distinguish from other message types.
#' Compare: print_workflow_summary (double borders), print_pipeline_complete (double).
#'
#' @examples
#' \dontrun{
#' print_stage_header("1", "Load & Validate Data")
#' # Output:
#' # +-------------------------------------------------------------------+
#' # |             STAGE 1: Load & Validate Data                         |
#' # +-------------------------------------------------------------------+
#'
#' print_stage_header("2.1", "Generate Ridgeline Variants")
#' # Output:
#' # +-------------------------------------------------------------------+
#' # |          STAGE 2.1: Generate Ridgeline Variants                   |
#' # +-------------------------------------------------------------------+
#' }
#'
#' @seealso [print_workflow_summary()], [print_pipeline_complete()]
#'
#' @export
print_stage_header <- function(stage_num, title, width = 65) {
  
  # Build stage text
  stage_text <- sprintf("STAGE %s: %s", stage_num, title)
  
  # Center text
  centered <- center_text(stage_text, width)
  
  # Print box
  message(sprintf("\n+%s+", strrep("-", width)))
  message(sprintf("|%s|", centered))
  message(sprintf("+%s+\n", strrep("-", width)))
  
  invisible(NULL)
}

# ==============================================================================
# WORKFLOW OUTPUT
# ==============================================================================

#' Print Workflow Summary
#'
#' @description
#' Prints a multi-line workflow completion summary with double-line ASCII box.
#' Shows key statistics and results from completed processing phase.
#'
#' @param workflow_name Character. Human-readable workflow name
#'   (e.g., "Ridgeline Generation", "Data Validation").
#' @param summary_lines Character vector. Detail lines to display.
#'   Each line printed on separate row within box.
#' @param width Integer. Interior width of box (excluding borders).
#'   Default: 65 characters.
#'
#' @return Invisible NULL (side effect: prints to console).
#'
#' @details
#' **Output Format:**
#' ```
#' ===[width equals]===
#' =[centered: WORKFLOW: Name]=
#' ===[width equals]===
#' |  summary_line_1                                                 |
#' |  summary_line_2                                                 |
#' |  summary_line_3                                                 |
#' ===[width equals]===
#' ```
#'
#' **Line Truncation:** Lines longer than (width-4) characters are
#' truncated with "..." appended to fit width.
#'
#' **Use Cases:**
#' - After data loading: rows processed, columns, data quality checks
#' - After plot generation: plots created, output directory, time elapsed
#' - After report generation: report path, total page count, warnings
#'
#' **Visual Distinction:** Double borders (===) distinguishes from stage headers.
#' Used for secondary summaries, not primary stages.
#'
#' @examples
#' \dontrun{
#' lines <- c(
#'   "Plots generated: 20",
#'   "Output directory: results/plots/ridgeline/variants/",
#'   "Time elapsed: 45.2 seconds"
#' )
#' print_workflow_summary("Ridgeline Generation", lines)
#'
#' # Output:
#' # ===================================================================
#' # =              WORKFLOW: Ridgeline Generation                     =
#' # ===================================================================
#' # |  Plots generated: 20                                            |
#' # |  Output directory: results/plots/ridgeline/variants/            |
#' # |  Time elapsed: 45.2 seconds                                     |
#' # ===================================================================
#' }
#'
#' @seealso [print_stage_header()], [print_pipeline_complete()]
#'
#' @export
print_workflow_summary <- function(workflow_name,
                                   summary_lines,
                                   width = 65) {
  
  # Build header
  header_text <- sprintf("WORKFLOW: %s", workflow_name)
  header_centered <- center_text(header_text, width)
  
  # Print double-line box
  message(sprintf("\n%s", strrep("=", width + 2)))
  message(sprintf("=%s=", header_centered))
  message(sprintf("%s", strrep("=", width + 2)))
  
  # Print summary lines (indented)
  for (line in summary_lines) {
    # Truncate if too long, otherwise pad to width
    if (nchar(line) > width - 4) {
      line <- substr(line, 1, width - 7)
      line <- paste0(line, "...")
    }
    padded_line <- sprintf("  %-*s", width - 2, line)
    message(paste0("|", padded_line, "|"))
  }
  
  # Print footer
  message(sprintf("%s\n", strrep("=", width + 2)))
  
  invisible(NULL)
}

#' Print Pipeline Complete Message
#'
#' @description
#' Prints a prominent final pipeline completion message with double-line box.
#' Call at end of orchestrator function to show completion status.
#'
#' @param main_message Character. Main status message
#'   (e.g., "✓ PIPELINE COMPLETE", "✗ PIPELINE FAILED").
#' @param details Character vector. Optional detail lines explaining status.
#'   Default: NULL (no details).
#' @param width Integer. Interior width of box (excluding borders).
#'   Default: 65 characters.
#'
#' @return Invisible NULL (side effect: prints to console).
#'
#' @details
#' **Output Format:**
#' ```
#' ===[width equals]===
#' =[centered: main_message]=
#' ===[width equals]===
#'
#'   detail_line_1
#'   detail_line_2
#'   detail_line_3
#'
#' ===[width equals]===
#' ```
#'
#' **Status Indicators:** Typically use:
#' - "✓ PIPELINE COMPLETE" for success
#' - "✗ PIPELINE FAILED" for errors
#' Or custom status: "✓ 20 Plots Generated"
#'
#' **Detail Lines:** Each detail line indented with 2 spaces for readability.
#' Lines longer than (width-4) truncated with "...".
#'
#' **Use in Pipelines:**
#' ```r
#' if (success) {
#'   print_pipeline_complete(
#'     "✓ PIPELINE COMPLETE",
#'     c("Plots: 20", "Time: 45s", "Status: success")
#'   )
#' } else {
#'   print_pipeline_complete(
#'     "✗ PIPELINE FAILED",
#'     c("Error:", error_message)
#'   )
#' }
#' ```
#'
#' **Visual Distinction:** Double borders with extra spacing emphasizes
#' this is the final message in pipeline execution.
#'
#' @examples
#' \dontrun{
#' print_pipeline_complete(
#'   "✓ PIPELINE COMPLETE",
#'   c("Plots generated: 20",
#'     "Output location: results/plots/ridgeline/variants/",
#'     "Time elapsed: 45.2 seconds",
#'     "Status: success")
#' )
#'
#' # Output:
#' # ===================================================================
#' # =                  ✓ PIPELINE COMPLETE                           =
#' # ===================================================================
#' #
#' #   Plots generated: 20
#' #   Output location: results/plots/ridgeline/variants/
#' #   Time elapsed: 45.2 seconds
#' #   Status: success
#' #
#' # ===================================================================
#' }
#'
#' @seealso [print_stage_header()], [print_workflow_summary()]
#'
#' @export
print_pipeline_complete <- function(main_message,
                                    details = NULL,
                                    width = 65) {
  
  # Center main message
  centered <- center_text(main_message, width)
  
  # Top border with extra spacing
  message(sprintf("\n%s", strrep("=", width + 2)))
  message(sprintf("=%s=", centered))
  message(sprintf("%s", strrep("=", width + 2)))
  
  # Print details if provided
  if (!is.null(details) && length(details) > 0) {
    message("")
    for (detail in details) {
      if (nchar(detail) > width - 4) {
        detail <- substr(detail, 1, width - 7)
        detail <- paste0(detail, "...")
      }
      message(sprintf("  %s", detail))
    }
  }
  
  # Bottom border
  message(sprintf("%s\n", strrep("=", width + 2)))
  
  invisible(NULL)
}

# ==============================================================================
# END R/functions/console.R
# ==============================================================================
