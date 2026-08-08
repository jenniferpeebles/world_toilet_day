testthat::test_that("optional CDC outputs are internally consistent when present", {
  annual_path <- file.path(
    Sys.getenv("WORLD_TOILET_PROJECT_ROOT"),
    "output",
    "data",
    "cdc_nndss_disease_context_annual.csv"
  )

  testthat::skip_if_not(file.exists(annual_path))

  annual <- readr::read_csv(annual_path, show_col_types = FALSE)

  testthat::expect_true(
    all(
      c(
        "year",
        "disease",
        "last_published_week",
        "reported_cases",
        "series_status",
        "retrieved_at",
        "source_url"
      ) %in% names(annual)
    )
  )
  testthat::expect_true(
    all(
      annual$disease %in% c(
        "Typhoid fever",
        "Paratyphoid fever",
        "Cholera"
      )
    )
  )
  testthat::expect_false(
    any(
      duplicated(
        paste(annual$year, annual$disease)
      )
    )
  )
  testthat::expect_true(all(annual$reported_cases >= 0, na.rm = TRUE))
  testthat::expect_match(
    annual$series_status[annual$year == max(annual$year)],
    "Year to date"
  )
})
