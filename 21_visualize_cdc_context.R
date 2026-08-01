# World Toilet Day: supplemental disease context
# 21_visualize_cdc_context.R
#
# Creates and exports a national trend graphic. This is descriptive public-
# health context only and is not an analysis of ACS plumbing access.

cdc_year_min <- min(cdc_annual$year, na.rm = TRUE)
cdc_year_max <- max(cdc_annual$year, na.rm = TRUE)
cdc_latest_week <- cdc_annual %>%
  dplyr::filter(year == cdc_year_max) %>%
  dplyr::summarise(week = max(last_published_week, na.rm = TRUE)) %>%
  dplyr::pull(week)

cdc_context_plot <- cdc_annual %>%
  dplyr::mutate(
    disease = factor(
      disease,
      levels = c(
        "Typhoid fever",
        "Paratyphoid fever",
        "Cholera"
      )
    )
  ) %>%
  ggplot2::ggplot(
    ggplot2::aes(
      x = year,
      y = reported_cases,
      color = disease
    )
  ) +
  ggplot2::geom_line(
    data = function(data) {
      data %>%
        dplyr::filter(year < cdc_year_max)
    },
    linewidth = 1
  ) +
  ggplot2::geom_point(
    ggplot2::aes(shape = year == cdc_year_max),
    size = 2.8,
    stroke = 1
  ) +
  ggplot2::scale_color_manual(
    values = c(
      "Typhoid fever" = "#6A3D9A",
      "Paratyphoid fever" = "#1F78B4",
      "Cholera" = "#E31A1C"
    )
  ) +
  ggplot2::scale_x_continuous(
    breaks = seq(cdc_year_min, cdc_year_max, by = 2)
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::label_comma(),
    expand = ggplot2::expansion(mult = c(0, 0.08))
  ) +
  ggplot2::scale_shape_manual(
    values = c("FALSE" = 16, "TRUE" = 1),
    labels = c(
      "FALSE" = "Completed year",
      "TRUE" = glue::glue("{cdc_year_max} provisional YTD")
    ),
    name = NULL
  ) +
  ggplot2::labs(
    title = "Once mass killers, typhoid and cholera are now rare in the U.S.",
    subtitle = stringr::str_wrap(
      glue::glue(
      "Modern water and sanitation, vaccination and treatment changed the ",
      "toll. Reported cases, {cdc_year_min}–{cdc_year_max}; ",
      "{cdc_year_max} is year to date through MMWR week {cdc_latest_week}"
      ),
      width = 105
    ),
    x = NULL,
    y = "Reported cases",
    color = NULL,
    caption = stringr::str_wrap(
      paste(
        "Source: CDC National Notifiable Diseases Surveillance System",
        "weekly tables. Weekly surveillance data are provisional and subject",
        "to revision. Most recent U.S. typhoid and cholera cases are",
        "associated with international travel. This graphic is descriptive",
        "context and is not correlated with ACS plumbing data."
      ),
      width = 145
    )
  ) +
  theme_peebles_chart(
    legend_position = "top",
    angle_x_labels = 0
  )

readr::write_csv(
  cdc_raw,
  file.path(paths$data, "cdc_nndss_disease_context_raw.csv")
)

readr::write_csv(
  cdc_annual,
  file.path(paths$data, "cdc_nndss_disease_context_annual.csv")
)

save_peebles_plot(
  plot = cdc_context_plot,
  filename = "cdc_typhoid_cholera_context.jpg",
  folder = paths$graphics,
  width = 10,
  height = 6.5,
  dpi = 300,
  bg = "white"
)
