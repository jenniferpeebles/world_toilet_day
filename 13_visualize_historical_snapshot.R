# World Toilet Day: historical ACS context
# 13_visualize_historical_snapshot.R
#
# Visualizes the 2005–2009 national estimate on its own. It does not display a
# modern comparison because the Census definition changed in 2016.

historical_row <- historical_national_snapshot %>%
  dplyr::slice(1)

historical_snapshot_plot <- ggplot2::ggplot(
  historical_row,
  ggplot2::aes(
    x = "United States",
    y = pct_lacking_complete_plumbing
  )
) +
  ggplot2::geom_col(
    width = 0.58,
    fill = "#2c7fb8"
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = pct_lacking_ci_low_90,
      ymax = pct_lacking_ci_high_90
    ),
    width = 0.16,
    linewidth = 0.7
  ) +
  ggplot2::geom_text(
    ggplot2::aes(
      label = paste0(
        scales::comma(housing_units_lacking_complete_plumbing),
        " housing units"
      )
    ),
    vjust = -1.3,
    size = 5
  ) +
  ggplot2::scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.01),
    expand = ggplot2::expansion(mult = c(0, 0.2))
  ) +
  ggplot2::labs(
    title = paste(
      "Back when the Census still asked about flush toilets"
    ),
    subtitle = stringr::str_wrap(
      paste(
        "In 2005–2009, “lacking complete plumbing” meant a housing unit",
        "lacked running water, a flush toilet, a bathtub/shower,",
        "or some combination."
      ),
      width = 95
    ),
    x = NULL,
    y = "Share of all housing units lacking complete plumbing",
    caption = stringr::str_wrap(
      paste(
        "Source: U.S. Census Bureau, 2005–2009 American Community Survey",
        "5-year estimates • Not directly comparable with 2016 or later data",
        paste0("• ", config$analyst_credit)
      ),
      width = 115
    )
  ) +
  theme_peebles_chart(angle_x_labels = 0)

save_peebles_plot(
  plot = historical_snapshot_plot,
  filename = glue::glue(
    "historical_plumbing_snapshot_{config$historical_data_year}.jpg"
  ),
  folder = paths$graphics,
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white"
)

message(
  "Created the standalone historical national chart; ",
  "no modern comparison was plotted."
)
