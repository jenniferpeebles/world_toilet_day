# World Toilet Day: selected README graphics
# 16_publish_readme_graphics.R
#
# Writes only the two publication-ready JPEGs embedded in README.md. Unlike
# routine files under output/, these images are intentionally tracked by Git.

if (!exists("state_map", inherits = TRUE) || is.null(state_map)) {
  stop(
    "The state map is unavailable. Run the pipeline through 04_visualize.R ",
    "before publishing README graphics.",
    call. = FALSE
  )
}

if (
  !exists("historical_snapshot_plot", inherits = TRUE) ||
    is.null(historical_snapshot_plot)
) {
  stop(
    "The historical snapshot is unavailable. Run the pipeline through ",
    "13_visualize_historical_snapshot.R before publishing README graphics.",
    call. = FALSE
  )
}

save_peebles_plot(
  plot = state_map,
  filename = glue::glue(
    "state_plumbing_map_{config$data_year}.jpg"
  ),
  folder = paths$readme_images,
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white"
)

save_peebles_plot(
  plot = historical_snapshot_plot,
  filename = glue::glue(
    "historical_plumbing_snapshot_{config$historical_data_year}.jpg"
  ),
  folder = paths$readme_images,
  width = 9,
  height = 6,
  dpi = 300,
  bg = "white"
)

message(
  "Published two tracked README graphics to: ",
  normalizePath(
    paths$readme_images,
    winslash = "/",
    mustWork = TRUE
  )
)
