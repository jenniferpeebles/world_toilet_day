data_year <- as.integer(Sys.getenv("WORLD_TOILET_DATA_YEAR"))
historical_data_year <- as.integer(
  Sys.getenv("WORLD_TOILET_HISTORICAL_DATA_YEAR")
)
test_project_root <- Sys.getenv("WORLD_TOILET_PROJECT_ROOT")
output_data_dir <- file.path(test_project_root, "output", "data")

read_output <- function(geography) {
  readr::read_csv(
    file.path(
      output_data_dir,
      paste0("b25047_", geography, "_", data_year, ".csv")
    ),
    show_col_types = FALSE
  )
}

required_columns <- c(
  "geoid",
  "name_clean",
  "total",
  "total_moe",
  "complete",
  "complete_moe",
  "lacking",
  "lacking_moe",
  "pct_complete",
  "pct_complete_moe",
  "pct_complete_ci_low",
  "pct_complete_ci_high",
  "pct_complete_ci_overlaps_zero",
  "pct_complete_cv_percent",
  "pct_complete_reliability",
  "pct_lacking",
  "pct_lacking_moe",
  "pct_lacking_ci_low",
  "pct_lacking_ci_high",
  "pct_lacking_ci_overlaps_zero",
  "pct_lacking_cv_percent",
  "pct_lacking_reliability"
)

expected_row_ranges <- list(
  us = c(1, 1),
  state = c(51, 51),
  county = c(3000, 3300),
  place = c(30000, 35000)
)

reliability_levels <- c(
  "High reliability",
  "Moderate reliability",
  "Low reliability",
  "Not classifiable"
)

for (geography in names(expected_row_ranges)) {
  testthat::test_that(
    paste(geography, "output has expected structure and geography coverage"),
    {
      data <- read_output(geography)
      expected_range <- expected_row_ranges[[geography]]

      testthat::expect_true(all(required_columns %in% names(data)))
      testthat::expect_gte(nrow(data), expected_range[[1]])
      testthat::expect_lte(nrow(data), expected_range[[2]])
      testthat::expect_false(any(is.na(data$geoid)))
      testthat::expect_equal(
        dplyr::n_distinct(data$geoid),
        nrow(data)
      )
    }
  )

  testthat::test_that(
    paste(geography, "counts and confidence bounds are internally consistent"),
    {
      data <- read_output(geography)

      testthat::expect_true(
        all(
          data$total == data$complete + data$lacking,
          na.rm = TRUE
        )
      )
      testthat::expect_true(
        all(
          data$pct_complete_ci_low >= 0 &
            data$pct_complete_ci_high <= 1,
          na.rm = TRUE
        )
      )
      testthat::expect_true(
        all(
          data$pct_lacking_ci_low >= 0 &
            data$pct_lacking_ci_high <= 1,
          na.rm = TRUE
        )
      )
      testthat::expect_true(
        all(
          data$pct_complete_ci_low <= data$pct_complete_ci_high,
          na.rm = TRUE
        )
      )
      testthat::expect_true(
        all(
          data$pct_lacking_ci_low <= data$pct_lacking_ci_high,
          na.rm = TRUE
        )
      )
    }
  )

  testthat::test_that(
    paste(geography, "reliability classifications use declared levels"),
    {
      data <- read_output(geography)

      testthat::expect_true(
        all(data$pct_complete_reliability %in% reliability_levels)
      )
      testthat::expect_true(
        all(data$pct_lacking_reliability %in% reliability_levels)
      )
      testthat::expect_true(
        all(data$pct_complete_cv_percent >= 0, na.rm = TRUE)
      )
      testthat::expect_true(
        all(data$pct_lacking_cv_percent >= 0, na.rm = TRUE)
      )
    }
  )
}

testthat::test_that("QA and row-level confidence flag files are valid", {
  qa <- readr::read_csv(
    file.path(output_data_dir, "qa_summary.csv"),
    show_col_types = FALSE
  )
  flags <- readr::read_csv(
    file.path(output_data_dir, "ci_zero_flags.csv"),
    show_col_types = FALSE
  )

  testthat::expect_equal(
    sort(qa$geography),
    sort(c("us", "state", "county", "place"))
  )
  testthat::expect_true(
    all(flags$confidence_interval_overlaps_zero)
  )
  testthat::expect_true(
    all(
      flags$confidence_interval_low_90 <= 0,
      na.rm = TRUE
    )
  )
})

testthat::test_that("expected graphics and GeoJSON files exist", {
  graphics <- file.path(
    test_project_root,
    "output",
    "graphics",
    paste0(
      c(
        "map_states_pct_lacking_",
        "map_counties_pct_lacking_",
        "map_places_pct_lacking_"
      ),
      data_year,
      ".jpg"
    )
  )
  geojson <- file.path(
    test_project_root,
    "output",
    "geojson",
    paste0(
      "b25047_",
      c("state", "county", "place"),
      "_",
      data_year,
      ".geojson"
    )
  )

  testthat::expect_true(all(file.exists(graphics)))
  testthat::expect_true(all(file.exists(geojson)))
  testthat::expect_true(all(file.info(graphics)$size > 0))
  testthat::expect_true(all(file.info(geojson)$size > 0))
})

testthat::test_that("interactive county map exists and is nonempty", {
  interactive_map <- file.path(
    test_project_root,
    "output",
    "interactive",
    paste0(
      "map_counties_pct_lacking_interactive_",
      data_year,
      ".html"
    )
  )

  testthat::expect_true(file.exists(interactive_map))
  testthat::expect_gt(file.info(interactive_map)$size, 10000)
})

testthat::test_that("county ranking outputs are complete and unique", {
  national_rankings <- readr::read_csv(
    file.path(
      output_data_dir,
      paste0("county_rankings_national_", data_year, ".csv")
    ),
    show_col_types = FALSE
  )
  georgia_rankings <- readr::read_csv(
    file.path(
      output_data_dir,
      paste0("county_rankings_georgia_", data_year, ".csv")
    ),
    show_col_types = FALSE
  )

  testthat::expect_gte(nrow(national_rankings), 3000)
  testthat::expect_lte(nrow(national_rankings), 3300)
  testthat::expect_equal(nrow(georgia_rankings), 159)
  testthat::expect_equal(
    dplyr::n_distinct(national_rankings$geoid),
    nrow(national_rankings)
  )
  testthat::expect_equal(
    sort(unique(georgia_rankings$decile_pct_lacking)),
    1:10
  )
  testthat::expect_true(
    all(
      dplyr::between(
        national_rankings$percentile_pct_lacking,
        0,
        100
      )
    )
  )
})

testthat::test_that("historical snapshot is national and noncomparative", {
  snapshot <- readr::read_csv(
    file.path(
      output_data_dir,
      paste0(
        "historical_plumbing_snapshot_",
        historical_data_year,
        ".csv"
      )
    ),
    show_col_types = FALSE
  )

  testthat::expect_equal(nrow(snapshot), 1)
  testthat::expect_equal(snapshot$geography, "United States")
  testthat::expect_true(all(!snapshot$modern_comparison_allowed))
  testthat::expect_true(
    stringr::str_detect(
      snapshot$historical_definition,
      "flush toilet"
    )
  )
  testthat::expect_true(
    stringr::str_detect(
      snapshot$interpretation,
      "does not identify which facility"
    )
  )
  testthat::expect_true(
    stringr::str_detect(
      snapshot$comparability_note,
      "Do not compare directly"
    )
  )

  historical_graphic <- file.path(
    test_project_root,
    "output",
    "graphics",
    paste0(
      "historical_plumbing_snapshot_",
      historical_data_year,
      ".jpg"
    )
  )

  testthat::expect_true(file.exists(historical_graphic))
  testthat::expect_gt(file.info(historical_graphic)$size, 0)
})

testthat::test_that("tracked README graphics exist and are nonempty", {
  readme_graphics <- file.path(
    test_project_root,
    "images",
    "readme",
    c(
      paste0("state_plumbing_map_", data_year, ".jpg"),
      paste0(
        "historical_plumbing_snapshot_",
        historical_data_year,
        ".jpg"
      )
    )
  )

  testthat::expect_true(all(file.exists(readme_graphics)))
  testthat::expect_true(all(file.info(readme_graphics)$size > 10000))
})
