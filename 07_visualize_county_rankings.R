# World Toilet Day: ACS plumbing access
# 07_visualize_county_rankings.R
#
# Shows the distribution and the highest/lowest county estimates nationally
# and within Georgia. Error bars display 90% confidence intervals.

plot_county_extremes <- function(data, comparison_label, n_each = 15) {
  extremes <- dplyr::bind_rows(
    data %>%
      dplyr::slice_min(pct_lacking, n = n_each, with_ties = FALSE) %>%
      dplyr::mutate(extreme = "Lowest estimated shares"),
    data %>%
      dplyr::slice_max(pct_lacking, n = n_each, with_ties = FALSE) %>%
      dplyr::mutate(extreme = "Highest estimated shares")
  ) %>%
    dplyr::mutate(
      county_label = stringr::str_remove(
        name_clean,
        ",\\s*[^,]+$"
      )
    )

  ggplot2::ggplot(
    extremes,
    ggplot2::aes(
      x = stats::reorder(county_label, pct_lacking),
      y = pct_lacking,
      fill = pct_lacking_reliability
    )
  ) +
    ggplot2::geom_col(width = 0.72) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = pct_lacking_ci_low,
        ymax = pct_lacking_ci_high
      ),
      width = 0.25,
      linewidth = 0.45
    ) +
    ggplot2::coord_flip() +
    ggplot2::facet_wrap(
      ggplot2::vars(extreme),
      scales = "free_y",
      ncol = 2
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 0.1),
      expand = ggplot2::expansion(mult = c(0, 0.05))
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        "High reliability" = "#1b9e77",
        "Moderate reliability" = "#d95f02",
        "Low reliability" = "#b2182b",
        "Not classifiable" = "#777777"
      ),
      drop = FALSE
    ) +
    ggplot2::labs(
      title = glue::glue(
        "Counties at both ends of the plumbing-access spectrum: ",
        comparison_label
      ),
      subtitle = paste(
        "Ranked by the estimated share of housing units lacking complete",
        "plumbing; error bars show 90% confidence intervals."
      ),
      x = NULL,
      y = "Share lacking complete plumbing",
      fill = "Estimate reliability",
      caption = source_caption
    ) +
    theme_peebles_chart(angle_x_labels = 0)
}

georgia_county_histogram <- ggplot2::ggplot(
  georgia_county_rankings,
  ggplot2::aes(x = pct_lacking)
) +
  ggplot2::geom_histogram(
    bins = 20,
    fill = "#2c7fb8",
    color = "white",
    linewidth = 0.3
  ) +
  ggplot2::scale_x_continuous(
    labels = scales::percent_format(accuracy = 0.1)
  ) +
  ggplot2::labs(
    title = "Most Georgia counties cluster at the low end of plumbing gaps",
    subtitle = paste(
      "Distribution across all 159 counties; county estimates vary in",
      "precision and should be read with their confidence intervals."
    ),
    x = "Share of housing units lacking complete plumbing",
    y = "Number of counties",
    caption = source_caption
  ) +
  theme_peebles_chart(angle_x_labels = 0)

georgia_county_extremes_plot <- plot_county_extremes(
  georgia_county_rankings,
  "Georgia"
)

national_county_extremes_plot <- plot_county_extremes(
  national_county_rankings,
  "50 states and D.C."
)

ranking_plots <- list(
  georgia_county_distribution = georgia_county_histogram,
  georgia_county_extremes = georgia_county_extremes_plot,
  national_county_extremes = national_county_extremes_plot
)

purrr::iwalk(
  ranking_plots,
  function(plot, filename_stem) {
    save_peebles_plot(
      plot = plot,
      filename = glue::glue(
        "{filename_stem}_{config$data_year}.jpg"
      ),
      folder = paths$graphics,
      width = ifelse(filename_stem == "georgia_county_distribution", 9, 13),
      height = ifelse(filename_stem == "georgia_county_distribution", 6, 8),
      dpi = 300,
      bg = "white"
    )
  }
)

message("Created Georgia and national county ranking graphics.")
