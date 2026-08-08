# World Toilet Day: ACS plumbing access
# 00_setup.R
#
# Defines project configuration, checks dependencies, and establishes output
# paths. Run the complete analysis from 99_run_pipeline.R.

required_packages <- c(
  "tidyverse",
  "janitor",
  "glue",
  "httr2",
  "beepr",
  "leaflet",
  "htmlwidgets",
  "knitr",
  "rmarkdown",
  "testthat",
  "tidycensus",
  "tigris",
  "sf",
  "scales",
  "viridis"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "Install the required packages before running the pipeline: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

invisible(
  lapply(
    required_packages,
    function(package) {
      library(package, character.only = TRUE)
    }
  )
)

options(
  digits = 3,
  scipen = 999,
  stringsAsFactors = FALSE,
  tigris_use_cache = TRUE
)

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

if (!file.exists(file.path(project_root, "world_toilet_day_public_script.Rproj"))) {
  stop(
    "Run 99_run_pipeline.R from the project root.",
    call. = FALSE
  )
}

source(
  file.path(project_root, "00_helpers.R"),
  local = globalenv(),
  encoding = "UTF-8"
)

config <- list(
  data_year = 2024,
  historical_data_year = 2009,
  survey = "acs5",
  geos = c("us", "state", "county", "place"),
  states = NULL,
  make_maps = TRUE,
  crs_map = 9311,
  analyst_credit = "Jennifer Peebles • AJC"
)

paths <- list(
  output = file.path(project_root, "output"),
  data = file.path(project_root, "output", "data"),
  graphics = file.path(project_root, "output", "graphics"),
  geojson = file.path(project_root, "output", "geojson"),
  interactive = file.path(project_root, "output", "interactive"),
  logs = file.path(project_root, "output", "logs"),
  readme_images = file.path(project_root, "images", "readme")
)

invisible(
  lapply(
    paths,
    dir.create,
    recursive = TRUE,
    showWarnings = FALSE
  )
)

if (!nzchar(Sys.getenv("CENSUS_API_KEY"))) {
  message(
    "No CENSUS_API_KEY environment variable was found. ",
    "Small requests may still work; set the key in your user .Renviron ",
    "for regular Census API use."
  )
}

b25047_variables <- c(
  total = "B25047_001",
  complete = "B25047_002",
  lacking = "B25047_003"
)

configure_project_pandoc <- function() {
  if (rmarkdown::pandoc_available()) {
    return(invisible(rmarkdown::find_pandoc()))
  }

  pandoc_candidates <- c(
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools",
    paste0(
      Sys.getenv("LOCALAPPDATA"),
      "/Programs/Positron/resources/app/quarto/bin/tools"
    )
  )

  pandoc_dir <- pandoc_candidates[
    file.exists(file.path(pandoc_candidates, "pandoc.exe"))
  ][1]

  if (is.na(pandoc_dir)) {
    stop(
      "Pandoc was not found. Open the project in RStudio or install Pandoc ",
      "before producing HTML output.",
      call. = FALSE
    )
  }

  Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
  invisible(rmarkdown::find_pandoc())
}
