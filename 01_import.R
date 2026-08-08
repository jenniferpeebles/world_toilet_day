# World Toilet Day: ACS plumbing access
# 01_import.R
#
# Retrieves the benchmark ACS estimates. Cleaning and calculations occur in
# 02_clean_analyze.R.

fetch_plumbing_data <- function(
    geo,
    year = config$data_year,
    survey = config$survey,
    states = config$states,
    with_geometry = TRUE
) {
  supported_geographies <- c("us", "state", "county", "place")

  if (!geo %in% supported_geographies) {
    stop("Unsupported geography: ", geo, call. = FALSE)
  }

  base_args <- list(
    variables = b25047_variables,
    year = year,
    survey = survey,
    cache_table = TRUE,
    output = "wide",
    geometry = with_geometry && geo != "us"
  )

  if (geo %in% c("us", "state")) {
    return(
      do.call(
        tidycensus::get_acs,
        c(list(geography = geo), base_args)
      )
    )
  }

  if (is.null(states)) {
    return(
      do.call(
        tidycensus::get_acs,
        c(list(geography = geo), base_args)
      )
    )
  }

  states %>%
    purrr::map_dfr(
      function(state) {
        do.call(
          tidycensus::get_acs,
          c(
            list(
              geography = geo,
              state = state
            ),
            base_args
          )
        )
      }
    )
}

us_raw <- if ("us" %in% config$geos) {
  fetch_plumbing_data("us", with_geometry = FALSE)
} else {
  NULL
}

state_raw <- if ("state" %in% config$geos) {
  fetch_plumbing_data("state", with_geometry = TRUE)
} else {
  NULL
}

county_raw <- if ("county" %in% config$geos) {
  fetch_plumbing_data("county", with_geometry = TRUE)
} else {
  NULL
}

place_raw <- if ("place" %in% config$geos) {
  fetch_plumbing_data("place", with_geometry = TRUE)
} else {
  NULL
}
