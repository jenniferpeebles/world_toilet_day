# World Toilet Day: local presentation and export helpers
#
# These small helpers were adapted from Jennifer Peebles' private
# PeeblesToolbox package so this public project can run without a private
# dependency. The original helpers and these local copies are MIT licensed.

theme_peebles_map <- function(base_size = 11, legend_position = "right") {
  ggplot2::theme_void(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(size = 11),
      plot.caption = ggplot2::element_text(color = "gray40", hjust = 0),
      legend.position = legend_position,
      panel.grid = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank()
    )
}

theme_peebles_chart <- function(
    base_size = 11,
    legend_position = "right",
    angle_x_labels = 25
) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 16),
      plot.subtitle = ggplot2::element_text(size = 11),
      plot.caption = ggplot2::element_text(color = "gray40", hjust = 0),
      axis.text.x = ggplot2::element_text(
        angle = angle_x_labels,
        hjust = if (angle_x_labels == 0) 0.5 else 1
      ),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = legend_position
    )
}

save_peebles_plot <- function(
    plot,
    filename,
    folder = file.path("output", "graphics"),
    width = 9,
    height = 6,
    dpi = 300,
    ...
) {
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }

  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  full_path <- file.path(folder, filename)

  ggplot2::ggsave(
    filename = full_path,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    ...
  )

  message(
    "Saved plot: ",
    normalizePath(full_path, winslash = "/", mustWork = FALSE)
  )
  invisible(plot)
}

export_geojson <- function(
    layer,
    filename,
    folder = file.path("output", "geojson"),
    overwrite = FALSE,
    quiet = TRUE
) {
  if (inherits(layer, "sfc")) {
    layer <- sf::st_sf(geometry = layer)
  } else if (is.character(layer) && length(layer) == 1L) {
    if (!file.exists(layer)) {
      stop("GIS layer file does not exist: ", layer, call. = FALSE)
    }
    layer <- sf::st_read(layer, quiet = quiet)
  }

  if (!inherits(layer, "sf")) {
    stop(
      "`layer` must be an sf object, an sfc geometry vector, or a path ",
      "to a GIS layer that sf can read.",
      call. = FALSE
    )
  }

  if (is.na(sf::st_crs(layer))) {
    stop(
      "The GIS layer has no coordinate reference system. Assign its true ",
      "CRS before exporting.",
      call. = FALSE
    )
  }

  filename <- as.character(filename)
  if (length(filename) != 1L || is.na(filename) || !nzchar(trimws(filename))) {
    stop("`filename` must be one nonempty filename.", call. = FALSE)
  }

  if (!grepl("\\.geojson$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".geojson")
  }

  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  output_path <- file.path(folder, filename)

  if (file.exists(output_path) && !isTRUE(overwrite)) {
    stop(
      "Output already exists: ", output_path,
      ". Use `overwrite = TRUE` to replace it.",
      call. = FALSE
    )
  }

  sf::st_transform(layer, 4326) %>%
    sf::st_write(
      dsn = output_path,
      driver = "GeoJSON",
      delete_dsn = isTRUE(overwrite),
      quiet = quiet
    )

  output_path <- normalizePath(
    output_path,
    winslash = "/",
    mustWork = TRUE
  )
  message("Saved WGS84 GeoJSON: ", output_path)
  invisible(output_path)
}
