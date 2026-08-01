# World Toilet Day: ACS plumbing access
# 04_visualize.R
#
# Builds the benchmark tables, highlights, charts, and maps. File output is
# handled in 05_export.R.

acs_period <- if (identical(config$survey, "acs5")) {
  paste0(config$data_year - 4, "–", config$data_year)
} else {
  as.character(config$data_year)
}

acs_survey_label <- dplyr::case_when(
  identical(config$survey, "acs5") ~ "5-year",
  identical(config$survey, "acs1") ~ "1-year",
  TRUE ~ config$survey
)

source_caption <- glue::glue(
  "Source: U.S. Census Bureau, {acs_period} American Community Survey ",
  "{acs_survey_label} estimates • {config$analyst_credit}"
)

plot_bar_with_moe <- function(
    data,
    label_col = "name_clean",
    title = "Share with complete plumbing",
    subtitle = NULL
) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = reorder(.data[[label_col]], pct_complete),
      y = pct_complete
    )
  ) +
    ggplot2::geom_col(alpha = 0.8) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = pct_complete_ci_low,
        ymax = pct_complete_ci_high
      ),
      width = 0.35,
      linewidth = 0.6
    ) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(
      labels = scales::percent_format(accuracy = 0.1)
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "Percent with complete plumbing",
      caption = source_caption
    ) +
    theme_peebles_chart(angle_x_labels = 0)
}

plot_choropleth <- function(
    data,
    value_col = "pct_lacking",
    fill_label = "% lacking",
    title = "Lacking complete plumbing",
    subtitle = NULL,
    crs = config$crs_map,
    shift_states = FALSE
) {
  if (!inherits(data, "sf")) {
    stop("`data` must be an sf object.", call. = FALSE)
  }

  map_data <- if (isTRUE(shift_states)) {
    tigris::shift_geometry(
      data,
      geoid_column = "geoid",
      position = "below"
    )
  } else {
    sf::st_transform(data, crs)
  }

  ggplot2::ggplot(map_data) +
    ggplot2::geom_sf(
      ggplot2::aes(fill = .data[[value_col]]),
      linewidth = 0
    ) +
    viridis::scale_fill_viridis(
      labels = scales::percent_format(accuracy = 0.1)
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      fill = fill_label,
      caption = source_caption
    ) +
    theme_peebles_map()
}

us_row <- if (!is.null(us_df)) {
  us_df %>%
    dplyr::slice(1)
} else {
  NULL
}

states_barplot <- if (!is.null(state_df)) {
  plot_bar_with_moe(
    state_df,
    title = "Percentage of housing units with complete plumbing (States + D.C.)",
    subtitle = glue::glue(
      "ACS {config$data_year} 5-year; error bars are 90% MOE"
    )
  )
} else {
  NULL
}

lower_48_leaders <- if (!is.null(state_df)) {
  state_df %>%
    dplyr::filter(
      !name_clean %in% c("Alaska", "Hawaii", "District of Columbia")
    ) %>%
    dplyr::slice_max(pct_lacking, n = 2, with_ties = FALSE)
} else {
  NULL
}

newsroom_state_name <- function(state_name) {
  abbreviations <- c(
    "Mississippi" = "Miss.",
    "West Virginia" = "W.Va."
  )

  dplyr::coalesce(unname(abbreviations[state_name]), state_name)
}

state_map_title <- if (!is.null(lower_48_leaders)) {
  leader_names <- newsroom_state_name(lower_48_leaders$name_clean)

  glue::glue(
    "{leader_names[[1]]}, {leader_names[[2]]} lead lower 48 states ",
    "in lack of complete plumbing"
  )
} else {
  NULL
}

state_map_subtitle <- if (!is.null(lower_48_leaders)) {
  alaska_share <- state_df %>%
    dplyr::filter(name_clean == "Alaska") %>%
    dplyr::pull(pct_lacking)

  leader_range <- range(lower_48_leaders$pct_lacking, na.rm = TRUE)

  glue::glue(
    "About {scales::percent(mean(leader_range), accuracy = 0.1)} of housing ",
    "units in both states lack complete plumbing facilities; Alaska is ",
    "highest at {scales::percent(alaska_share, accuracy = 0.1)}."
  )
} else {
  NULL
}

state_map <- if (!is.null(state_df) && isTRUE(config$make_maps)) {
  plot_choropleth(
    state_df,
    value_col = "pct_lacking",
    fill_label = "% lacking",
    title = state_map_title,
    subtitle = state_map_subtitle,
    shift_states = TRUE
  )
} else {
  NULL
}

top_state <- if (!is.null(state_df)) {
  state_df %>%
    dplyr::slice_max(pct_complete, n = 1)
} else {
  NULL
}

bottom_state <- if (!is.null(state_df)) {
  state_df %>%
    dplyr::slice_min(pct_complete, n = 1)
} else {
  NULL
}

county_top15 <- if (!is.null(county_df)) {
  county_df %>%
    dplyr::arrange(dplyr::desc(pct_complete)) %>%
    dplyr::select(
      name_clean,
      state_name,
      total,
      pct_complete,
      pct_complete_moe
    ) %>%
    dplyr::slice_head(n = 15)
} else {
  NULL
}

county_bottom15 <- if (!is.null(county_df)) {
  county_df %>%
    dplyr::arrange(pct_complete) %>%
    dplyr::select(
      name_clean,
      state_name,
      total,
      pct_complete,
      pct_complete_moe
    ) %>%
    dplyr::slice_head(n = 15)
} else {
  NULL
}

counties_bottom30_plot <- if (!is.null(county_df)) {
  county_df %>%
    dplyr::arrange(pct_complete) %>%
    dplyr::slice_head(n = 30) %>%
    plot_bar_with_moe(
      title = "Counties with lowest share of complete plumbing (Bottom 30)",
      subtitle = glue::glue(
        "ACS {config$data_year} 5-year; error bars = 90% MOE"
      )
    )
} else {
  NULL
}

county_map <- if (!is.null(county_df) && isTRUE(config$make_maps)) {
  plot_choropleth(
    county_df,
    value_col = "pct_lacking",
    fill_label = "% lacking",
    title = "Plumbing access gaps vary sharply among U.S. counties",
    subtitle = paste(
      "Yellow areas have a larger share of housing units without",
      "complete plumbing facilities."
    )
  )
} else {
  NULL
}

pct100_cty <- if (!is.null(county_df)) {
  county_df %>%
    dplyr::filter(pct_complete_percentile == 100) %>%
    nrow()
} else {
  NULL
}

pct001_cty <- if (!is.null(county_df)) {
  county_df %>%
    dplyr::filter(pct_complete_percentile == 1) %>%
    nrow()
} else {
  NULL
}

place_top15 <- if (!is.null(place_df)) {
  place_df %>%
    dplyr::arrange(dplyr::desc(pct_complete)) %>%
    dplyr::select(
      name_clean,
      state_name,
      total,
      pct_complete,
      pct_complete_moe
    ) %>%
    dplyr::slice_head(n = 15)
} else {
  NULL
}

place_bottom15 <- if (!is.null(place_df)) {
  place_df %>%
    dplyr::arrange(pct_complete) %>%
    dplyr::select(
      name_clean,
      state_name,
      total,
      pct_complete,
      pct_complete_moe
    ) %>%
    dplyr::slice_head(n = 15)
} else {
  NULL
}

places_top30_plot <- if (!is.null(place_df)) {
  place_df %>%
    dplyr::arrange(dplyr::desc(pct_complete)) %>%
    dplyr::slice_head(n = 30) %>%
    plot_bar_with_moe(
      title = "Places with highest share of complete plumbing (Top 30)",
      subtitle = glue::glue(
        "ACS {config$data_year} 5-year; error bars = 90% MOE"
      )
    )
} else {
  NULL
}

place_map <- if (!is.null(place_df) && isTRUE(config$make_maps)) {
  plot_choropleth(
    place_df,
    value_col = "pct_lacking",
    fill_label = "% lacking",
    title = "Plumbing access gaps persist in U.S. cities and communities",
    subtitle = paste(
      "Yellow areas have a larger share of housing units without",
      "complete plumbing facilities."
    )
  )
} else {
  NULL
}

states_w_100th <- if (!is.null(place_df)) {
  place_df %>%
    dplyr::filter(pct_complete_percentile == 100) %>%
    dplyr::count(state_name, name = "places_in_100th") %>%
    dplyr::arrange(dplyr::desc(places_in_100th))
} else {
  NULL
}

states_w_1st <- if (!is.null(place_df)) {
  place_df %>%
    dplyr::filter(pct_complete_percentile == 1) %>%
    dplyr::count(state_name, name = "places_in_1st") %>%
    dplyr::arrange(dplyr::desc(places_in_1st))
} else {
  NULL
}
