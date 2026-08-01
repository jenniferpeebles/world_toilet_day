# World Toilet Day: ACS plumbing access
# 08_create_interactive_county_map.R
#
# Creates a self-contained Leaflet map from the already analyzed and QA'd
# county output. This is a presentation step and does not change the analysis.

configure_project_pandoc()

county_map_data <- if (exists("county_df", inherits = TRUE)) {
  county_df
} else {
  sf::st_read(
    file.path(
      paths$geojson,
      glue::glue("b25047_county_{config$data_year}.geojson")
    ),
    quiet = TRUE
  )
}

county_map_data <- county_map_data %>%
  sf::st_transform(4326)

county_palette <- leaflet::colorNumeric(
  palette = viridis::viridis(256, direction = -1),
  domain = county_map_data$pct_lacking,
  na.color = "#d9d9d9"
)

county_labels <- glue::glue(
  "<strong>{htmltools::htmlEscape(county_map_data$name_clean)}</strong><br/>",
  "Housing units lacking complete plumbing: ",
  "{scales::comma(county_map_data$lacking)}<br/>",
  "Share lacking complete plumbing: ",
  "{scales::percent(county_map_data$pct_lacking, accuracy = 0.1)}<br/>",
  "90% confidence interval: ",
  "{scales::percent(county_map_data$pct_lacking_ci_low, accuracy = 0.1)}",
  "–",
  "{scales::percent(county_map_data$pct_lacking_ci_high, accuracy = 0.1)}<br/>",
  "Reliability: ",
  "{htmltools::htmlEscape(county_map_data$pct_lacking_reliability)}"
) %>%
  lapply(htmltools::HTML)

interactive_county_map <- leaflet::leaflet(
  county_map_data,
  options = leaflet::leafletOptions(
    minZoom = 3,
    preferCanvas = TRUE
  )
) %>%
  leaflet::addProviderTiles(
    leaflet::providers$CartoDB.PositronNoLabels
  ) %>%
  leaflet::addPolygons(
    fillColor = ~county_palette(pct_lacking),
    fillOpacity = 0.82,
    color = "#ffffff",
    weight = 0.35,
    opacity = 0.8,
    label = county_labels,
    popup = county_labels,
    highlightOptions = leaflet::highlightOptions(
      weight = 2,
      color = "#222222",
      fillOpacity = 0.95,
      bringToFront = TRUE
    )
  ) %>%
  leaflet::addLegend(
    position = "bottomright",
    pal = county_palette,
    values = ~pct_lacking,
    title = "Housing units lacking<br/>complete plumbing",
    labFormat = leaflet::labelFormat(transform = function(x) x * 100, suffix = "%"),
    opacity = 0.9
  ) %>%
  leaflet::addControl(
    html = paste0(
      "<div style='background:rgba(255,255,255,.94);padding:10px 12px;",
      "max-width:360px;box-shadow:0 1px 5px rgba(0,0,0,.35);'>",
      "<strong>Where U.S. housing units lack complete plumbing</strong><br/>",
      "<span style='font-size:12px;'>County estimates. Mouse over or click ",
      "a county for its estimate, 90% confidence interval and reliability. ",
      "Source: U.S. Census Bureau, 2020–2024 American Community Survey ",
      "5-year estimates.</span></div>"
    ),
    position = "topleft"
  )

interactive_map_file <- file.path(
  paths$interactive,
  glue::glue(
    "map_counties_pct_lacking_interactive_{config$data_year}.html"
  )
)

interactive_map_libdir <- file.path(
  paths$interactive,
  paste0(
    "leaflet_widget_dependencies_",
    Sys.getpid(),
    "_",
    format(Sys.time(), "%Y%m%d%H%M%S")
  )
)

htmlwidgets::saveWidget(
  widget = interactive_county_map,
  file = interactive_map_file,
  selfcontained = TRUE,
  libdir = interactive_map_libdir,
  title = "Where U.S. housing units lack complete plumbing"
)

message(
  "Created interactive county map: ",
  normalizePath(
    interactive_map_file,
    winslash = "/",
    mustWork = TRUE
  )
)
