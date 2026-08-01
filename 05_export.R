# World Toilet Day: ACS plumbing access
# 05_export.R
#
# Writes final datasets, QA results, maps, and GeoJSON files.

write_plumbing_outputs <- function(data, stem, write_geojson = TRUE) {
  csv_data <- if (inherits(data, "sf")) {
    sf::st_drop_geometry(data)
  } else {
    data
  }

  readr::write_csv(
    csv_data,
    file.path(paths$data, paste0(stem, ".csv"))
  )

  if (isTRUE(write_geojson) && inherits(data, "sf")) {
    export_geojson(
      layer = data,
      filename = paste0(stem, ".geojson"),
      folder = paths$geojson,
      overwrite = TRUE
    )
  }

  invisible(data)
}

if (!is.null(us_df)) {
  write_plumbing_outputs(
    us_df,
    glue::glue("b25047_us_{config$data_year}"),
    write_geojson = FALSE
  )
}

if (!is.null(state_df)) {
  write_plumbing_outputs(
    state_df,
    glue::glue("b25047_state_{config$data_year}")
  )
}

if (!is.null(county_df)) {
  write_plumbing_outputs(
    county_df,
    glue::glue("b25047_county_{config$data_year}")
  )
}

if (!is.null(place_df)) {
  write_plumbing_outputs(
    place_df,
    glue::glue("b25047_place_{config$data_year}")
  )
}

readr::write_csv(
  qa_summary,
  file.path(paths$data, "qa_summary.csv")
)

readr::write_csv(
  ci_zero_flags,
  file.path(paths$data, "ci_zero_flags.csv")
)

if (!is.null(state_map)) {
  save_peebles_plot(
    plot = state_map,
    filename = glue::glue(
      "map_states_pct_lacking_{config$data_year}.jpg"
    ),
    folder = paths$graphics,
    width = 9,
    height = 6,
    dpi = 300,
    bg = "white"
  )
}

if (!is.null(county_map)) {
  save_peebles_plot(
    plot = county_map,
    filename = glue::glue(
      "map_counties_pct_lacking_{config$data_year}.jpg"
    ),
    folder = paths$graphics,
    width = 10.5,
    height = 7,
    dpi = 300,
    bg = "white"
  )
}

if (!is.null(place_map)) {
  save_peebles_plot(
    plot = place_map,
    filename = glue::glue(
      "map_places_pct_lacking_{config$data_year}.jpg"
    ),
    folder = paths$graphics,
    width = 10.5,
    height = 7,
    dpi = 300,
    bg = "white"
  )
}
