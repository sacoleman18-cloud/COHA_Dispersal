## Shared utilities for Manuscript plotting
period_levels <- function() {
  c(
    "1980-1985", "1986-1991", "1992-1997", "1998-2003",
    "2004-2009", "2010-2015", "2016-2021", "2022-2027"
  )
}

assign_periods <- function(df, year_col = "year") {
  df[[year_col]] <- as.integer(df[[year_col]])
  df$period <- dplyr::case_when(
    df[[year_col]] >= 1980 & df[[year_col]] <= 1985 ~ "1980-1985",
    df[[year_col]] >= 1986 & df[[year_col]] <= 1991 ~ "1986-1991",
    df[[year_col]] >= 1992 & df[[year_col]] <= 1997 ~ "1992-1997",
    df[[year_col]] >= 1998 & df[[year_col]] <= 2003 ~ "1998-2003",
    df[[year_col]] >= 2004 & df[[year_col]] <= 2009 ~ "2004-2009",
    df[[year_col]] >= 2010 & df[[year_col]] <= 2015 ~ "2010-2015",
    df[[year_col]] >= 2016 & df[[year_col]] <= 2021 ~ "2016-2021",
    df[[year_col]] >= 2022 & df[[year_col]] <= 2027 ~ "2022-2027",
    TRUE ~ NA_character_
  )
  lvls <- period_levels()
  df <- df %>% dplyr::mutate(period = factor(period, levels = lvls, ordered = TRUE))
  df
}

hawkO_palette <- function(n) {
  hawkO_natural <- c("#1F2A3A", "#56677F", "#8C6A54", "#C98C63", "#EAD7B8", "#EF8C27")
  grDevices::colorRampPalette(hawkO_natural)(n)
}

plot_theme <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 10, color = "gray50"),
      axis.title = element_text(size = 12),
      axis.text = element_text(size = 10, face = "bold", color = "black"),
      axis.text.y = ggtext::element_markdown(lineheight = 1.1),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.title.y = element_text(angle = 0, vjust = 0.5, margin = margin(r = 8)),
      axis.title.x = element_text(margin = margin(t = 8)),
      plot.background = element_rect(fill = "white", color = NA)
    )
}

compute_period_stats <- function(plot_df) {
  # Create a local lowercased dispersal indicator from the canonical `dispersed` column.
  df <- plot_df %>% dplyr::mutate(disp_lower = tolower(trimws(as.character(dispersed))))

  period_means <- df %>%
    dplyr::filter(disp_lower == "wisconsin") %>%
    dplyr::group_by(period) %>%
    dplyr::summarise(mean_mass = mean(mass, na.rm = TRUE), .groups = "drop")

  data_unknown <- df %>% dplyr::filter(disp_lower == "unknown")
  unknown_means <- data_unknown %>%
    dplyr::group_by(period) %>%
    dplyr::summarise(mean_mass = mean(mass, na.rm = TRUE), .groups = "drop")

  period_counts <- df %>%
    dplyr::group_by(period) %>%
    dplyr::summarise(
      n_wisconsin = sum(disp_lower == "wisconsin", na.rm = TRUE),
      n_unknown = sum(disp_lower == "unknown", na.rm = TRUE),
      .groups = "drop"
    )

  label_map <- period_counts %>%
    dplyr::mutate(
      label = sprintf(
        "<span style='color:#000000;'>%s</span><br><span style='color:#666666;'>Dispersal: %d<br>Non-dispersal: %d</span>",
        period,
        n_wisconsin,
        n_unknown
      )
    ) %>%
    dplyr::arrange(period)

  period_labels <- label_map$label
  names(period_labels) <- label_map$period

  list(
    period_means = period_means,
    unknown_means = unknown_means,
    period_counts = period_counts,
    period_labels = period_labels
  )
}

write_repro_report <- function(path, script_name, input_paths = NULL, output_paths = NULL, seed = NULL) {
  sink(path)
  cat("=== Reproducibility Report ===\n\n")
  cat("Script: ", script_name, "\n", sep = "")
  cat("Execution time: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n", sep = "")
  cat("R version: ", R.version.string, "\n", sep = "")
  cat("OS: ", Sys.info()["sysname"], " ", Sys.info()["release"], "\n\n", sep = "")
  cat("Loaded packages:\n")
  print(sessionInfo()$otherPkgs)
  cat("\n")

  cat("Input files:\n")
  if (!is.null(input_paths)) {
    for (p in input_paths) {
      if (file.exists(p)) {
        cat("- ", p, " (sha256): ", digest::digest(p, algo = "sha256", file = TRUE), "\n", sep = "")
      }
    }
  }
  cat("\n")

  cat("Output files:\n")
  if (!is.null(output_paths)) {
    for (p in output_paths) {
      if (file.exists(p)) {
        cat("- ", p, " (sha256): ", digest::digest(p, algo = "sha256", file = TRUE), "\n", sep = "")
      }
    }
  }
  cat("\n")

  if (!is.null(seed)) cat("Random seed: ", seed, "\n")
  sink()
}
